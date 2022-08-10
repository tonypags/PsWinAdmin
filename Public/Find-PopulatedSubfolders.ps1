function Find-PopulatedSubfolders {
    <#
    .SYNOPSIS
    Lists folders with large number of files
    .PARAMETER ConfigPath
    A file for the ConfigPath parameter should include
    1 path per line, a string (optional wildcard-anywhere) for
    the Resolve-Path cmdlet. These paths resolve to multiple
    root folders, and are then recursed to finnd ANY folder
    with more than the given number of $Items.
    .EXAMPLE
    Find-PopulatedSubfolders -ConfigPath $ConfigPath -Items 500
    .NOTES
    At some point a 2nd parameter set can be added to take
    an array of paths instead of a file import.

    Sample object:
    Name = [string]
    FullName = [string]
    Items = [int]
    TotalSize = [int64]
    #>
    [CmdletBinding()]
    param(

        # Only return folders with this many file children
        [Parameter(Mandatory)]
        [int]
        $Items,

        # File with Resolve-Path list of paths
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]
        $ConfigPath

    )#END: param()

    # Import Path [string[]]s
    $Parents = Get-Content -Path $ConfigPath | Where-Object {
        $_ -notlike '*#*' -and
        -not [string]::isnullorempty($_)
    }

    # Resolve Path [object[]]s and expand [string[]]s
    $resolvedParents = foreach ($folder in $Parents) {
        (Resolve-Path -Path $folder -ea Ignore).Path
    }

    # Recurse Child [object[]]s (folders only) and expand [string[]]s
    $recursedParents = foreach ($folder in $resolvedParents) {
        (Get-ChildItem -Path $folder -Recurse -Directory).FullName |
        Where-Object {$_}
    }

    # Set-Location "$($env:SYSTEMDRIVE)\"
    $Violations = [System.Collections.Generic.List[System.Object]]@()
    foreach ($path in $recursedParents) {

        $files = @(Get-ChildItem -Path $path -File -ea 0 -ev 'errDir')

        if ($path -and $files.Count -ge $Items) {

            $leaf = Split-Path $path -Leaf

            $TotalSize = [math]::Round(
                (
                    ($files | ForEach-Object {$_.length} |
                    Measure-Object -Sum).Sum / 1MB
                ),
                2
            )
            $Violations.Add([pscustomobject]@{
                Items     = [int]($files.Count)
                Name      = $leaf
                TotalSize = $TotalSize
                FullName  = $path
            })
        }
    }

    $Violations

}#END: function Find-PopulatedSubfolders {}
