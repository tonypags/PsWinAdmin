function Find-PstFullName
{
    <#
    .SYNOPSIS
    Searches the computer local disks and finds any files of type PST.
    #>

    param (
        # The target computer(s) to search for PST files.
        [Parameter()]
        [string[]]
        $ComputerName = @($env:COMPUTERNAME),

        # Option to include the Current Timestamp and file Modified Date with the output, useful when reviewing historical data in the future.
        [Parameter()]
        [switch]
        $IncludeDate,

        # Option to include the ComputerName with the output, useful when performing this search on multiple devices.
        [Parameter()]
        [switch]
        $IncludeName,

        # Option to output text when nothing is found, instead of null output.
        [Parameter()]
        [switch]
        $ShowNothingFoundMessage
    )    

    Begin {
        [datetime]$Now = Get-Date
        [string]$NowDateLabel = 'Discovered'
        [string]$strDateFormat = 'yyyy-MM-ddTHH:mm:ss'
        [string]$NothingFoundMessage = "No PST files were found. "
    }

    Process {

        Foreach ($Computer in $ComputerName) {

            # Prepare the output formatting for the file hash string
            $FormatSplat = @{
                Format = [ordered]@{
                    '~' = {"""$($_.FullName)"""}
                }
                Delimiter = ' '
                Equater = ': '
                ErrorAction = 'Stop'
            }

            # Add dates to formatting if requested
            if ($IncludeDate) {
                $FormatSplat.Format.Add('Modified',
                    {$_.LastWriteTime.ToString($strDateFormat)}
                )
                
                $FormatSplat.Format.Add($NowDateLabel,
                    {$Now.ToString($strDateFormat)}
                )

                $NothingFoundMessage = $NothingFoundMessage +
                    "$($NowDateLabel): $($Now.ToString($strDateFormat))"
            }

            
            $FindSplat = @{
                Extension = 'PST'
                ComputerName = $Computer
                ErrorAction = 'Stop'
            }
            # Sometimes CIM commands error out on the local device.
            if ($env:COMPUTERNAME -eq $Computer) {
                $FindSplat.Remove('ComputerName')
            }
            # Find the files and format the output
            Try {
                [string[]]$strSearchResult = 
                    Find-FileByExtension @FindSplat |
                        Format-ObjectToString @FormatSplat
            } Catch {
                throw (Terminating Error: $($_.Exception.Message))
            }

            # Build the final output string(s) for this computer
            if ($strSearchResult) {

                ForEach ($strResult in $strSearchResult) {
                    
                    # Empty variable to build a string from
                    [string]$thisResult = ''
                    
                    if ($IncludeName) {
                        $thisResult += "$($Computer)\"
                    }

                    $thisResult += $strResult
                    
                    Write-Output $thisResult
                    Write-Debug $thisResult

                }

            } elseif ($ShowNothingFoundMessage) {

                # Empty variable to build a string from
                [string]$Result = ''

                if ($IncludeName) {
                    $Result += "$($Computer)\"
                }

                $Result += $NothingFoundMessage

                Write-Output $Result
                Write-Debug $Result

            } else {

                Write-Verbose $NothingFoundMessage
                Write-Debug $NothingFoundMessage

            }

        }

    }

    End {}

}
