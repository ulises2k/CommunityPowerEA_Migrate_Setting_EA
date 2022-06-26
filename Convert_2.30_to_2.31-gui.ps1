# Script to Upgrade .Set File From CommunityPower EA v2.30.x to v2.31.x
# Drag and drop file settings 2.30.x MT5 to windows form and press button
#
# Autor: Ulises Cune (@Ulises2k)
# v2.1


Function Get-IniFile ($file) {
    $ini = [ordered]@{}
    switch -regex -file $file {
        "^\s*(.+?)\s*=\s*(.*)$" {
            $name, $value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                if ($value.Contains('||') ) {
                    $ini[$name] = $value.Split('||')[0]
                    continue
                }
                else {
                    $ini[$name] = $value
                    continue
                }
            }
        }
    }
    $ini
}

function Set-OrAddIniValue {
    Param(
        [string]$FilePath,
        [hashtable]$keyValueList
    )

    $content = Get-Content $FilePath
    $keyValueList.GetEnumerator() | ForEach-Object {
        if ($content -match "^$($_.Key)\s*=") {
            $content = $content -replace "$($_.Key)\s*=(.*)", "$($_.Key)=$($_.Value)"
        }
        else {
            $content += "$($_.Key)=$($_.Value)"
        }
    }

    $content | Set-Content $FilePath
}

function MainConvertVersion ([string]$filePath) {

    #Detect Version 2.31
    if (!(Select-String -Path $filePath -Quiet -Pattern "MinMarginLevel")) {

        $PathDest = (Get-Item $filePath).BaseName + "-v2.31.set"
        $CurrentDir = Split-Path -Path "$filePath"
        $filePathNew = "$CurrentDir\$PathDest"
        Copy-Item "$filePath" -Destination $filePathNew

        $inifile = Get-IniFile($filePathNew)
        #This is the instruction
        #https://communitypowerea.userecho.com/en/communities/1/topics/28-all-pips-parameters-calculated-using-atr?redirect_to_reply=1857#comment-1857
        # Default Value 2.31
        #; Expert properties
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            MinMarginLevel = "0"
        }

        Add-Content -Path $filePathNew -Value "; Volatility for all parameters nominated in points"
        Add-Content -Path $filePathNew -Value "VolPV_Properties===================================================================================="
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            VolPV_Type = "1"
        }

        #ATR parameters must be set in the corresponding section.
        $StepATR_TF = $inifile['StepATR_TF']
        $StepATR_Period = $inifile['StepATR_Period']
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            VolPV_TF      = $StepATR_TF
            VolPV_Period  = $StepATR_Period
            VolPV_MinSize = "0"
            VolPV_MaxSize = "0"
        }



        #; Pending entry properties
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            Pending_Distance_ModeP = "0"
        }

        #; StopLoss properties
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            StopLoss_ModeP = "0"
        }

        #; TakeProfit properties
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            TakeProfit_ModeP       = "0"
            MinProfitToClose_ModeP = "0"
        }

        #; Global Account properties
        Add-Content -Path $filePathNew -Value "; Global Account properties"
        Add-Content -Path $filePathNew -Value "GlobalAccount_Properties===================================================================================="
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            GlobalAccountTakeProfit_ccy    = "0"
            GlobalAccountTakeProfit_perc   = "0"
            GlobalAccountTargetProfit_ccy  = "0"
            GlobalAccountTargetProfit_perc = "0"
        }


        #; TrailingStop properties
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            TrailingStop_ModeP = "0"
        }

        #Default
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            MartingailType   = "0"
            Martingail_ModeP = "0"
        }

        # ATR * coefficient" mode must be replaced with "Martingale enabled",
        if ([int]$inifile['MartingailType'] -eq 3) {
            #"Step size calc mode" must be set to "Coefficient to volatility",
            Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
                MartingailType   = "1"
                Martingail_ModeP = "1"
            }
        }

        #Previous step * coefficient" mode must be replaced with "Martingale enabled".
        if ([int]$inifile['MartingailType'] -eq 2) {
            Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
                MartingailType = "1"
            }
        }

        #Step increase coefficient" for "Fixed step" mode must be set 1.
        if ([int]$inifile['MartingailType'] -eq 1) {
            Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
                StepCoeff = "1"
            }
        }

        #Add default values to replace below
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            AntiMartingailType   = "0"
            AntiMartingail_ModeP = "0"
        }

        # ATR * coefficient" mode must be replaced with "Martingale enabled",
        if ([int]$inifile['AntiMartingailType'] -eq 3) {
            #"Step size calc mode" must be set to "Coefficient to volatility",
            Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
                AntiMartingailType   = "1"
                AntiMartingail_ModeP = "1"
            }
        }

        #Previous step * coefficient" mode must be replaced with "Martingale enabled".
        if ([int]$inifile['AntiMartingailType'] -eq 2) {
            Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
                AntiMartingailType = "1"
            }
        }

        #Step increase coefficient" for "Fixed step" mode must be set 1.
        if ([int]$inifile['AntiMartingailType'] -eq 1) {
            Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
                AntiStepCoeff = "0"
            }
        }


        #; Anti-Martingail properties
        Set-OrAddIniValue -FilePath $filePathNew  -keyValueList @{
            AntiStopLoss_ModeP = "0"
        }
        return $true
    }
    else {
        return $false
    }
}

#######################GUI################################################################
### API Windows Forms ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

### Create form ###
$form = New-Object System.Windows.Forms.Form
$form.Text = "Convert Version 2.30 to 2.31 CommunityPower EA"
$form.Size = '512,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True

### Define controls ###
# Button
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '75,23'
$button.Width = 120
$button.Text = "Convert to 2.31 MT5"

# Checkbox
$checkbox = New-Object System.Windows.Forms.Checkbox
$checkbox.Location = '140,8'
$checkbox.AutoSize = $True
$checkbox.Text = "Clear afterwards"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Location = '5,40'
$label.AutoSize = $True
$label.Text = "Drag and Drop 2.30 MT5 files settings here:"

# Listbox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 480
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True

# StatusBar
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"

### Add controls to form ###
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($checkbox)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()

### Write event handlers ###
$button_Click = {
    foreach ($item in $listBox.Items) {
        if (!($i -is [System.IO.DirectoryInfo])) {
            if (MainConvertVersion -file $item) {
                [System.Windows.Forms.MessageBox]::Show('Successfully Convert from 2.30 to 2.31 MT5 Community Power EA', 'Convert from 2.30 to 2.31 MT5', 0, 64)
            }
            else {
                [System.Windows.Forms.MessageBox]::Show('This files is version 2.31', 'Convert from 2.30 to 2.31 MT5', 0, 64)
            }
        }
    }

    if ($checkbox.Checked -eq $True) {
        $listBox.Items.Clear()
    }

    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

$listBox_DragOver = [System.Windows.Forms.DragEventHandler] {
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        # $_ = [System.Windows.Forms.DragEventArgs]
        $_.Effect = 'Copy'
    }
    else {
        $_.Effect = 'None'
    }
}

$listBox_DragDrop = [System.Windows.Forms.DragEventHandler] {
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) {
        # $_ = [System.Windows.Forms.DragEventArgs]
        $listBox.Items.Add($filename)
    }
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}

### Wire up events ###
$button.Add_Click($button_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)

#### Show form ###
[void] $form.ShowDialog()
