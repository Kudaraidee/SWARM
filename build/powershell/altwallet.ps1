
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

function Get-AltWallets {

    ##Get Wallet Config
    $Wallet_Json = Get-Content ".\config\wallets\wallets.json" | ConvertFrom-Json
    
    if(-not $global:Config.Params.AltWallet1){$Global:All_AltWallets = $Wallet_Json.All_AltWallets}

    ##Sort Only Wallet Info
    $Wallet_Json = $Wallet_Json | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | % {if ($_ -like "*AltWallet*") {@{"$($_)" = $Wallet_Json.$_}}}

    ##Go Through Each Wallet, see if it has been modified.
    $Wallet_Configs = @()

    $Wallet_Json.keys | % {
        $Add = $false
        $Current_Wallet = $_
        $Wallet_Hash = @{"$Current_Wallet" = @{}}
        $Wallet_Json.$Current_Wallet.PSObject.Properties.Name | % {
            $Symbol = "$($_)"
            if ($_ -ne "add coin symbol here") {
                if ($_ -ne "add another coin symbol here") {
                    $Wallet_Hash.$Current_Wallet.Add("$Symbol", @{})
                    $Wallet_Pools = [Array]$Wallet_Json.$Current_Wallet.$Symbol.pools
                    $Wallet_Address = $Wallet_Json.$Current_Wallet.$Symbol.address
                    $Wallet_Hash.$Current_Wallet.$Symbol.Add("address", $Wallet_Address)
                    $Wallet_Hash.$Current_Wallet.$Symbol.Add("pools", $Wallet_Pools)
                    $Add = $true
                }
            }
        }
        if($Add -eq $true){$Wallet_Configs += $Wallet_Hash}
    }

    $Wallet_Configs
}

function Get-Wallets {

## Wallet Information
$global:Wallets = [PSCustomObject]@{}
$NewWallet1= @()
$NewWallet2 = @()
$NewWallet3 = @()
$AltWallet_Config = Get-AltWallets

##Remove NiceHash From Regular Wallet
if($global:Config.Params.Nicehash_Wallet1){$global:Config.Params.PoolName | %{if($_ -ne "nicehash"){$NewWallet1 += $_}}}
else{$global:Config.Params.PoolName | %{$NewWallet1 += $_}}
if($global:Config.Params.Nicehash_Wallet2){$global:Config.Params.PoolName | %{if($_ -ne "nicehash"){$NewWallet2 += $_}}}
else{$global:Config.Params.PoolName | %{$NewWallet1 += $_}}
if($global:Config.Params.Nicehash_Wallet3){$global:Config.Params.PoolName | %{if($_ -ne "nicehash"){$NewWallet3 += $_}}}
else{$global:Config.Params.PoolName | %{$NewWallet3 += $_}}

$C = $true
if($global:Config.Params.Coin){$C = $false}
if($C -eq $false){write-log "Coin Parameter Specified, disabling All alternative wallets." -ForegroundColor Yellow}

if($global:Config.Params.AltWallet1 -and $C -eq $true){$global:Wallets | Add-Member "AltWallet1" @{$global:Config.Params.AltPassword1 = @{address = $global:Config.Params.AltWallet1; Pools = $NewWallet1}}}
elseif($AltWallet_Config.AltWallet1 -and $C -eq $true){$global:Wallets | Add-Member "AltWallet1" $AltWallet_Config.AltWallet1}
if($global:Config.Params.Wallet1 -and $C -eq $true){$global:Wallets | Add-Member "Wallet1" @{$global:Config.Params.Passwordcurrency1 = @{address = $global:Config.Params.Wallet1; Pools = $NewWallet1}}}
else{$global:Wallets | Add-Member "Wallet1" @{$global:Config.Params.Passwordcurrency1 = @{address = $global:Config.Params.Wallet1; Pools = $NewWallet1}}}

if($global:Config.Params.AltWallet2 -and $C -eq $true ){$global:Wallets | Add-Member "AltWallet2" @{$global:Config.Params.AltPassword2 = @{address = $global:Config.Params.AltWallet2; Pools = $NewWallet2}}}
elseif($AltWallet_Config.AltWallet2 -and $C -eq $True ){$global:Wallets | Add-Member "AltWallet2" $AltWallet_Config.AltWallet2}
if($global:Config.Params.Wallet2 -and $C -eq $true){$global:Wallets | Add-Member "Wallet2" @{$global:Config.Params.Passwordcurrency2 = @{address = $global:Config.Params.Wallet2; Pools = $NewWallet2}}}
else{$global:Wallets | Add-Member "Wallet2" @{$global:Config.Params.Passwordcurrency2 = @{address = $global:Config.Params.Wallet2; Pools = $NewWallet2}}}

if($global:Config.Params.AltWallet3 -and $C ){$global:Wallets | Add-Member "AltWallet3" @{$global:Config.Params.AltPassword3 = @{address = $global:Config.Params.AltWallet3; Pools = $NewWallet3}}}
elseif($AltWallet_Config.AltWallet3 -and $C ){$global:Wallets | Add-Member "AltWallet3" $AltWallet_Config.AltWallet3}
if($global:Config.Params.Wallet3 -and $C -eq $true){$global:Wallets | Add-Member "Wallet3" @{$global:Config.Params.Passwordcurrency3 = @{address = $global:Config.Params.Wallet3; Pools = $NewWallet3}}}
else{$global:Wallets | Add-Member "Wallet3" @{$global:Config.Params.Passwordcurrency3 = @{address = $global:Config.Params.Wallet3; Pools = $NewWallet3}}}

if($global:Config.Params.Nicehash_Wallet1){$global:Wallets | Add-Member "Nicehash_Wallet1" @{"BTC" = @{address = $global:Config.Params.Nicehash_Wallet1; Pools = "nicehash"}}}
if($global:Config.Params.Nicehash_Wallet2){$global:Wallets | Add-Member "Nicehash_Wallet2" @{"BTC" = @{address = $global:Config.Params.Nicehash_Wallet2; Pools = "nicehash"}}}
if($global:Config.Params.Nicehash_Wallet3){$global:Wallets | Add-Member "Nicehash_Wallet3" @{"BTC" = @{address = $global:Config.Params.Nicehash_Wallet3; Pools = "nicehash"}}}


if (Test-Path ".\wallet\keys") {$Oldkeys = Get-ChildItem ".\wallet\keys"}
if ($Oldkeys) {Remove-Item ".\wallet\keys\*" -Force}
if (-Not (Test-Path ".\wallet\keys")) {new-item -Path ".\wallet" -Name "keys" -ItemType "directory" | Out-Null}
$global:Wallets.PSObject.Properties.Name | %{$global:Wallets.$_ | ConvertTo-Json -Depth 3 | Set-Content ".\wallet\keys\$($_).txt"}
}