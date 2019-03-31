##Miner Path Information
if ($NVIDIA.xmrig_nv.path3) { $Path = "$($NVIDIA.xmrig_nv.path3)" }
else { $Path = "None" }
if ($NVIDIA.xmrig_nv.uri) { $Uri = "$($NVIDIA.xmrig_nv.uri)" }
else { $Uri = "None" }
if ($NVIDIA.xmrig_nv.minername) { $MinerName = "$($NVIDIA.xmrig_nv.minername)" }
else { $MinerName = "None" }
if ($Platform -eq "linux") { $Build = "Tar" }
elseif ($Platform -eq "windows") { $Build = "Zip" }

$ConfigType = "NVIDIA3"
$User = "User3"

##Log Directory
$Log = Join-Path $dir "logs\$ConfigType.log"

##Parse -GPUDevices
if ($NVIDIADevices3 -ne "none") { $Devices = $NVIDIADevices3 }
else { $Devices = "none" }

##Get Configuration File
$GetConfig = "$dir\config\miners\xmrig_nv.json"
try { $Config = Get-Content $GetConfig | ConvertFrom-Json }
catch { Write-Warning "Warning: No config found at $GetConfig" }

##Export would be /path/to/[SWARMVERSION]/build/export##
$ExportDir = Join-Path $dir "build\export"

##Prestart actions before miner launch
$BE = "/usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0"
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
            [PSCustomObject]@{
                Delay      = $Config.$ConfigType.delay
                Symbol     = "$($_.Symbol)"
                MinerName  = $MinerName
                Prestart   = $PreStart
                Type       = $ConfigType
                Path       = $Path
                Devices    = $Devices
                DeviceCall = "xmrstak"
                Arguments  = "-a $($Config.$ConfigType.naming.$($_.Algorithm)) --api-port=50051 -o stratum+tcp://$($_.Host):$($_.Port) -u $($_.User3) -p$($_.Pass3)$($Diff) --donate-level 1 --nicehash $($Config.$ConfigType.commands.$($_.Algorithm))"    
                HashRates  = [PSCustomObject]@{$($_.Algorithm) = $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) }
                Quote      = if ($($Stats."$($Name)_$($_.Algorithm)_hashrate".Day)) { $($Stats."$($Name)_$($_.Algorithm)_hashrate".Day) * ($_.Price) }else { 0 }
                PowerX     = [PSCustomObject]@{$($_.Algorithm) = if ($Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($Watts.default."$($ConfigType)_Watts") { $Watts.default."$($ConfigType)_Watts" }else { 0 } }
                ocpower    = if ($Config.$ConfigType.oc.$($_.Algorithm).power) { $Config.$ConfigType.oc.$($_.Algorithm).power }else { $OC."default_$($ConfigType)".Power }
                occore     = if ($Config.$ConfigType.oc.$($_.Algorithm).core) { $Config.$ConfigType.oc.$($_.Algorithm).core }else { $OC."default_$($ConfigType)".core }
                ocmem      = if ($Config.$ConfigType.oc.$($_.Algorithm).memory) { $Config.$ConfigType.oc.$($_.Algorithm).memory }else { $OC."default_$($ConfigType)".memory }
                ocfans     = if ($Config.$ConfigType.oc.$($_.Algorithm).fans) { $Config.$ConfigType.oc.$($_.Algorithm).fans }else { $OC."default_$($ConfigType)".fans }
                FullName   = "$($_.Mining)"
                MinerPool  = "$($_.Name)"
                Port       = 50051
                API        = "xmrstak"
                Wrap       = $false
                Wallet     = "$($_.$User)"
                URI        = $Uri
                BUILD      = $Build
                Algo       = "$($_.Algorithm)"
                Log        = $Log 
            }            
        }
    }
}
