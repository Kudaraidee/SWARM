function Global:Get-CoinShares {

    . .\build\api\pools\zergpool.ps1;
    . .\build\api\pools\nlpool.ps1;    
    . .\build\api\pools\ahashpool.ps1;
    . .\build\api\pools\blockmasters.ps1;
    . .\build\api\pools\hashrefinery.ps1;
    . .\build\api\pools\phiphipool.ps1;
    . .\build\api\pools\fairpool.ps1;
    . .\build\api\pools\blazepool.ps1;

    $global:Config.Params.Type | ForEach-Object { $global:Share_Table.Add("$($_)", @{ }) }

    ##For 
    $global:Config.Params.Poolname | % {
        switch ($_) {
            "zergpool" { Get-ZergpoolData }
            "nlpool" { Get-NlPoolData }        
            "ahashpool" { Get-AhashpoolData }
            "blockmasters" { Get-BlockMastersData }
            "hashrefinery" { Get-HashRefineryData }
            "phiphipool" { Get-PhiphipoolData }
            "fairpool" { Get-FairpoolData }
            "blazepool" { Get-BlazepoolData }
        }
    }
}