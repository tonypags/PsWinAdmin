function Test-ProcessRunningUnderSessionId {

    <#
    .SYNOPSIS
    Tests a process to see if the given user started it.
    .PARAMETER Name
    The name of the process in question. Wildcards not allowed.
    .PARAMETER SessionID
    The session ID of the user to test agains (see quser result for ID number). Default is the current user.
    .EXAMPLE
    Test-ProcessRunningUnderSessionId -Name msiexec
    
    Checks to see if msiexec.exe was initialted by the current user.
    .EXAMPLE
    Test-ProcessRunningUnderSessionId -Name msiexec -SessionId 2
    
    Checks to see if msiexec.exe was initialted by the user with the session ID 2
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [ValidateNotNull()]
        [int]
        $SessionId = ((Get-UserSession | Where-Object {$_.Username -eq $env:USERNAME}).Id)
    )

    Process {
        $ProcessInQuestionsSessionId = Get-Process $Name -ea 0 | Select-Object -exp SessionId -ea 0
        if ($ProcessInQuestionsSessionId -eq $SessionId) {
            $true
        }
        else {
            $false
        }
    }
}