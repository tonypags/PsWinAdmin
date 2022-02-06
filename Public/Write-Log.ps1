﻿function Write-Log
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
       $TimestampFormat = 'yyyy-MM-dd_HH:mm:ss',

       # Type of message, allowed are DEBUG, INFO*, WARN, ERROR, FAIL, etc
       [Parameter()]
       [ValidateSet("DEBUG", "VERBOSE", "INFO", "WARN", "ERROR", "FAIL", "CRITICAL")]
       [ValidateNotNull()]
       [ValidateNotNullOrEmpty()]
       [string]
       $EntryType = 'INFO'
    )

    Begin
    {
    }
    Process
    {
        $EntryType = $EntryType.ToUpper()
        
        # Make sure the file exists
        if(Test-Path $FilePath){}else{
            New-Item -ItemType File -Path $FilePath -Force | 
                Out-Null
        }

        # Build the string, starting with the date and type
        [string]$strContent = $null
        $strContent = $strContent + "$((Get-Date).ToString($TimestampFormat)) "
        $strContent = $strContent + "[$($EntryType)]: "
        $strContent = $strContent + $env:USERNAME + '@'
        $strContent = $strContent + $env:COMPUTERNAME + '.'
        $strContent = $strContent + $env:USERDNSDOMAIN + ' '
        $strContent = $strContent + $Content

        # Add Content to the file.
        Try{
            $Splat = @{
                Value = $strContent
                Path = $FilePath
                Force = $true
                ErrorAction = 'Stop'
                ErrorVariable = 'LogError'
            }
            Add-Content @Splat
        }
        Catch{
            
            if(!$WriteLogErrorHappened){
                Write-Host "Logging error:" -ForegroundColor Gray
                Write-Host "$($LogError.ErrorRecord)`n" -ForegroundColor DarkCyan
                Set-Variable -Name 'WriteLogErrorHappened' -Scope Global -Value $true
            }
        }

    }
    End
    {
    }
}
