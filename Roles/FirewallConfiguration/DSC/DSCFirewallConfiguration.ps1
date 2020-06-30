param (
    $ConfPath
)

configuration FirewallConfiguration
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName NetworkingDsc

    Node $AllNodes.NodeName
    {
        #---Firewall Settings---#

        #  Enable ping requests in and out
        Firewall FPS-ICMP4-ERQ-In {
            Name    = 'FPS-ICMP4-ERQ-In'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall FPS-ICMP6-ERQ-In {
            Name    = 'FPS-ICMP6-ERQ-In'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall FPS-ICMP4-ERQ-Out {
            Name    = 'FPS-ICMP4-ERQ-Out'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall FPS-ICMP6-ERQ-Out {
            Name    = 'FPS-ICMP6-ERQ-Out'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable remote volume management
        Firewall RVM-VDS-In-TCP {
            Name    = 'RVM-VDS-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RVM-VDSLDR-In-TCP {
            Name    = 'RVM-VDSLDR-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RVM-RPCSS-In-TCP {
            Name    = 'RVM-RPCSS-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable remote service management
        Firewall RemoteSvcAdmin-In-TCP {
            Name    = 'RemoteSvcAdmin-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RemoteSvcAdmin-NP-In-TCP {
            Name    = 'RemoteSvcAdmin-NP-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RemoteSvcAdmin-RPCSS-In-TCP {
            Name    = 'RemoteSvcAdmin-RPCSS-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable Remote Event Log Management
        Firewall RemoteEventLogSvc-In-TCP {
            Name    = 'RemoteEventLogSvc-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RemoteEventLogSvc-NP-In-TCP {
            Name    = 'RemoteEventLogSvc-NP-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RemoteEventLogSvc-RPCSS-In-TCP {
            Name    = 'RemoteEventLogSvc-RPCSS-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable Remote Scheduled Tasks Management
        Firewall RemoteTask-In-TCP {
            Name    = 'RemoteTask-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RemoteTask-RPCSS-In-TCP {
            Name    = 'RemoteTask-RPCSS-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable Windows Firewall Remote Management
        Firewall RemoteFwAdmin-In-TCP {
            Name    = 'RemoteFwAdmin-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall RemoteFwAdmin-RPCSS-In-TCP {
            Name    = 'RemoteFwAdmin-RPCSS-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Allow PowerShell remoting from any subnet
        Firewall WinRM-HTTP-In-TCP-Public {
            Name    = 'WinRM-HTTP-In-TCP-Public'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Public')
        }
        #  Enable WMI management requests in
        Firewall WMI-WINMGMT-In-TCP {
            Name    = 'WMI-WINMGMT-In-TCP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable Remote Shutdown
        Firewall Wininit-Shutdown-In-Rule-TCP-RPC {
            Name    = 'Wininit-Shutdown-In-Rule-TCP-RPC'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
        #  Enable Network Discovery on the Domain Network
        Firewall NETDIS-FDPHOST-In-UDP {
            Name    = 'NETDIS-FDPHOST-In-UDP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }

        Firewall NETDIS-FDPHOST-Out-UDP {
            Name    = 'NETDIS-FDPHOST-Out-UDP'
            Ensure  = 'Present'
            Enabled = 'True'
            Profile = ('Any')
        }
    }

    Node $AllNodes.Where{ $_.Role -eq "SQLServer" }.NodeName
    {
        #Enabling SQL Server Ports
        Firewall SQLServer {
            Name        = 'SQL Server'
            DisplayName = 'Firewall Rule for SQL Server'
            Group       = 'SQL Server Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('1433')
            Protocol    = 'TCP'
        }

        Firewall SQLAdminConnection {
            Name        = 'SQL Admin Connection'
            DisplayName = 'Firewall Rule for SQL Admin Connection'
            Group       = 'SQL Server Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('1434')
            Protocol    = 'TCP'
        }

        Firewall SQLDatabaseManagement {
            Name        = 'SQL Database Management'
            DisplayName = 'Firewall Rule for SQL Database Management'
            Group       = 'SQL Server Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('1434')
            Protocol    = 'UDP'
        }

        Firewall SQLServiceBroker {
            Name        = 'SQL Service Broker'
            DisplayName = 'Firewall Rule for SQL Service Broker'
            Group       = 'SQL Server Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('4022')
            Protocol    = 'TCP'
        }

        Firewall SQLDebuggerRPC {
            Name        = 'SQL Debugger/RPC'
            DisplayName = 'Firewall Rule for SQL Debugger/RPC'
            Group       = 'SQL Server Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('135')
            Protocol    = 'TCP'
        }

        Firewall AlwaysOn {
            Name        = 'SQL Always On'
            DisplayName = 'Firewall Rule for SQL Always On'
            Group       = 'SQL Server Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('5022')
            Protocol    = 'TCP'
        }
        #Enabling SQL Analysis Ports
        Firewall SQLAnalysisServices {
            Name        = 'SQL Analysis Services'
            DisplayName = 'Firewall Rule for SQL Analysis Services'
            Group       = 'SQL Analysis Services Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('2383')
            Protocol    = 'TCP'
        }

        Firewall SQLBrowser {
            Name        = 'SQL Browser'
            DisplayName = 'Firewall Rule for SQL Browser'
            Group       = 'SQL Analysis Services Firewall Rule Group'
            Ensure      = 'Present'
            Enabled     = 'True'
            Profile     = ('Domain', 'Private')
            Direction   = 'Inbound'
            LocalPort   = ('2382')
            Protocol    = 'TCP'
        }

    }
}
FirewallConfiguration -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath