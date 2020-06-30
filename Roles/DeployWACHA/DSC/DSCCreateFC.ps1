param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,
    $RoleConfig
)
    $VMsConfigContent = (Get-Content $RoleConfig | ConvertFrom-Json)
    $NodeNameFirst = $VMsConfigContent.vms[0].VMNetworkAdapters[0].IpAddress
    $NodeNameSecond = $VMsConfigContent.vms[1].VMNetworkAdapters[0].IpAddress

Configuration CreateFC
{

    Import-DscResource -Module ComputerManagementDsc
    Import-DscResource -ModuleName xFailOverCluster

    Node $AllNodes.Where{$_.Role -eq 'FirstServerNode'}.NodeName
    {

                WindowsFeature AddFailoverFeature {
                    Ensure = 'Present'
                    Name   = 'Failover-clustering'
                }

                WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature {
                    Ensure    = 'Present'
                    Name      = 'RSAT-Clustering-PowerShell'
                    DependsOn = '[WindowsFeature]AddFailoverFeature'
                }

                WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature {
                    Ensure    = 'Present'
                    Name      = 'RSAT-Clustering-CmdInterface'
                    DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
                }

                xCluster CreateCluster {
                    Name                          = $VMsConfigContent.ClusterName
                    StaticIPAddress               = $VMsConfigContent.ClusterIPAddress
                    # This user must have the permission to create the CNO (Cluster Name Object) in Active Directory, unless it is prestaged.
                    DomainAdministratorCredential = $Credential
                    DependsOn                     = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
                }
    }

    Node $AllNodes.Where{ $_.Role -eq 'AdditionalServerNode' }.NodeName
    {

                WindowsFeature AddFailoverFeature {
                    Ensure = 'Present'
                    Name   = 'Failover-clustering'
                }

                WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature {
                    Ensure    = 'Present'
                    Name      = 'RSAT-Clustering-PowerShell'
                    DependsOn = '[WindowsFeature]AddFailoverFeature'
                }

                WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature {
                    Ensure    = 'Present'
                    Name      = 'RSAT-Clustering-CmdInterface'
                    DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
                }

                xWaitForCluster WaitForCluster {
                    Name             = $VMsConfigContent.ClusterName
                    RetryIntervalSec = 10
                    RetryCount       = 60
                    DependsOn        = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature'
                }

                xCluster JoinSecondNodeToCluster {
                    Name                          = $VMsConfigContent.ClusterName
                    StaticIPAddress               = $VMsConfigContent.ClusterIPAddress
                    DomainAdministratorCredential = $Credential
                    DependsOn                     = '[xWaitForCluster]WaitForCluster'
                }

    }

}
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = "$NodeNameFirst"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            Role     = 'FirstServerNode'
        },
        @{
            NodeName                    = "$NodeNameSecond"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            Role     = 'AdditionalServerNode'
        }
    )
}
CreateFC -outputPath ".\Roles\DeployWACHA\DSC\temp\" -ConfigurationData  $ConfigData