$ConfigFiles = dir "Hosts\*-HOSTS.psd1"
Import-module "$PSScriptRoot\HostsDialog.ps1" -Force

$ConfigFile = HostsDialog -configFile $ConfigFiles

If ($ConfigFile -notlike "*-HOSTS.psd1"){
    Write-Host "Not Selected file.."
}else{
    .\Roles\FirewallConfiguration\DSC\DSCFirewallConfiguration.ps1 -ConfPath .\Hosts\$ConfigFile
    Start-DscConfiguration -Path ".\Roles\FirewallConfiguration\DSC\temp\" -Verbose -Wait -Force
    Get-ChildItem ".\Roles\FirewallConfiguration\DSC\temp\" -Include *.mof -Recurse | Remove-Item
}
