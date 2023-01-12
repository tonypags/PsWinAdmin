function Get-ChildAcl {
    <#
    .SYNOPSIS
    Report of ACL info on given folder's children
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [ValidateScript({Test-Path $_})]
        [Alias('Path')]
        [string]
        $Parent
    )

    $Children = Get-ChildItem $Parent -Directory 

    Foreach ($item in $Children) {

        $Access = Get-Acl $item -ea 0 -ev errAcl
        $Path = $Access.PsPath -replace '^.*::'
        $Owner = $Access.Owner
        $Group = $Access.Group
        foreach ($acl in $Access.Access) {
            [PsCustomObject]@{
                Path             = $Path
                User             = $acl.IdentityReference
                Type             = $acl.AccessControlType
                Rights           = $acl.FileSystemRights
                IsInherited      = $acl.IsInherited
                InheritanceFlags = $acl.InheritanceFlags
                PropagationFlags = $acl.PropagationFlags
                Owner            = $Owner
                Group            = $Group
            }
        }
    }
}#END: function Get-ChildAcl
