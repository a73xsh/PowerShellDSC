[CmdletBinding()]
param (
    $ConfPath,
    $RoleConfig
)

configuration DeployVMs
{

    $VMsConfigContent = (Get-Content $RoleConfig | ConvertFrom-Json)

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -module xHyper-V

    Node $AllNodes.Where{ $_.Role -eq "Hyper-V" -and $_.Site -like "TEST-*" }.NodeName
    {

        foreach ($vm in $VMsConfigContent.Test.vms) {

            $unattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <settings pass="specialize">

    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
        <RegisteredOrganization>OS33</RegisteredOrganization>
        <RegisteredOwner>INFRA</RegisteredOwner>
        <ComputerName>$($vm.ComputerName)</ComputerName>
        <TimeZone>UTC</TimeZone>
    </component>

    </settings>

  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" >
      <UserAccounts>
        <AdministratorPassword>
          <Value>$($vm.AdministratorPassword)</Value>
          <PlainText>false</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
    </component>

    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" >
      <InputLocale>en-us</InputLocale>
      <SystemLocale>en-us</SystemLocale>
      <UILanguage>en-us</UILanguage>
      <UserLocale>en-us</UserLocale>
    </component>
  </settings>

</unattend>

"@

           $joinDomain = @"


del C:\Windows\Panther\unattend.xml
Shutdown -r -t 0
"@

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

            Script "Create Unattendxml-$($vm.vmname)"{
                TestScript = {
                    Test-Path "(Join-Path -Path $($vm.Path) -ChildPath $($vm.vmname))\Automation\unattend.xml)"
                }
                SetScript  = {
                    $using:unattend | Out-File (Join-Path -Path $using:vm.Path -ChildPath "$($using:vm.vmname)\Automation\unattend.xml") -Encoding utf8
                }
                GetScript  = {
                    return @{ Result = (Join-Path -Path $using:vm.Path -ChildPath "$($using:vm.vmname)\Automation\unattend.xml") }
                }
                DependsOn  = "[File]VMFolder-Automation-$($vm.vmname)"
            }

            xVhdFile "CopyUnattendxml-$($vm.vmname)" {
                VhdPath       = (Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)\$($vm.vmname)_OSDisk.vhdx")
                FileDirectory = MSFT_xFileDirectory {
                    SourcePath      = Join-Path -Path $vm.Path -ChildPath "$($vm.vmname)\Automation\unattend.xml"
                    Ensure = "Present"
                    #Content = $unattend
                    Type = "File"
                    DestinationPath = "\Windows\Panther\unattend.xml"
                    Force = $true
                }



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
            <#
            foreach ($SCSIController in $VM.VMScsiControllers) {

                xVHD "Disk-$($SCSIController.Name)" {

                    Name             = $SCSIController.Name
                    Path             = $SCSIController.Path
                    Generation       = $SCSIController.Generation
                    MaximumSizeBytes = $($SCSIController.MaximumSizeBytes) / 1
                    Ensure           = $SCSIController.Ensure

                }

                xVMScsiController "Controller-$($SCSIController.SCSIControllerNumber)" {

                    Ensure           = $SCSIController.Ensure
                    VMName           = $vm.vmname
                    ControllerNumber = $SCSIController.SCSIControllerNumber
                    RestartIfNeeded  = $true
                    DependsOn        = "[xVHD]Disk-$($SCSIController.Name)"

                }
                # Attach the VHD
                xVMHardDiskDrive "ExtraDisk-$($SCSIController.Name)" {
                    VMName             = $vm.vmname
                    Path               = (Join-Path "$($SCSIController.Path)" -ChildPath "$($SCSIController.Name)")
                    ControllerType     = 'SCSI'
                    ControllerNumber   = $SCSIController.SCSIControllerNumber
                    ControllerLocation = $SCSIController.ControllerLocation
                    Ensure             = $SCSIController.Ensure
                    DependsOn          = "[xVMScsiController]Controller-$($SCSIController.SCSIControllerNumber)"
                }
            }
            #>


    }

}
}
DeployVMs -outputPath ".\Roles\DeployVMs\DSC\temp\" -ConfigurationData $ConfPath
