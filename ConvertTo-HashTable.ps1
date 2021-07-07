function ConvertTo-HashTable {
    <#
    .SYNOPSIS
    Converts text file content like a PSD1 file into a hashtable.
    .PARAMETER Path
    The file containing the hash table, ex: PSD1 file
    .PARAMETER HashTableContent
    The hashtable represented as a string (array)
    .EXAMPLE
    $hash = ConvertTo-HashTable -HashTableContent (Get-Content $filepath)
    .EXAMPLE
    $hash = Get-Content $filepath | ConvertTo-HashTable
    .EXAMPLE
    $hash = ConvertTo-HashTable -Path ./filename.psd1
    #>
    [CmdletBinding(DefaultParameterSetName='byContent')]
    param (

        # The file containing the hash table, ex: PSD1 file
        [Parameter(ParameterSetName='byPath')]
        [string]
        $Path,

        # The hashtable represented as a string (array)
        [Parameter(ValueFromPipeline,ParameterSetName='byContent')]
        [string[]]
        $HashTableContent

    )
    
    begin {
        [string]$Content = $null
    }
    
    process {

        if ($PSCmdlet.ParameterSetName -eq 'byContent') {

            foreach ($line in $HashTableContent) {
                $Content = $Content + $line + "`n"
            }
            
        } elseif ($PSCmdlet.ParameterSetName -eq 'byPath') {

            Try {
                Write-Verbose "Content being parsed from config file: [$($Path)]."
                $content = Get-Content -Path $Path -Raw -ErrorAction Stop
            } Catch {
                throw "Unable to parse file content: $($Error[0].Exception.Message)"
            }

        }

    }
    
    end {

        # Define a hashtable for all tasks (KEY=pathToParentFolder, VALUE=retentionInDays)
        Try {
            $scriptBlock = [scriptblock]::Create($content)
            $scriptBlock.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
            & $scriptBlock
        } Catch {
            throw "Unable to execute parsed text as a scriptblock!"
        }

    }

}#END: function ConvertTo-HashTable {}
