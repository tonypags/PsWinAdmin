function Reset-IisApplicationPool {
    [CmdletBinding(
        ConfirmImpact="High",
        SupportsShouldProcess=$true
    )]
    $WmiProps = @{
        namespace = "root\MicrosoftIISv2"
        class = "IIsApplicationPool"
    }
    $appPools = (Get-WmiObject @WmiProps).Name
    
    if ($pscmdlet.ShouldProcess(
        "appPools",
        "Recycle"
    )) {
        foreach ($appPool in $AppPools) {
            # Should Process?
            $appPool.Recycle()
        }
    }

}
