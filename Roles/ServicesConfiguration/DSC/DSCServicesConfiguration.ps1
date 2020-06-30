param (
    $ConfPath
)

configuration ServicesConfiguration
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    Node $AllNodes.NodeName
    {

        Service PlugPlay {
            Name        = "PlugPlay"
            StartupType = "Automatic"
            State       = "Running"
        }

        Service RemoteRegistry {
            Name        = "RemoteRegistry"
            StartupType = "Automatic"
            State       = "Running"
        }

        Service vds {
            Name        = "vds"
            StartupType = "Automatic"
            State       = "Running"
        }

    }
}

ServicesConfiguration -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath