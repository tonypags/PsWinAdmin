# PsWinAdmin
Various Windows tools for use by an administrator.

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
