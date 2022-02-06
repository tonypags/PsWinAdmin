function Format-Json {
    <#
    .SYNOPSIS
    Prettifies JSON output.
    .DESCRIPTION
    Reformats a JSON string so the output looks better than what ConvertTo-Json outputs.
    .PARAMETER Json
    Required: [string] The JSON text to Beautify.
    .PARAMETER Compress
    Optional: Write-Outputs the json string compressed.
    .PARAMETER Indentation
    Optional: The number of spaces (1..1024) to use for indentation. Defaults to 4.
    .PARAMETER AsArray
    Optional: If set, the output will be in the form of a string array, otherwise a single string is output.
    .EXAMPLE
    $json | ConvertTo-Json  | Format-Json -Indentation 2
    .NOTES
    Borrowed from Theo: https://stackoverflow.com/a/56324939
    #>
    [CmdletBinding(DefaultParameterSetName = 'Beautify')]
    Param(
        [Parameter(
            Mandatory,
            Position = 0, 
            ValueFromPipeline
        )]
        [string]
        $Json,

        [Parameter(ParameterSetName = 'Compress')]
        [switch]
        $Compress,

        [Parameter(ParameterSetName = 'Beautify')]
        [ValidateRange(1, 1024)]
        [int16]
        $Indentation = 4,

        [Parameter(ParameterSetName = 'Beautify')]
        [switch]
        $AsArray
    )

    if ($PSCmdlet.ParameterSetName -eq 'Compress') {

        ($Json | ConvertFrom-Json) | ConvertTo-Json -Depth 99 -Compress

    } elseif ($PSCmdlet.ParameterSetName -eq 'Beautify') {

        # If the input JSON text has been created with ConvertTo-Json -Compress
        # then we first need to reconvert it without compression
        if ($Json -notmatch '\r?\n') {
            $Json = ($Json | ConvertFrom-Json) | ConvertTo-Json -Depth 99
        }
    
        $indent = 0
        $regexUnlessQuoted = '(?=([^"]*"[^"]*")*[^"]*$)'
    
        $result = $Json -split '\r?\n' |
            ForEach-Object {
                # If the line contains a ] or } character, 
                # we need to decrement the indentation level unless it is inside quotes.
                if ($_ -match "[}\]]$regexUnlessQuoted") {
                    $indent = [Math]::Max($indent - $Indentation, 0)
                }
    
                # Replace all colon-space combinations by ": " unless it is inside quotes.
                $line = (' ' * $indent) + ($_.TrimStart() -replace ":\s+$regexUnlessQuoted", ': ')
    
                # If the line contains a [ or { character, 
                # we need to increment the indentation level unless it is inside quotes.
                if ($_ -match "[\{\[]$regexUnlessQuoted") {
                    $indent += $Indentation
                }
    
                $line
            }
    
        if ($AsArray) {
            
            $result
        
        } else {

            $result -Join [Environment]::NewLine

        }

    } else {
        Write-Warning "Unhandled ParameterSetName: $($PSCmdlet.ParameterSetName)"
    }

}
