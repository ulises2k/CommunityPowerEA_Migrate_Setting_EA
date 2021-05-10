# Script to Upgrade .Set File From CommunityPower EA v2.30.x to v2.31.x
# Run:
# Open cmd.exe and execute this
# powershell.exe -file ".\Convert_2.30_to_2.31.ps1" EURUSD-v2.30.set
# The file migrated is EURUSD-v2.30-Migrate-v2.31.set
#
# Autor: Ulises Cune (@Ulises2k)
# v2.0


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


$filePath = $args[0]
#$filePath = "Default-v2.30.set"
$Destino = (Get-Item $filePath).BaseName + "-Migrate-v2.31.set"
Copy-Item "$filePath" -Destination $Destino

$filePath = $Destino
$file = Get-Content -Path $filePath
$inifile = Get-IniFile($filePath)

#Detect Version 2.31
if (!(Select-String -Path $filePath -Quiet -Pattern "MinMarginLevel")) {

    # Default Value 2.31
    #; Expert properties
    Add-Content -Path $filePath -Value "MinMarginLevel=0"

    Add-Content -Path $filePath -Value "; Volatility for all parameters nominated in points"
    Add-Content -Path $filePath -Value "VolPV_Properties===================================================================================="
    Add-Content -Path $filePath -Value "VolPV_Type=1"

    #ATR parameters must be set in the corresponding section.
    #$StepATR_TF=Select-String -Path $filePath -Pattern "StepATR_TF=(\d+)" | % {$_.Matches.Groups[1].Value}
    #Add-Content -Path $filePath -Value "VolPV_TF=$StepATR_TF"
    $StepATR_TF = $inifile['StepATR_TF']
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        VolPV_TF = $StepATR_TF
    }



    #$StepATR_Period=Select-String -Path $filePath -Pattern "StepATR_Period=(\d+)" | % {$_.Matches.Groups[1].Value}
    #Add-Content -Path $filePath -Value "VolPV_Period=$StepATR_Period"
    $StepATR_Period = $inifile['StepATR_Period']
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        VolPV_Period = $StepATR_Period
    }

    Add-Content -Path $filePath -Value "VolPV_MinSize=0"
    Add-Content -Path $filePath -Value "VolPV_MaxSize=0"

    #; Pending entry properties
    Add-Content -Path $filePath -Value "Pending_Distance_ModeP=0"

    #; StopLoss properties
    Add-Content -Path $filePath -Value "StopLoss_ModeP=0"

    #; TakeProfit properties
    Add-Content -Path $filePath -Value "TakeProfit_ModeP=0"
    Add-Content -Path $filePath -Value "MinProfitToClose_ModeP=0"

    #; Global Account TakeProfit properties
    Add-Content -Path $filePath -Value "; Global Account TakeProfit properties"
    Add-Content -Path $filePath -Value "GlobalAccountTakeProfit_Prop===================================================================================="
    Add-Content -Path $filePath -Value "GlobalAccountTakeProfit_ccy=0"
    Add-Content -Path $filePath -Value "GlobalAccountTakeProfit_perc=0"

    #; TrailingStop properties
    Add-Content -Path $filePath -Value "TrailingStop_ModeP=0"

    #Default
    Add-Content -Path $filePath -Value "MartingailType=0"
    Add-Content -Path $filePath -Value "Martingail_ModeP=0"

    # ATR * coefficient" mode must be replaced with "Martingale enabled",
    #if (Select-String -Path $filePath -Quiet -Pattern "MartingailType=3") {
    if ([int]$inifile['MartingailType'] -eq 3) {
        #Add-Content -Path $filePath -Value "MartingailType=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            MartingailType = "1"
        }

        #"Step size calc mode" must be set to "Coefficient to volatility",
        #Add-Content -Path $filePath -Value "Martingail_ModeP=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            Martingail_ModeP = "1"
        }
    }

    #Previous step * coefficient" mode must be replaced with "Martingale enabled".
    #if (Select-String -Path $filePath -Quiet -Pattern "MartingailType=2") {
    if ([int]$inifile['MartingailType'] -eq 2) {
        #Add-Content -Path $filePath -Value "MartingailType=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            MartingailType = "1"
        }
    }

    #Step increase coefficient" for "Fixed step" mode must be set 1.
    #if (Select-String -Path $filePath -Quiet -Pattern "MartingailType=1") {
    if ([int]$inifile['MartingailType'] -eq 1) {
        #$file.Replace("StepCoeff=","")
        #Add-Content -Path $filePath -Value "StepCoeff=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            StepCoeff = "1"
        }
    }

    #Add default values to replace below
    Add-Content -Path $filePath -Value "AntiMartingailType=0"
    Add-Content -Path $filePath -Value "AntiMartingail_ModeP=0"

    # ATR * coefficient" mode must be replaced with "Martingale enabled",
    #if (Select-String -Path $filePath -Quiet -Pattern "AntiMartingailType=3") {
    if ([int]$inifile['AntiMartingailType'] -eq 3) {
        #Add-Content -Path $filePath -Value "AntiMartingailType=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiMartingailType = "1"
        }

        #"Step size calc mode" must be set to "Coefficient to volatility",
        #Add-Content -Path $filePath -Value "AntiMartingail_ModeP=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiMartingail_ModeP = "1"
        }
    }

    #Previous step * coefficient" mode must be replaced with "Martingale enabled".
    #if (Select-String -Path $filePath -Quiet -Pattern "AntiMartingailType=2") {
    if ([int]$inifile['AntiMartingailType'] -eq 2) {
        #Add-Content -Path $filePath -Value "AntiMartingailType=1"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiMartingailType = "1"
        }
    }

    #Step increase coefficient" for "Fixed step" mode must be set 1.
    #if (Select-String -Path $filePath -Quiet -Pattern "AntiMartingailType=1") {
    if ([int]$inifile['AntiMartingailType'] -eq 1) {
        #Add-Content -Path $filePath -Value "AntiStepCoeff=0"
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiStepCoeff = "1"
        }
    }


    #; Anti-Martingail properties
    Add-Content -Path $filePath -Value "AntiStopLoss_ModeP=0"
}
else {
    Write-Output ".set file is version 2.31"
}