﻿function Get-RebootReport {
    [CmdletBinding()]
    param (
        # Computer(s) to report on reboot history.
        [Parameter(Position=0)]
        [string[]]
        $ComputerName=$env:COMPUTERNAME,
        
        [switch]$SkipCheck
    )
    
    begin {
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            if (-not ( Test-Connection $Computer -Count 2 -Quiet -ea 0 ) -and !$SkipCheck){
                Write-Warning "The device named $Computer is not responding to an Echo request!"
            }else{
        
            Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                logname='System'; id=1074} |
                    ForEach-Object {
                        $rv = New-Object PSObject |
                            Select-Object Date,
                                        User,
                                        Action,
                                        Process,
                                        Reason,
                                        ReasonCode,
                                        Comment
                        $rv.Date = $_.TimeCreated
                        $rv.User = $_.Properties[6].Value
                        $rv.Process = $_.Properties[0].Value -replace '^.*\\' -replace '\s.*$'
                        $rv.Action = $_.Properties[4].Value
                        $rv.Reason = $_.Properties[2].Value
                        $rv.ReasonCode = $_.Properties[3].Value
                        $rv.Comment = $_.Properties[5].Value
                        $rv
                    }
            }
        }
    }
    
    end {
    }
}
