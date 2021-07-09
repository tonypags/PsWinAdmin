function Get-DnsServerList {
    <#
    .SYNOPSIS
    Collects DNS IP stack from the active adapter.
    .DESCRIPTION
    Leverages the Get-DnsClientServerAddress cmdlet and returns
    device info including ServerName, InterfaceAlias, and
    an ordered list of IP Addresses. WinRM/CIM access using
    $Credential is required for non-local queries.
    .PARAMETER ComputerName
    Pull DNS info from this target(s). Default is localhost.
    .PARAMETER Credential
    Required only if $ComputerName is not the localhost.
    .PARAMETER AddressFamily
    IPv4 or IPv6 or both. Default is IPv4. Use tab-completion for allowed values.
    .EXAMPLE
    Get the local device's DNS info.

    PS > Get-DnsServerList -AddressFamily IPv4,IPv6 |
    >> Select ServerName, InterfaceAlias, DnsIpStack

    ServerName InterfaceAlias DnsIpStack
    ---------- -------------- ---------------
    PC2        Ethernet       {10.10.2.12, 4.2.2.2}
    .EXAMPLE
    Get the local device's IPv4 DNS info.

    PS > Get-DnsServerList | Select ServerName, InterfaceAlias, DnsIpStack

    ServerName InterfaceAlias DnsIpStack
    ---------- -------------- ---------------
    PC1        Ethernet       {10.10.1.12, 1.1.1.1}
    .EXAMPLE
    Get a remote device's IPv4 DNS info.

    PS > Get-DnsServerList PC2 -Credential (Get-Credential) |
    >> Select ServerName, InterfaceAlias, DnsIpStack

    ServerName InterfaceAlias DnsIpStack
    ---------- -------------- ---------------
    PC2        Ethernet       {10.10.2.12, 4.2.2.2}
    .EXAMPLE
    Get a list of servers from AD and then pull their DNS info.

    PS > $sv = Get-ADSIComputerInfo -OsType 'Windows Server'
    PS > $rpt = Get-DnsServerList -ComputerName ($sv.Computer)
    PS > $rpt[48,99] | Select ServerName, InterfaceAlias, DnsIpStack

    ServerName  InterfaceAlias DnsIpStack
    ----------  -------------- ---------------
    PRODA02     Ethernet0      {10.22.10.10, 10.0.1.5, 10.20.10.15}
    serv1       Ethernet       {10.22.10.10, 10.0.1.5, 10.20.10.15}
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
            @{Name='DnsIpStack';Exp={
                $_.ServerAddresses
            }}
            @{Name='DnsIpList';Exp={
                $_.ServerAddresses -join ', '
            }}
            @{Name='ServerFqdn';Exp={
                $thisDNS.Name
            }}
            @{Name='ServerIp';Exp={
                $thisDNS.IPAddress
            }}

        )

        $dnsSplat = @{
            Name = $null
            Type = 'A'
            NoHostsFile = $true
            ErrorAction = 'SilentlyContinue'
        }

        $CleanUp = {
            param($CimSession=$using:CimSession)
            if ($CimSession) {
                $CimSession | Remove-CimSession -Confirm:$false -ErrorAction 0
                Remove-Variable 'CimSession' -ErrorAction 0
            }
        }

    }

    process {

        foreach ($Computer in $ComputerName) {

            $dnsProps = @{
                AddressFamily = $AddressFamily
            }

            $nicProps = @{
                ClassName = 'win32_networkadapterconfiguration'
                Filter = 'IpEnabled="true"'
                ErrorAction = 'Stop'
            }

            # Are we attempting to connect to a remote device?
            if ($Computer -eq $env:COMPUTERNAME) {
                # do nothing
            } else {

                # Resolve DNS first, before connection
                $dnsSplat.Set_Item('Name',$Computer)
                $thisDNS = (Resolve-DnsName @dnsSplat).Where(
                    {$_ -is [Microsoft.DnsClient.Commands.DnsRecord_A]}
                ).Where(
                    {$_.Name -like "$($Computer)*"}
                )

                if ($thisDNS.IPAddress) {

                    # Attempt to create a remote session
                    $cimProps = @{
                        ComputerName = $Computer
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) {$cimProps.Add('Credential',$Credential)}

                    Try {

                        $CimSession = New-CimSession @cimProps
                            
                    } Catch {
                        
                        Invoke-Command -ScriptBlock $CleanUp -ArgumentList $CimSession
                        Write-Warning "Could not connect to $(
                            $Computer
                        ) [CIM]: $(
                            $Error[0].Exception.Message
                        )"
                        continue
                                
                    }#END: Try {}

                    $dnsProps.Add('CimSession',$CimSession)
                    $nicProps.Add('CimSession',$CimSession)
                    Write-Verbose "Connected to CimSession on $(
                        $Computer
                    )"

                } else {

                    Write-Warning "$($Computer
                        ) does not resolve to an IP Address"
                    continue

                }#END: if ($thisDNS.IPAddress) {}

            }#END: if ($Computer -eq $env:COMPUTERNAME) {}

            # Find the correct adapter
            Try {

                $ifIndex = @(Get-CimInstance @nicProps
                    ).InterfaceIndex | Sort-Object

            } Catch {

                if ($_ -like "Cannot find the active adapter") {
                    Invoke-Command -ScriptBlock $CleanUp -ArgumentList $CimSession
                    Write-Warning "Cannot find the active adapter on $(
                        $Computer): $(
                        $Error[0].Exception.Message)"
                    continue
                }

            }
            $dnsProps.Add('InterfaceIndex',$ifIndex)

            # Get the adapter's DNS stack
            Try {
                                
                $rawResult = @(Get-DnsClientServerAddress @dnsProps).Where(
                    {$_.ServerAddresses}
                ) 

            } Catch {

                Invoke-Command -ScriptBlock $CleanUp -ArgumentList $CimSession
                Write-Warning "Cannot find the DNS config on $(
                    $Computer): $(
                    $Error[0].Exception.Message)"
                continue

            }

            Invoke-Command -ScriptBlock $CleanUp -ArgumentList $CimSession
            
            # Ensure we grab only 1 adapter
            $Result = if (@($rawResult).count -gt 1) {

                # We will compare these IP Address arrays
                $baseline = $null
                $ifIndexToUse = $null
                foreach ($iFace in $rawResult) {

                    $thisStack = $iFace.ServerAddresses
                    $baseline = if ($baseline) {
                        
                        # There should not be any difference, ever
                        #  ...this is known, empirically.
                        if (Compare-Object $baseline $thisStack) {
                            Write-Warning "$($Computer) has $(@($ifIndex
                                ).count) IP-enabled interfaces!"
                            Write-Warning "Selecting the first item with index $($ifIndexToUse)"
                        } else {
                            $baseline
                        }

                    } else {
                        
                        # The first item through the loop always ends here
                        # We will use this value
                        $thisStack
                        # The first item is always the lowest ifIndex
                        $ifIndexToUse = $iFace.InterfaceIndex

                    }#END: if ($baseline) {}

                }#END: foreach ($iFace in $rawResult) {}

                $rawResult.Where({$_.InterfaceIndex -eq $ifIndexToUse})

            } else {
                $rawResult
            }

            $Result | Select-Object $ColumnOrder

        }#END: foreach ($Computer in $ComputerName) {}
    
    }#END: process {}

}#END: function Get-DnsServerList {}
