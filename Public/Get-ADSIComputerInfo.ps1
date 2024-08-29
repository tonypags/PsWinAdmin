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
    Write-Verbose "$((Get-Date).ToLongTimeString()):  $(($Result|Measure-Object).Count) objects returned from ADSI search"
    Write-Output $Result
}
