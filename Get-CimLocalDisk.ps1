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
        $ComputerName = @($env:COMPUTERNAME)
    )

    Foreach ($Computer in $ComputerName) {

        $cimSplat = @{
            ComputerName = $Computer
            Namespace = 'root/cimv2'
            Class = 'win32_logicaldisk'
            Filter = "DriveType='3'"
        }    

        Get-CimInstance @cimSplat

    }
}
