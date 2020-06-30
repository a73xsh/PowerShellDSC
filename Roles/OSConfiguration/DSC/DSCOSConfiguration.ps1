param (
    $ConfPath
)

configuration OSConfiguration
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    Node $AllNodes.NodeName
    {

        TimeZone HostTime {
            IsSingleInstance = 'Yes'
            TimeZone         = 'UTC'
        }

        Script RenameGuestAccount {
            SetScript  = { Rename-LocalUser -Name "Guest" -NewName "OS33_Guest" }
            TestScript = { [bool](Get-LocalUser -Name "OS33_Guest" -ErrorAction Ignore) }
            GetScript  = { @{Ensure = if ([bool](Get-LocalUser -Name "OS33_Guest" -ErrorAction Ignore)) { 'Present' } else { 'Absent' } } }

        }

        RemoteDesktopAdmin RemoteDesktopSettings {
            IsSingleInstance   = 'yes'
            Ensure             = 'Present'
            UserAuthentication = 'Secure'
        }

        PowerPlan SetPlanHighPerformance {
          IsSingleInstance = 'Yes'
          Name             = 'High performance'
        }

        WindowsFeature RSAT-Clustering-Powershell {
            Ensure               = 'Present'
            Name                 = 'RSAT-Clustering-Powershell'
            IncludeAllSubFeature = $true
        }

        WindowsFeature Hyper-V-PowerShell {
            Ensure               = 'Present'
            Name                 = 'Hyper-V-PowerShell'
            IncludeAllSubFeature = $true
        }

        WindowsFeature Windows-Defender {
            Ensure = 'Absent'
            Name   = 'Windows-Defender'
        }

    }

    Node $AllNodes.Where{ $_.Role -ne "DomainControler" }.NodeName
    {
        Group AddGroupToLocalAdminGroup {
            GroupName        = 'Administrators'
            Ensure           = 'Present'
            MembersToInclude = 'sddc\Local_Hosts_Admin'
            #Credential           = $dCredential
            #PsDscRunAsCredential = $DCredential
        }
    }

    Node $AllNodes.Where{ $_.Role -eq "DomainControler" }.NodeName
    {
        Service EnableW32Time {
            Name        = "W32Time"
            StartupType = "Automatic"
            State       = "Running"
        }

        Script EnableTimeSynchronization {
            TestScript = {
                return ((Get-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Parameters").NtpServer -match "ntp.org")
            }
            SetScript  = {
                w32tm.exe /config /manualpeerlist:"0.us.pool.ntp.org,1.us.pool.ntp.org,2.us.pool.ntp.org,3.us.pool.ntp.org" /syncfromflags:manual /update | Out-Null
                Restart-Service W32Time
                w32tm.exe /resync
            }
            GetScript  = {
                return (Get-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Services\W32Time\Parameters").NtpServer
            }
            DependsOn  = "[Service]EnableW32Time"
        }
    }

}

OSConfiguration -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath