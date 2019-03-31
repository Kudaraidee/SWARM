if ($nvidia.phoenix.path3) { $Path = "$($nvidia.phoenix.path3)" }
else { $Path = "None" }
if ($nvidia.phoenix.uri) { $Uri = "$($nvidia.phoenix.uri)" }
else { $Uri = "None" }
if ($nvidia.phoenix.minername) { $MinerName = "$($nvidia.phoenix.minername)" }
else { $MinerName = "None" }
if ($Platform -eq "linux") { $Build = "Tar" }
elseif ($Platform -eq "windows") { $Build = "Zip" }

$ConfigType = "NVIDIA3"
$User = "User3"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Parse -GPUDevices
if ($NVIDIADevices3 -ne "none") {
    $ClayDevices3 = $NVIDIADevices3 -split ","
    $ClayDevices3 = Switch ($ClayDevices3) { "10" { "a" }; "11" { "b" }; "12" { "c" }; "13" { "d" }; "14" { "e" }; "15" { "f" }; "16" { "g" }; "17" { "h" }; "18" { "i" }; "19" { "j" }; "20" { "k" }; default { "$_" }; }
    $ClayDevices3 = $ClayDevices3 | ForEach-Object { $_ -replace ("$($_)", ",$($_)") }
    $ClayDevices3 = $ClayDevices3 -join ""
    $ClayDevices3 = $ClayDevices3.TrimStart(" ", ",")  
    $ClayDevices3 = $ClayDevices3 -replace (",", "")
    $Devices = $ClayDevices3
}
else { $Devices = "none" }

##Get Configuration File
$GetConfig = "$dir\config\miners\phoenix.json"
try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
catch { Write-Warning "Warning: No config found at $GetConfig" }

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$Prestart = @()
$PreStart += "export LD_LIBRARY_PATH=$ExportDir"
$Config.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

if ($Coins -eq $true) { $Pools = $CoinPools }else { $Pools = $AlgoPools }

##Build Miner Settings
$Config.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $MinerAlgo = $_
    $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
        if ($Algorithm -eq "$($_.Algorithm)" -and $Bad_Miners.$($_.Algorithm) -notcontains $Name) {
            if ($Config.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($Config.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
            if ($_.Worker) { $MinerWorker = "-eworker $($_.Worker) " }
            else { $MinerWorker = "-epsw $($_.Pass3)$($Diff) " }
            [PSCustomObject]@{
                Delay      = $Config.$ConfigType.delay
                Symbol     = "$($_.Symbol)"
                MinerName  = $MinerName
                Prestart   = $PreStart
                Type       = $ConfigType
                Path       = $Path
                Devices    = $Devices
                DeviceCall = "claymore"
                Arguments  = "-platform 2 -mport 7333 -mode 1 -allcoins 1 -allpools 1 -epool $($_.Protocol)://$($_.Host):$($_.Port) -ewal $($_.User3) $MinerWorker-wd 0 -logfile `'$(Split-Path $Log -Leaf)`' -logdir `'$(Split-Path $Log)`' -gser 2 -dbg -1 -eres 1 $($Config.$ConfigType.commands.$($_.Algorithm))"
                HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) }
                Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) { $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price) }else { 0 }
                PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) { $Config.$ConfigType.oc.$($_.Algorithm).power }else { $OC."default_$($ConfigType)".Power }
                occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) { $Config.$ConfigType.oc.$($_.Algorithm).memory }else { $OC."default_$($ConfigType)".memory }
                ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                ethpill    = $Config.$ConfigType.oc.$($_.Algorithm).ethpill
                pilldelay  = $Config.$ConfigType.oc.$($_.Algorithm).pilldelay
                FullName   = "$($_.Mining)"
                API        = "claymore"
                Port       = 7333
                MinerPool  = "$($_.Name)"
                Wallet     = "$($_.$User)"
                URI        = $Uri
                BUILD      = $Build
                Algo       = "$($_.Algorithm)"
                Log        = "miner_generated"
            }            
        }
    }
}