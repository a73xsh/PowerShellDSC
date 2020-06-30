Function Set-TrustedHosts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$VMName
    )
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $VMName -Concatenate -Force
}
