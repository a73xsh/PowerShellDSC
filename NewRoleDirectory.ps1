Param
(
    [Parameter(Mandatory = $true, Position = 0)]   # Service Profile name
    [String]$RoleName
)

$shareRoot = ".\Roles"                     # Local share root

$RolePath = Join-Path $shareRoot $RoleName
$RoleDSC = Join-Path $RolePath "DSC"
$DSCTemp = Join-Path $RoleDSC "Temp"
$RoleConfig = Join-Path $RolePath "Config"

If (Test-Path $RolePath) {
    Write-Host "Directory $RolePath already exists.  Exiting" -ForegroundColor Red
    Exit
}

$null = New-Item -Path $RolePath        -ItemType Container
$null = New-Item -Path $RoleDSC -ItemType Container
#$null = New-Item -Path $RoleDSC -Name "DSC$($RoleName).ps1" -ItemType File
$null = New-Item -Path $DSCTemp     -ItemType Container
$null = New-Item -Path $DSCTemp -Name "DSC_MOF_FILES" -ItemType File
$null = New-Item -Path $RoleConfig        -ItemType Container
$null = New-Item -Path $RoleConfig  -Name "DSC_CONFIG_FILE_JSON" -ItemType File

$ConfPath = '$ConfPath'
$AllNodes = '$AllNodes'

@"
param (
    $($ConfPath)
)

configuration $($RoleName)
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    Node $($AllNodes).NodeName
    {


    }

}

$($RoleName) -outputPath "$($RoleDSC)\temp\" -ConfigurationData $($ConfPath)
"@ | Out-File "$($RoleDSC)\DSC$($RoleName).ps1" -Encoding utf8

Write-Host "Directories created:"
Write-Host "  $RolePath"
Write-Host "  $RoleDSC"
Write-Host "  $DSCTemp"
Write-Host "  $RoleConfig `n"
