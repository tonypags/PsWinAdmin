$Uri = 'https://fpdownload.macromedia.com/get/flashplayer/current/support/uninstall_flash_player.exe';
$FilePath = 'C:\Windows\temp\adobe\uninstall_flash_player.exe';
$Parent = Split-Path $FilePath -Parent;
if (Test-Path $Parent) {} else {New-Item -ItemType Directory $Parent -Force|out-null};
(New-Object Net.WebClient).DownloadFile($Uri,$FilePath);
if (Test-Path $FilePath) {Start-Process $FilePath -ArgumentList '-uninstall -force' -wait}else{Write-Error 'Failed to download file!'};
