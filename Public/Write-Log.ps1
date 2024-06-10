function Write-Log
{
    <#
    .Synopsis
    Easily write to a log file within your scripts. 
    .DESCRIPTION
    Allows a programmer to create consistant, organized 
    log entries. Outputs timestamp and tags for entry 
    type (ie: info, error)
    .PARAMETER FilePath
    Location of the log file. 
    .PARAMETER Content
    The message contents to add to the log file. 
    .PARAMETER TimestampFormat
    Define the datestamp string, defaults to 'yyyy\-MM\-dd\_HH\:mm\:ss'
    .PARAMETER EntryType
    Type of message, allowed are DEBUG, INFO*, WARN, ERROR, FAIL
    .EXAMPLE
    $LogSplat = @{
        FilePath = 'C:\Temp\Log.txt'
        TimestampFormat = 'yyyy\-MM\-dd\_HH\:mm\:ss'
        EntryType = 'INFO'
    }
    [string]$var | log @LogSplat 
    .EXAMPLE
    [string]$var | log @LogSplat -EntryType Error
    .EXAMPLE
    $FilePath = 'c:\temp\log.txt'
    $streamWriter = New-Object System.IO.StreamWriter($filePath)
    $LogSplat = @{
        StreamWriter = $streamWriter
        TimestampFormat = 'yyyy\-MM\-dd\_HH\:mm\:ss'
        EntryType = 'INFO'
    }
    'Message here' | Write-Log @LogSplat 
    $streamWriter.Close()
    .INPUTS
    The message contents to add to the log file can be piped 
    into the function as a single string value. 
    #>
    [CmdletBinding(DefaultParameterSetName='Slow')]
    [Alias('log')]
    Param
    (
        # Location of the log file
        [Parameter(ParameterSetName='Slow',
                  Mandatory,Position=0)]
        [ValidatePattern('.+\.log|.+\.txt')]
        [string]
        $FilePath,

        # $streamWriter = New-Object System.IO.StreamWriter($filePath) ; $streamWriter.Close()
        [Parameter(ParameterSetName='Fast')]
        [System.IO.StreamWriter]
        $StreamWriter,

        # The message contents to add to the log file
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=1)]
        [Alias('Message')]
        [string]
        $Content,

       # Define the datestamp string, defaults to DiDictionary
       [Parameter()]
       [ValidateNotNull()]
       [ValidateNotNullOrEmpty()]
       [string]
       $TimestampFormat = 'yyyy-MM-dd_HH:mm:ss.fff',

       # Type of message, allowed are DEBUG, INFO*, WARN, ERROR, FAIL, etc
       [Parameter()]
       [ValidateSet("DEBUG", "VERBOSE", "INFO", "WARN", "ERROR", "FAIL", "CRITICAL")]
       [ValidateNotNull()]
       [ValidateNotNullOrEmpty()]
       [string]
       $EntryType = 'INFO',

       [Parameter()]
       [switch]
       $Quiet,

       [Parameter()]
       [switch]
       $PassHost
    )

    Process {
        $EntryType = $EntryType.ToUpper()
        
        # Make sure the file exists
        if ($PSCmdlet.ParameterSetName -eq 'Fast') {$FilePath = $streamWriter.BaseStream.Name}
        if(Test-Path $FilePath -ea 0){}else{
            New-Item -ItemType File -Path $FilePath -Force | Out-Null
        }

        # Build the string, starting with the date and type
        [string]$strContent = "$((Get-Date).ToString($TimestampFormat)) [$($EntryType)]: $(whoami)@$($env:COMPUTERNAME) $Content"

        # Add Content to the file.
        Try {
            $origEAP = $ErrorActionPreference
            if ($PSCmdlet.ParameterSetName -eq 'Slow') {
                $Splat = @{
                    Value = $strContent
                    Path = $FilePath
                    Force = $true
                }
                Add-Content @Splat -ea Stop -ev LogError        # SLOW
            } elseif ($PSCmdlet.ParameterSetName -eq 'Fast') {
                $ErrorActionPreference = 'Stop'
                $streamWriter.WriteLine($strContent)            # FAST
                $ErrorActionPreference = $origEAP
            } else {
                throw "Unhandled ParameterSetName: $($PSCmdlet.ParameterSetName)"
            }
        } Catch {
            $ErrorActionPreference = $origEAP

            if (-not $Quiet -and -not $WriteLogErrorHappened) {
                Write-Error "Logging error: $($LogError.ErrorRecord)`n"
                Set-Variable -Name 'WriteLogErrorHappened' -Scope Global -Value $true # prevents multiple errors
            }
        }

        if ($PassHost.IsPresent) { Write-Host $Content }
    }
}
