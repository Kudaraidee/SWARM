$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName 
$zpool_Request = [PSCustomObject]@{ }
$zpool_Sorted = [PSCustomObject]@{ }
$zpool_UnSorted = [PSCustomObject]@{ }

if ($(arg).Ban_GLT -eq "Yes") { $NoGLT = "GLT" }

if ($(arg).xnsub -eq "Yes") { $X = "#xnsub" } 

## Skip if user didn't specify
if ($Name -in $(arg).PoolName) {
    
    try { $zpool_Request = Invoke-RestMethod "https://zpool.ca/api/currencies" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop }
    catch {
        log "SWARM contacted ($Name) for a failed API check. (Coins)"; 
        return
    }

    if (($zpool_Request | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
        log "SWARM contacted ($Name) but ($Name) the response was empty." 
        return
    }

    Switch ($(arg).Location) {
        "US" { $region = "na" }
        "EUROPE" { $region = "eu" }
        "ASIA" { $region = "sea" }
    }
   
    ## Add symbol to the list for sorting
    $zpool_Request.PSObject.Properties.Name | ForEach-Object { $zpool_Request.$_ | Add-Member "sym" $_ }

    ## Convert to universal naming schema
    $zpool_Request.PSObject.Properties.Name | ForEach-Object {
        $Algo = $zpool_Request.$_.Algo.ToLower()
        $zpool_Request.$_ | Add-Member "Original_Algo" $Algo
        $zpool_Request.$_.Algo = $global:Config.Pool_Algos.PSObject.Properties.Name | % { if ($Algo -in $global:Config.Pool_Algos.$_.alt_names) { $_ } }
    }

    ## Make an algo list, include asic algorithms not usually in SWARM
    ## Remove algos that users/SWARM have banned.
    $zpoolAlgos = @()
    $zpoolAlgos += $(vars).Algorithm
    $zpoolAlgos += $(arg).ASIC_ALGO
    $Algos = $zpoolAlgos | ForEach-Object { if ($Bad_pools.$_ -notcontains $Name) { $_ } }

    ## Convert estimate to decimal
    $zpool_Request.PSObject.Properties.Value | % { $_.Estimate = [Decimal]$_.Estimate }

    ## Automatically add Active Coins for calcs. Active Coins are coins that are currently being mined.
    $Active = $zpool_Request.PSObject.Properties.Value | Where-Object sym -in $(vars).ActiveSymbol
    if ($Active) { $Active | ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force } }

    ## Single Coin/Specic Coin mining
    if ($(arg).Coin.Count -gt 1 -and $(arg).Coin -ne "") {
        $CoinsOnly = $zpool_Request.PSObject.Properties.Value | Where-Object sym -in $(arg).Coin
        if ($CoinsOnly) { $CoinsOnly | ForEach-Object { $zpool_Sorted | Add-Member $_.sym $_ -Force } }
    } else {
        $Algos | ForEach-Object {
            $Selected = $_
            $AlgoPool_list = $zpool_Request.PSObject.Properties.Value | Where Algo -eq $Selected

            ## Only choose coins with 24 hour returns or choose all coins (since they all have historical ttf longer than 24 hr).
            if ( ($Algopool."24h_btc" | Measure-Object -Sum | select -ExpandProperty Sum -ne 0) ) {
                $BestCoins = $AlgoPool_list | Where "24h_btc" -ne 0
            } else { $BestCoins = $AlgoPool_list }

            ## Narrow the coins with pipeline (faster):
            ## Not directly banned
            ## Not a GLT coin (if -Ban_GLT is "Yes")
            ## Is specified by user (i.e. the algorithm wasn't specifically banned.)
            ## estimate isn't 0
            $Best = $BestCoins | 
                Where-Object $DoAutoCoin -eq $true |
                Where-Object Algo -eq $Selected | 
                Where-Object Algo -in $(vars).FeeTable.zpool.keys | 
                Where-Object Algo -in $(vars).divisortable.zpool.Keys |
                Where-Object { $global:Config.Pool_Algos.$($_.Algo) } |
                Where-Object { $Name -notin $global:Config.Pool_Algos.$($_.sym).exclusions } |
                Where-Object Sym -notin $(vars).BanHammer |
                Where-Object Sym -notlike "*$NoGLT*" |
                Where-Object estimate -gt 0 | 
                Sort-Object Price -Descending |
                Select -First 1

            ## Add It to the sorting list
            if ($Best) { $zpool_Sorted | Add-Member $_.sym $_ }

            ## Add remaining coins for historical stats if user specified a
            ## time frame higher than live. If it is live, there is no point
            ## to record all coins.
            if ($(arg).Stat_Coin -ne "live") {
                $AlgoPool_list | Where sym -ne $Best.sym | ForEach-Object {
                    $zpool_UnSorted | Add-Member $_.sym $_ -Force 
                }
            }
        }
    }


    ## First stat the historical coins.
    $zpool_UnSorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
        $zpool_Algorithm = $zpool_UnSorted.$_.algo.ToLower()
        $zpool_Symbol = $zpool_UnSorted.$_.sym.ToUpper()
        $Fees = [Double]$(vars).FeeTable.zpool.$zpool_Algorithm
        $Estimate = [Double]$zpool_UnSorted.$_.estimate

        # mbtc - 6 bit estimates mh
        ## check to see for yiimp bug:
        if ($zpool_UnSorted.$_."24h_btc_shared" -gt 0) { $Divisor = (1000000 * [Double]$(vars).divisortable.zergpool.$Zergpool_Algorithm) } 
        else {
            ## Returns are not actually mbtc/day - Flaw with yiimp calculation with everything based on daily returns:
            $Divisor = ( 1000000 * ( [Double]$(vars).divisortable.zergpool.$Zergpool_Algorithm / 2 ) )
        }

        $Workers = [Double]$zpool_UnSorted.$_.Workers
        $Cut = ConvertFrom-Fees $Fees $Workers $Estimate $Divisor

        ## Stat Zpool Coin. Throw error if there is an issue with pool stat.
        try { 
            $StatAlgo = $zpool_Symbol -replace "`_", "`-" 
            $Stat = Global:Set-Stat -Name "$($Name)_$($StatAlgo)_coin_profit" -Value $Cut
        }
        catch { log "Failed To Calculate Stat For $zpool_Symbol" }
    }

    ## Now to the best coins.
    $zpool_Sorted | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
        $zpool_Algorithm = $zpool_Sorted.$_.algo.ToLower()
        $zpool_Symbol = $zpool_Sorted.$_.sym.ToUpper()
        $zap = "zap=$zpool_Symbol,"
        $zpool_Port = $zpool_Sorted.$_.port
        $Zpool_Host = "$($zpool_Request.$_.Original_Algo).$($region).mine.zpool.ca$X"
        $Fees = [Double]$(vars).FeeTable.zpool.$zpool_Algorithm
        $Estimate = [Double]$zpool_Sorted.$_.estimate
        # mbtc - 6 bit estimates mh
        ## check to see for yiimp bug:
        if ($zpool_Sorted.$_."24h_btc" -gt 0) { $Divisor = (1000000 * [Double]$(vars).divisortable.zergpool.$Zergpool_Algorithm) } 
        else {
            ## returns are not actually mbtc/day - Flaw with yiimp calculation:
            $Divisor = ( 1000000 * ( [Double]$(vars).divisortable.zergpool.$Zergpool_Algorithm / 2 ) )
        }
        $Workers = $zpool_Sorted.$_.Workers
        $Cut = ConvertFrom-Fees $Fees $Workers $Estimate $Divisor

        $Stat = Global:Set-Stat -Name "$($Name)_$($zpool_Symbol)_coin_profit" -Value $Cut


        ## Wallet Swapping/Solo mining
        $Pass1 = $global:Wallets.Wallet1.Keys
        $User1 = $global:Wallets.Wallet1.$($(arg).Passwordcurrency1).address
        $Pass2 = $global:Wallets.Wallet2.Keys
        $User2 = $global:Wallets.Wallet2.$($(arg).Passwordcurrency2).address
        $Pass3 = $global:Wallets.Wallet3.Keys
        $User3 = $global:Wallets.Wallet3.$($(arg).Passwordcurrency3).address

        if ($global:Wallets.AltWallet1.keys) {
            $global:Wallets.AltWallet1.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet1.$_.Pools -contains $Name) {
                    $Pass1 = $_;
                    $User1 = $global:Wallets.AltWallet1.$_.address;
                }
            }
        }
        if ($global:Wallets.AltWallet2.keys) {
            $global:Wallets.AltWallet2.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet2.$_.Pools -contains $Name) {
                    $Pass2 = $_;
                    $User2 = $global:Wallets.AltWallet2.$_.address;
                }
            }
        }
        if ($global:Wallets.AltWallet3.keys) {
            $global:Wallets.AltWallet3.Keys | ForEach-Object {
                if ($global:Wallets.AltWallet3.$_.Pools -contains $Name) {
                    $Pass3 = $_;
                    $User3 = $global:Wallets.AltWallet3.$_.address;
                }
            }
        }
                
        if ($(vars).All_AltWallets) {
            $(vars).All_AltWallets.keys | ForEach-Object {
                $Sym = $_
                $Zpool_Sym = $zpool_Symbol -split "-" | Select -First 1
                if ($(vars).All_AltWallets.$Sym.exchange -ne "Yes") {
                    $Pass1 = $Sym
                    $Pass2 = $Sym
                    $Pass3 = $Sym
                    $mc = ""
                    if ($(vars).All_AltWallets.$Sym.address -ne "add address of coin if you wish to mine to that address, or leave alone." -and $(vars).All_AltWallets.$_.address -ne "") {
                        $User1 = $(vars).All_AltWallets.$Sym.address
                        $User2 = $(vars).All_AltWallets.$Sym.address
                        $User3 = $(vars).All_AltWallets.$Sym.address
                    }
                }
            }
        }
    
        ## Add the stat for next step in calcuation:
        [PSCustomObject]@{
            Symbol    = "$zpool_Symbol-Coin"
            Algorithm = $zpool_Algorithm
            Price     = $Stat.$($(arg).Stat_Coin)
            Protocol  = "stratum+tcp"
            Host      = $zpool_Host
            Port      = $zpool_Port
            User1     = $User1
            User2     = $User2
            User3     = $User3
            Pass1     = "c=$Pass1,$($zap)id=$($(arg).RigName1)"
            Pass2     = "c=$Pass2,$($zap)id=$($(arg).RigName2)"
            Pass3     = "c=$Pass3,$($zap)id=$($(arg).RigName3)"
        } 

        ## Done
    }
}