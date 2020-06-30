param
(
    $RoleConfig
)
$VMsConfigContent = (Get-Content $RoleConfig | ConvertFrom-Json)
$NodeNameFirst = $VMsConfigContent.vms[0].VMNetworkAdapters[0].IpAddress
$NodeNameSecond = $VMsConfigContent.vms[1].VMNetworkAdapters[0].IpAddress

Configuration RebootNode
{
    Import-DscResource -Module ComputerManagementDsc

    Node $AllNodes.NodeName
    {
        PendingReboot "AfterProvisionVM" {
            Name      = "AfterProvisionVM"
        }
    }

}
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "*"

        },
        @{
            NodeName                    = "$NodeNameFirst"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            Role                        = 'FirstServerNode'
        },
        @{
            NodeName                    = "$NodeNameSecond"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
            Role                        = 'AdditionalServerNode'
        }
    )
}
RebootNode -outputPath ".\Roles\DeployWACHA\DSC\temp\" -ConfigurationData  $ConfigData