function Resolve-HostsFileEntry {
    param([string]$Name)
    $hostsFile = "C:\Windows\system32\drivers\etc\hosts"
    $line = Get-Content $hostsFile | Select-String -Pattern ($Name -replace '\..*$')
    [regex]::Match($line,'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').Groups[1].Value
}#END: function Resolve-HostsFileEntry
