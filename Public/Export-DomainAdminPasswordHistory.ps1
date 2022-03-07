function Export-AdAdminPwdHistoryHtml {

    <#
    .EXAMPLE
    Get-ADAdminPwdHistory | Export-AdAdminPwdHistoryHtml
    #>

    [CmdletBinding()]
    param (

        # Pipeline object from Get-ADAdminPwdHistory
        [Parameter(ValueFromPipeline=$true)]
        $InputObject,

        # Destination path
        [Parameter(Position=0)]
        [ValidatePattern('\.html?$')]
        [string]
        $Path=(Join-Path $env:TEMP "$($env:USERDOMAIN)-Domain-Admin-Account-Info.html"),

        # Returns a FileInfo object that represents the exported file
        [Parameter()]
        [switch]
        $PassThru,

        # Prevents overwriting the existing file
        [Parameter()]
        [switch]
        $NoClobber

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

        $Splat = @{FilePath = $Path}
        if (!$NoClobber) {$Splat.Add('Force',$true)}

        $OutputObject |
            Sort-Object PasswordLastSet -Descending |
            ConvertTo-HTML -head $Head |
            Out-File @Splat

        if ($PassThru) {

            Get-Item $Path

        }

    }

}#END function Export-AdAdminPwdHistoryHtml
