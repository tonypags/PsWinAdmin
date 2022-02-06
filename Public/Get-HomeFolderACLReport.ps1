function Get-HomeFolderACLReport {
    
    <#
    .SYNOPSIS
    Checks all folders to ensure users have full control of their home share.
    .DESCRIPTION
    Assumes the name of the folder equals the username and returns an object with the ACL info or null.
    #>
    
    [CmdletBinding()]
    param(

        # Path under which all home folders are stored
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$Parent
    )

    Begin {

    }

    Process {

        $Children = Get-ChildItem $Parent -Directory 

        Foreach ($item in $Children) {
            Get-FolderACLReport -FullName "$Parent\$item"
        }

        $Username = ($Parent -replace 'd:\\home\\' -replace '\\.*').Trim()
        
        $Access = (Get-Acl $Parent -ea 0 -ev errAcl | 
                Select-Object -ExpandProperty AccessToString) -split "`n" |
            Where-Object {$_ -like "*$Username*" -and
            $_ -like "*Allow*FullControl*"} 
        

        if (!$Access) {
            $Access = "No access for user: $($Username)"
        }
        else {
            [string]$Access = $Access -join '; '
        }

        New-Object -TypeName psobject -Property @{
            Path   = $Parent
            Access = $Access
        }
    }

    End {
    }
}
