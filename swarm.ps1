<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

## Set Current Path
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
##filepath dir
$global:dir = (Split-Path $script:MyInvocation.MyCommand.Path)
$env:Path += ";$global:dir\build\cmd"
try { Get-ChildItem . -Recurse | Unblock-File } catch {}
try { if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { Start-Process "powershell" -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath `'$($global:Dir)`'" -WindowStyle Minimized } }catch { }
if(-not (Test-Path ".\build\txt\fixed.txt")) {
try {
Write-Host "Removing Previous Net Firewall Rules"
Remove-NetFirewallRule -All
} catch {}
"Fixed" | Set-Content ".\build\txt\fixed.txt"
}
try{ $Net = Get-NetFireWallRule } catch {}
if($Net) {
try { if( -not ( $Net | Where {$_.DisplayName -like "*swarm.ps1*"} ) ) { New-NetFirewallRule -DisplayName 'swarm.ps1' -Direction Inbound -Program "$global:dir\swarm.ps1" -Action Allow | Out-Null} } catch { }
}
$Net = $Null
## Debug Mode- Allow you to run with last known arguments or arguments.json.
$Debug = $false
if ($Debug -eq $True) {
    Start-Transcript ".\logs\debug.log"
    if ((Test-Path "C:\")) { Set-ExecutionPolicy Bypass -Scope Process }
}

## Date Bug
$global:cultureENUS = New-Object System.Globalization.CultureInfo("en-US")
[cultureinfo]::CurrentCulture = 'en-US'
. .\build\powershell\command-startup.ps1;

## Get Parameters
$Global:config = @{ }
Get-Parameters

if (-not (Test-Path ".\build\txt")) { New-Item -Name "txt" -ItemType "Directory" -Path ".\build" | Out-Null }
$global:Config.Params.Platform | Set-Content ".\build\txt\os.txt"

##Start The Log
$global:dir | Set-Content ".\build\bash\dir.sh";
$Log = 1;
. .\build\powershell\startlog.ps1;
$global:logname = $null
start-log -Number $Log;
if (-not $global:Config.Params.Platform) {
    write-log "Detecting Platform..." -Foreground Cyan
    if (Test-Path "C:\") { $global:Config.Params.Platform = "windows" }
    else { $global:Config.Params.Platform = "linux" }
    Write-log "OS = $($global:Config.Params.Platform)" -ForegroundColor Green
}

$global:Config.Add("Pool_Algos",(Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json))

## Load Codebase
. .\build\powershell\killall.ps1; . .\build\powershell\remoteupdate.ps1; . .\build\powershell\octune.ps1;
. .\build\powershell\datafiles.ps1; . .\build\powershell\command-stats.ps1; . .\build\powershell\command-pool.ps1;
. .\build\powershell\command-miner.ps1; . .\build\powershell\launchcode.ps1; . .\build\powershell\datefiles.ps1;
. .\build\powershell\watchdog.ps1; . .\build\powershell\download.ps1; . .\build\powershell\hashrates.ps1;
. .\build\powershell\naming.ps1; . .\build\powershell\childitems.ps1; . .\build\powershell\powerup.ps1;
. .\build\api\hiveos\hello.ps1; . .\build\powershell\checkbackground.ps1; . .\build\powershell\maker.ps1;
. .\build\powershell\intensity.ps1; . .\build\powershell\cl.ps1; . .\build\powershell\screen.ps1; 
. .\build\api\hiveos\do-command.ps1; . .\build\api\hiveos\response.ps1; . .\build\api\html\api.ps1; 
. .\build\powershell\config_file.ps1; . .\build\powershell\altwallet.ps1; . .\build\api\pools\include.ps1; 
. .\build\api\miners\include.ps1; . .\build\api\miners\include.ps1; . .\build\api\hiveos\oc-tune.ps1;
if ($global:Config.Params.Platform -eq "linux") { . .\build\powershell\sexyunixlogo.ps1; . .\build\powershell\gpu-count-unix.ps1 }
if ($global:Config.Params.Platform -eq "windows") { . .\build\api\hiveos\hiveoc.ps1; . .\build\powershell\sexywinlogo.ps1; . .\build\powershell\bus.ps1; . .\build\powershell\environment.ps1; }

## Version
$Version = Get-Content ".\h-manifest.conf" | ConvertFrom-StringData
$Version.CUSTOM_VERSION | Set-Content ".\build\txt\version.txt"
$Version = $Version.CUSTOM_VERSION

## Initiate Update Check
if ($global:Config.Params.Platform -eq "Windows") { $GetUpdates = "Yes" }
else { $GetUpdates = $global:Config.Params.Update }
start-update -Update $Getupdates

##Load Previous Times & PID Data
## Close Previous Running Agent- Agent is left running to send stats online, even if SWARM crashes
if ($global:Config.Params.Platform -eq "windows") { Start-AgentCheck } 

##Start Date Collection
Get-DateFiles
Start-Sleep -S 1
$PID | Out-File ".\build\pid\miner_pid.txt"

## Change console icon and title
if ($global:Config.Params.Platform -eq "windows") {
    $host.ui.RawUI.WindowTitle = "SWARM";
    Start-Process "powershell" -ArgumentList "-command .\build\powershell\icon.ps1 `".\build\apps\SWARM.ico`"" -NoNewWindow
}

## Crash Reporting
Start-CrashReporting

##Clear Old Agent Stats
Clear-Stats

## Check For Remote Arugments Change Arguments To Remote Arguments
if ((Test-Path ".\config\parameters\newarguments.json") -or $Debug -eq $true) {
    write-Log "Detected New Arguments- Changing Parameters" -ForegroundColor Cyan
    write-Log "These arguments can be found/modified in config < parameters < newarguments.json" -ForegroundColor Cyan
    Start-Sleep -S 2
}

if ($global:Config.Params.Platform -eq "windows") { 
    ##Remove Exclusion
}

## lower case (Linux file path)
if ($global:Config.Params.Platform -eq "Windows") { $global:Config.Params.Platform = "windows" }

## upper case (Linux file path)
$global:Config.Params.Type | ForEach-Object {
    if ($_ -eq "amd1") { $_ = "AMD1" }
    if ($_ -eq "nvidia1") { $_ = "NVIDIA1" }
    if ($_ -eq "nvidia2") { $_ = "NVIDIA2" }
    if ($_ -eq "nvidia2") { $_ = "NVIDIA3" }
    if ($_ -eq "cpu") { $_ = "CPU" }
    if ($_ -eq "asic") { $_ = "ASIC" }
}

## create debug/command folder
if (-not (Test-Path ".\build\txt")) { New-Item -Path ".\build" -Name "txt" -ItemType "directory" | Out-Null }

## Time Sych For All SWARM Users
write-Log "Sycronizing Time Through Nist" -ForegroundColor Yellow
$Sync = Get-Nist
try { Set-Date $Sync -ErrorAction Stop }catch { write-Log "Failed to syncronize time- Are you root/administrator?" -ForegroundColor red; Start-Sleep -S 5 }

##HiveOS Confirmation
write-Log "HiveOS = $($global:Config.Params.HiveOS)"

#Startings Settings (Non User Arguments):
$BenchmarkMode = "No"
$Instance = 1
$DecayStart = Get-Date
$DecayPeriod = 60 #seconds
$DecayBase = 1 - 0.1 #decimal percentage
$Deviation = $global:Config.Params.Donate
$WalletDonate = "1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i"
$NicehashDonate = "3JfBiUZZV17DTjAFCnZb97UpBgtLPLLDop"
$UserDonate = "MaynardVII"
$WorkerDonate = "Rig1"
$PoolNumber = 1
$ActiveMinerPrograms = @()
$Global:DWallet = $null
$global:DCheck = $false
$DonationMode = $false
$Warnings = @()
$global:Pool_Hashrates = @{ }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12,[Net.SecurityProtocolType]::Tls11,[Net.SecurityProtocolType]::tls

## Initialize
 $global:GPU_Count = $null
 $global:BusData = $null
 switch ($global:Config.params.Platform) {
     "linux" { Start-LinuxConfig }
     "windows" { Start-WindowsConfig }
 }

## Determine AMD platform
if ($global:Config.Params.Type -like "*AMD*") {
    if ([string]$global:Config.Params.CLPlatform) { $AMDPlatform = [string]$global:Config.Params.CLPlatform }
    else {
        [string]$AMDPlatform = get-AMDPlatform
        write-Log "AMD OpenCL Platform is $AMDPlatform"
    }
}

#Timers
if ($global:Config.Params.Timeout) { $TimeoutTime = [Double]$global:Config.Params.Timeout * 3600 }
else { $TimeoutTime = 10000000000 }
$TimeoutTimer = New-Object -TypeName System.Diagnostics.Stopwatch
$TimeoutTimer.Start()
$logtimer = New-Object -TypeName System.Diagnostics.Stopwatch
$logtimer.Start()
$LoadTimer = New-Object -TypeName System.Diagnostics.Stopwatch

##GPU-Count- Parse the hashtable between devices.
if ($global:Config.Params.Type -like "*NVIDIA*" -or $global:Config.Params.Type -like "*AMD*" -or $global:Config.Params.Type -like "*CPU*") {
    if (Test-Path ".\build\txt\nvidiapower.txt") { Remove-Item ".\build\txt\nvidiapower.txt" -Force }
    if (Test-Path ".\build\txt\amdpower.txt") { Remove-Item ".\build\txt\amdpower.txt" -Force }
    if ($global:GPU_Count -ne 0) { $Global:GPUCount = @(); for ($i = 0; $i -lt $Global:GPU_Count; $i++) { [string]$Global:GPUCount += "$i," } }
    if ($global:Config.Params.CPUThreads -ne 0) { $CPUCount = @(); for ($i = 0; $i -lt $global:Config.Params.CPUThreads; $i++) { [string]$CPUCount += "$i," } }
    if ($Global:GPU_Count -eq 0) { $Device_Count = $global:Config.Params.CPUThreads }
    else { $Device_Count = $Global:GPU_Count }
    write-Log "Device Count = $Device_Count" -foregroundcolor green
    Start-Sleep -S 2
    if ($GPUCount -ne $null) { $LogGPUS = $GPUCount.Substring(0, $GPUCount.Length - 1) }

    if ([string]$global:Config.Params.GPUDevices1) {
        $NVIDIADevices1 = [String]$global:Config.Params.GPUDevices1 -replace " ", ","; 
        $AMDDevices1 = [String]$global:Config.Params.GPUDevices1 -replace " ", "," 
    }
    else { 
        $NVIDIADevices1 = "none"; 
        $AMDDevices1 = "none" 
    }
    if ([string]$global:Config.Params.GPUDevices2) { $NVIDIADevices2 = [String]$global:Config.Params.GPUDevices2 -replace " ", "," } else { $NVIDIADevices2 = "none" }
    if ([string]$global:Config.Params.GPUDevices3) { $NVIDIADevices3 = [String]$global:Config.Params.GPUDevices3 -replace " ", "," } else { $NVIDIADevices3 = "none" }

    $GCount = Get-Content ".\build\txt\devicelist.txt" | ConvertFrom-Json
    $NVIDIATypes = @(); if ($global:Config.Params.Type -like "*NVIDIA*") { $global:Config.Params.Type | Where { $_ -like "*NVIDIA*" } | % { $NVIDIATypes += $_ } }
    $CPUTypes = @(); if ($global:Config.Params.Type -like "*CPU*") { $global:Config.Params.Type | Where { $_ -like "*CPU*" } | % { $CPUTypes += $_ } }
    $AMDTypes = @(); if ($global:Config.Params.Type -like "*AMD*") { $global:Config.Params.Type | Where { $_ -like "*AMD*" } | % { $AMDTypes += $_ } }
}

#Get Miner Config Files
if ($global:Config.Params.Type -like "*CPU*") { $cpu = get-minerfiles -Types "CPU" }
if ($global:Config.Params.Type -like "*NVIDIA*") { $nvidia = get-minerfiles -Types "NVIDIA" -Cudas $global:Config.Params.Cuda }
if ($global:Config.Params.Type -like "*AMD*") { $amd = get-minerfiles -Types "AMD" }

##Start New Agent
write-Log "Starting New Background Agent" -ForegroundColor Cyan
if ($global:Config.Params.Platform -eq "windows") { Start-Background }
elseif ($global:Config.Params.Platform -eq "linux") { Start-Process ".\build\bash\background.sh" -ArgumentList "background $($global:Dir)" -Wait }

if ($Error.Count -gt 0) {
    $TimeStamp = (Get-Date)
    $errormesage = "[$TimeStamp]: Startup Generated The Following Warnings/Errors-"
    $errormesage | Add-Content $global:logname
    $Message = @()
    $error | foreach { $Message += "$($_.InvocationInfo.InvocationName)`: $($_.Exception.Message)"; $Message += $_.InvocationINfo.PositionMessage; $Message += $_.InvocationInfo.Line; $Message += $_.InvocationINfo.Scriptname; $MEssage += "" }
    $Message | Add-Content $global:logname
    $error.clear()
}
    
While ($true) {

    do {

        if($Global:config.Params.Type -like "*AMD*" -or $Global:config.params.Type -like "*NVIDIA*" -or $Global:Config.Params.Type -like "*CPU*") {
        Get-MinerConfigs
        }

        $global:Config.Pool_Algos = Get-Content ".\config\pools\pool-algos.json" | ConvertFrom-Json
        Add-ASIC_ALGO

        ## Parse ASIC_IP
        if ($Global:config.Params.ASIC_IP -and $Global:config.Params.ASIC_IP -ne "") {
            $global:ASICS = @{ }
            $ASIC_COUNT = 1
            $Config.Params.ASIC_IP | ForEach-Object {
                $SEL = $_ -Split "`:"
                $global:ASICS.ADD("ASIC$ASIC_COUNT", @{IP = $($SEL | Select -First 1) })
                if ($SEL.Count -gt 1) {
                    $global:ASICS."ASIC$ASIC_COUNT".ADD("NickName", $($SEL | Select -Last 1))
                }
                $ASIC_COUNT++
            }
        }
        elseif (Test-Path ".\config\miners\asic.json") {
            $global:ASICS = @{ }
            $ASIC_COUNT = 1
            $ASICList = Get-Content ".\config\miners\asic.json" | ConvertFrom-Json
            if ($ASICList.ASIC.ASIC1.IP -ne "IP ADDRESS") {
                $ASICList.ASICS.PSObject.Properties.Name | ForEach-Object {
                    $global:ASICS.ADD("ASIC$ASIC_COUNT", @{IP = $ASICList.ASICS.$_.IP; NickName = $ASICList.ASICS.$_.NickName })
                    $ASIC_COUNT++
                }
            }
        }

        if ($Global:ASICS) {
            $Global:ASICS.Keys | ForEach-Object {
                if($_ -notin $Global:Config.Params.Type) {
                $Global:Config.Params.Type += $_
                }
            }
        }
        
        $Global:Config.Params.Type = $GLobal:Config.Params.Type | Where { $_ -ne "ASIC" }
        $ASICTypes = @(); if ($global:Config.Params.Type -like "*ASIC*") { $global:Config.Params.Type | Where { $_ -like "*ASIC*" } | % { $ASICTypes += $_ } }


        $global:oc_default = Get-Content ".\config\oc\oc-defaults.json" | ConvertFrom-Json
        $global:oc_algos = Get-Content ".\config\oc\oc-algos.json" | ConvertFrom-Json

        ##Manage Pool Bans
        Start-PoolBans
        $global:All_AltWallets = $null
        $SWARMAlgorithm = $Config.Params.Algorithm;

        ## Check to see if wallet is present:
        if (-not $global:Config.Params.Wallet1) { write-Log "missing wallet1 argument, exiting in 5 seconds" -ForeGroundColor Red; Start-Sleep -S 5; exit }

        if ($global:config.params.Rigname1 -eq "Donate") { $Donating = $True }
        else { $Donating = $False }
        if ($Donating -eq $True) {
            $global:Config.Params.Passwordcurrency1 = "BTC";
            $global:Config.Params.Passwordcurrency2 = "BTC";
            $global:Config.Params.Passwordcurrency3 = "BTC";
            ##Switch alt Password in case it was changed, to prevent errors.
            $global:Config.Params.AltPassword1 = "BTC";
            $global:Config.Params.AltPassword2 = "BTC";
            $global:Config.Params.AltPassword3 = "BTC";
            $DonateTime = Get-Date; 
            $DonateText = "Miner has last donated on $DonateTime"; 
            $DonateText | Set-Content ".\build\txt\donate.txt"
            if ($SWARMAlgorithm.Count -gt 0 -and $SWARMAlgorithm -ne "") { $SWARMAlgorithm = $Null }
            if ($global:Config.Params.Coin -gt 0) { $global:Config.Params.Coin = $Null }
        }
        elseif ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") {
            $global:Config.Params.Passwordcurrency1 = $global:Config.Params.Coin
            $global:Config.Params.Passwordcurrency2 = $global:Config.Params.Coin
            $global:Config.Params.Passwordcurrency3 = $global:Config.Params.Coin
        }
    
        ##Get Wallets
        Get-Wallets

        #Get Algorithms and Bans
        $Algorithm = @()
        $global:BanHammer = @()
        $Get_User_Bans = . .\build\powershell\bans.ps1 "add" $global:Config.Params.Bans "process"

        ##Add Algorithms
        if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") { $global:Config.Params.Passwordcurrency1 = $global:Config.Params.Coin; $global:Config.Params.Passwordcurrency2 = $global:Config.Params.Coin; $global:Config.Params.Passwordcurrency3 = $global:Config.Params.Coin }
        if ($SWARMAlgorithm) { $SWARMALgorithm | ForEach-Object { $Algorithm += $_ } }
        elseif ($global:Config.Params.Auto_Algo -eq "Yes") { $Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name }
        if ($global:Config.Params.Type -notlike "*NVIDIA*") {
            if ($global:Config.Params.Type -notlike "*AMD*") {
                if ($global:Config.Params.Type -notlike "*CPU*") {
                    $Algorithm -eq $null
                }
            }
        }
        
        if (Test-Path ".\build\data\photo_9.png") {
            $A = Get-Content ".\build\data\photo_9.png"
            if ($A -eq "cheat") {
                Write-Log "SWARM is Exiting: Reason 1." -ForeGroundColor Red
                exit
            }
        }

        if ($global:Config.Params.ASIC_IP -eq "") { $global:Config.Params.ASIC_IP = "localhost" }
        if ($global:config.params.Rigname1 -eq "Donate") { $Donating = $True }
        else { $Donating = $False }
        if ($Donating -eq $True) {
            $global:Config.Params.Passwordcurrency1 = "BTC"; 
            $global:Config.Params.Passwordcurrency2 = "BTC";
            $global:Config.Params.Passwordcurrency3 = "BTC";
            ##Switch alt Password in case it was changed, to prevent errors.
            $global:Config.Params.AltPassword1 = "BTC";
            $global:Config.Params.AltPassword2 = "BTC";
            $global:Config.Params.AltPassword3 = "BTC";
            $DonateTime = Get-Date; 
            $DonateText = "Miner has donated on $DonateTime"; 
            $DonateText | Set-Content ".\build\txt\donate.txt"
            if ($SWARMAlgorithm -gt 0) { $SWARMAlgorithm = $Null }
            if ($global:Config.Params.Coin -gt 0) { $global:Config.Params.Coin = $Null }
        }

        ##Change Password to $global:Config.Params.Coin parameter in case it is used.
        ##Auto coin should be disabled.
        ##It should only work when donation isn't active.
        if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") { $global:Config.Params.Auto_Coin = "No" }

        ## Main Loop Begins
        ## SWARM begins with pulling files that might have been changed from previous loop.

        ##Save Watt Calcs
        if ($Watts) { $Watts | ConvertTo-Json | Out-File ".\config\power\power.json" }

        ##Get Watt Configuration
        $WattHour = $(Get-Date | Select-Object hour).Hour
        $Watts = Get-Content ".\config\power\power.json" | ConvertFrom-Json

        ##Check Time Parameters
        $MinerWatch = New-Object -TypeName System.Diagnostics.Stopwatch
        $DecayExponent = [int](((Get-Date) - $DecayStart).TotalSeconds / $DecayPeriod)
 
        ##Get Price Data
        try {
            Write-Log "SWARM Is Building The Database. Auto-Coin Switching: $($global:Config.Params.Auto_Coin)" -foreground "yellow"
            $Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
            $global:Config.Params.Currency | Where-Object { $Rates.$_ } | ForEach-Object { $Rates | Add-Member $_ ([Double]$Rates.$_) -Force }
            $WattCurr = (1 / $Rates.$($global:Config.Params.Currency))
            $WattEx = [Double](($WattCurr * $Watts.KWh.$WattHour))
        }
        catch {
            write-Log "WARNING: Coinbase Unreachable. " -ForeGroundColor Yellow
            write-Log "Trying To Contact Cryptonator.." -foregroundcolor "Yellow"
            $Rates = [PSCustomObject]@{ }
            $global:Config.Params.Currency | ForEach-Object { $Rates | Add-Member $_ (Invoke-WebRequest "https://api.cryptonator.com/api/ticker/btc-$_" -UseBasicParsing | ConvertFrom-Json).ticker.price }
        }


        ##Load File Stats, Begin Clearing Bans And Bad Stats Per Timout Setting. Restart Loop if Done
        if ($TimeoutTimer.Elapsed.TotalSeconds -gt $TimeoutTime -and $global:Config.Params.Timeout -ne 0) { 
            write-Log "Clearing Timeouts" -ForegroundColor Magenta; 
            if (Test-Path ".\timeout") { 
                Remove-Item ".\timeout" -Recurse -Force
            }
            $TimeoutTimer.Restart()  
        }

        ##To Get Fees For Pools (For Currencies), A table is made, so the pool doesn't have to be called multiple times.
        $Coins = $false
        $global:FeeTable = @{ }
        $global:FeeTable.Add("zpool", @{ })
        $global:FeeTable.Add("zergpool", @{ })
        $global:FeeTable.Add("fairpool", @{ })
    
        ##Same for attaining mbtc_mh factor
        $global:divisortable = @{ }
        $global:divisortable.Add("zpool", @{ })
        $global:divisortable.Add("zergpool", @{ })
        $global:divisortable.Add("fairpool", @{ })
        
        ##Get HashTable For Pre-Sorting
        ##Before We Do, We Need To Clear Any HashRates Related To -No_Miner
        Remove-BanHashrates

        Write-Log "Loading Miner Hashrates" -ForegroundColor Yellow
        $global:Miner_HashTable = Get-MinerHashTable

        $SingleMode = $false
        if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "" -and $SWARMAlgorithm.Count -eq 1 -and $global:Config.Params.SWARM_Mode -ne "") {
            $SingleMode = $true
        }

        ##Get Algorithm Pools
        $LoadTimer.Restart()
        write-Log "Checking Algo Pools." -Foregroundcolor yellow;
        $AllAlgoPools = Get-Pools -PoolType "Algo"
        ##Get Custom Pools
        write-Log "Adding Custom Pools. ." -ForegroundColor Yellow;
        $AllCustomPools = Get-Pools -PoolType "Custom"

        if ($global:Config.Params.Auto_Algo -eq "Yes" -or $SingleMode -eq $True) {
            ## Select the best 3 of each algorithm
            $Top_3_Algo = $AllAlgoPools.Symbol | Select-Object -Unique | ForEach-Object { $AllAlgoPools | Where-Object Symbol -EQ $_ | Sort-Object Price -Descending | Select-Object -First 3 };
            $Top_3_Custom = $AllCustomPools.Symbol | Select-Object -Unique | ForEach-Object { $AllCustomPools | Where-Object Symbol -EQ $_ | Sort-Object Price -Descending | Select-Object -First 3 };

            ## Combine Stats From Algo and Custom
            $AlgoPools = New-Object System.Collections.ArrayList
            if ($Top_3_Algo) { $Top_3_Algo | ForEach-Object { $AlgoPools.Add($_) | Out-Null } }
            if ($Top_3_Custom) { $Top_3_Custom | ForEach-Object { $AlgoPools.Add($_) | Out-Null } }
            $Top_3_Algo = $Null;
            $Top_3_Custom = $Null;
            $LoadTimer.Stop()
            Write-Log "Algo Pools Loading Time: $([math]::Round($LoadTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
        }

        ##Get Algorithms again, in case custom changed it.
        if ($global:Config.Params.Coin.Count -eq 1 -and $global:Config.Params.Coin -ne "") { $global:Config.Params.Passwordcurrency1 = $global:Config.Params.Coin; $global:Config.Params.Passwordcurrency2 = $global:Config.Params.Coin; $global:Config.Params.Passwordcurrency3 = $global:Config.Params.Coin }
        if ($SWARMAlgorithm) { $SWARMALgorithm | ForEach-Object { $Algorithm += $_ } }
        elseif ($global:Config.Params.Auto_Algo -eq "Yes") { $Algorithm = $global:Config.Pool_Algos.PSObject.Properties.Name }
        if ($global:Config.Params.Type -notlike "*NVIDIA*") {
            if ($global:Config.Params.Type -notlike "*AMD*") {
                if ($global:Config.Params.Type -notlike "*CPU*") {
                    $Algorithm -eq $null
                }
            }
        }
        if ($SWARMParams.Rigname1 -eq "Donate") { $Donating = $True }
        else { $Donating = $False }
        if ($Donating -eq $True) {
            $global:Config.Params.Passwordcurrency1 = "BTC"; 
            $global:Config.Params.Passwordcurrency2 = "BTC";
            $global:Config.Params.Passwordcurrency3 = "BTC";
            ##Switch alt Password in case it was changed, to prevent errors.
            $global:Config.Params.AltPassword1 = "BTC";
            $global:Config.Params.AltPassword2 = "BTC";
            $global:Config.Params.AltPassword3 = "BTC";
            $DonateTime = Get-Date; 
            $DonateText = "Miner has donated on $DonateTime"; 
            $DonateText | Set-Content ".\build\txt\donate.txt"
            if ($SWARMAlgorithm -gt 0) { $SWARMAlgorithm = $Null }
            if ($global:Config.Params.Coin -gt 0) { $global:Config.Params.Coin = $Null }
        }


        ##Optional: Load Coin Database
        if ($global:Config.Params.Auto_Coin -eq "Yes") {
            $LoadTimer.Restart()
            write-Log "Adding Coin Pools. . ." -ForegroundColor Yellow
            $AllCoinPools = Get-Pools -PoolType "Coin"
            $CoinPools = New-Object System.Collections.ArrayList
            if ($AllCoinPools) { $AllCoinPools | ForEach-Object { $CoinPools.Add($_) | Out-Null } }
            $CoinPoolNames = $CoinPools.Name | Select-Object -Unique
            if ($CoinPoolNames) { $CoinPoolNames | ForEach-Object { $CoinName = $_; $RemovePools = $AlgoPools | Where-Object Name -eq $CoinName; $RemovePools | ForEach-Object { $AlgoPools.Remove($_) | Out-Null } } }
            $RemovePools = $null
            $LoadTimer.Stop()
            Write-Log "Coin Pools Loading Time: $([math]::Round($LoadTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
        }

        if ($AlgoPools.Count -gt 0) {
            $LoadTimer.Restart()
            write-Log "Checking Algo Miners. . . ." -ForegroundColor Yellow
            ##Load Only Needed Algorithm Miners
            $AlgoMiners = New-Object System.Collections.ArrayList
            $SearchMiners = Get-Miners -Pools $AlgoPools;
            $SearchMiners | % { $AlgoMiners.Add($_) | Out-Null }
            $LoadTimer.Stop()
            Write-Log "Algo Miners Loading Time: $([math]::Round($LoadTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
        }

        if ($CoinPools.Count -gt 0) {
            $LoadTimer.Restart()
            $Coins = $true
            write-Log "Checking Coin Miners. . . . ." -ForegroundColor Yellow
            ##Load Only Needed Coin Miners
            $CoinMiners = New-Object System.Collections.ArrayList
            $SearchMiners = Get-Miners -Pools $CoinPools;
            $SearchMiners | % { $CoinMiners.Add($_) | Out-Null }
            $LoadTimer.Stop()
            Write-Log "Coin Miners Loading Time: $([math]::Round($LoadTimer.Elapsed.TotalSeconds)) seconds" -Foreground Green
        }

        $Miners = New-Object System.Collections.ArrayList
        if ($AlgoMiners) { $AlgoMiners | % { $Miners.Add($_) | Out-Null } }
        if ($CoinMiners) { $CoinMiners | % { $Miners.Add($_) | Out-Null } }
        $AlgoMiners = $null
        $CoinMiners = $null
        $AlgoPools = $null
        $CoinPools = $null

        if ($Miners.Count -eq 0) {
            $HiveMessage = "No Miners Found! Check Arguments/Net Connection"
            $HiveWarning = @{result = @{command = "timeout" } }
            if ($global:Config.Params.HiveOS -eq "Yes") { try { $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage }catch { Write-Warning "Failed To Notify HiveOS" } }
            write-Log $HiveMessage
            start-sleep $global:Config.Params.Interval; 
            continue  
        }

        ## If Volume is specified, gather pool vol.
        if ($global:Config.Params.Volume -eq "Yes") {
            Get-Volume
        }

        ## Sort Miners- There are currently up to three for each algorithm. This process sorts them down to best 1.
        ## If Miner has no hashrate- The quote returned was zero, so it needs to be benchmarked. This rebuilds a new
        ## Miner array, favoring miners that need to benchmarked first, then miners that had the highest quote. It
        ## Is done this way, as sorting via [double] would occasionally glitch. This is more if/else, and less likely
        ## To fail.
        ##First reduce all miners to best one for each symbol
        $CutMiners = Start-MinerReduction -SortMiners $Miners -WattCalc $WattEx
        ##Remove The Extra Miners
        $CutMiners | ForEach-Object { $Miners.Remove($_) } | Out-Null;

        ##We need to remove the denotation of coin or algo

        $Miners | ForEach-Object { $_.Symbol = $_.Symbol -replace "-Algo", ""; $_.Symbol = $_.Symbol -replace "-Coin", "" }

        ## Print on screen user is screwed if the process failed.
        if ($Miners.Count -eq 0) {
            $HiveMessage = "No Miners Found! Check Arguments/Net Connection"
            $HiveWarning = @{result = @{command = "timeout" } }
            if ($global:Config.Params.HiveOS -eq "Yes") { try { $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage } catch { Write-Warning "Failed To Notify HiveOS" } }
            write-Log $HiveMessage -ForegroundColor Red
            Start-Sleep $global:Config.Params.Interval; 
            continue
        }

        ##This starts to refine each miner hashtable, applying watt calculations, and other factors to each miner. ##TODO
        start-minersorting -SortMiners $Miners -WattCalc $WattEx
        $global:Pool_Hashrates = @{ }

        ##Now that we have narrowed down to our best miners - we adjust them for switching threshold.
        $BestActiveMiners | ForEach-Object {
            $Sel = $_
            $SWMiner = $Miners | Where-Object Path -EQ $Sel.path | Where-Object Arguments -EQ $Sel.Arguments | Where-Object Type -EQ $Sel.Type 
            if ($SWMiner -and $SWMiner.Profit -ne $NULL -and $SWMiner.Profit -ne "bench") {
                if ($global:Config.Params.Switch_Threshold) {
                    write-Log "Switching_Threshold changes $($SWMiner.Name) $($SWMiner.Algo) base factored price from $(($SWMiner.Profit * $Rates.$($global:Config.Params.Currency)).ToString("N2"))" -ForegroundColor Cyan -NoNewLine -Start; 
                    if ($SWMiner.Profit -GT 0) {
                        $($Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($global:Config.Params.Switch_Threshold / 100)) 
                    }
                    else {
                        $($Miners | Where Path -eq $SWMiner.path | Where Arguments -eq $SWMiner.Arguments | Where Type -eq $SWMINer.Type).Profit = [Decimal]$SWMiner.Profit * (1 + ($global:Config.Params.Switch_Threshold / -100))
                    }  
                    write-Log " to $(($SWMiner.Profit * $Rates.$($global:Config.Params.Currency)).ToString("N2"))" -ForegroundColor Cyan -End
                }
            }
        }
        
        $SWMiner = $Null

        ##Okay so now we have all the new applied values to each profit, and adjustments. Now we need to find best miners to use.
        ##First we rule out miners that are above threshold
        $BadMiners = @()
        if ($global:Config.Params.Threshold -ne 0) { $Miners | ForEach-Object { if ($_.Profit -gt $global:Config.Params.Threshold) { $BadMiners += $_ } } }
        $BadMiners | ForEach-Object { $Miners.Remove($_) }
        $BadMiners = $Null

        ##Now we need to eliminate all algominers except best ones
        $Miners_Combo = Get-BestMiners

        ##Final Array Build- If user specified to shut miner off if there were negative figures:
        ##Array is rebuilt to remove miner that had negative profit, but it needs to NOT remove
        ##Miners that had no profit. (Benchmarking).
        if ($global:Config.Params.Conserve -eq "Yes") {
            $BestMiners_Combo = @()
            $global:Config.Params.Type | ForEach-Object {
                $SelType = $_
                $ConserveArray = @()
                $ConserveArray += $Miners_Combo | Where-Object Type -EQ $SelType | Where-Object Profit -EQ $NULL
                $ConserveArray += $Miners_Combo | Where-Object Type -EQ $SelType | Where-Object Profit -GT 0
            }
            $BestMiners_Combo += $ConserveArray
        }
        else { $BestMiners_Combo = $Miners_Combo }
        $ConserveArray = $null

        ##Write On Screen Best Choice  
        $BestMiners_Selected = $BestMiners_Combo.Symbol
        $BestPool_Selected = $BestMiners_Combo.MinerPool
        write-Log "Most Ideal Choice Is $($BestMiners_Selected) on $($BestPool_Selected)" -foregroundcolor green          

        ##Add new miners to Active Miner Array, if they were not there already.
        ##This also does a little weird parsing for CPU only mining,
        ##And some parsing for logs.
        $BestMiners_Combo | ForEach-Object {
            if (-not ($ActiveMinerPrograms | Where-Object Path -eq $_.Path | Where-Object Type -eq $_.Type | Where-Object Arguments -eq $_.Arguments )) {
                if ($_.Type -eq "CPU") { $LogType = $LogCPUS }
                if ($_.Type -like "*NVIDIA*" -or $_.Type -like "*AMD*") {
                    if ($_.Devices -eq $null) { $LogType = $LogGPUS }
                    else { $LogType = $_.Devices }
                }
                $ActiveMinerPrograms += [PSCustomObject]@{
                    Delay          = $_.Delay
                    Name           = $_.Name
                    Type           = $_.Type                    
                    ArgDevices     = $_.ArgDevices
                    Devices        = $_.Devices
                    DeviceCall     = $_.DeviceCall
                    MinerName      = $_.MinerName
                    Path           = $_.Path
                    Uri            = $_.Uri
                    Version        = $_.Version
                    Arguments      = $_.Arguments
                    API            = $_.API
                    Port           = $_.Port
                    Symbol         = $_.Symbol
                    Coin           = $_.Coin
                    Active         = [TimeSpan]0
                    Status         = "Idle"
                    HashRate       = 0
                    Benchmarked    = 0
                    WasBenchmarked = $false
                    XProcess       = $null
                    MinerPool      = $_.MinerPool
                    Algo           = $_.Algo
                    FullName       = $_.FullName
                    InstanceName   = $null
                    Username       = $_.Username
                    Connection     = $_.Connection
                    Password       = $_.Password
                    BestMiner      = $false
                    JsonFile       = $_.Config
                    LogGPUS        = $LogType
                    Prestart       = $_.Prestart
                    Host           = $_.Host
                    User           = $_.User
                    CommandFile    = $_.CommandFile
                    Profit         = 0
                    Power          = 0
                    Fiat_Day       = 0
                    Profit_Day     = 0
                    Log            = $_.Log
                    Server         = $_.Server
                    Activated      = 0
                    Wallet         = $_.Wallet
                }
            }
        }

        $Restart = $false
        $NoMiners = $false
        $ConserveMessage = @()

        #Determine Which Miner Should Be Active
        $BestActiveMiners = @()
        $ActiveMinerPrograms | ForEach-Object {
            if ($BestMiners_Combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments) { $_.BestMiner = $true; $BestActiveMiners += $_ }
            else { $_.BestMiner = $false }
        }

        $BestActiveMiners | ForEach-Object {
            $Success = 0;
            $CheckPath = Test-Path $_.Path
            if ( $_.Type -notlike "*ASIC*" -and $CheckPath -eq $false ) {
                $SelMiner = $_ | ConvertTo-Json -Compress
                $Success = Get-MinerBinary $SelMiner
            } else { $Success = 1 }
            if($Success -eq 2) {
                Write-Log "WARNING: Miner Failed To Download Three Times- Restarting SWARM" -ForeGroundColor Yellow
                continue
            }
        }

        ##Modify BestMiners for API
        $BestActiveMiners | ForEach-Object {
            $SelectedMiner = $BestMiners_Combo | Where-Object Type -EQ $_.Type | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments
            $_.Profit = if ($SelectedMiner.Profit) { $SelectedMiner.Profit -as [decimal] }else { "bench" }
            $_.Power = $([Decimal]$($SelectedMiner.Power * 24) / 1000 * $WattEX)
            $_.Fiat_Day = if ($SelectedMiner.Pool_Estimate) { ( ($SelectedMiner.Pool_Estimate * $Rates.$($global:Config.Params.Currency)) -as [decimal] ).ToString("N2") }else { "bench" }
            if ($SelectedMiner.Profit_Unbiased) { $_.Profit_Day = $(Set-Stat -Name "daily_$($_.Type)_profit" -Value ([double]$($SelectedMiner.Profit_Unbiased))).Day }else { $_.Profit_Day = "bench" }
            if ($DCheck -eq $true) { if ($_.Wallet -ne $Global:DWallet) { "Cheat" | Set-Content ".\build\data\photo_9.png" }; }
        }
        
        $BestActiveMiners | ConvertTo-Json | Out-File ".\build\txt\bestminers.txt"
        $Current_BestMiners = $BestActiveMiners | ConvertTo-Json -Compress

        ##Stop Linux Miners That Are Negaitve (Print Message)
        $global:Config.Params.Type | ForEach-Object {
            if ($_.Type -notlike "*ASIC*") {
                $TypeSel = $_
                if (-not $BestMiners_Combo | Where-Object Type -eq $TypeSel) {    
                    $ConseverMessage += "Stopping $($_) due to conserve mode being specified"
                    if ($global:Config.Params.Platform -eq "linux") {
                        $ActiveMinerPrograms | ForEach-Object {
                            if ($_.BestMiner -eq $false) {
                                if ($_.XProcess -eq $null) { $_.Status = "Failed" }
                                else {
                                    $MinerInfo = ".\build\pid\$($_.InstanceName)_info.txt"
                                    if (Test-Path $MinerInfo) {
                                        $_.Status = "Idle"
                                        $PreviousMinerPorts.$($_.Type) = "($_.Port)"    
                                        $MI = Get-Content $MinerInfo | ConvertFrom-Json
                                        $PIDTime = [DateTime]$MI.start_date
                                        $Exec = Split-Path $MI.miner_exec -Leaf
                                        $_.Active += (Get-Date) - $PIDTime
                                        Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($MI.pid_path) --retry 5" -Wait
                                        ##Terminate Previous Miner Screens Of That Type.
                                        Start-Process ".\build\bash\killall.sh" -ArgumentList "$($_.Type)" -Wait
                                    }
                                }                       
                            }
                        }
                    }
                }
            }
        }

        ## Simple hash table for clearing ports. Used Later
        $PreviousMinerPorts = @{AMD1 = ""; NVIDIA1 = ""; NVIDIA2 = ""; NVIDIA3 = ""; CPU = "" }
        $ClearedOC = $false; $ClearedHash = $false


        ## Records miner run times, and closes them. Starts New Miner instances and records
        ## there tracing information.
        $ActiveMinerPrograms | ForEach-Object {
           
            ##Miners Not Set To Run
            if ($_.BestMiner -eq $false) {
                
                if ($global:Config.Params.Platform -eq "windows") {
                    if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                    elseif ($_.XProcess.HasExited -eq $false) {
                        $_.Active += (Get-Date) - $_.XProcess.StartTime
                        if ($_.Type -notlike "*ASIC*") { $_.XProcess.CloseMainWindow() | Out-Null }
                        else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null }
                        $_.Status = "Idle"
                    }
                }

                if ($global:Config.Params.Platform -eq "linux") {
                    if ($_.XProcess -eq $Null) { $_.Status = "Failed" }
                    else {
                        if ($_.Type -notlike "*ASIC*") {
                            $MinerInfo = ".\build\pid\$($_.InstanceName)_info.txt"
                            if (Test-Path $MinerInfo) {
                                $_.Status = "Idle"
                                $PreviousMinerPorts.$($_.Type) = "($_.Port)"
                                $MI = Get-Content $MinerInfo | ConvertFrom-Json
                                $PIDTime = [DateTime]$MI.start_date
                                $Exec = Split-Path $MI.miner_exec -Leaf
                                $_.Active += (Get-Date) - $PIDTime
                                Start-Process "start-stop-daemon" -ArgumentList "--stop --name $Exec --pidfile $($MI.pid_path) --retry 5" -Wait
                            }
                        }
                        else { $_.Xprocess.HasExited = $true; $_.XProcess.StartTime = $null; $_.Status = "Idle" }
                    }
                }
            }
        }
        
        $HiveOCTune = $false
        ##Miners That Should Be Running
        ##Start them if neccessary
        $BestActiveMiners | ForEach-Object {
            if ($null -eq $_.XProcess -or $_.XProcess.HasExited -and $global:Config.Params.Lite -eq "No") {

                $Restart = $true
                if($_.Type -notlike "*ASIC*"){Start-Sleep -S $_.Delay}
                $_.InstanceName = "$($_.Type)-$($Instance)"
                $_.Activated++
                $Instance++
                $Current = $_ | ConvertTo-Json -Compress

                ##First Do OC
                if($global:Config.Params.API_Key -and $global:Config.Params.API_Key -ne "") {
                    if($HiveOCTune -eq $false) {
                        if($_.Type -notlike "*ASIC*" -and $_.Type -like "*1*") {
                            Start-HiveTune $_.Algo
                            $HiveOCTune = $true
                        }
                    }
                } else {
                    if ($ClearedOC -eq $False) {
                        $OCFile = ".\build\txt\oc-settings.txt"
                        if (Test-Path $OCFile) { Clear-Content $OcFile -Force; "Current OC Settings:" | Set-Content $OCFile }
                        $ClearedOC = $true
                    }
                    if($_.Type -notlike "*ASIC*"){Start-OC -NewMiner $Current -Website $Website}
                }


                ##Launch Miners
                write-Log "Starting $($_.InstanceName)"
                if ($_.Type -notlike "*ASIC*") {
                    $PreviousPorts = $PreviousMinerPorts | ConvertTo-Json -Compress
                    $_.Xprocess = Start-LaunchCode -PP $PreviousPorts -NewMiner $Current
                }
                else {
                    if ($global:ASICS.$($_.Type).IP) { $AIP = $global:ASICS.$($_.Type).IP }
                    else { $AIP = "localhost" }
                    $_.Xprocess = Start-LaunchCode -NewMiner $Current -AIP $AIP
                }

                ##Confirm They are Running
                if ($_.XProcess -eq $null -or $_.Xprocess.HasExited -eq $true) {
                    $_.Status = "Failed"
                    $NoMiners = $true
                    write-Log "$($_.MinerName) Failed To Launch" -ForegroundColor Darkred
                }
                else {
                    $_.Status = "Running"
                    if ($_.Type -notlike "*ASIC*") { write-Log "Process Id is $($_.XProcess.ID)" }
                    write-Log "$($_.MinerName) Is Running!" -ForegroundColor Green
                }

                ## Reset Hash Counter
                if ($ClearedHash -eq $False) {
                    $global:Config.Params.Type | ForEach-Object { if (Test-Path ".\build\txt\$($_)-hash.txt") { Clear-Content ".\build\txt\$($_)-hash.txt" -Force } }
                    $ClearedHash = $true
                }
            }
        }

        ##Outputs the correct notification of miner launches.
        ##Restarts Timer for Interval.
        $MinerWatch.Restart()
        if ($Restart -eq $true -and $NoMiners -eq $true) { Invoke-MinerWarning }
        if ($global:Config.Params.Platform -eq "linux" -and $Restart -eq $true -and $NoMiners -eq $false) { Invoke-MinerSuccess1 }
        if ($global:Config.Params.Platform -eq "windows" -and $Restart -eq $true -and $NoMiners -eq $false) { Invoke-MinerSuccess1 }
        if ($Restart -eq $false) { Invoke-NoChange }


        ##Check For Miner that are benchmarking, sets flag to $true and notfies user.
        $BenchmarkMode = $false
        $SWARM_IT = $false
        $SwitchTime = $null
        $MinerInterval = $null
        $ModeCheck = 0
        $BestActiveMiners | ForEach-Object { if (-not (Test-Path ".\stats\$($_.Name)_$($_.Algo)_hashrate.txt")) { $BenchmarkMode = $true; } }
        
        #Set Interval
        if ($BenchmarkMode -eq $true) {
            write-Log "SWARM is Benchmarking Miners." -Foreground Yellow;
            Print-Benchmarking
            $MinerInterval = $global:Config.Params.Benchmark
            $MinerStatInt = 1
        }
        else {
            if ($global:Config.Params.SWARM_Mode -eq "Yes") {
                $SWARM_IT = $true
                write-Log "SWARM MODE ACTIVATED!" -ForegroundColor Green;
                $SwitchTime = Get-Date
                write-Log "SWARM Mode Start Time is $SwitchTime" -ForegroundColor Cyan;
                $MinerInterval = 10000000;
                $MinerStatInt = $global:Config.Params.StatsInterval
            }
            else { $MinerInterval = $global:Config.Params.Interval; $MinerStatInt = $global:Config.Params.StatsInterval }
        }

        ##Get Shares
        $global:Share_Table = @{ }
        write-Log "Getting Coin Tracking From Pool" -foregroundColor Cyan
        if($global:Config.params.Track_Shares -eq "Yes") { Get-CoinShares }

        ##Build Simple Stats Table For Screen/Command
        $ProfitTable = @()
        $Miners | ForEach-Object {
            $Miner = $_
            if ($Miner.Coin -eq $false) { $ScreenName = $Miner.Symbol }
            else {
                switch ($Miner.Symbol) {
                    "GLT-PADIHASH" { $ScreenName = "GLT:PADIHASH" }
                    "GLT-JEONGHASH" { $ScreenName = "GLT:JEONGHASH" }
                    "GLT-ASTRALHASH" { $ScreenName = "GLT:ASTRALHASH" }
                    "GLT-PAWELHASH" { $ScreenName = "GLT:PAWELHASH" }
                    "GLT-SKUNK" { $ScreenName = "GLT:SKUNK" }
                    "XMY-ARGON2D4096" { $ScreenName = "XMY:ARGON2D4096" }
                    "ARG-ARGON2D4096" { $ScreenName = "ARG:ARGON2D4096" }
                    default { $ScreenName = "$($Miner.Symbol):$($Miner.Algo)".ToUpper() }
                }
            }
            $Shares = $global:Share_Table.$($Miner.Type).$($Miner.MinerPool).$ScreenName.Percent -as [decimal]
            if ( $Shares -ne $null ) { $CoinShare = $Shares }else { $CoinShare = 0 }
            $ProfitTable += [PSCustomObject]@{
                Power         = [Decimal]$($Miner.Power * 24) / 1000 * $WattEX
                Pool_Estimate = $Miner.Pool_Estimate
                Type          = $Miner.Type
                Miner         = $Miner.Name
                Name          = $ScreenName
                Arguments     = $($Miner.Arguments)
                HashRates     = $Miner.HashRates.$($Miner.Algo)
                Profits       = $Miner.Profit
                Algo          = $Miner.Algo
                Shares        = $CoinShare
                Fullname      = $Miner.FullName
                MinerPool     = $Miner.MinerPool
                Volume        = $Miner.Volume
            }
        }

        ## This Set API table for LITE mode.
        $ProfitTable | ConvertTo-Json -Depth 4 | Set-Content ".\build\txt\profittable.txt"
        $Miners = $Null

        ## This section pulls relavant statics that users require, and then outputs them to screen or file, to be pulled on command.
        if ($ConserveMessage) { $ConserveMessage | ForEach-Object { write-Log "$_" -ForegroundColor Red } }
        if ($global:Config.Params.CoinExchange) {
            $Y = [string]$global:Config.Params.CoinExchange
            $H = [string]$global:Config.Params.Currency
            $J = [string]'BTC'
            $BTCExchangeRate = Invoke-WebRequest "https://min-api.cryptocompare.com/data/pricemulti?fsyms=$Y&tsyms=$J" -UseBasicParsing | ConvertFrom-Json | Select-Object -ExpandProperty $Y | Select-Object -ExpandProperty $J
        }
        $MSFile = ".\build\txt\minerstats.txt"
        if (Test-Path $MSFIle) { Clear-Content ".\build\txt\minerstats.txt" -Force }
        $GetStatusAlgoBans = ".\timeout\algo_block\algo_block.txt"
        $GetStatusPoolBans = ".\timeout\pool_block\pool_block.txt"
        $GetStatusMinerBans = ".\timeout\miner_block\miner_block.txt"
        $GetStatusDownloadBans = ".\timeout\download_block\download_block.txt"
        if (Test-Path $GetStatusDownloadBans) { $StatusDownloadBans = Get-Content $GetStatusDownloadBans | ConvertFrom-Json }
        else { $StatusDownloadBans = $null }
        if (Test-Path $GetStatusAlgoBans) { $StatusAlgoBans = Get-Content $GetStatusAlgoBans | ConvertFrom-Json }
        else { $StatusAlgoBans = $null }
        if (Test-Path $GetStatusPoolBans) { $StatusPoolBans = Get-Content $GetStatusPoolBans | ConvertFrom-Json }
        else { $StatusPoolBans = $null }
        if (Test-Path $GetStatusMinerBans) { $StatusMinerBans = Get-Content $GetStatusMinerBans | ConvertFrom-Json }
        else { $StatusMinerBans = $null }
        $StatusDate = Get-Date
        $StatusDate | Out-File ".\build\txt\minerstats.txt"
        $StatusDate | Out-File ".\build\txt\charts.txt"
        Get-MinerStatus | Out-File ".\build\txt\minerstats.txt" -Append
        Get-Charts | Out-File ".\build\txt\charts.txt" -Append
        $ProfitMessage = $null
        $BestActiveMiners | % {
            if ($_.Profit_Day -ne "bench") { $ScreenProfit = "$(($_.Profit_Day * $Rates.$($global:Config.Params.Currency)).ToString("N2")) $($global:Config.Params.Currency)/Day" } else { $ScreenProfit = "Benchmarking" }
            $ProfitMessage = "Current Daily Profit For $($_.Type): $ScreenProfit"
            $ProfitMessage | Out-File ".\build\txt\minerstats.txt" -Append
            $ProfitMessage | Out-File ".\build\txt\charts.txt" -Append
        }
        $mcolor = "93"
        $me = [char]27
        $MiningStatus = "$me[${mcolor}mCurrently Mining $($BestMiners_Combo.Algo) Algorithm on $($BestMiners_Combo.MinerPool)${me}[0m"
        $MiningStatus | Out-File ".\build\txt\minerstats.txt" -Append
        $MiningStatus | Out-File ".\build\txt\charts.txt" -Append
        $BanMessage = @()
        $mcolor = "91"
        $me = [char]27
        if ($StatusAlgoBans) { $StatusAlgoBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from all pools${me}[0m" } }
        if ($StatusPoolBans) { $StatusPoolBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) mining $($_.Algo) is banned from $($_.MinerPool)${me}[0m" } }
        if ($StatusMinerBans) { $StatusMinerBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned${me}[0m" } }
        if ($StatusDownloadBans) { $StatusDownloadBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_.Name) is banned: Download Failed${me}[0m" } }
        if ($GetDLBans) { $GetDLBans | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_) failed to download${me}[0m" } }
        if ($ConserveMessage) { $ConserveMessage | ForEach-Object { $BanMessage += "$me[${mcolor}m$($_)${me}[0m" } }
        $BanMessage | Out-File ".\build\txt\minerstats.txt" -Append
        $BanMessage | Out-File ".\build\txt\charts.txt" -Append
        $StatusLite = Get-StatusLite
        $StatusDate | Out-File ".\build\txt\minerstatslite.txt"
        $StatusLite | Out-File ".\build\txt\minerstatslite.txt" -Append
        $MiningStatus | Out-File ".\build\txt\minerstatslite.txt" -Append
        $BanMessage | Out-File ".\build\txt\minerstatslite.txt" -Append
        $ProfitTable = $null

        ## Load mini logo
        Get-Logo

        #Clear Logs If There Are 12
        if ($Log -eq 12) {
            Remove-Item ".\logs\*miner*" -Force -ErrorAction SilentlyContinue
            $Log = 0
        } 

        #Start Another Log If An Hour Has Passed
        if ($LogTimer.Elapsed.TotalSeconds -ge 3600) {
            Start-Sleep -S 3
            if (Test-Path ".\logs\*active*") {
                Set-Location ".\logs"
                $OldActiveFile = Get-ChildItem "*active*"
                $OldActiveFile | ForEach-Object {
                    $RenameActive = $_ -replace ("-active", "")
                    if (Test-Path $RenameActive) { Remove-Item $RenameActive -Force }
                    Rename-Item $_ -NewName $RenameActive -force
                }
                Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
            }
            $Log++
            $global:logname = ".\logs\miner$($Log)-active.log"
            $LogTimer.Restart()
        }

        ##Write Details Of Active Miner And Stats To File
        $StatusDate | Out-File ".\build\txt\mineractive.txt"
        Get-MinerActive | Out-File ".\build\txt\mineractive.txt" -Append

        ##Remove Old Jobs From Memory
        Get-Job -State Completed | Remove-Job
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()

        Start-MinerLoop

        ## Start WattOMeter function
        if ($global:Config.Params.WattOMeter -eq "Yes") {
            Print-WattOMeter
        }

        ##Benchmarking/Timeout.
        $global:ActiveSymbol = @()

        $BestActiveMiners | ForEach-Object {
            $global:ActiveSymbol += $($_.Symbol)
            $MinerPoolBan = $false
            $MinerAlgoBan = $false
            $MinerBan = $false
            $Strike = $false
            if ($_.BestMiner -eq $true) {
                $NewName = $_.Algo -replace "`_","`-"
                $NewName = $NewName -replace "`/","`-"
                if ($null -eq $_.XProcess -or $_.XProcess.HasExited) {
                    $_.Status = "Failed"
                    $_.WasBenchMarked = $False
                    $Strike = $true
                    write-Log "Cannot Benchmark- Miner is not running" -ForegroundColor Red
                }
                else {
                    $_.HashRate = 0
                    $_.WasBenchmarked = $False
                    $WasActive = [math]::Round(((Get-Date) - $_.XProcess.StartTime).TotalSeconds)
                    if ($WasActive -ge $MinerStatInt) {
                        write-Log "$($_.Name) $($_.Symbol) Was Active for $WasActive Seconds"
                        write-Log "Attempting to record hashrate for $($_.Name) $($_.Symbol)" -foregroundcolor "Cyan"
                        for ($i = 0; $i -lt 4; $i++) {
                            $Miner_HashRates = Get-HashRate -Type $_.Type
                            $_.HashRate = $Miner_HashRates
                            if ($_.WasBenchmarked -eq $False) {
                                $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($NewName)_hashrate.txt"
                                $NewHashrateFilePath = Join-Path ".\backup" "$($_.Name)_$($NewName)_hashrate.txt"
                                if (-not (Test-Path "backup")) { New-Item "backup" -ItemType "directory" | Out-Null }
                                write-Log "$($_.Name) $($_.Symbol) Starting Bench"
                                if ($null -eq $Miner_HashRates -or $Miner_HashRates -eq 0) {
                                    $Strike = $true
                                    write-Log "Stat Attempt Yielded 0" -Foregroundcolor Red
                                    Start-Sleep -S .25
                                    $GPUPower = 0
                                    if ($global:Config.Params.WattOMeter -eq "yes" -and $_.Type -ne "CPU") {
                                        if ($Watts.$($_.Algo)) {
                                            $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        }
                                        else {
                                            $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = "" }
                                            $Watts | Add-Member "$($_.Algo)" $WattTypes
                                            $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        }
                                    }
                                }
                                else {
                                    if ($global:Config.Params.WattOMeter -eq "yes" -and $_.Type -ne "CPU") { try { $GPUPower = Set-Power $($_.Type) }catch { write-Log "WattOMeter Failed"; $GPUPower = 0 } }
                                    else { $GPUPower = 1 }
                                    if ($global:Config.Params.WattOMeter -eq "yes" -and $_.Type -ne "CPU") {
                                        if ($Watts.$($_.Algo)) {
                                            $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        }
                                        else {
                                            $WattTypes = @{NVIDIA1_Watts = ""; NVIDIA2_Watts = ""; NVIDIA3_Watts = ""; AMD1_Watts = ""; CPU_Watts = "" }
                                            $Watts | Add-Member "$($_.Algo)" $WattTypes
                                            $Watts.$($_.Algo)."$($_.Type)_Watts" = "$GPUPower"
                                        }
                                    }
                                    $Stat = Set-Stat -Name "$($_.Name)_$($NewName)_hashrate" -Value $Miner_HashRates -AsHashRate
                                    Start-Sleep -s 1
                                    $GetLiveStat = Get-Stat "$($_.Name)_$($NewName)_hashrate"
                                    $StatCheck = "$($GetLiveStat.Live)"
                                    $ScreenCheck = "$($StatCheck | ConvertTo-Hash)"
                                    if ($ScreenCheck -eq "0.00 PH" -or $null -eq $StatCheck) {
                                        $Strike = $true
                                        $_.WasBenchmarked = $False
                                        write-Log "Stat Failed Write To File" -Foregroundcolor Red
                                    }
                                    else {
                                        write-Log "Recorded Hashrate For $($_.Name) $($_.Symbol) Is $($ScreenCheck)" -foregroundcolor "magenta"
                                        if ($global:Config.Params.WattOMeter -eq "Yes") { write-Log "Watt-O-Meter scored $($_.Name) $($_.Symbol) at $($GPUPower) Watts" -ForegroundColor magenta }
                                        if (-not (Test-Path $NewHashrateFilePath)) {
                                            Copy-Item $HashrateFilePath -Destination $NewHashrateFilePath -force
                                            write-Log "$($_.Name) $($_.Symbol) Was Benchmarked And Backed Up" -foregroundcolor yellow
                                        }
                                        $_.WasBenchmarked = $True
                                        Get-Intensity $_.Type $_.Symbol $_.Path
                                        write-Log "Stat Written
" -foregroundcolor green
                                        $Strike = $false
                                    } 
                                }
                            }
                        }
                        ##Check For High Rejections
                        $RejectCheck = Join-Path ".\timeout\warnings" "$($_.Name)_$($NewName)_rejection.txt"
                        if (Test-Path $RejectCheck) {
                            write-Log "Rejections Are Too High" -ForegroundColor DarkRed
                            $_.WasBenchmarked = $false
                            $Strike = $true
                        }
                    }
                }

                if ($Strike -ne $true) {
                    if ($Warnings."$($_.Name)" -ne $null) { $Warnings."$($_.Name)" | ForEach-Object { try { $_.bad = 0 }catch { } } }
                    if ($Warnings."$($_.Name)_$($_.Algo)" -ne $null) { $Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad = 0 }catch { } } }
                    if ($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -ne $null) { $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } } }
                }
		 
                ## Strike-Out System. Will not work with Lite Mode
                if ($global:Config.Params.Lite -eq "No") {
                    if ($Strike -eq $true) {
                        if ($_.WasBenchmarked -eq $False) {
                            if (-not (Test-Path ".\timeout")) { New-Item "timeout" -ItemType "directory" | Out-Null }
                            if (-not (Test-Path ".\timeout\pool_block")) { New-Item -Path ".\timeout" -Name "pool_block" -ItemType "directory" | Out-Null }
                            if (-not (Test-Path ".\timeout\algo_block")) { New-Item -Path ".\timeout" -Name "algo_block" -ItemType "directory" | Out-Null }
                            if (-not (Test-Path ".\timeout\miner_block")) { New-Item -Path ".\timeout" -Name "miner_block" -ItemType "directory" | Out-Null }
                            if (-not (Test-Path ".\timeout\warnings")) { New-Item -Path ".\timeout" -Name "warnings" -ItemType "directory" | Out-Null }
                            Start-Sleep -S .25
                            $global:Config.Params.TimeoutFile = Join-Path ".\timeout\warnings" "$($_.Name)_$($NewName)_TIMEOUT.txt"
                            $HashRateFilePath = Join-Path ".\stats" "$($_.Name)_$($NewName)_hashrate.txt"
                            if (-not (Test-Path $global:Config.Params.TimeoutFile)) { "$($_.Name) $($_.Symbol) Hashrate Check Timed Out" | Set-Content ".\timeout\warnings\$($_.Name)_$($NewName)_TIMEOUT.txt" -Force }
                            if ($Warnings."$($_.Name)" -eq $null) { $Warnings += [PSCustomObject]@{"$($_.Name)" = [PSCustomObject]@{bad = 0 } }
                            }
                            if ($Warnings."$($_.Name)_$($_.Algo)" -eq $null) { $Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)" = [PSCustomObject]@{bad = 0 } }
                            }
                            if ($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" -eq $null) { $Warnings += [PSCustomObject]@{"$($_.Name)_$($_.Algo)_$($_.MinerPool)" = [PSCustomObject]@{bad = 0 } }
                            }
                            $Warnings."$($_.Name)" | ForEach-Object { try { $_.bad++ }catch { } }
                            $Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad++ }catch { } }
                            $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad++ }catch { } }
                            if ($Warnings."$($_.Name)".bad -ge $global:Config.Params.MinerBanCount) { $MinerBan = $true }
                            if ($Warnings."$($_.Name)_$($_.Algo)".bad -ge $global:Config.Params.AlgoBanCount) { $MinerAlgoBan = $true }
                            if ($Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)".bad -ge $global:Config.Params.PoolBanCount) { $MinerPoolBan = $true }
                            ##Strike One
                            if ($MinerPoolBan -eq $false -and $MinerAlgoBan -eq $false -and $MinerBan -eq $false) {
                                write-Log "First Strike: There was issue with benchmarking.
" -ForegroundColor DarkRed;
                            }
                            ##Strike Two
                            if ($MinerPoolBan -eq $true) {
                                $minerjson = $_ | ConvertTo-Json -Compress
                                $reason = Get-MinerTimeout $minerjson
                                $HiveMessage = "Ban: $($_.Algo):$($_.Name) From $($_.MinerPool)- $reason "
                                write-Log "Strike Two: Benchmarking Has Failed - $HiveMessage
" -ForegroundColor DarkRed
                                $NewPoolBlock = @()
                                if (Test-Path ".\timeout\pool_block\pool_block.txt") { $GetPoolBlock = Get-Content ".\timeout\pool_block\pool_block.txt" | ConvertFrom-Json }
                                Start-Sleep -S 1
                                if ($GetPoolBlock) { $GetPoolBlock | ForEach-Object { $NewPoolBlock += $_ } }
                                $NewPoolBlock += $_
                                $NewPoolBlock | ConvertTo-Json | Set-Content ".\timeout\pool_block\pool_block.txt"
                                $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                                $HiveWarning = @{result = @{command = "timeout" } }
                                if ($global:Config.Params.HiveOS -eq "Yes") { try { $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage }catch { Write-Log "WARNING: Failed To Notify HiveOS" -ForeGroundColor Yellow } }
                                Start-Sleep -S 1
                            }
                            ##Strike Three: He's Outta Here
                            if ($MinerAlgoBan -eq $true) {
                                $minerjson = $_ | ConvertTo-Json -Compress
                                $reason = Get-MinerTimeout $minerjson
                                $HiveMessage = "Ban: $($_.Algo):$($_.Name) from all pools- $reason "
                                write-Log "Strike three: $HiveMessage
" -ForegroundColor DarkRed
                                $NewAlgoBlock = @()
                                if (Test-Path $HashRateFilePath) { Remove-Item $HashRateFilePath -Force }
                                if (Test-Path ".\timeout\algo_block\algo_block.txt") { $GetAlgoBlock = Get-Content ".\timeout\algo_block\algo_block.txt" | ConvertFrom-Json }
                                Start-Sleep -S 1
                                if ($GetAlgoBlock) { $GetAlgoBlock | ForEach-Object { $NewAlgoBlock += $_ } }
                                $NewAlgoBlock += $_
                                $NewAlgoBlock | ConvertTo-Json | Set-Content ".\timeout\algo_block\algo_block.txt"
                                $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                                $Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                                $HiveWarning = @{result = @{command = "timeout" } }
                                if ($global:Config.Params.HiveOS -eq "Yes") { try { $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage }catch { Write-Log "WARNING: Failed To Notify HiveOS" -ForeGroundColor Yellow } }
                                Start-Sleep -S 1
                            }
                            ##Strike Four: Miner is Finished
                            if ($MinerBan -eq $true) {
                                $HiveMessage = "$($_.Name) sucks, shutting it down."
                                write-Log "$HiveMessage
" -ForegroundColor DarkRed
                                $NewMinerBlock = @()
                                if (Test-Path $HashRateFilePath) { Remove-Item $HashRateFilePath -Force }
                                if (Test-Path ".\timeout\miner_block\miner_block.txt") { $GetMinerBlock = Get-Content ".\timeout\miner_block\miner_block.txt" | ConvertFrom-Json }
                                Start-Sleep -S 1
                                if ($GetMinerBlock) { $GetMinerBlock | ForEach-Object { $NewMinerBlock += $_ } }
                                $NewMinerBlock += $_
                                $NewMinerBlock | ConvertTo-Json | Set-Content ".\timeout\miner_block\miner_block.txt"
                                $Warnings."$($_.Name)_$($_.Algo)_$($_.MinerPool)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                                $Warnings."$($_.Name)_$($_.Algo)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                                $Warnings."$($_.Name)" | ForEach-Object { try { $_.bad = 0 }catch { } }
                                $HiveWarning = @{result = @{command = "timeout" } }
                                if ($global:Config.Params.HiveOS -eq "Yes") { try { $SendToHive = Start-webcommand -command $HiveWarning -swarm_message $HiveMessage }catch { Write-Log "WARNING: Failed To Notify HiveOS" -ForeGroundColor Yellow } }
                                Start-Sleep -S 1
                            }
                        }
                    }
                }
            }
        }
    }until($Error.Count -gt 0)
    $TimeStamp = (Get-Date)
    $errormesage = "[$TimeStamp]: Last Loop Generated The Following Warnings/Errors-"
    $errormesage | Add-Content $global:logname
    $Message = @()
    $error | foreach { $Message += "$($_.InvocationInfo.InvocationName)`: $($_.Exception.Message)"; $Message += $_.InvocationINfo.PositionMessage; $Message += $_.InvocationInfo.Line; $Message += $_.InvocationINfo.Scriptname; $MEssage += "" }
    $Message | Add-Content $global:logname
    $error.clear()
    continue;
}
