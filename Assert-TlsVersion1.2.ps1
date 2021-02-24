function Assert-TlsVersion1.2 {

    [CmdletBinding()]

    param()
    
    # Ensure we are running as an admin
    $vMsg = "$(strDate) Testing current session to ensure we are running as admin."
    Write-Verbose $vMsg
    Write-Debug $vMsg
    Confirm-RequiresAdmin


    # Ensure the key exists before asking for its value
    $Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
    Try {
        
        $item = Get-Item $Key -ea Stop -ev errItem

    } Catch [System.Management.Automation.ItemNotFoundException] {
        
        $item = New-Item -ItemType Directory -Path $Key -Force -ea 0 -ev errItem

    } Finally {
        
        if (-not $item) {
            Write-Error "$Key Key not found and unable to be created! [$($errItem.CategoryInfo.Category)]"
        }

    }


    # Gather current settings if they exist
    $regTlsDisabledByDefault = $item | Get-ItemProperty -Name 'DisabledByDefault' -ea 0
    $regTlsEnabled = $item | Get-ItemProperty -Name 'Enabled' -ea 0


    # Retrieve the values using conditionals
    if ($regTlsDisabledByDefault) {

        # Get the DisabledByDefault setting value if it exists
        [int]$intTlsDisabledByDefault = $regTlsDisabledByDefault.DisabledByDefault

    } else {
        
        # Create the DisabledByDefault setting if it does not exist
        $regTlsDisabledByDefault = $item | New-ItemProperty -Name 'DisabledByDefault' -Value 0
        [int]$intTlsDisabledByDefault = $regTlsDisabledByDefault.DisabledByDefault

    }#END:  if ($regTlsDisabledByDefault)

    if ($regTlsEnabled) {
        
        # Get the Enabled setting value if it exists
        [int]$intTlsEnabled = $regTlsEnabled.Enabled

    } else {
        
        # Create the Enabled setting if it does not exist
        $regTlsEnabled = $item | New-ItemProperty -Name 'Enabled' -Value 1
        [int]$intTlsEnabled = $regTlsEnabled.Enabled

    }#END:  if ($regTlsEnabled)


    # Assert the required values
    if ($intTlsDisabledByDefault -ne 0) {

        $item | Set-ItemProperty -Name 'DisabledByDefault' -Value 0
        $regTlsDisabledByDefault = $item | Get-ItemProperty -Name 'DisabledByDefault' -ea 0
        [int]$intTlsDisabledByDefault = $regTlsDisabledByDefault.DisabledByDefault

        # Finally, check it again
        if ($intTlsDisabledByDefault -ne 0) {
            Write-Error "'DisabledByDefault' value could not be set!"
        }

    }

    if ($intTlsEnabled -ne 1) {

        $item | Set-ItemProperty -Name 'Enabled' -Value 1
        $regTlsEnabled = $item | Get-ItemProperty -Name 'Enabled' -ea 0
        [int]$intTlsEnabled = $regTlsEnabled.Enabled

        # Finally, check it again
        if ($intTlsEnabled -ne 1) {
            Write-Debug "enabled: `$intTlsEnabled , `$regTlsEnabled"
            Write-Error "'Enabled' value could not be set!"
        }

    }

}
