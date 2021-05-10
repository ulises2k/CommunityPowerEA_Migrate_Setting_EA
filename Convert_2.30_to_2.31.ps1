# Script to Upgrade .Set File From CommunityPower EA v2.30.x to v2.31.x
# Run:
# Open cmd.exe and execute this
# powershell.exe -file ".\Convert_2.30_to_2.31.ps1" EURUSD-v2.30.set
# The file migrated is EURUSD-v2.30-Migrate-v2.31.set
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
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        MinMarginLevel = "0"
    }

    Add-Content -Path $filePath -Value "; Volatility for all parameters nominated in points"
    Add-Content -Path $filePath -Value "VolPV_Properties===================================================================================="
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        VolPV_Type = "1"
    }

    #ATR parameters must be set in the corresponding section.
    $StepATR_TF = $inifile['StepATR_TF']
    $StepATR_Period = $inifile['StepATR_Period']
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        VolPV_TF      = $StepATR_TF
        VolPV_Period  = $StepATR_Period
        VolPV_MinSize = "0"
        VolPV_MaxSize = "0"
    }



    #; Pending entry properties
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        Pending_Distance_ModeP = "0"
    }

    #; StopLoss properties
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        StopLoss_ModeP = "0"
    }

    #; TakeProfit properties
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        TakeProfit_ModeP       = "0"
        MinProfitToClose_ModeP = "0"
    }

    #; Global Account properties
    Add-Content -Path $filePath -Value "; Global Account properties"
    Add-Content -Path $filePath -Value "GlobalAccount_Properties===================================================================================="
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        GlobalAccountTakeProfit_ccy    = "0"
        GlobalAccountTakeProfit_perc   = "0"
        GlobalAccountTargetProfit_ccy  = "0"
        GlobalAccountTargetProfit_perc = "0"
    }


    #; TrailingStop properties
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        TrailingStop_ModeP = "0"
    }

    #Default
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        MartingailType   = "0"
        Martingail_ModeP = "0"
    }

    # ATR * coefficient" mode must be replaced with "Martingale enabled",
    if ([int]$inifile['MartingailType'] -eq 3) {
        #"Step size calc mode" must be set to "Coefficient to volatility",
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            MartingailType   = "1"
            Martingail_ModeP = "1"
        }
    }

    #Previous step * coefficient" mode must be replaced with "Martingale enabled".
    if ([int]$inifile['MartingailType'] -eq 2) {
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            MartingailType = "1"
        }
    }

    #Step increase coefficient" for "Fixed step" mode must be set 1.
    if ([int]$inifile['MartingailType'] -eq 1) {
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            StepCoeff = "1"
        }
    }

    #Add default values to replace below
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        AntiMartingailType   = "0"
        AntiMartingail_ModeP = "0"
    }

    # ATR * coefficient" mode must be replaced with "Martingale enabled",
    if ([int]$inifile['AntiMartingailType'] -eq 3) {
        #"Step size calc mode" must be set to "Coefficient to volatility",
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiMartingailType   = "1"
            AntiMartingail_ModeP = "1"
        }
    }

    #Previous step * coefficient" mode must be replaced with "Martingale enabled".
    if ([int]$inifile['AntiMartingailType'] -eq 2) {
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiMartingailType = "1"
        }
    }

    #Step increase coefficient" for "Fixed step" mode must be set 1.
    if ([int]$inifile['AntiMartingailType'] -eq 1) {
        Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
            AntiStepCoeff = "0"
        }
    }


    #; Anti-Martingail properties
    Set-OrAddIniValue -FilePath $filePath  -keyValueList @{
        AntiStopLoss_ModeP = "0"
    }

    Write-Output "Successfully migrated from 2.30 to 2.31 Community Power EA"
}
else {
    Write-Output ".set file is version 2.31"
}