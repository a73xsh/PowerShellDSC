function HostsDialog {
    param(
        $FILE,
        $ConfigFiles
    )
if ($FILE)
	{
		if (Test-Path $FILE)
			{
				#Set the data configuration file
				$ConfigFile = $FILE
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
		#Create list of Config Files
		[array]$DropDownArray = $null
		foreach ($CFs in $ConfigFiles)
			{
				[array]$DropDownArray += $CFs.Name
			}

		#Menu Function
		function Return-DropDown
			{
				$Choice = $DropDown.SelectedItem.ToString()
				$Form.Close()
			}
		[array]$DropDownArray += "EXIT"

		#Generate GUI input box for Config File Selection
		[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
		[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
		$Form = New-Object System.Windows.Forms.Form
		$Form.width = 700
		$Form.height = 150
		$Form.StartPosition = "CenterScreen"
		$Form.Text = "Hosts File to use"
		$DropDown = new-object System.Windows.Forms.ComboBox
		$DropDown.Location = new-object System.Drawing.Size(100,10)
		$DropDown.Size = new-object System.Drawing.Size(550,30)
		ForEach ($Item in $DropDownArray)
			{
				$DropDown.Items.Add($Item) | Out-Null
			}
		$Form.Controls.Add($DropDown)
		$DropDownLabel = new-object System.Windows.Forms.Label
		$DropDownLabel.Location = new-object System.Drawing.Size(1,10)
		$DropDownLabel.size = new-object System.Drawing.Size(255,20)
		$DropDownLabel.Text = "Hosts File"
		$Form.Controls.Add($DropDownLabel)
		$Button = new-object System.Windows.Forms.Button
		$Button.Location = new-object System.Drawing.Size(300,50)
		$Button.Size = new-object System.Drawing.Size(75,25)
		$Button.Text = "Select"
		$Button.Add_Click({Return-DropDown})
		$form.Controls.Add($Button)
		$Form.Add_Shown({$Form.Activate()})
		$Form.ShowDialog() | Out-Null

		#Check for valid entry
		if ($DropDown.SelectedItem -eq $null)
			{
				Write-Host -ForegroundColor Red "Nothing Selected"
				exit
			}

		#Check to see if EXIT selected
		if ($DropDown.SelectedItem -eq "EXIT")
			{
				Write-Host -ForegroundColor DarkBlue "You have chosen to EXIT the script"
				exit
			}
		#Set the data configuration file
		$ConfigFile = $DropDown.SelectedItem
		$ConfigFileDir = $CFs.Directory
	}

$ConfigFile
}
