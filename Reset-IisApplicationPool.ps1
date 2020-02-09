function Reset-IisApplicationPool {
    $WmiProps = @{
        namespace = "root\MicrosoftIISv2"
        class = "IIsApplicationPool"
    }
    $appPools = Get-WmiObject @WmiProps |
        Select-Object -ExpandProperty Name
    foreach ($appPool in $AppPools) {
       $appPool.Recycle()
    }
}
