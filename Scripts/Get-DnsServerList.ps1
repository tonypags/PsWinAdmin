function Get-ADSIComputerInfo {
    <#
    .SYNOPSIS
    Retrieves computer objects from Active Directory using ADSI.
    .DESCRIPTION
    Retrieves all enabled domain computer objects from Active Directory without
    using the ActiveDirectory module.
    .EXAMPLE
    $sv = Get-ADSIComputerInfo -OsType 'Windows Server'
    .EXAMPLE
    $ad = Get-ADSIComputerInfo -Verbose
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(
            'Windows Server',
            'CentOS',
            'All'
        )]
        [string]
        $OsType='All',

        [Parameter()]
        [switch]
        $IncludeDisabled
    )

    Write-Verbose "$((Get-Date).ToLongTimeString()):  Finding enabled AD computers..."
    # Build the AD object with all computer objects found
    $adsi = $null
    $adsi = [adsisearcher]"objectcategory=computer"

    # To return only the enabled computer objects, use '!userAccountControl:1.2.840.113556.1.4.803:=2'
    [string[]]$filters = $null
    $filters += 'objectClass=Computer'
    if ($IncludeDisabled) {} else {$filters += '!userAccountControl:1.2.840.113556.1.4.803:=2'}
    if ($OsType -eq 'All') {
        # Do nothing
    } elseif ($OsType -eq 'Windows Server') {
        $filters += 'operatingsystem=*server*'
        $filters += 'operatingsystem=*Windows*'
    } elseif ($OsType -eq 'CentOS') {
        $filters += 'operatingsystem=*CentOS*'
    }
    $adsi.filter = if ($filters.count -eq 1) {
        "($($filters))"
    } else {
        "(&{0})" -f (
            ($filters | ForEach-Object {"($($_))"}) -join ''
        )
    }
    $ComputerADSI = $adsi.FindAll()
    $Result = Foreach ($C in $ComputerADSI){
        $obj = $C.Properties
        $props = @{
            Computer    = [string]$obj.name
            OSName      = [string]$obj.operatingsystem -replace 
                                     'Windows','Win' -replace 
                                'Professional','Pro' -replace 
                                    'Standard','Std' -replace 
                                    'Ultimate','Ult' -replace 
                                  'Enterprise','Ent' -replace 
                                    'Business','Biz' -replace 
                                        'with', 'w/' -replace 
                                'Media Center','MedCtr'
            Description = [string]($obj.description)
            AD_OU       = [string]($obj.distinguishedname) -replace 
                                  '^CN=[\w\d-_]+,\w\w=','' -replace 
                                                ',OU=','/' -replace ',DC=.*'
            LastLogon   = [datetime]::FromFileTime([string]$obj.lastlogon)
            ADCreated   = [datetime]($obj.whencreated)[0]
        }
        New-Object -TypeName PSObject -Property $props
    }
    Write-Verbose "$((Get-Date).ToLongTimeString()):  $(@($Result).count) objects returned from ADSI search"
    Write-Output $Result
}

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
    .EXAMPLE
    Get a list of servers from AD and then pull their DNS info.

    PS > $sv = Get-ADSIComputerInfo -OsType 'Windows Server'
    PS > $rpt = Get-DnsServerList -ComputerName ($sv.Computer)
    PS > $rpt[48,99]

    ServerName  InterfaceAlias ServerAddresses
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
            $InterfaceIndex = @(Get-NetAdapter @netProps).Where({
                $_.Status -eq 'Up'
            }).ifIndex | Sort-Object | Select-Object -First 1
            $dnsProps.Add('InterfaceIndex',$InterfaceIndex)

            Get-DnsClientServerAddress @dnsProps |
                Select-Object $ColumnOrder
    
            if ($CimSession) {
                $CimSession | Remove-CimSession -Confirm:$false
                Remove-Variable 'CimSession'
            }

        }#END: foreach ($Computer in $ComputerName) {}
    
    }#END: process {}

}#END: function Get-DnsServerList {}

$sv = Get-ADSIComputerInfo -OsType 'Windows Server'
$rpt = Get-DnsServerList -ComputerName ($sv.Computer) -Verbose
Write-Host ''
Write-Host "Out of $(@($sv).count) total servers, $(@($rpt).count) returned DNS info."
