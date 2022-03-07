# PsWinAdmin
Various Windows tools for use by an administrator.

***

# Getting Started
1.	Installation process 
<!--
    Access to the repository required:

        $repo = 'PsGallery' # Private internal repo is preferred
        Install-Module -Name PsWinAdmin -Repository $repo
-->

    Without Repository available, clone directly from Git:

        $uri = ' '.Trim()
        $ModuleParent = $env:PSModulePath -split ';' | Where {$_ -like "*$($env:USERNAME)*"} | Select -First 1
        Set-Location $ModuleParent
        git clone $uri

<br>

2.	Dependencies

    This module has the following PowerShell Dependancies:
    
        None

    This module has the following Software Dependancies:
    
        Windows OS

<br>

3.	Version History

    - v0.2.0.5 - Initial Commit.

<br>



# Build, Test, and Publish

1.  Pester test. 

2.  Get next version number `v#.#.#.#` and a comment `[string]` for the change log.

3.  Create a new Package folder as .\Package\v#.#.#.#\

4.  Copy the PSD1 files in as-is.

    Update the version number and copyright date if required.

	Update the Exported Function Name array with the basenames of the files under the Public folder only.

5.  Create a new, blank PSM1 file in here. 

    Populate it with all of the PS1 files' content from the .\Public and .\Private folders.

6.  Create a NUSPEC file and update the version and change log.

7.  Build the NuGet package.

8.  Push to private repo.


<br>


# Examples

## Check for Pending Reboots
```
[Net.ServicePointManager]::SecurityProtocol=[enum]::GetNames([Net.SecurityProtocolType])|Foreach-Object{[Net.SecurityProtocolType]::$_};(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-PendingReboot.ps1')|iex;Get-PendingReboot
```

## Review Reboot History
```
[Net.ServicePointManager]::SecurityProtocol=[enum]::GetNames([Net.SecurityProtocolType])|Foreach-Object{[Net.SecurityProtocolType]::$_};(New-Object Net.WebClient).DownloadString( 'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-RebootReport.ps1' )| iex; Get-RebootReport | ft -a -wrap
```

## Check for software matching a string
```
$strAppName = '*application*name*partial*';[Net.ServicePointManager]::SecurityProtocol=[enum]::GetNames([Net.SecurityProtocolType])|Foreach-Object{[Net.SecurityProtocolType]::$_};(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-InstalledSoftware.ps1')|iex;Get-InstalledSoftware | ?{$_.Name -like $strAppName}
```

## Ensure TLS v1.2 is enabled on Windows supported OSes
```
[Net.ServicePointManager]::SecurityProtocol=[enum]::GetNames([Net.SecurityProtocolType])|Foreach-Object{[Net.SecurityProtocolType]::$_};$web=(New-Object Net.WebClient);@('Confirm-RequiresAdmin','Assert-TlsVersion1.2') | %{$web.DownloadString("https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/$($_).ps1")|iex; iex "$_"}
```

## Find Events around the time of the last reboot
(this example outputs to the console using Format-Table)
```
$LogNames=@('System','Application');[Net.ServicePointManager]::SecurityProtocol=[enum]::GetNames([Net.SecurityProtocolType])|Foreach-Object{[Net.SecurityProtocolType]::$_};(New-Object Net.WebClient).DownloadString( 'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-RebootReport.ps1' )| iex;$LastRebootTime = (Get-RebootReport)[0].Date;$Events=@();$LogNames|%{$FilterHashtable = @{LogName=$_;EndTime=($LastRebootTime.AddMinutes(5));StartTime=($LastRebootTime.AddMinutes(-60));};Get-WinEvent -FilterHashtable $FilterHashtable|%{$Events += $_}};$Events| sort TimeCreated |ft LogName, TimeCreated, ProviderName, Message -a -wrap;
```


# Contribute
How to help make this module better: 

1.  Add your changes to a new feature sub-branch.

2.  Add Pester tests for your changes.

3.  Push your branch to origin.

4.  Submit a PR with description of changes.

5.  Follow up in 1 business day.


<br>

