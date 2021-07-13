function ConvertTo-HashTable {
    <#
    .SYNOPSIS
    Converts text file content like a PSD1 file into a hashtable.
    .DESCRIPTION
    Convert raw text contained in a PSD1 file and
    creates a hashtable object on the pipeline, after
    running a basic verification routine on the logic in the file.
    .PARAMETER Path
    A file containing the hash table, ex: PSD1 file
    .PARAMETER HashTableContent
    The hashtable represented as a string (or array)
    .PARAMETER Force
    Does not check the loic before executing the code contained in the PSD1 file.
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
        [ValidateScript({Test-Path $_})]
        [string]
        $Path,

        # The hashtable represented as a string (array)
        [Parameter(ValueFromPipeline,ParameterSetName='byContent')]
        [string[]]
        $HashTableContent,

        # Does not check the loic before executing the code contained in the PSD1 file.
        [Parameter()]
        [switch]
        $Force

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
            if ($Force) {} else {
                $scriptBlock.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
            }
            & $scriptBlock
        } Catch {
            throw "Unable to execute parsed text as a scriptblock!"
        }

    }

}#END: function ConvertTo-HashTable {}
