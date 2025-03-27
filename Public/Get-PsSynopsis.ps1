function Get-PsSynopsis {
    <#
    .SYNOPSIS
    Locates the help notes for synopsis in a given script
    #>
    param([string]$ScriptPath)

    $ptnHelpMarkers = '^\s*\.\w|#>'

    $AllContent = Get-Content $ScriptPath
    $AllMatches = $AllContent | select-string $ptnHelpMarkers

    $allLineNumbers = @($AllMatches.LineNumber)
    $synopsis = $AllMatches | Where-Object {$_.Line -eq '.SYNOPSIS'}

    if ($synopsis) {

        $idxSynopsis = $allLineNumbers.IndexOf($synopsis.LineNumber)
        $idxNextItem = $idxSynopsis + 1

        $synLineNumber = $AllMatches[$idxSynopsis].LineNumber
        $nxtLineNumber = $AllMatches[$idxNextItem].LineNumber

        # next line number is minus 2, because we minus 1 for the index, and another 1 for the line above it
        $synopsisContent = $AllContent[$synLineNumber..($nxtLineNumber - 2)] -join ' ' -replace '\s\s+',' '
        $synopsisContent

    } else {
        Write-Warning "No Synopsis found for script: $ScriptPath"
    }

}#END: function Get-PsSynopsis
