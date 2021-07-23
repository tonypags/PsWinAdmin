function Remove-FilePastRetention {
    <#
    .SYNOPSIS
    Removes old files by date, as specified in a confg file.
    .PARAMETER ConfigPath
    This file must contain a hash table for all paths
    (KEY=pathToParentFolder, VALUE=retentionInDays)
    .PARAMETER Recurse
    Remove all items matching the config in all subfolders
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Path to the config file
        [Parameter()]
        [string]
        $ConfigPath = (Join-Path $PSScriptRoot 'retention.cfg.psd1'),

        # Remove all items matching the config in all subfolders
        [Parameter()]
        [switch]
        $Recurse
    )

    Confirm-RequiresAdmin

    # Define a hashtable for all tasks (KEY=pathToParentFolder, VALUE=retentionInDays)
    Try {
        Write-Verbose "Content being parsed from config file: [$($ConfigPath)]."
        $Tasks = Get-Content -Path $ConfigPath -ErrorAction Stop | ConvertTo-HashTable
    } Catch {
        Write-Warning "File Missing: [$($ConfigPath)]"
        Write-Warning "Error: [$($Error[0].Exception.Message)]"
        Write-Warning "Try running the New-RetentionConfig function"
        throw "File Missing: [$($ConfigPath)]"
    }

    # Check that the hashtable is not null
    if ($Tasks) {} else {
        Write-Warning "File has no tasks: [$($ConfigPath)]"
        Write-Warning "Try opening this file and reviewing the helpful comments."
        throw "File has no tasks: [$($ConfigPath)]"
    }

    $Now = Get-Date

    # Loop thru each path and remove items
    Foreach ($task in @($Tasks.Keys)) {

        $ret = $Tasks[$task]
        $Path = $task

        # Find files 
        $FilesToDelete = @()
        Write-Verbose "Finding files older than $($ret) days under $($Path)."
        $FilesToDelete += Get-ChildItem $Path -File -Recurse |
            Where-Object {$_.LastWriteTime -lt $Now.AddDays(-$ret)}

        # Action files
        $props = @{
            Recurse = $Recurse
            Force = $true
            WhatIf = $WhatIfPreference
            Verbose = $VerbosePreference
        }
        Write-Debug "`$FilesToDelete & `$Path & `$ret variables populated."
        if ($FilesToDelete) {

            Write-Verbose "Deleting $(@($FilesToDelete).count
                ) files older than $($ret) days under $($Path)."
            $FilesToDelete | Remove-Item @props

        } else {
            Write-Verbose "No files older than $($ret) days under $($Path)."
        }
    
    }

}#END: function Remove-FilePastRetention {}
