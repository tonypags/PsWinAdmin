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
    PRDVWSWHA02 Ethernet0      {10.202.102.150, 10.6.1.55, 10.207.100.150}
    halas       Ethernet       {10.202.102.150, 10.6.1.55, 10.207.100.150}
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

                $dnsSplat.Set_Item('Name',$Computer)
                $thisDNS = (Resolve-DnsName @dnsSplat).Where(
                    {$_ -is [Microsoft.DnsClient.Commands.DnsRecord_A]}
                ).Where(
                    {$_.Name -like "$($Computer)*"}
                )

                if ($thisDNS.IPAddress) {

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

                $ifIndex = (Get-CimInstance @nicProps).InterfaceIndex

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

                Get-DnsClientServerAddress @dnsProps |
                    Select-Object $ColumnOrder

            } Catch {

                Invoke-Command -ScriptBlock $CleanUp -ArgumentList $CimSession
                Write-Warning "Cannot find the DNS config on $(
                    $Computer): $(
                    $Error[0].Exception.Message)"
                continue

            }
    
            Invoke-Command -ScriptBlock $CleanUp -ArgumentList $CimSession

        }#END: foreach ($Computer in $ComputerName) {}
    
    }#END: process {}

}#END: function Get-DnsServerList {}

<# I am attempting to pull a computer list from AD
NO! pull it from VMware instead


#### creds #####
$path = 'C:\Users\solarwindsops\Documents\WindowsPowerShell\Credentials\solarwindsops@nfl.net.xml'
$SWOPScreds = Import-CliXml $path
#### creds #####


$sv = Invoke-Command -Session $nflroot -ScriptBlock {Get-AdComputer -f $filter}
$sv.count

#>

$strNow = (Get-Date).ToString('yyyyMMdd-HHmmss')
$tsctPath = "C:\Temp\Get-DsnServerList.transcript.$($strNow).txt"
$warnPath = "C:\Temp\Get-DsnServerList.warnings.$($strNow).txt"
Start-Transcript -Path $tsctPath
# $sv = Get-VM
$sv = Get-Content 'c:\temp\servers.txt' | Sort-Object
$rpt = Get-DnsServerList -ComputerName $sv -Verbose
Stop-Transcript
$Warnings = Get-Content $tsctPath | Select-String '^WARNING'
$Warnings | Out-String | Out-File $warnPath
Write-Host ''
Write-Host "Out of $(@($sv).count) total servers, $(@($rpt).count) returned DNS info."
Write-Host '$sv = total servers (AD)'
Write-Host '$rpt = Report of results'

Get-Item $tsctPath,$warnPath

# Ensure cleaned up
Get-Variable CimSession -ea 0
Get-CimSession
