function Reset-IisApplicationPool {
    [CmdletBinding(
        ConfirmImpact="High",
        SupportsShouldProcess=$true
    )]
    param()
    $appPools = Get-IISAppPool
    
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
