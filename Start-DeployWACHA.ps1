#$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
param(
        $HOSTFILE,
        $VMFILE
    )
# All exported functions
foreach ($function in (Get-ChildItem "$PSScriptRoot\functions\*.ps1")) {
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)
}

$ConfigFiles = dir "Hosts\*-HOSTS.psd1"
$VMsConfigContent = dir "Roles\DeployWACHA\Config\*-Vms.json"

if ($HOSTFILE -and $VMFILE)
	{
		if ((Test-Path $HOSTFILE) -and (Test-Path $VMFILE))
			{
				$SelectForm =  New-Object PSObject -Property @{
            	HostsConfig = $HOSTFILE.Split("\")[-1]
            	VMsConfig   = $VMFILE.Split("\")[-1]
        }
			}
		else
			{
				Write-Host ""
				Write-Host -ForegroundColor Red "The file you specified does not exist"
				Write-Host -ForegroundColor Red "	Exiting..."
				exit
			}
	}
else
	{
		#Create list of Config Files Hosts
		[array]$DropDownHostsArray = $null
		foreach ($CFs in $ConfigFiles)
			{
				[array]$DropDownHostsArray += $CFs.Name
			}

        #Create list of Config Files VMs
        [array]$DropDownVmsArray = $null
        foreach ($Vm in $VMsConfigContent) {
            [array]$DropDownVmsArray += $Vm.Name
        }
		#Menu Function
		function Return-DropDown
			{
				$Choice = $DropDownHosts.SelectedItem.ToString()
				$Form.Close()
			}
		[array]$DropDownHostsArray += "EXIT"

		#Generate GUI input box for Config File Selection
		[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
		[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
		$Form = New-Object System.Windows.Forms.Form
		$Form.width = 700
		$Form.height = 150
		$Form.StartPosition = "CenterScreen"
		$Form.Text = "Hosts File to use"


        $DropDownHosts = new-object System.Windows.Forms.ComboBox
		$DropDownHosts.Location = new-object System.Drawing.Size(100,10)
        $DropDownHosts.Size = new-object System.Drawing.Size(550,30)

		ForEach ($Item in $DropDownHostsArray)
			{
				$DropDownHosts.Items.Add($Item) | Out-Null
            }
        $Form.Controls.Add($DropDownHosts)
		$DropDownHostsLabel = new-object System.Windows.Forms.Label
		$DropDownHostsLabel.Location = new-object System.Drawing.Size(1,10)
		$DropDownHostsLabel.size = new-object System.Drawing.Size(255,20)
		$DropDownHostsLabel.Text = "Hosts File"
        $Form.Controls.Add($DropDownHostsLabel)

        $DropDownVMs = new-object System.Windows.Forms.ComboBox
        $DropDownVMs.Location = new-object System.Drawing.Size(100, 40)
        $DropDownVMs.Size = new-object System.Drawing.Size(550, 30)

        ForEach ($Item in $DropDownVmsArray) {
            $DropDownVMs.Items.Add($Item) | Out-Null
        }
        $Form.Controls.Add($DropDownVMs)
        $DropDownVmsLabel = new-object System.Windows.Forms.Label
        $DropDownVmsLabel.Location = new-object System.Drawing.Size(1, 40)
        $DropDownVmsLabel.size = new-object System.Drawing.Size(255, 20)
        $DropDownVmsLabel.Text = "Vms File"
        $Form.Controls.Add($DropDownVmsLabel)


		$Button = new-object System.Windows.Forms.Button
		$Button.Location = new-object System.Drawing.Size(300,70)
		$Button.Size = new-object System.Drawing.Size(75,25)
		$Button.Text = "Select"
		$Button.Add_Click({Return-DropDown})
		$form.Controls.Add($Button)
		$Form.Add_Shown({$Form.Activate()})
		$Form.ShowDialog() | Out-Null

		#Check for valid entry
		if (($DropDownHosts.SelectedItem -eq $null) -and ($DropDownVMs.SelectedItem -eq $null))
			{
				Write-Host -ForegroundColor Red "Nothing Selected"
				exit
			}

		#Check to see if EXIT selected
		if ($DropDownHosts.SelectedItem -eq "EXIT")
			{
				Write-Host -ForegroundColor DarkBlue "You have chosen to EXIT the script"
				exit
			}
		#Set the data configuration file
		#$ConfigFile = $DropDownHosts.SelectedItem
        #$ConfigFileDir = $CFs.Directory
        $SelectForm =  New-Object PSObject -Property @{
            HostsConfig = $DropDownHosts.SelectedItem
            VMsConfig   = $DropDownVMs.SelectedItem
        }

    }
	#Write-Host $SelectForm.HostsConfig
# Deploy VMs
.\Roles\DeployWACHA\DSC\DSCDeployWACHA.ps1 -ConfPath .\Hosts\$($SelectForm.HostsConfig) -RoleConfig .\Roles\DeployWACHA\Config\$($SelectForm.VMsConfig)
Start-DscConfiguration -Path ".\Roles\DeployWACHA\DSC\temp\" -Verbose -Wait -Force
Get-ChildItem ".\Roles\DeployWACHA\DSC\temp\" -Include *.mof -Recurse | Remove-Item

#Provision Vms
$VMsConfigContent = (Get-Content .\Roles\DeployWACHA\Config\$($SelectForm.VMsConfig) | ConvertFrom-Json)
$VHDImageCredentials = Import-CliXml -Path .\Credentials\VHDImageCredentials.xml
$DomainCredentials = Import-Clixml -Path .\Credentials\DomainCredentials.xml
foreach ($vm in $VMsConfigContent.vms) {
	$ComputerName = $vm.ComputerName
	$domain = $vm.domain
	$IpAddress = $vm.VMNetworkAdapters[0].IpAddress

	Set-TrustedHosts $IpAddress.ToString()
	Write-Host "Added $IpAddress, $ComputerName to TrustedHosts"

	Write-Host "Waiting for WinRM..."
    while ((Invoke-Command -ComputerName $IpAddress -Credential $VHDImageCredentials {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}

	Write-Host "Enable ping on all profiles"
    Invoke-Command -ComputerName $IpAddress -Credential $VHDImageCredentials -ScriptBlock {
		Set-NetFirewallRule -Name FPS-ICMP4-ERQ-In -Enabled True -Profile Any -RemoteAddress Any
		Set-NetFirewallRule -Name FPS-ICMP4-ERQ-Out -Enabled True -Profile Any -RemoteAddress Any
	}

	Write-Host "Copy DSC Resources to $ComputerName"
	.\Roles\DeployWACHA\DSC\DSCCopyDSCResources.ps1 -NodeName $IpAddress -Credential $DomainCredentials -RoleConfig .\Roles\DeployWACHA\Config\$($SelectForm.VMsConfig)
	Start-DscConfiguration -Path ".\Roles\DeployWACHA\DSC\temp\" -Verbose -Wait -Force -Credential $VHDImageCredentials
	Get-ChildItem ".\Roles\DeployWACHA\DSC\temp\" -Include *.mof -Recurse | Remove-Item


	if($domain){
		Write-Host "Join Domain"
		.\Roles\DeployWACHA\DSC\DSCDomainJoin.ps1 -NodeName $IpAddress -Credential $DomainCredentials -DomainName $domain -ComputerName $ComputerName
		Start-DscConfiguration -Path ".\Roles\DeployWACHA\DSC\temp\" -Verbose -Wait -Force -Credential $VHDImageCredentials
		Get-ChildItem ".\Roles\DeployWACHA\DSC\temp\" -Include *.mof -Recurse | Remove-Item
	}

	if ($vm.VMScsiControllers){
		Write-Host "Formatting data drive and making ready for first use"
		Invoke-Command -ComputerName $IpAddress -Credential $VHDImageCredentials -ScriptBlock {
			Get-Disk |
			Where-Object PartitionStyle -eq 'RAW' |
			Initialize-Disk -PartitionStyle GPT -PassThru |
			New-Partition -AssignDriveLetter -UseMaximumSize |
			Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -confirm:$false }
	}
	Write-Host "Restart VMs $ComputerName"
	Invoke-Command -ComputerName $IpAddress -Credential $VHDImageCredentials -ScriptBlock {
		Restart-computer -Force
	}
	Write-Host "Test VM $ComputerName available..."
    while ((Invoke-Command -ComputerName $IpAddress -Credential $VHDImageCredentials {"Test"} -ErrorAction SilentlyContinue) -ne "Test") {Start-Sleep -Seconds 1}



}

Write-Host "will create a failover cluster with two nodes..."
.\Roles\DeployWACHA\DSC\DSCCreateFC.ps1 -Credential $DomainCredentials -RoleConfig .\Roles\DeployWACHA\Config\$($SelectForm.VMsConfig)
Start-DscConfiguration -Path ".\Roles\DeployWACHA\DSC\temp\" -Verbose -Wait -Force -Credential $VHDImageCredentials
Get-ChildItem ".\Roles\DeployWACHA\DSC\temp\" -Include *.mof -Recurse | Remove-Item

Write-Host "Restarting nodes..."
.\Roles\DeployWACHA\DSC\DSCRebootNode.ps1 -RoleConfig .\Roles\DeployWACHA\Config\$($SelectForm.VMsConfig)
Start-DscConfiguration -Path ".\Roles\DeployWACHA\DSC\temp\" -Verbose -Wait -Force -Credential $VHDImageCredentials
Get-ChildItem ".\Roles\DeployWACHA\DSC\temp\" -Include *.mof -Recurse | Remove-Item
