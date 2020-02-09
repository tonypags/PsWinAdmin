function Send-String {

    <#
    .SYNOPSIS
    Sends an array of strings to the keyboard for automated input tasks.
    #>

    [CmdletBinding()]
    param (
        # String or array of strings to send
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [string[]]$String,

        # Seconds to wait before sending
        [Parameter()]
        [int]$InitialDelay=3,

        # Seconds to wait after sending each string
        [Parameter()]
        [int]$IntervalDelay=3,

        # Send Enter key after sending each string
        [Parameter()]
        [switch]$SendEnter
    )
    
    Begin {
        Add-Type -AssemblyName Microsoft.VisualBasic -ea Stop
        Add-Type -AssemblyName System.Windows.Forms -ea Stop
        $arrKeys = New-Object -TypeName System.Collections.ArrayList
    }

    Process {
        Foreach ($Key in $String) {
            [void]($arrKeys.Add($Key))
        }
    }

    End {
        Start-Sleep $InitialDelay
        $arrKeys | Foreach-Object {
            [System.Windows.Forms.SendKeys]::SendWait($_)
            if($SendEnter){[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")}
            Start-Sleep -Seconds $IntervalDelay
        }
    }
}
