function Find-ActiveNicInterface {
    <#
    .SYNOPSIS
    Finds active NIC on the computer.
    
    .DESCRIPTION
    Returns active NIC CIM object of the local computer,
    or a remote computer if given a CimSession parameter.
    
    .PARAMETER CimSession
    Optionally get info from a remote computer by passing an
    existing CimSession object to this function.
    
    .PARAMETER IncludeNullGateway
    Used in cases where you want to return an active NIC that
    isn't connected to any router.
    
    .EXAMPLE
    Find-ActiveNicInterface

    Returns the local active NIC.
    .EXAMPLE
    Find-ActiveNicInterface -IncludeNullGateway
    
    Returns the local active NICs but doesn't discard
    NICs without a gateway IP.
    .EXAMPLE
    $cred = Get-Credential
    $cs = New-CimSession -ComputerName hostname -Credential $cred
    Find-ActiveNicInterface -CimSession $cs

    Returns the remote active NIC.
    #>
    [CmdletBinding()]
    param (
        $CimSession,

        [switch]
        $IncludeNullGateway
    )
    
    $nicProps = @{
        ClassName = 'win32_networkadapterconfiguration'
        Filter = 'IpEnabled="true" AND DHCPEnabled="false"'
    }
    if ($CimSession) {$nicProps.CimSession = $CimSession}
    
    Try {
        
        # Find the correct adapter
        $NICs = Get-CimInstance @nicProps -ea 'Stop'
        if ($IncludeNullGateWay) {} else {
            $NICs = $NICs | Where-Object DefaultIPGateway
        }

        $NICs

    } Catch {

        if ($_ -like "Cannot find the active adapter") {
            Write-Warning "Cannot find the active adapter on $(
                $CimSession.ComputerName): $(
                $_.exception.message)"
            return
        }

    }

}#END: function Find-ActiveNicInterface
