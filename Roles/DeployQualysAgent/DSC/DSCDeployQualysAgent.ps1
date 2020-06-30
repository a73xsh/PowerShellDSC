param (
    $ConfPath
)

configuration DeployQualysAgent
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    $QualysConfigContent = (Get-Content .\Roles\DeployQualysAgent\Config\QualysAgent.json | ConvertFrom-Json)

    Node $AllNodes.NodeName
    {

        File TempFolder {
            Type            = 'Directory'
            DestinationPath = 'c:\Temp'
            Ensure          = 'Present'
        }

        #Install Qualys agent
        File CopyAgent {
            Type            = 'File'
            SourcePath      = (Join-Path -Path $QualysConfigContent.SourceShare -ChildPath $QualysConfigContent.AgentFile)
            DestinationPath = 'C:\Temp\QualysCloudAgent.exe'
            Ensure          = 'Present'
            DependsOn       = "[File]TempFolder"
        }

    }

    Node $AllNodes.Where{ $_.Site -like "PROD-*" }.NodeName
    {
            Package QualysCloudAgent {
                Ensure    = "Present"
                Name      = "Qualys Cloud Security Agent"
                Path      = "C:\Temp\QualysCloudAgent.exe"
                ProductId = ''
                Arguments = "CustomerId=$($QualysConfigContent.ProdSite.CustomerId) ActivationId=$($QualysConfigContent.ProdSite.ActivationId)"
            }
    }

    Node $AllNodes.Where{ $_.Site -like "DEV-*" }.NodeName
    {
        Package QualysCloudAgent {
            Ensure    = "Present"
            Name      = "Qualys Cloud Security Agent"
            Path      = "C:\Temp\QualysCloudAgent.exe"
            ProductId = ''
            Arguments = "CustomerId=$($QualysConfigContent.DevSite.CustomerId) ActivationId=$($QualysConfigContent.DevSite.ActivationId)"
        }
    }
}
DeployQualysAgent -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath