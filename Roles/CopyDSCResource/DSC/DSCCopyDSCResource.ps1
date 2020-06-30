param (
    $ConfPath
)

Configuration CopyDSCResource {

    $DSCConfigContent = (Get-Content .\Roles\CopyDSCResource\Config\DSCResource.json | ConvertFrom-Json)

    Node $AllNodes.NodeName
    {
        File TempFolder {
            Type            = 'Directory'
            DestinationPath = 'c:\Temp'
            Ensure          = 'Present'
        }

        #DSResource
<#         File DSCResourceFolder {
            Ensure          = "Present"
            SourcePath      = "$($DSCConfigContent.SourceShare)"
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\Modules"
            #Recurse         = $true
            Type            = "File"
        } #>

        Script DownloadDSC {
            GetScript  = { @{ Result = (Test-Path -Path "c:\temp\modules.zip"); } };
            SetScript  = {
                $Uri = $using:DSCConfigContent.SourceShare;
                $OutFile = "c:\temp\modules.zip";
                Invoke-WebRequest -Uri $Uri -OutFile $OutFile;
                Unblock-File -Path $OutFile;
            };
            TestScript = { return $false }
        }

        Archive ExtractModules {
            Ensure      = "Present"
            Path        = "c:\temp\modules.zip"
            Destination = "C:\Temp\"
        }

        File DSCResourceFolder {
            Ensure          = "Present"
            SourcePath      = "c:\temp\modules"
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\Modules"
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[Archive]ExtractModules"
        }
    }
}

CopyDSCResource -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath
