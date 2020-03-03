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
    #>

    Try {

        $DCs = & netdom query dc
        $DCs[2..($DCs.count -3)]

    } Catch {

        Write-Warning "Could not enumerate DC list."
        Write-Warning "Make sure this device is a domain-joined device."
        Exit 0

    }
    
}
