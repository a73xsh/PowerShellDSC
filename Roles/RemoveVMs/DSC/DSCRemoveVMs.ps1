param (
    $ConfPath,
    $RoleConfig
)

configuration RemoveVMs
{

    $VMsConfigContent = (Get-Content $RoleConfig | ConvertFrom-Json)

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -module xHyper-V

    Node $AllNodes.Where{ $_.Role -eq "Hyper-V" }.NodeName
    {

        foreach ($vm in $VMsConfigContent.vms) {

            # Ensures a VM with all the properties
            xVMHyperV $vm.vmname {
                Ensure                      = "Absent"
                Name                        = $vm.vmname
                VhdPath                     = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)\$($vm.vmname)_OSDisk.vhdx")
                State                       = 'Running'
                Path                        = $vm.Path
                Generation                  = 2
                StartupMemory               = $($vm.MemoryStartupBytes) / 1
                MinimumMemory               = $($vm.MemoryMinimumBytes) / 1
                MaximumMemory               = $($vm.MaximumMemory) / 1
                ProcessorCount              = $vm.ProcessorCount
                RestartIfNeeded             = $true
                #WaitForIP       = $vm.VMNetworkAdapters.IpAddress[0]
                AutomaticCheckpointsEnabled = $false
                #DependsOn       = "SystemDisk-$($vm.vmname)"
            }

            File "VMFolder-$($vm.vmname)" {
                DestinationPath = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)")
                Type            = 'Directory'
                Ensure          = "Absent"
                Recurse         = $true
                Force = $true
                DependsOn       = "[xVMHyperV]$($vm.vmname)"
            }
        }
    }

}

RemoveVMs -outputPath ".\Roles\RemoveVMs\DSC\temp\" -ConfigurationData $ConfPath
