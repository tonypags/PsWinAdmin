function Disable-Windows2019Telemetry {
    
    <#
    .SYNOPSIS
    Disabled Windows Telemetry.
    .DESCRIPTION
    Disables all services known to be related to windows telemetry in Server 2019. 
    A reboot is required for the changes to take effect.
    #>
    [CmdletBinding()]
    
    param()
    
    # Ensure we're running as admin
    Confirm-RequiresAdmin

    # For post-message later
    $ChangesWereMade = $false

    # Define the service names to disable
    $strServiceName = @(
        'WpnUserService'
        'UserDataSvc'
        'UnistoreSvc'
        'DevicesFlowUserSvc'
        'PimIndexMaintenanceSvc'
        'PrintWorkflowUserSvc'
    )

    # Define the regitry path to search for names to disable
    $strRegParent = 'HKLM:\System\CurrentControlSet\Services\'
    $objRegServiceKey = Get-ChildItem $strRegParent

    # Loop through service names and find keys
    Foreach ($strService in $strServiceName) {

        # Find the items that match
        $objService =  $objRegServiceKey |
            Where-Object {$_.Name -like "*$($strService)*"}
        
        # Loop through each item and asset Start type is Disabled (4)
        Foreach ($obj in $objService) {

            $strSvcName = $obj.name | split-path -leaf
            Write-Debug "Service object for '$($strSvcName)' stored in: `$obj"

            # What is the current value?
            [int]$intStart = ($obj | Get-ItemProperty -Name Start -ea 0).Start
            
            # If it's not 4, change it to 4
            if ($intStart -ne 4) {

                $objNewValue = $obj |
                    Set-ItemProperty -Name Start -Value 4 -PassThru -Confirm:$false -ea 0
                $ChangesWereMade = $true

                # What is the new value?
                [int]$intStart = $objNewValue.Start

                # If it's not 4, throw a warning
                if ($intStart -ne 4) {
                    Write-Warning "Could not set value on Service named $($strSvcName)!"
                } else {
                    Write-Verbose "Successfully set Startup Type on Service named $($strSvcName)!"
                }

            }#END: if ($intStart -ne 4)
        }#END: Foreach ($obj in $objService)
    }#END: Foreach ($strService in $strServiceName)

    # Disable Telemetry
    $objDCKey = Get-Item 'hklm:\Software\Policies\Microsoft\Windows\DataCollection'
    $strProperty = 'Allow Telemetry'
    $objProperty = $objDCKey | Get-ItemProperty -Name $strProperty -ea 0
    Write-Debug "Telemetry Keys stored in: `$objDCKey; `$objProperty"
    if ($objProperty) {

        # Read the current value
        $intStartValue = $objProperty.$strProperty

        # If it's not 0, change it to 0
        if ($intStartValue -ne 0) {
            $objDCKey |
                Set-ItemProperty -Name $strProperty -Value 0 -Confirm:$false -ea 0
            $ChangesWereMade = $true
            Write-Verbose "Disabled Telemetry setting (old value: $($intStartValue))."
        }

    } else {

        # Set a new value and make it 0
        $objDCKey |
            New-ItemProperty -Name $strProperty -Value 0 -Confirm:$false -ea 0 |
            Out-NUll
        $ChangesWereMade = $true
        Write-Verbose "Disabled Telemetry setting (no old value)."
    }
    
    # If changes were made, a restart is required
    if ($ChangesWereMade) {
        Write-Warning "Please restart computer for changes to take effect."
    } else {
        Write-Verbose "No changes were made."
    }

}#END: function Disable-Windows2019Telemetry
