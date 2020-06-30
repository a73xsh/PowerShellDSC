param (
    $ConfPath
)
$ZBXConfigContent = (Get-Content .\Roles\DeployZabbixAgent\Config\ZabbixAgent.json | ConvertFrom-Json)

Configuration DeployZabbixAgent
{

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    Node $allNodes.NodeName {

        $config = @"
### option: logfile
#       name of log file.
#       if not set, syslog is used.
#
LogFile=$($ZBXConfigContent.AgentConfig.LogFile)

### option: logfilesize
#       maximum size of log file in mb.
#       0 - disable automatic log rotation.
#
LogFileSize=$($ZBXConfigContent.AgentConfig.LogFileSize)

### option: debuglevel
#       specifies debug level
#       0 - no debug
#       1 - critical information
#       2 - error information
#       3 - warnings
#       4 - for debugging (produces lots of information)
#
DebugLevel=$($ZBXConfigContent.AgentConfig.DebugLevel)


### option: sourceip
#       source ip address for outgoing connections.
#

### option: enableremotecommands
#       whether remote commands from zabbix server are allowed.
#       0 - not allowed
#       1 - allowed
#
EnableRemoteCommands=$($ZBXConfigContent.AgentConfig.EnableRemoteCommands)

### option: logremotecommands
#       enable logging of executed shell commands as warnings.
#       0 - disabled
#       1 - enabled
#
LogRemoteCommands=$($ZBXConfigContent.AgentConfig.LogRemoteCommands)

##### passive checks related

### option: server
#       list of comma delimited ip addresses (or hostnames) of zabbix servers.
#       incoming connections will be accepted only from the hosts listed here.
#       no spaces allowed.
#       if ipv6 support is enabled then '127.0.0.1', '::127.0.0.1', '::ffff:127.0.0.1' are treated equally.
#
# mandatory: yes
# default:
# server=
Server=$($ZBXConfigContent.AgentConfig.Server)

### option: listenport
#       agent will listen on this port for connections from the server.
#
ListenPort=$($ZBXConfigContent.AgentConfig.ListenPort)


### option: listenip
#       list of comma delimited ip addresses that the agent should listen on.
#       first ip address is sent to zabbix server if connecting to it to retrieve list of active checks.
#

### option: startagents
#       number of pre-forked instances of zabbix_agentd that process passive checks.
#       if set to 0, disables passive checks and the agent will not listen on any tcp port.
#
StartAgents=$($ZBXConfigContent.AgentConfig.StartAgents)

##### active checks related
### option: serveractive
#       list of comma delimited ip:port (or hostname:port) pairs of zabbix servers for active checks.
#       if port is not specified, default port is used.
#       ipv6 addresses must be enclosed in square brackets if port for that host is specified.
#       if port is not specified, square brackets for ipv6 addresses are optional.
#       if this parameter is not specified, active checks are disabled.
#       example: serveractive=127.0.0.1:20051,zabbix.domain,[::1]:30051,::1,[12fc::1]
#
ServerActive=$($ZBXConfigContent.AgentConfig.ServerActive)

### option: hostname
#       unique, case sensitive hostname.
#       required for active checks and must match hostname as configured on the server.
#       value is acquired from hostnameitem if undefined.
#
Hostname=$($allNodes.NodeName).$($allNodes.Domain)

### option: hostnameitem
#       item used for generating hostname if it is undefined.
#       ignored if hostname is defined.
#

### option: hostmetadata
#   optional parameter that defines host metadata.
#   host metadata is used at host auto-registration process.
#   an agent will issue an error and not start if the value is over limit of 255 characters.
#   if not defined, value will be acquired from hostmetadataitem.
#

### option: hostmetadataitem
#   optional parameter that defines an item used for getting host metadata.
#   host metadata is used at host auto-registration process.
#   during an auto-registration request an agent will log a warning message if
#   the value returned by specified item is over limit of 255 characters.
#   this option is only used when hostmetadata is not defined.
#

### option: refreshactivechecks
#       how often list of active checks is refreshed, in seconds.
#
RefreshActiveChecks=$($ZBXConfigContent.AgentConfig.RefreshActiveChecks)

### option: buffersend
#       do not keep data longer than n seconds in buffer.
#
BufferSend=$($ZBXConfigContent.AgentConfig.BufferSend)

### option: buffersize
#       maximum number of values in a memory buffer. the agent will send
#       all collected data to zabbix server or proxy if the buffer is full.
#
BufferSize=$($ZBXConfigContent.AgentConfig.BufferSize)

### option: maxlinespersecond
#       maximum number of new lines the agent will send per second to zabbix server
#       or proxy processing 'log' and 'logrt' active checks.
#       the provided value will be overridden by the parameter 'maxlines',
#       provided in 'log' or 'logrt' item keys.
#
MaxLinesPerSecond=$($ZBXConfigContent.AgentConfig.MaxLinesPerSecond)

############ advanced parameters #################

### option: alias
#       sets an alias for parameter. it can be useful to substitute long and complex parameter name with a smaller and simpler one.
#

### option: timeout
#       spend no more than timeout seconds on processing
#
Timeout=$($ZBXConfigContent.AgentConfig.Timeout)

### Option: User
#   Drop privileges to a specific, existing user on the system.
#   Only has effect if run as 'root' and AllowRoot is disabled.
#
# Mandatory: no
# Default:


### option: include
#       you may include individual files or all files in a directory in the configuration file.
#       installing zabbix will create include directory in /usr/local/etc, unless modified during the compile time.
#
Include=$($ZBXConfigContent.IncludeDir)

####### user-defined monitored parameters #######

### option: unsafeuserparameters
#       allow all characters to be passed in arguments to user-defined parameters.
#       0 - do not allow
#       1 - allow
#
UnsafeUserParameters=$($ZBXConfigContent.AgentConfig.UnsafeUserParameters)
"@

        File $ZBXConfigContent.InstallDir {
            Type            = 'Directory'
            DestinationPath = $ZBXConfigContent.InstallDir
            Ensure          = 'Present'
        }

        File $ZBXConfigContent.IncludeDir {
            Type            = 'Directory'
            DestinationPath = $ZBXConfigContent.IncludeDir
            Ensure          = 'Present'
        }

        File $ZBXConfigContent.ScriptsDir {
            Type            = 'Directory'
            DestinationPath = $ZBXConfigContent.ScriptsDir
            Ensure          = 'Present'
        }

        File CopyZabbixAgent {
            Type            = 'File'
            SourcePath      = (Join-Path -Path $ZBXConfigContent.SourceShare -ChildPath $ZBXConfigContent.AgentFile)
            DestinationPath = (Join-Path -Path $ZBXConfigContent.InstallDir -ChildPath $ZBXConfigContent.AgentFile)
            Ensure          = 'Present'
            #DependsOn       = "[File]$($ZBXConfigContent.InstallDir"
        }

        Archive ArchiveExample {
            Ensure      = "Present"
            Path        = (Join-Path -Path $ZBXConfigContent.InstallDir -ChildPath $ZBXConfigContent.AgentFile)
            Destination = $ZBXConfigContent.InstallDir
        }

        File ConfigFile {
            DestinationPath = $ZBXConfigContent.InstallDir + "\conf\zabbix_agentd.conf"
            Contents        = $config
            Force           = $true
        }

        #Remove UTF BOM
        Script RemoveUTFBOM{
            testScript = {
                #$ZBXCfgPath = $using:ZBXConfigContent.InstallDir + "\conf\zabbix_agentd.conf"
                <# [bool](Test-path $ZBXCfgPath -ErrorAction SilentlyContinue)  #>
                #Test-Path  $ZBXCfgPath
                return $false
            }
            setscript  = {
                $ZBXCfgPath = $using:ZBXConfigContent.InstallDir + "\conf\zabbix_agentd.conf"
                [System.IO.File]::WriteAllLines(
                    $ZBXCfgPath,
                    (Get-Content -Path $ZBXCfgPath),
                    (New-Object System.Text.UTF8Encoding($False))
                    )
            }
            getscript  = {
                @{Result = write-verbose "Encoding change to ANSI"}
            }
            DEpendsOn = '[File]ConfigFile'
        }
        #Register service
        Script Installmyservice {
            testScript = { [bool](Get-Service "Zabbix Agent" -ErrorAction SilentlyContinue) }
            setscript  = {
                $ZBXExePath = $using:ZBXConfigContent.InstallDir + "\bin\zabbix_agentd.exe"
                $ZBXCfgPath = $using:ZBXConfigContent.InstallDir + "\conf\zabbix_agentd.conf"
                cmd.exe /c "$ZBXExePath --config $ZBXCfgPath --install >nul 2>&1"
            }
            getscript  = { @{Result = (Get-Service "Zabbix Agent" -ErrorAction SilentlyContinue) } }
        }

    }
}

DeployZabbixAgent -outputPath "$PSScriptRoot\temp\" -ConfigurationData $ConfPath