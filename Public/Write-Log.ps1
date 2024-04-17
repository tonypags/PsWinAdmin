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
    .INPUTS
    The message contents to add to the log file can be piped 
    into the function as a single string value. 
    #>
    [CmdletBinding()]
    [Alias('log')]
    Param
    (
        # Location of the log file
        [Parameter(Mandatory=$true,
                  Position=0)]
        [ValidatePattern('.+\.log|.+\.txt')]
        [string]
        $FilePath,

        # The message contents to add to the log file
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=1)]
        [Alias('Message')]
        [string]
        $Content,

       # Define the datestamp string, defaults to DiDictionary
       [string]
       [ValidateNotNull()]
       [ValidateNotNullOrEmpty()]
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
        if(Test-Path $FilePath){}else{
            New-Item -ItemType File -Path $FilePath -Force | 
                Out-Null
        }

        # Find the local domain
        $lclDomain = Try {
            (Get-CimInstance Win32_ComputerSystem -ea Stop).Domain.ToUpper()
        } Catch {
            $env:USERDNSDOMAIN
        }

        # Build the string, starting with the date and type
        [string]$strContent = $null
        $strContent = $strContent + "$((Get-Date).ToString($TimestampFormat)) "
        $strContent = $strContent + "[$($EntryType)]: "
        $strContent = $strContent + (whoami) + '@'
        $strContent = $strContent + $env:COMPUTERNAME + '.'
        $strContent = $strContent + $lclDomain + ' '
        $strContent = $strContent + $Content

        # Add Content to the file.
        Try {
            $Splat = @{
                Value = $strContent
                Path = $FilePath
                Force = $true
            }
            Add-Content @Splat -ea Stop -ev LogError

        } Catch {
            
            if (-not $Quiet -and -not $WriteLogErrorHappened) {
                Write-Error "Logging error: $($LogError.ErrorRecord)`n"
                Set-Variable -Name 'WriteLogErrorHappened' -Scope Global -Value $true # prevents multiple errors
            }
        }

        if ($PassHost.IsPresent) { Write-Host $Content }
    }
}
