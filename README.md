# PsWinAdmin
Various Windows tools for use by an administrator.

## Check for Pending Reboots
```
(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-PendingReboot.ps1')|iex;Get-PendingReboot
```

## Check for software matching a string
```
$strAppName = '*application*name*partial*';(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-InstalledSoftware.ps1')|iex;Get-InstalledSoftware | ?{$_.Name -like $strAppName}
```
