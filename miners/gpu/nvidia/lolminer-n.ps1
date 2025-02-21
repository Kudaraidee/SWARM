. .\build\powershell\global\miner_stat.ps1;
. .\build\powershell\global\modules.ps1;
$(vars).NVIDIATypes | ForEach-Object {

    ### Due to lolminer api- only 1 group can exist.
    if ( $_ -eq "NVIDIA1" -and $(vars).AMDTypes.Count -eq 0) {
        $ConfigType = $_; $Num = $ConfigType -replace "NVIDIA", ""
        $CName = "lolminer-n"

        ##Miner Path Information
        if ($(vars).nvidia.$CName.$ConfigType) { $Path = "$($(vars).nvidia.$CName.$ConfigType)" }
        else { $Path = "None" }
        if ($(vars).nvidia.$CName.uri) { $Uri = "$($(vars).nvidia.$CName.uri)" }
        else { $Uri = "None" }
        if ($(vars).nvidia.$CName.minername) { $MinerName = "$($(vars).nvidia.$CName.minername)" }
        else { $MinerName = "None" }

        $User = "User$Num"; $Pass = "Pass$Num"; $Name = "$CName-$Num"; $Port = "6300$Num"

        $MinerAlgos = @();

        Switch ($Num) {
            1 { $Get_Devices = $(vars).NVIDIADevices1; $Rig = $(arg).RigName1; $MinerAlgos = $(vars).GPUAlgorithm1 }
            2 { $Get_Devices = $(vars).NVIDIADevices2; $Rig = $(arg).RigName2;  $MinerAlgos = $(vars).GPUAlgorithm2 }
            3 { $Get_Devices = $(vars).NVIDIADevices3; $Rig = $(arg).RigName3;  $MinerAlgos = $(vars).GPUAlgorithm3 }
        }
    
        ##Log Directory
        $Log = Join-Path $($(vars).dir) "logs\$Name.log"

        ##Parse -GPUDevices
        if ($Get_Devices -ne "none") { $Devices = $Get_Devices }
        else { $Devices = $Get_Devices }

        ##Get Configuration File
        ##This is located in config\miners
        $MinerConfig = $Global:config.miners.$CName

        ##Export would be /path/to/[SWARMVERSION]/build/export && Bleeding Edge Check##
        $ExportDir = "/lib/x86_x64-linux-gnu"
        $Miner_Dir = Join-Path ($(vars).dir) ((Split-Path $Path).replace(".", ""))

        ##Prestart actions before miner launch
        ##This can be edit in miner.json
        $Prestart = @()
        #if ($IsLinux) { $Prestart += "export LD_PRELOAD=/lib/x86_64-linux-gnu/libcurl.so.4" }
        $PreStart += "export LD_LIBRARY_PATH=$ExportDir`:$Miner_Dir"
        if ($IsLinux) { $Prestart += "export DISPLAY=:0" }
        $MinerConfig.$ConfigType.prestart | ForEach-Object { $Prestart += "$($_)" }

        if ($(vars).Coins) { $Pools = $(vars).CoinPools } else { $Pools = $(vars).AlgoPools }

        if ($(vars).Bancount -lt 1) { $(vars).Bancount = 5 }

        ##Build Miner Settings
        $MinerConfig.$ConfigType.commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

            $MinerAlgo = $_

            if (
                $MinerAlgo -in $MinerAlgos -and
                $Name -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
                $ConfigType -notin $global:Config.Pool_Algos.$MinerAlgo.exclusions -and
                $Name -notin $(vars).BanHammer
            ) {
                $StatAlgo = $MinerAlgo -replace "`_", "`-"
                $Stat = Global:Get-Stat -Name "$($Name)_$($StatAlgo)_hashrate"
                if ($(arg).Rej_Factor -eq "Yes" -and $Stat.Rejections -gt 0 -and $Stat.Rejection_Periods -ge 3) { $HashStat = $Stat.Hour * (1 - ($Stat.Rejections * 0.01)) }
                else { $HashStat = $Stat.Hour }
                $Pools | Where-Object Algorithm -eq $MinerAlgo | ForEach-Object {
                    $SelAlgo = $_.Algorithm
                    if ($MinerConfig.$ConfigType.difficulty.$($_.Algorithm)) { $Diff = ",d=$($MinerConfig.$ConfigType.difficulty.$($_.Algorithm))" }else { $Diff = "" }
                    [PSCustomObject]@{
                        MName             = $Name
                        Coin              = $(vars).Coins
                        Delay             = $MinerConfig.$ConfigType.delay
                        Fees              = $MinerConfig.$ConfigType.fee.$($_.Algorithm)
                        Symbol            = "$($_.Symbol)"
                        MinerName         = $MinerName
                        Prestart          = $PreStart
                        Type              = $ConfigType
                        Path              = $Path
                        Devices           = $Devices
                        Stratum           = "$($_.Protocol)://$($_.Pool_Host):$($_.Port)"
                        Version           = "$($(vars).nvidia.$CName.version)"
                        DeviceCall        = "lolminer"
                        Arguments         = "--algo $($MinerConfig.$ConfigType.naming.$($_.Algorithm)) --pool $($_.Pool_Host):$($_.Port) --user $($_.$User) $AddArgs--pass $($_.$Pass)$($Diff) --apiport $Port $($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                        HashRates         = [Decimal]$Stat.Hour
                        HashRate_Adjusted = [Decimal]$Hashstat
                        Quote             = $_.Price
                        Rejections        = $Stat.Rejections
                        Power             = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                        MinerPool         = "$($_.Name)"
                        Port              = $Port
                        Worker            = $Rig
                        API               = "lolminer"
                        Wallet            = "$($_.$User)"
                        URI               = $Uri
                        Server            = "localhost"
                        Algo              = "$($_.Algorithm)"
                        Log               = $Log
                    }
                }
            }
        }
    }
}
