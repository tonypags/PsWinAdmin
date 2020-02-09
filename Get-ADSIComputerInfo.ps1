function Get-ADSIComputerInfo {

    <#
    .SYNOPSIS
    Retrieves computer objects from Active Directory.
    .DESCRIPTION
    Retrieves all enabled domain computer objects from Active Directory without using the ActiveDirectory module.
    #>

    $ErrorActionPreference = 'SilentlyContinue'
    $VerbosePreference = 'Continue'

    Write-Verbose "$((Get-Date).ToLongTimeString()):  Finding enabled AD computers..."
    # Build the AD object with all computer objects found
    $adsi = $null
    $adsi = [adsisearcher]"objectcategory=computer"
    # To return only the enabled computer objects, use '!userAccountControl:1.2.840.113556.1.4.803:=2'
    $adsi.filter = "(&(objectClass=Computer)(!userAccountControl:1.2.840.113556.1.4.803:=2))"
    $EnabledADComputerADSI = $adsi.FindAll()
    $EnabledADComputer = Foreach ($E in $EnabledADComputerADSI){
        $obj = $E.Properties
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
    Write-Verbose "$((Get-Date).ToLongTimeString()):  $($EnabledADComputer.count) objects returned from ADSI search"
    Write-Output $EnabledADComputer
}
