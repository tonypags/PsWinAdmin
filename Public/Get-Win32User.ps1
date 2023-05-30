function Get-Win32User {
    Param(
    
    )
    
    $filter = "NOT SID = 'S-1-5-18' AND NOT SID = 'S-1-5-19' AND NOT SID = 'S-1-5-20'"
    Get-CimInstance -Class Win32_UserProfile -Filter $filter -ComputerName $env:COMPUTERNAME
    
}
