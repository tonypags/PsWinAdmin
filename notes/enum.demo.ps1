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
#>

#Safety in case the entire script is run instead of a selection

break

#Set PowerShell ISE Zoom to 175%

$psISE.Options.Zoom = 175

#Import the various modules that I might decide to use during the presentation

Import-Module -Name SQLPS, ActiveDirectory, MrSQL, MrToolkit

#Set location

Set-Location -Path C:\Demo

#Clear the screen

Clear-Host

#Show PowerShell version used in this demo (PowerShell version 4)

Invoke-Command -ComputerName PC01, DC01, SQL01 {
    $PSVersionTable.PSVersion
}

<#
Create a Script or Function?
Whenever possible, I prefer to write a function because to me it's more tool oriented.
I can place it in a script module, place that module in the PSModulePath and with PowerShell version 3 and higher,
I can simply call the function.
With PowerShellGet in PowerShell version 5, it's also easier to share those modules in a NuGet respository.

PowerShellGet: The BIG EASY way to discover, install, and update PowerShell modules
http://mikefrobbins.com/2015/04/23/powershellget-the-big-easy-way-to-discover-install-and-update-powershell-modules/

Don't overcomplicate things. Keep it simple and use the most straight forward way to accomplish a task.
Avoid Aliases and Positional Parameters in scripts and functions and any code that you share
Format your code for readability
Don't hard code values (don't use static values), use parameters and variables
Don't write unnecessary code even if it doesn't hurt anything because it adds unnecessary complexity
Attention to detail goes a long way when writing any PowerShell code
#>

#endregion

#region Function Naming

#Use a Pascal case name with an approved verb and a singular noun. I also recommend prefixing the noun.
#Name Example: ApprovedVerb-PrefixSingularNoun

Get-Verb | Sort-Object -Property Verb | Out-GridView

#Example of a simple function

function Get-Version {
    $PSVersionTable.PSVersion
}

Get-Version

#There's a good chance of name collisions with functions named something like Get-Version

#Prefix your noun to help prevent naming collisions 

function Get-PSVersion {
    $PSVersionTable.PSVersion
}

Get-PSVersion

#Even prefixing the noun with something like PS still has a good chance of having a name collision

#I typically prefix my function nouns with my initials. Develop a standard and stick to it

function Get-MrPSVersion {
    $PSVersionTable.PSVersion
}

Get-MrPSVersion

#Once loaded into memory, you can see functions on the Function PSDrive

Get-ChildItem -Path Function:\Get-*Version

#If you want to remove functions from your current session, remove them from the Function PSDrive

Get-ChildItem -Path Function:\Get-*Version | Remove-Item

#Verify they were indeed removed

Get-ChildItem -Path Function:\Get-*Version

#If the functions were loaded as part of a module, simply unload the module to remove them
#Remove-Module -Name <ModuleName>

#help about_Functions -Full

#endregion

#region Parameters

#Don't statically assign values! Use parameters and variables
#Parameter Naming - Use the same/similar names as the default cmdlets for your parameter names when possible

function Test-MrParameter {

    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameter -ComputerName Server01, Server02

#Why did I use ComputerName and not Computer, ServerName, or Host for my parameter name?
#Because I wanted my function standardized like the default cmdlets

function Get-MrParameterCount {
    param (
        [string[]]$ParameterName
    )

    foreach ($Parameter in $ParameterName) {
        $Results = Get-Command -ParameterName $Parameter -ErrorAction SilentlyContinue

        [pscustomobject]@{
            ParameterName = $Parameter
            NumberOfCmdlets = $Results.Count
        }
    }
}

Get-MrParameterCount -ParameterName ComputerName, Computer, ServerName, Host, Machine

#Now back to our Test-MrParameter function

function Test-MrParameter {

    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

#Show there are no common parameters

Test-MrParameter -

Get-Command -Name Test-MrParameter -Syntax
(Get-Command -Name Test-MrParameter).Parameters.Keys

#help about_Functions_Advanced_Parameters -Full

#endregion

#region CmdletBinding

#Add CmdletBinding to turn the function into an advanced function

function Test-MrCmdletBinding {
    
    [CmdletBinding()] #<<-- This turns a regular function into an advanced function
    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

#This adds common parameters. CmdletBinding does require a param block, but the param block can be empty.

Test-MrCmdletBinding -

#Show there are now additional (common) parameters

Get-Command -Name Test-MrCmdletBinding -Syntax
(Get-Command -Name Test-MrCmdletBinding).Parameters.Keys

#help about_CommonParameters -Full
#help about_Functions_CmdletBindingAttribute -Full
#help about_Functions_Advanced -Full
#help about_Functions_Advanced_Methods -Full

#endregion

#region SupportsShouldProcess

function Test-MrSupportsShouldProcess {
    
    [CmdletBinding(SupportsShouldProcess)]
    param (
        $ComputerName
    )

    Write-Output $ComputerName

}

#SupportsShouldProcess adds WhatIf & Confirm parameters. This is only needed for commands that make changes.

Test-MrSupportsShouldProcess -

#Show there are now WhatIf & Confirm parameters

Get-Command -Name Test-MrSupportsShouldProcess -Syntax
(Get-Command -Name Test-MrSupportsShouldProcess).Parameters.Keys

#endregion

#region Parameter Validation

#Validate input early on. Why allow your code to continue on a path when it's not posible to successfully complete without valid input?

#Always type the variables that are being used for your parameters (specify a datatype)
#Use a Type Constraint in Windows PowerShell: https://technet.microsoft.com/en-us/magazine/ff642464.aspx

function Test-MrParameterValidation {
    
    [CmdletBinding()]
    param (
        [string]$ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation -ComputerName Server01
Test-MrParameterValidation -ComputerName Server01, Server02
Test-MrParameterValidation

#Make the ComputerName parameter mandatory

function Test-MrParameterValidation {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation

#Allow more than one ComputerName to be entered by typing $ComputerName as an array of strings

function Test-MrParameterValidation {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation

#Default values can NOT be used with mandatory parameters

function Test-MrParameterValidation {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName = $env:COMPUTERNAME #<<-- This will not work with a mandatory parameter
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation

#Use the ValidateNotNullOrEmpty parameter validation attribute with a default value

function Test-MrParameterValidation {
    
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Write-Output $ComputerName

}

Test-MrParameterValidation
Test-MrParameterValidation -ComputerName Server01, Server02

#Notice that $env:COMPUTERNAME was used instead of localhost or . which makes the command more dynamic

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

#endregion

#region Verbose Output

function Test-MrVerboseOutput {
    
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    foreach ($Computer in $ComputerName) {
        #Attempting to perform some action on $Computer <<-- Don't use inline comments like this, use write verbose instead.
        Write-Output $Computer
    }

}

Test-MrVerboseOutput -ComputerName Server01, Server02 -Verbose

#Use Write-Verbose instead of writing inline comments

function Test-MrVerboseOutput {
    
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    foreach ($Computer in $ComputerName) {
        Write-Verbose -Message "Attempting to perform some action on $Computer"
        Write-Output $Computer
    }

}

Test-MrVerboseOutput -ComputerName Server01, Server02
Test-MrVerboseOutput -ComputerName Server01, Server02 -Verbose

#endregion

#region Pipeline Input

#ValueFromPipeline

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline)]
        [string[]]$ComputerName
    )

    PROCESS {   
        Write-Output $ComputerName    
    }

}

'dc01', 'pc01' | Test-MrPipelineInput

$Object = New-Object -TypeName PSObject -Property @{'ComputerName' = 'Server01', 'Server02'}
$Object | Test-MrPipelineInput

#ValueFromPipelineByPropertyName

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {   
            Write-Output $ComputerName    
    }

}

'dc01', 'pc01' | Test-MrPipelineInput
$Object | Test-MrPipelineInput

#Both ValueFromPipeline and ValueFromPipelineByPropertyName

function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {  
        Write-Output $ComputerName
    }

}

'dc01', 'pc01' | Test-MrPipelineInput
$Object | Test-MrPipelineInput



function Test-MrPipelineInput {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    BEGIN {

        Write-Output "Test $ComputerName"
    }

}

'dc01', 'pc01' | Test-MrPipelineInput
$Object | Test-MrPipelineInput

#endregion

#region Error Handling
#Use try / catch where you think an error may occur. Only terminating errors are caught. Turn a non-terminating error into a terminating one.
#Don't change $ErrorActionPreference unless absolutely necessary and change it back if you do. Use -ErrorAction on a per command basis instead.

#An unhandled exception is generated when a computer cannot be contacted

function Test-MrErrorHandling {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            Test-WSMan -ComputerName $Computer
        }
    }

}

Test-MrErrorHandling -ComputerName DC01
Test-MrErrorHandling -ComputerName DoesNotExist, DC01

#This also generates an unhandled exception because the command doesn't generate a terminating error

function Test-MrErrorHandling {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                Test-WSMan -ComputerName $Computer
            }
            catch {
                Write-Warning -Message "Unable to connect to Computer: $Computer"
            }
        }
    }

}

Test-MrErrorHandling -ComputerName DoesNotExist, DC01

#Specify the ErrorAction parameter with Stop as the value to turn a non-terminating error into a terminating one.
#Don't modify the global $ErrorActionPreference variable. If you do change it, change it back after the command.

function Test-MrErrorHandling {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )

    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                Test-WSMan -ComputerName $Computer -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Unable to connect to Computer: $Computer"
            }
        }
    }

}

Test-MrErrorHandling -ComputerName DoesNotExist, DC01

#help about_Try_Catch_Finally -Full

#endregion

#region Comment Based Help

function Get-MrAutoStoppedService {

<#
.SYNOPSIS
    Returns a list of services that are set to start automatically, are not
    currently running, excluding the services that are set to delayed start.
 
.DESCRIPTION
    Get-MrAutoStoppedService is a function that returns a list of services from
    the specified remote computer(s) that are set to start automatically, are not
    currently running, and it excludes the services that are set to start automatically
    with a delayed startup.
 
.PARAMETER ComputerName
    The remote computer(s) to check the status of the services on.

.PARAMETER Credential
    Specifies a user account that has permission to perform this action. The default
    is the current user.
 
.EXAMPLE
     Get-MrAutoStoppedService -ComputerName 'Server1', 'Server2'

.EXAMPLE
     'Server1', 'Server2' | Get-MrAutoStoppedService

.EXAMPLE
     Get-MrAutoStoppedService -ComputerName 'Server1', 'Server2' -Credential (Get-Credential)
 
.INPUTS
    String
 
.OUTPUTS
    PSCustomObject
 
.NOTES
    Author:  Mike F Robbins
    Website: http://mikefrobbins.com
    Twitter: @mikefrobbins
#>

    [CmdletBinding()]
    param (
    
    )

    #Function Body

}

help Get-MrAutoStoppedService -Full

#Cntl + J for Snipets
#help about_Comment_Based_Help -Full

#endregion

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
