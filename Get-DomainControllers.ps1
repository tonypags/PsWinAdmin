function Get-DomainControllers {
    <#
    .SYNOPSIS
    Returns an array of DC server names.
    .DESCRIPTION
    Returns an array of hostnames found to be listed as DCs in the netdom command.
    .EXAMPLE
    Get-DomainControllers
    DC1
    DC2
    .NOTES
    netdom command is for servers only.
    This is OK for this command for now, but future usage may require it work on Workstations. 
    Build a new version of this function that will leverage ADSI commands.
    #>

    Try {

        $DCs = & netdom query dc
        $DCs[2..($DCs.count -3)]

    } Catch {

        Write-Warning "Could not enumerate DC list."
        Write-Warning "Make sure this device is a domain controller."
        break

    }
    
}
