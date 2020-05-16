function Find-FileByExtension
{
    <#
    .SYNOPSIS
    Searches the computer local disks and finds any files of the given type.
    #>

    param (
        # File extension to find on the computers' local disks.
        [Parameter(Mandatory=$true,
            Position=0)]
        [string]
        $Extension,

        # The target computer(s) to search for files.
        [Parameter()]
        [string[]]
        $ComputerName = @($env:COMPUTERNAME)
    )    

    Begin {}

    Process {

        # Ensure the extension string is in the correct format
        if ($Extension -notlike '.*') {
            $Extension = '.' + $Extension
        }

        Foreach ($Computer in $ComputerName) {

            Write-Verbose "Searching for $($Extension.Trim('.')) files under all local disks on $($Computer)"

            Foreach ($Disk in (Get-CimLocalDisk).DeviceID) {
                Get-ChildItem $Disk -Filter "*$($Extension)" -Force -Recurse -ea 0
            }

        }

    }
        
    End {}
}
