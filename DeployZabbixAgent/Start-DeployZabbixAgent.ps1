.\DSC\DSCZabbixAgent.ps1 -ConfPath .\Config\DEV-HOSTS.psd1
Start-DscConfiguration -Path ".\DSC\temp\" -Verbose -Wait -Force