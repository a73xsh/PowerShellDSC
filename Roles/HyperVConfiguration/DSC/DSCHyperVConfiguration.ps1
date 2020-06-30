param (
    $ConfPath
)

configuration HyperVConfiguration
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName xHyper-V
    Import-DSCResource -ModuleName NetworkingDsc


    Node $AllNodes.Where{ $_.Role -eq "Hyper-V" }.NodeName
    {

        # Hyper-V settings
        WindowsFeature Hyper-V {
            Ensure               = 'Present'
            Name                 = "Hyper-V"
            IncludeAllSubFeature = $true
        }

        WindowsFeature Multipath-IO {
            Ensure = 'Present'
            Name   = 'Multipath-IO'
        }

        WindowsFeature Failover-Clustering {
            Ensure = 'Present'
            Name   = 'Failover-Clustering'
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

        #MPIO Settigs XIO

        Registry XIOMpioPathVerifyEnabled {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "PathVerifyEnabled"
            ValueData = "0"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioPathVerificationPeriod {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "PathVerificationPeriod"
            ValueData = "30"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioPDORemovePeriod {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "PDORemovePeriod"
            ValueData = "50"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioRetryCount {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "RetryCount"
            ValueData = "10"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioRetryInterval {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "RetryInterval"
            ValueData = "5"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioUseCustomPathRecoveryInterval {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "UseCustomPathRecoveryInterval"
            ValueData = "1"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioPathRecoveryInterval {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "PathRecoveryInterval"
            ValueData = "25"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioDiskPathCheckDisabled {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "DiskPathCheckDisabled"
            ValueData = "00000000"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

        Registry XIOMpioDiskPathCheckInterval {
            Ensure    = "Present"
            Key       = "HKLM:\SYSTEM\CurrentControlSet\Services\mpio\Parameters"
            ValueName = "DiskPathCheckInterval"
            ValueData = "25"
            ValueType = "Dword"
            DependsOn = "[WindowsFeature]Multipath-IO"
        }

    }

    Node $AllNodes.Where{ $_.Role -eq "Hyper-V" -and $_.Site -like "PROD-*" }.NodeName
    {
        #Network Settings
        NetAdapterName RenameNetAdapterManagement {
            NewName    = $Node.NetAdapterMGMT
            MacAddress = $Node.MacAddressMGMT
        }

        NetAdapterName RenameNetAdapterCluster {
            NewName = $Node.NetAdapterCluster
            Name    = 'vEthernet (HV-Cluster)'
        }

        NetAdapterName RenameNetAdapterLVM {
            NewName = $Node.NetAdapterLVM
            Name    = 'vEthernet (HV-LVM)'
        }

        NetIPInterface DisableDhcp {
            InterfaceAlias = $Node.NetAdapterMGMT
            AddressFamily  = 'IPv4'
            Dhcp           = 'Disabled'
            DependsOn      = "[NetAdapterName]RenameNetAdapterManagement"
        }

        IPAddress IPv4AddressMGMTInterface {
            IPAddress      = $Node.IPAdapterMGMT
            InterfaceAlias = $Node.NetAdapterMGMT
            AddressFamily  = 'IPV4'
            DependsOn      = "[NetAdapterName]RenameNetAdapterManagement"
        }

        DnsServerAddress PrimaryAndSecondary {
            Address        = $Node.DNSSServers
            InterfaceAlias = $Node.NetAdapterMGMT
            AddressFamily  = 'IPv4'
            Validate       = $true
            DependsOn      = "[NetAdapterName]RenameNetAdapterManagement"
        }

        DefaultGatewayAddress SetDefaultGateway {
            Address        = $Node.DFGWAdapterMGMT
            InterfaceAlias = $Node.NetAdapterMGMT
            AddressFamily  = 'IPv4'
            DependsOn      = "[NetAdapterName]RenameNetAdapterManagement"
        }

        NetAdapterAdvancedProperty JumboPacketLiveMigration {
            NetworkAdapterName = $Node.NetAdapterLVM
            RegistryKeyword    = "*JumboPacket"
            RegistryValue      = 9014
        }

        NetAdapterAdvancedProperty JumboPacketCluster {
            NetworkAdapterName = $Node.NetAdapterCluster
            RegistryKeyword    = "*JumboPacket"
            RegistryValue      = 9014
        }

        #Disable RSS on Hyper-V adapters, because enable VMQ
<#
        NetAdapterRss DisableRssNIC-B {
            Name    = 'vNIC-B'
            Enabled = $False
        }

        NetAdapterRss DisableRssNIC-A {
            Name    = 'vNIC-A'
            Enabled = $False
        } #>
    }
}
HyperVConfiguration -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath