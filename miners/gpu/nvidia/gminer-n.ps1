                            "nicehash" { $AddArgs = "--algo etchash --proto stratum " }
                            "zergpool" { $AddArgs = "--algo etchash " }
                        }
                    }
                }
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
                    ArgDevices        = $ArgDevices
                    Devices           = $Devices
                    Stratum           = "$($_.Protocol)://$($_.Pool_Host):$($_.Port)"
                    Version           = "$($(vars).nvidia.$CName.version)"
                    DeviceCall        = "gminer"
                    Arguments         = "--api $Port --server $($_.Pool_Host) --port $($_.Port) $AddArgs--user $GetUser --logfile `'$Log`' $UserPass$($MinerConfig.$ConfigType.commands.$($_.Algorithm))"
                    HashRates         = [Decimal]$Stat.Hour
                    HashRate_Adjusted = [Decimal]$Hashstat
                    Quote             = $_.Price
                    Rejections        = $Stat.Rejections
                    Power             = if ($(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts") { $(vars).Watts.$($_.Algorithm)."$($ConfigType)_Watts" }elseif ($(vars).Watts.default."$($ConfigType)_Watts") { $(vars).Watts.default."$($ConfigType)_Watts" }else { 0 }
                    MinerPool         = "$($_.Name)"
                    API               = "gminer"
                    Port              = $Port
                    Worker            = $Rig
                    Wallet            = "$($_.$User)"
                    URI               = $Uri
                    Server            = "localhost"
                    Algo              = "$($_.Algorithm)"
                    Log               = "miner_generated"
                }
            }
        }
    }
}
