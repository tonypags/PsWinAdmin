function Get-CimLocalDisk
{
    <#
    .SYNOPSIS
    Discovers any local disk on the system
    #>

    param(
        # The target computer(s) to search for PST files.
        [Parameter()]
        [string[]]
        $ComputerName = @($env:COMPUTERNAME),
        
        [Parameter()]
        [ValidateSet('LocalDisk','DriveMap','Any')]
        $Type = 'LocalDisk'
    )

    Foreach ($Computer in $ComputerName) {

        $cimSplat = @{
            Namespace = 'root/cimv2'
            Class = 'win32_logicaldisk'
            ErrorAction = 'Stop'
        }    
        
        switch ($Type) {
            'LocalDisk' {$cimSplat.Filter = "DriveType='3'"}
            'DriveMap'  {$cimSplat.Filter = "DriveType='4'"}
            'Any' {}
            Default {Write-Warning 'Unhandled Drive Type! Returning Any...'}
        }

        # Add computername if not this computer
        if (@($env:COMPUTERNAME,'localhost') -notcontains $Computer) {
            $cimSplat.Add('ComputerName',$Computer)
        }

        Try {
            Get-CimInstance @cimSplat
        } Catch {
            Try {
                Get-WmiObject @cimSplat
            } Catch {
                Throw "Data Collection Failed: $($_.Exception.Message)"
            }
        }

    }
}
