function Get-LastLoggedOnUser {
    Param(
    
    )
        $Win32Users  = Get-Win32User
        $LastUser = $Win32Users | Sort-Object -Property LastUseTime -Descending | Select-Object -First 1
        $UserSID = New-Object System.Security.Principal.SecurityIdentifier($LastUser.SID)
        
        Get-LocalUserAccount -Sid $UserSID.Value
    
}
