param (
    $ConfPath
)

configuration DeployAgents
{
    #Install-PackageProvider -Name NuGet
    #Install-Module -Name xHyper-V
    #Install-Module -Name ComputerManagementDsc

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    $McafeeConfigContent = (Get-Content .\Roles\DeployMcafeeAgent\Config\McafeeAgent.json | ConvertFrom-Json)

    Node $AllNodes.NodeName
    {

        File TempFolder {
            Type            = 'Directory'
            DestinationPath = 'c:\Temp'
            Ensure          = 'Present'
        }

    }

    Node $AllNodes.Where{ $_.Site -like "PROD-*" }.NodeName
    {

        #Install mcafee epo agents
        File CopyAgentMcafee {
            Type            = 'File'
            SourcePath      = (Join-Path -Path $McafeeConfigContent.SourceShare -ChildPath $McafeeConfigContent.ProdSite.AgentFile)
            DestinationPath = (Join-Path -Path 'C:\Temp' -ChildPath $McafeeConfigContent.ProdSite.AgentFile)
            Ensure          = 'Present'
            DependsOn       = "[File]TempFolder"
        }

        Archive ArchiveExample {
            Ensure      = "Present"
            Path        = (Join-Path -Path 'C:\Temp' -ChildPath $McafeeConfigContent.ProdSite.AgentFile)
            Destination = "C:\Temp\"
        }

        Package McAfeeAgent {
            Ensure    = "Present"
            Name      = "McAfee Agent"
            Path      = "C:\Temp\magent563\FramePkg.exe"
            ProductId = ''
            Arguments = '/install=agent' # args for silent mode
        }


    }

    Node $AllNodes.Where{ $_.Site -like "DEV-*" }.NodeName
    {

        #Install mcafee epo agents
        File CopyAgentMcafee {
            Type            = 'File'
            SourcePath      = (Join-Path -Path $McafeeConfigContent.SourceShare -ChildPath $McafeeConfigContent.DevSite.AgentFile)
            DestinationPath = (Join-Path -Path 'C:\Temp' -ChildPath $McafeeConfigContent.DevSite.AgentFile)
            Ensure          = 'Present'
            DependsOn       = "[File]TempFolder"
        }

        Archive ArchiveExample {
            Ensure      = "Present"
            Path        = (Join-Path -Path 'C:\Temp' -ChildPath $McafeeConfigContent.DevSite.AgentFile)
            Destination = "C:\Temp\"
        }

        Package McAfeeAgent {
            Ensure    = "Present"
            Name      = "McAfee Agent"
            Path      = "C:\Temp\magent563\FramePkg.exe"
            ProductId = ''
            Arguments = '/install=agent' # args for silent mode
        }

    }


}
DeployAgents -outputPath "C:\temp" -ConfigurationData $ConfPath