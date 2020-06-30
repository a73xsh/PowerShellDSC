param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,
    [Parameter(Mandatory)]
    [string]
    $DomainName,
    [Parameter(Mandatory)]
    [string]
    $ComputerName
)
Configuration DomainJoin
{
    Import-DscResource -Module ComputerManagementDsc

    Node $NodeName
    {
        Computer "JoinDomain-$($ComputerName)" {
            Name       = $ComputerName
            DomainName = $DomainName
            Credential = $Credential # Credential to join to domain
        }

        PendingReboot "AfterDomainJoin-$($ComputerName)" {
            Name      = "AfterDomainJoin-$($ComputerName)"
            DependsOn = "[Computer]JoinDomain-$($ComputerName)"
        }
    }
}
$ConfigData = @{
    AllNodes = @(
        @{
            NodeName                    = "$NodeName"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }
    )
}

JoinDomain -outputPath ".\Roles\JoinDomain\DSC\temp\" -ConfigurationData $ConfPath
