#region Presentation Prep

exit # do not run this

<#
PowerShell Toolmaking with Advanced Functions and Script Modules
Presentation from SQL Saturday #521 Atlanta 2016
Author:  Mike F Robbins
Website: http://mikefrobbins.com
Twitter: @mikefrobbins

Edited by Tony Pagliaro:
- I enjoyed this enum section: https://www.youtube.com/watch?v=oxalhLN_r8o&t=2500s
- I found the code and will make a full commit before removing any non-enum content.
- I removed it!
#>

#Safety in case the entire script is run instead of a selection

break

#Set PowerShell ISE Zoom to 175%

$psISE.Options.Zoom = 175






#Use an emuneration to validate parameter input
function Test-MrConsoleColorValidation {
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [System.ConsoleColor[]]$Color = [System.Enum]::GetValues([System.ConsoleColor])
    )
    Write-Output $Color
}

Test-MrConsoleColorValidation
Test-MrConsoleColorValidation -Color Blue, DarkBlue
Test-MrConsoleColorValidation -Color Pink
Test-MrConsoleColorValidation -

#To find enumerations, download Get-Type from the TechNet script repository (written by Warren Frame aka Cookie Monster)
#https://gallery.technet.microsoft.com/scriptcenter/Get-Type-Get-exported-fee19cf7

Get-Type -BaseType System.Enum
[System.Enum]::GetValues([System.DayOfWeek])

#Use the IPAddress type accelerator to validate IPv4 and IPv6 addresses

function Test-MrIPAddress {
    [CmdletBinding()]
    param (
        [ipaddress]$IPAddress
    )
    Write-Output $IPAddress
}

Test-MrIPAddress -IPAddress 10.1.1.255
Test-MrIPAddress -IPAddress 10.1.1.256
Test-MrIPAddress -IPAddress 2001:db8::ff00:42:8329
Test-MrIPAddress -IPAddress 2001:db8:::ff00:42:8329

#Use the following to find type accelerators:
[psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get |
Sort-Object -Property Value

#If you have the PowerShell Community Extensions, you can also use the following:
#[accelerators]::get


#help about_Comment_Based_Help -Full







#region Additional Resources
#help about_Requires -Full
#help about_Splatting -Full
#help about_Throw -Full
#help about_Break -Full
#help about_Continue -Full
#help about_Return -Full
#help about_Functions_OutputTypeAttribute -Full
#help about_If -Full

#PowerShell Practice and Style Guide
#https://github.com/PoshCode/PowerShellPracticeAndStyle

#Walkthrough: An example of how I write PowerShell functions
#http://mikefrobbins.com/2015/06/19/walkthrough-an-example-of-how-i-write-powershell-functions/

#Free eBook on PowerShell Advanced Functions
#http://mikefrobbins.com/2015/04/17/free-ebook-on-powershell-advanced-functions/

#Free eBooks on PowerShell.org
#http://powershell.org/freebooks/

#endregion
