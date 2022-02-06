function Get-LocalUserAccount {

    <#
    .SYNOPSIS
    Retrieves information on the specified user account from the local machine.
    .DESCRIPTION
    Retrieves information on the specified user account from the local machine.
    .NOTES
    https://github.com/OfficeDev/Office-IT-Pro-Deployment-Scripts

    #>

    [CmdletBinding(DefaultParameterSetName='Username')]
    Param(
        
        # The Username of the account to look up
        [Parameter(ParameterSetName='Username',
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Username=($env:USERNAME),

        # The SID of the account to look up
        [Parameter(ParameterSetName='Sid',
            ValueFromPipelineByPropertyName=$true)]
        [string]
        $Sid

    )
    
    if ($PsCmdlet.ParameterSetName -eq 'Username') {

        $obj = Get-Win32User |
            Where-Object {$_.LocalPath -like "$($env:SYSTEMDRIVE):\Users\$($Username)*"}

    } else {

        $UserSID = New-Object System.Security.Principal.SecurityIdentifier($Sid)
        $User = ($UserSID.Translate([System.Security.Principal.NTAccount])).Value
        $Username = $User.Split("\")[-1]

        $obj = Get-Win32User | Where-Object {$_.LocalPath -like "*$($Username)*"}

    }
    
    $obj | Add-Member -MemberType NoteProperty -Name Username -Value $Username -PassThru

}
