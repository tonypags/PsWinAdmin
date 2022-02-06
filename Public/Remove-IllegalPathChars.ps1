function Remove-IllegalPathChars {
    [CmdletBinding()]
    param (
        # Path (string) on which to execute 'replace with null' operation.
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName','FilePath','ReportPath')]
        [string[]]
        $Path
    )
    Begin {
        # NEVER CHANGE THE DEFAULT VALUE! Unless Microsoft changes their policy.
        # https://docs.microsoft.com/en-us/windows/desktop/FileIO/naming-a-file
        # Regex "or" string containing the chars to remove from the file path.
        $IllegalChars = '\/|\\|\"|\*|\<|\>|\:|\||\?|[\.\s]+?$'
    }
    Process {
        foreach ($item in $Path) {
            ([string]($item -replace $IllegalChars)).Trim()
        }
    }
    End {}
}
