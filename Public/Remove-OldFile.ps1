Function Remove-OldFile 
{
    <#
    .SYNOPSIS
    Deletes old files. 
    .DESCRIPTION
    Deletes old files in a given folder which are older than a given date.
    .EXAMPLE
    Remove-OldFile -Path "C:\Program Files\Symantec\Symantec Endpoint Protection Manager\data\outbox\ImportPackage" -Retention 14 -whatif
    #>

    param (
        # Folder where files in question are located
        [Parameter(Mandatory=$true)]
        [string]$Path,

        # Number of Days old a file must be to be deleted
        [Parameter(Mandatory=$true)]
        [int]$Retention,

        [Parameter()]
        [switch]$WhatIf
    )

    ### Get the drive space baseline value
    $DriveLetter = (Resolve-Path $Path) -replace '\\.*'
    $oDriveSpace = Get-WmiObject win32_logicaldisk | 
                        where { $_.DeviceID -eq $DriveLetter } |
                        select -expand FreeSpace | %{
                            [math]::Round(( $_ / 1MB),0) 
                        }

    ### BEGIN PERFORM ACTION ###
    $FilesToDelete = Get-ChildItem -Path $Path | 
                        Where {$_.Mode -notlike "*d*"  } |
                        Where {$_.LastAccessTime -lt ((Get-Date).AddDays(-$Retention))}
    if($WhatIf){$FilesToDelete | Remove-Item -WhatIf}
    else{$FilesToDelete | Remove-Item -Force}


    ###  END PERFORM ACTION  ###
    sleep 5

    ### Get the new drive space value
    $pDriveSpace = Get-WmiObject win32_logicaldisk | 
                        where { $_.DeviceID -eq $DriveLetter } |
                        select -expand FreeSpace | %{
                            [math]::Round(( $_ / 1MB),0) 
                        }

    ### Find any files not deleted ###
    $FilesNotDeleted = @()
    $FilesToDelete | Foreach -Process {
        $Item = $_ 
        if (Test-Path $_.FullName){
            $FilesNotDeleted += $Item 
        }
    }
    ### END Find files not deleted ###

    ### BEGIN REPORT ###
    if ($FilesNotDeleted){
        Write-Output "$($FilesNotDeleted.count) of $($FilesToDelete.count) still exist! $($oDriveSpace - $pDriveSpace)MB of space recovered."
        ### To Do: 
        # notify the issue via email, inlcude client and device name as it appears on the nable alert email.  
    } else {
        Write-Output "$($FilesToDelete.count) files deleted. $($oDriveSpace - $pDriveSpace)MB of space recovered."
        ### To Do: 
        # log files deleted
    }
    ###  END REPORT  ###

}


