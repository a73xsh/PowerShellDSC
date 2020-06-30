param
(
    [string[]]$NodeName = 'localhost',
    [Parameter(Mandatory = $true)]
    [ValidateNotNullorEmpty()]
    [System.Management.Automation.PSCredential]
    $Credential,
    $RoleConfig
)
$VMsConfigContent = (Get-Content $RoleConfig | ConvertFrom-Json)

Configuration CopyDSCResource {
    Node $NodeName

    {
        #DSResource
        File DSCResourceFolder {
            Ensure          = "Present"
            SourcePath      = $VMsConfigContent.DSCResources
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\Modules"
            Recurse         = $true
            Type            = "Directory"
            PsDscRunAsCredential = $Credential
            Credential           = $Credential
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

CopyDSCResource -outputPath ".\Roles\DeployWACHA\DSC\temp\" -ConfigurationData  $ConfigData