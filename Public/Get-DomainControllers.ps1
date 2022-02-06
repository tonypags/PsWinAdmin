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

        [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain(
        ).DomainControllers.Name -replace '\..*'

    } Catch {

        Write-Warning "Could not enumerate DC list."
        Write-Warning "Make sure this device is a domain-joined computer or server."
        break

    }
    
}
