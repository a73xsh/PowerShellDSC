param (
    $ConfPath,
    $RoleConfig
)

configuration DeployWACHA
{

    $VMsConfigContent = (Get-Content $RoleConfig | ConvertFrom-Json)

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -module xHyper-V

    Node $AllNodes.NodeName
    {
         foreach ($vm in $VMsConfigContent.vms) {

            File "VMFolder-$($vm.vmname)" {
                DestinationPath = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)")
                Type            = 'Directory'
                Ensure          =  "Present"
            }

            File "VMFolder-Automation-$($vm.vmname)" {
                DestinationPath = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)\Automation")
                Type            = 'Directory'
                Ensure          = "Present"
            }

                File "SystemDisk-$($vm.vmname)" {
                SourcePath      = $vm.parentvhd
                DestinationPath = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)\$($vm.vmname)_OSDisk.vhdx")
                Type            = "File"
                Ensure          =  "Present"
            }



            # Ensures a VM with all the properties
            xVMHyperV $vm.vmname {
                Ensure          = "Present"
                Name            = $vm.vmname
                VhdPath         = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)\$($vm.vmname)_OSDisk.vhdx")
                State           = 'Running'
                Path            = $vm.Path
                Generation      = 2
                StartupMemory   = $($vm.MemoryStartupBytes) / 1
                MinimumMemory   = $($vm.MemoryMinimumBytes) / 1
                MaximumMemory   = $($vm.MaximumMemory) / 1
                ProcessorCount  = $vm.ProcessorCount
                RestartIfNeeded = $true
                #WaitForIP       = $vm.VMNetworkAdapters.IpAddress[0]
                AutomaticCheckpointsEnabled = $false
                #DependsOn       = "SystemDisk-$($vm.vmname)"
            }

            Script "DisableTimeSync-$($vm.vmname)" {
                TestScript = {
                    return (-not (Get-VMIntegrationService -VMName $using:vm.vmname -Name "Time Synchronization").Enabled)
                }
                SetScript  = {
                    Get-VMIntegrationService -VMName $using:vm.vmname -Name "Time Synchronization" | Disable-VMIntegrationService
                }
                GetScript  = {
                    return @{ Result = (Get-VMIntegrationService -VMName $using:vm.vmname -Name "Time Synchronization" | Select -ExpandProperty Enabled | Out-String) }
                }
                DependsOn  = "[xVMHyperV]$($vm.vmname)"

            }

            Script "Remove AdapterName-$($vm.vmname)" {
                TestScript = {
                    return(-not (Get-VMNetworkAdapter -VMname $using:vm.vmname -Name "Network Adapter" -ErrorAction SilentlyContinue))
                }
                SetScript  = {
                    Remove-VMNetworkAdapter -VMName $using:vm.vmname -VMNetworkAdapterName "Network Adapter"
                }
                GetScript  = {
                    return @{ Result = (Get-VMNetworkAdapter -VMname $using:vm.vmname | Select -ExpandProperty Name | Out-String) }
                }
                DependsOn  = "[xVMHyperV]$($vm.vmname)"
            }


            foreach ($NetAdapter in $VM.VMNetworkAdapters) {
                xVMNetworkAdapter "$($NetAdapter.Name)-$($vm.vmname)" {
                    Ensure         = $NetAdapter.Ensure
                    Id             = $NetAdapter.ID
                    Name           = $NetAdapter.Name
                    SwitchName     = $NetAdapter.SwitchName
                    VMName         = $vm.vmname
                    VlanId         = $NetAdapter.VlanId
                    NetworkSetting = xNetworkSettings {
                        IpAddress      = $NetAdapter.IpAddress
                        Subnet         = $NetAdapter.Subnet
                        DefaultGateway = $NetAdapter.DefaultGateway
                        DnsServer      = $NetAdapter.DnsServer
                    }
                }
            }

            # Not working correctly
            If ($VM.VMScsiControllers){
                foreach ($SCSIController in $VM.VMScsiControllers) {

                    xVHD "Disk-$($SCSIController.Name)" {

                        Name             = $SCSIController.Name
                        Path             = $SCSIController.Path
                        Generation       = $SCSIController.Generation
                        MaximumSizeBytes = $($SCSIController.MaximumSizeBytes) / 1
                        Ensure           = $SCSIController.Ensure

                    }

                    # Attach the VHD
                    xVMHardDiskDrive "ExtraDisk-$($SCSIController.Name)" {
                        VMName             = $vm.vmname
                        Path               = (Join-Path $vm.Path -ChildPath "$($vm.vmname)\$($SCSIController.Name)")
                        ControllerType     = 'SCSI'
                        ControllerNumber   = $SCSIController.SCSIControllerNumber
                        ControllerLocation = $SCSIController.ControllerLocation
                        Ensure             = $SCSIController.Ensure
                        DependsOn          = "[xVHD]Disk-$($SCSIController.Name)"
                    }
                }
            }
        }
    }
}
DeployWACHA -outputPath ".\Roles\DeployWACHA\DSC\temp\" -ConfigurationData $ConfPath
