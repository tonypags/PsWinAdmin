function Confirm-RequiresAdmin {

    <#
    .SYNOPSIS
    Confirms environment has local admin privilages.
    .DESCRIPTION
    Older versions of PowerShell do not support the #Requires -RunAsAdministrator feature. This function fills the gap.
    .EXAMPLE
    Confirm-RequiresAdmin
    Call this function at the top of your script. AN error will be thrown in the same manner as the modern feature.
    .NOTES
    https://github.com/OfficeDev/Office-IT-Pro-Deployment-Scripts
    #>

    param()


    If (-NOT 
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
            ).IsInRole(`
                [Security.Principal.WindowsBuiltInRole] "Administrator"
            )
        )
    {
        throw "Administrator rights are required to run this script!"
    }

}

