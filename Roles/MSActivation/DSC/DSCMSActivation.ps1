param (
    $ConfPath
)

configuration MSActivation
{
    $MSActivationContent = (Get-Content .\Roles\MSActivation\Config\MSActivation.json | ConvertFrom-Json)

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName DSCR_MSLicense


     Node $AllNodes.Where{ $_.Role -eq "Hyper-V" }.NodeName
     {
        cWindowsLicense Win2019 {
            ProductKey = $MSActivationContent.HostsActivation.ProductKey
            Activate   = $true
        }
     }
        Node $AllNodes.Where{ $_.Role -ne "Hyper-V" }.NodeName
     {
        cWindowsLicense Win2019 {
            ProductKey = $MSActivationContent.MgmtActivation.ProductKey
            Activate   = $true
        }
     }
}

MSActivation -outputPath ".\Roles\MSActivation\DSC\temp\" -ConfigurationData $ConfPath
