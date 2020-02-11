function Get-ADAdminPwdHistory {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        if (!(Get-Module ActiveDirectory)) {
            Throw "ActiveDirectory module required!"
        }
    }
    
    process {
        Get-ADGroupMember -Identity "Domain Admins" | 
        Get-ADUser -Properties PasswordLastSet, PasswordNeverExpires |
        Select-Object Name, PasswordLastSet, PasswordNeverExpires
    }
    
    end {
    }
}

function Export-AdAdminPwdHistoryHtml {
    [CmdletBinding()]
    param (
        # Pipeline object
        [Parameter(ValueFromPipeline=$true)]
        $InputObject,

        # Destination
        [Parameter(Position=0)]
        [ValidatePattern('\.html?$')]
        [string]
        $Path=(Join-Path $env:TEMP "$($env:USERDOMAIN)-Domain-Admin-Account-Info.html")
    )
    
    begin {
        $Head = @"
            <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd"&gt;
            <html><head><meta http-equiv="refresh" content="120" />
            <style type="text/css">
            body { background-color:#FFFFFF; }
            td, th { border:1px solid black;
                        border-collapse:collapse; }
            th { color:white;
                    background-color:black; }
            table, tr, td, th { padding: 2px; margin: 1px }
            table { margin-left:1px; }
            </style>
"@
        $OutputObject = New-Object System.Collections.ArrayList
    }
    
    process {
        Foreach ($obj in $InputObject) {
            [void]($OutputObject.Add($obj))
        }
    }
    
    end {
        $OutputObject |
            Sort-Object PasswordLastSet -Descending |
            ConvertTo-HTML -head $Head |
            Out-File $Path -Force
    }
}

Import-Module ActiveDirectory -Force
$Path = (Join-Path $env:TEMP "$($env:USERDOMAIN)-Domain-Admin-Account-Info.html")
Get-ADAdminPwdHistory | Export-AdAdminPwdHistoryHtml -Path $Path
