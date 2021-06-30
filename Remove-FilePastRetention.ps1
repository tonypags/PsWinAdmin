function Remove-FilePastRetention {
    <#
    .SYNOPSIS
    Removes old files by date, as specified in a confg file.
    .PARAMETER ConfigPath
    This file must contain a hash table for all paths (KEY=pathToParentFolder, VALUE=retentionInDays)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Path to the config file
        [Parameter()]
        [string]
        $ConfigPath = (Join-Path $PSScriptRoot 'retention.cfg.psd1')
    )

    Confirm-RequiresAdmin

    # Define a hashtable for all tasks (KEY=pathToParentFolder, VALUE=retentionInDays)
    Try {
        $content = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop
        $scriptBlock = [scriptblock]::Create($content)
        $scriptBlock.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
        $Tasks = (& $scriptBlock)
    } Catch {
        Write-Warning "File Missing: [$($ConfigPath)]"
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

    # Loop thru each show and remove items
    Foreach ($task in @($Tasks.Keys)) {

        $ret = $Tasks[$task]
        $Path = $task

        # Look for video files 
        $FilesToDelete = @()
        $FilesToDelete += Get-ChildItem $Path -File -Recurse |
            Where-Object {$_.LastWriteTime -lt $Now.AddDays(-$ret)} |
            Where-Object {$Ext -contains $_.Extension}

        Write-Debug "`$FilesToDelete & `$Path variables populated."
        Write-Verbose "Deleting files older than $($ret) days under $($Path)."
        $FilesToDelete | Remove-Item -Force
    
    }

}#END: function Remove-FilePastRetention {}
