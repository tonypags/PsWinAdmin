function Find-AdLockoutEvent {
    param (
        # Must be a DC server
        [Parameter(Mandatory=$true)]
        [string]
        $DCServer,

        [Parameter(Mandatory=$true)]
        [string]
        $Username,

        [Parameter()]
        [int]
        $Minutes = 30
    )

    Get-WinEvent -Computername $DCServer -filterHashTable @{
        LogName="Security";
        StartTime=(get-date).AddMinutes(-$Minutes);
    } | 
	Where-Object {
        (
            $_.KeywordsDisplayNames -eq 'Audit Failure' -and 
            $_.Message -like "*$Username*"
        ) -or (
            $_.Message -like '*Fail*' -and 
            $_.Message -like "*$Username*"
        )
    }
}
