function Use-ConsoleBeep {

    <#
    .SYNOPSIS
    Allows automated activation of the PC speaker.
    .NOTES
    Your Opus is waiting for you.
    #>

    [CmdletBinding()]
    [Alias('beep')]
    Param (
        # Frequency of tone, in Hz, between 37 - 20000
        [Parameter(Position=0)]
        [ValidateRange(37,20000)]
        [Alias("tone")]
        [int]
        $Frequency=1000,

        # Duration of tone, in milliseconds, between 1 - 60000
        [Parameter(Position=1)]
        [ValidateRange(1,60000)]
        [int]
        $Length=250,

        # Number of milliseconds to deply until the next beep. 0 means no repeat, max 60000
        [Parameter(Position=1)]
        [int]
        $Delay=0
    )

    Begin
    {
    }
    Process
    {
        if($Delay){
            Write-Host "Press Ctrl+C to exit the beep loop." -ForegroundColor Cyan
            While($true){
                [console]::Beep($Frequency,$Length)
                Start-Sleep -Milliseconds $Delay
            }
        }else{
            [console]::Beep($Frequency,$Length)
        }
    }
    End
    {
    }
}
