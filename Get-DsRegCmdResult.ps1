function Get-DsRegCmdStatus {
    <#
    .SYNOPSIS
    Returns DSREGCMD status information as a PowerShell object.
    .DESCRIPTION
    Returns DSREGCMD status information as a PowerShell object, optionally from an existing output dump to text file.
    .EXAMPLE
    Get-DsRegDcmStatus
    Runs the Command live and parses its results.
    .EXAMPLE
    Get-DsRegDcmStatus -InLogPath C:\temp\testout.txt
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
        [Parameter(ParameterSetName='InLogPath',
            Position=0)]
        [AllowNull()]
        [string]
        $InLogPath,

        [Parameter(ParameterSetName='OutLogPath',
            Position=1)]
        [AllowNull()]
        [string]
        $OutLogPath,

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
    $ptnEndOfSection = '\+----'                   # If a line starts with (+) it's a separatros, the end of a section

    # These will track the depth of the level 2 properties
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
            
            # Next import a property name and value until we get a null line
            for ($j = $CurrentSectionLine; $thisLine -notmatch $ptnEndOfSection; $j++) {
                
                if ($thisLine.Trim()) {

                    # Find the name and value for this line
                    $PropertyName = [regex]::Match($thisLine, $ptnPropertyName).Groups[1].Value.Trim()
                    $PropertyValue = [regex]::Match($thisLine, $ptnPropertyValue).Groups[1].Value.Trim()
                    $thisColumnOrder += $PropertyName

                    # Add these to the current hash
                    #Write-Debug "About to add $PropertyName with value $PropertyValue"
                    $thisHash.Add($PropertyName, $PropertyValue)
                    $thisLine = $Status[$j+1]

                } elseif ($j+1 -ge $Status.Count) {

                    Write-Debug "Reached end of content. $($j+1) >= $($Status.Count)"
                    $i = $j
                    break

                } else {

                    $thisLine = $Status[$j+1]
                    #Write-Debug "Found a null `$thisLine."

                }

            }# end for ($j = $CurrentSectionLine; $thisLine -match $ptnPropertyLine; $j++)
            $i = $j

            # Add the section and it's child to the output
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
            New-Item -ItemType Directory -Path $LogParent -Force
        }
        
        $Status | Out-File -FilePath $OutLogPath -Force
        
    }# end if ($OutLogPath)

    # Sned object to pipeline
    [pscustomobject]$OutputHash | Select-Object $ColumnOrder

}# end function Get-DsRegDcmStatus

