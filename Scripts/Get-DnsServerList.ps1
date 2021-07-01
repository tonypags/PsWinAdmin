function Get-DnsServerList {
    <#
    .SYNOPSIS
    Collects DNS IP stack from the active adapter.
    .DESCRIPTION
    Leverages the Get-DnsClientServerAddress cmdlet and returns
    device info including ServerName, InterfaceAlias, and
    an ordered list of ServerAddresses. WinRM/CIM access using
    $Credential is required for non-local queries.
    .PARAMETER ComputerName
    Pull DNS info from this target(s). Default is localhost.
    .PARAMETER Credential
    Required only if $ComputerName is not the localhost.
    .PARAMETER AddressFamily
    IPv4 or IPv6 or both. Default is IPv4. Use tab-completion for allowed values.
    .EXAMPLE
    Get the local device's DNS info.

    PS > Get-DnsServerList -AddressFamily IPv4,IPv6

    ServerName InterfaceAlias ServerAddresses
    ---------- -------------- ---------------
    PC2        Ethernet       {10.10.2.12, 4.2.2.2}
    .EXAMPLE
    Get the local device's IPv4 DNS info.

    PS > Get-DnsServerList

    ServerName InterfaceAlias ServerAddresses
    ---------- -------------- ---------------
    PC1        Ethernet       {10.10.1.12, 1.1.1.1}
    .EXAMPLE
    Get a remote device's IPv4 DNS info.

    PS > Get-DnsServerList PC2 -Credential (Get-Credential)

    ServerName InterfaceAlias ServerAddresses
    ---------- -------------- ---------------
    PC2        Ethernet       {10.10.2.12, 4.2.2.2}
    #>
    [CmdletBinding()]
    param (
        # Pull DNS info from this target(s). Default is localhost.
        [Parameter(Position=0)]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        # Required only if $ComputerName is not the localhost.
        [Parameter()]
        [PSCredential]
        $Credential,

        # IPv4 or IPv6 or both. Default is IPv4 only.
        [Parameter()]
        [ValidateSet('IPv4','IPv6')]
        [string[]]
        $AddressFamily = 'IPv4'
    )

    begin {

        $ColumnOrder = @(

            @{Name='ServerName';Exp={
                $_.CimSystemProperties.ServerName
            }}
            'InterfaceAlias'
            'ServerAddresses'

        )

    }

    process {

        foreach ($Computer in $ComputerName) {

            $dnsProps = @{
                AddressFamily = $AddressFamily
            }

            $netProps = @{
                Physical = $true
            }

            # Are we attempting to connect to a remote device?
            if ($Computer -eq $env:COMPUTERNAME) {
                # do nothing
            } else {

                Try {
                
                    $cimProps = @{
                        ComputerName = $Computer
                        Credential = $Credential
                        ErrorAction = 'Stop'
                    }
                    $CimSession = New-CimSession @cimProps

                    $dnsProps.Add('CimSession',$CimSession)
                    $netProps.Add('CimSession',$CimSession)
                    Write-Verbose "Connected to CimSession on $(
                        $Computer
                    )"

                } Catch {
                
                    Write-Warning "Could not connect to $(
                        $Computer
                    ): $(
                        $Error[0].Exception.Message
                    )"
                    
                    # Skip check since no connection
                    continue

                }#END: Try {}

            }#END: if ($Computer -eq $env:COMPUTERNAME) {}

            # Find the correct adapter
            $InterfaceIndex = (Get-NetAdapter @netProps).Where({
                $_.Status -eq 'Up'
            }).ifIndex | Sort-Object | Select-Object -First 1
            $dnsProps.Add('InterfaceIndex',$InterfaceIndex)

            Get-DnsClientServerAddress @dnsProps |
                Select-Object $ColumnOrder
        
            $CimSession | Remove-CimSession -Confirm:$false

        }#END: foreach ($Computer in $ComputerName) {}
    
    }#END: process {}

}#END: function Get-DnsServerList {}

(Get-DnsServerList).ServerAddresses
