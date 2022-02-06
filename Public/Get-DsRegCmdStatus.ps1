
function Get-DsRegCmdStatus {

    <#
    .SYNOPSIS
    Returns DSREGCMD status information as a PowerShell object.
    .DESCRIPTION
    Returns DSREGCMD status information as a PowerShell object, optionally from an existing output dump to text file.
    .PARAMETER InLogPath
    Runs a test on a previously created log file.
    .PARAMETER OutLogPath
    Export the result to a txt file.
    .PARAMETER DefaultCase
    Placeholder for parameter set, value has no effect on logic.
    .EXAMPLE
    Get-DsRegCmdStatus
    
    Runs the Command live and parses its results.
    .EXAMPLE
    (Get-DsRegCmdStatus |
        Where-Object {$_.'Device State'.AzureAdJoined -eq 'YES'}
    ).'Tenant Details'.TenantName

    Runs the Command live and returns only the Tenant Name.
    .EXAMPLE
    Get-DsRegCmdStatus -InLogPath C:\temp\testout.txt
    
    Parses previously captured results.
    .NOTES
    Command line help output, for reference:
 
    DSREGCMD switches
                 /? : Displays the help message for DSREGCMD
            /status : Displays the device join status
        /status_old : Displays the device join status in old format
              /join : Schedules and monitors the Autojoin task to Hybrid Join the device
             /leave : Performs Hybrid Unjoin
             /debug : Displays debug messages
 
    #>
    
    [CmdletBinding(DefaultParameterSetName='DefaultCase')]
    param (
        
        # Runs a test on a previously created log file.
        [Parameter(ParameterSetName='InLogPath',
            Position=0)]
        [AllowNull()]
        [string]
        $InLogPath,

        # Export the result to a txt file.
        [Parameter(ParameterSetName='OutLogPath',
            Position=1)]
        [AllowNull()]
        [string]
        $OutLogPath,

        # Placeholder for parameter set, value has no effect on logic.
        [Parameter(ParameterSetName='DefaultCase')]
        [AllowNull()]
        [string]
        $DefaultCase
        
    )
        
    if ($InLogPath) {
        # Get content from existing file
        $Status = Get-Content -Path $InLogPath -ea Stop
    } else {
        # Run command and capture result
        $Status = dsregcmd.exe /status
    }


    $ptnHeaderLine = '\|\s\w.*'                   # If a line starts with a pipe (|) that is a heading
    $ptnSectionName = '\|\s([\w\s\d]+?)\s\s+?\|'  # Grab the heading name
    $ptnPropertyName = '\s*?(.+?)\s\:\s.*'        # Grab the property name
    $ptnPropertyValue = '\s+?[\w\s]+?\s\:\s(.*)$' # Grab the property value
    $ptnEndOfSection = '\+----'                   # If a line starts with (+) it's a separator, or the end of a section

    # These will help track the progress of 1st level properties (sections)
    $CurrentSectionLine = 0
    $thisLine = $null
    $OutputHash = New-Object -TypeName System.Collections.Hashtable
    $ColumnOrder = @()


    # Parse the result
    for ($i = 0; $i -lt $Status.Count; $i++) {
        
        # for loop will Read each line and make a new top-level property name
        if ($Status[$i] -match $ptnHeaderLine) {
            
            $SectionName = [regex]::Match($Status[$i], $ptnSectionName).Groups[1].Value
            $ColumnOrder += $SectionName
            
            # Then look for the the next end of section and use ConvertFrom-StringData cmdlet
            $CurrentSectionLine = $i + 3
            $thisLine = $Status[$CurrentSectionLine]
            $thisHash = New-Object -TypeName System.Collections.Hashtable
            $thisColumnOrder = @()
            
            # Next import a property name and value until we get to the 'end of section' line
            for ($j = $CurrentSectionLine; $thisLine -notmatch $ptnEndOfSection; $j++) {
                
                if ($thisLine.Trim()) {

                    # Find the name and value for this line
                    $PropertyName = [regex]::Match($thisLine, $ptnPropertyName).Groups[1].Value.Trim()
                    $PropertyValue = [regex]::Match($thisLine, $ptnPropertyValue).Groups[1].Value.Trim()
                    $thisColumnOrder += $PropertyName

                    # Add these to the current hash
                    Write-Debug "About to add $PropertyName with value $PropertyValue"
                    $thisHash.Add($PropertyName, $PropertyValue)
                    $thisLine = $Status[$j+1]

                } elseif ($j+1 -ge $Status.Count) {

                    Write-Debug "Reached end of content. $($j+1) >= $($Status.Count)"
                    $i = $j
                    break

                } else {

                    $thisLine = $Status[$j+1]
                    Write-Debug "Found a null `$thisLine."

                }

            }# end for ($j = $CurrentSectionLine; $thisLine -match $ptnPropertyLine; $j++)
            
            # Update $i value after the nested for loop moved further down the raw content of $Status using $j
            $i = $j

            # Add the completed section and its children as psobject to the output
            $OutputHash.Add($SectionName, (
                [pscustomobject]$thisHash | Select-Object $thisColumnOrder
            ))
            Write-Debug "`$OutputHash has been updated."
                
        }# end if ($Status[$i] -match $ptnHeaderLine)
    
    } #end for ($i = 0; $i -lt $Status.Count; $i++)

    
    # Add the raw output as well
    $OutputHash.Add('RawContent', $Status)
    Write-Debug "`$OutputHash has been updated."


    # Output to log if given a path
    if ($OutLogPath) {
        
        # Ensure the parent folder exists
        $LogParent = Split-Path $OutLogPath -Parent
        if (-not (Test-Path $LogParent)) {
            New-Item -ItemType Directory -Path $LogParent -Force | Out-Null
            Write-Verbose "Created folder: $LogParent"
        }
        
        $Status | Out-File -FilePath $OutLogPath -Force
        
    }# end if ($OutLogPath)

    # Send object to pipeline
    [pscustomobject]$OutputHash | Select-Object $ColumnOrder

}# end function Get-DsRegCmdStatus

