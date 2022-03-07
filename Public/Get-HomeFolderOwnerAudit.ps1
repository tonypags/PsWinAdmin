function Get-HomeFolderOwnerAudit {

    <#
    .SYNOPSIS
    Checks all folders to ensure users have full control of their home share.
    .DESCRIPTION
    Assumes the name of the folder equals the username and returns an object with booleans.
    #>

    param(
        $HomeShare = 'D:\home'
    )

    $ACL = Get-ChildItem $HomeShare -Directory | get-acl
    Foreach ($item in $ACL) {
        # Find the data for comparison
        $FolderName = $item.PSChildName
        $ptnFolderOwner = '.*\\(.+)'
        $FolderOwner = [regex]::Match($item.owner, $ptnFolderOwner).groups[1].value
    
        # test the data
        $OwnerIsSelf = if ($FolderName -eq $FolderOwner) {$true} else {$false}

        # Add the result
        $Item | Add-Member -MemberType NoteProperty -Name OwnerIsSelf -Value $OwnerIsSelf -PassThru
    }
}
