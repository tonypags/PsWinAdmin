# Software Deployment TEMPLATE from Sierra Pacific
exit # this is a template

$source = "https://agent.domain.com/download"
$x32file = "agent.msi"
$x64file = "agent.msi"
$softwarename = "My Agent"
$AgentSplat = @{
    appid = '123456789101112131415'
    permachine = $true
    disablestart = $false
}
$filename = $x32file
if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {$filename = $x64file}
$destdir = "$env:SystemDrive\Windows\Temp\$softwarename"

function sysLog {
    Param (
        [Parameter(Mandatory = $true)]$message,
        [Parameter(Mandatory = $true)]$category,
        [Parameter(Mandatory = $false)]$display = $false
    )
    $sysLogName = "$softwarename Installation Script"
    switch ($category) {
        'ERROR' { $etype = 1; break}
        'WARN' { $etype = 2; break}
        default { $etype = 4; break}
    }
    If (-not([System.Diagnostics.EventLog]::SourceExists($sysLogName))) { New-EventLog -LogName Application -Source $sysLogName }
    Write-EventLog -Message $message -LogName Application -Source $sysLogName -EntryType $etype -EventId 1001 -Category 0
    $string = "["+(Get-Date -Format g)+"] " + "[$category] $message"
    if($display -eq $true) {write-host $message}
    Return
}
function downloadFile {
    Param (
        [Parameter(Mandatory = $true)]$source,
        [Parameter(Mandatory = $true)]$destdir,
        [Parameter(Mandatory = $true)]$filename
    )
    If (!(Test-Path -Path $destdir)) {
        sysLog -category "INFO" -message "Creating local destination directory $destdir" -display $true
        Try {
            New-Item -Path $destdir -ItemType Directory | Out-Null
        } Catch {
            sysLog -category "ERROR" -message "Failed to create the destination directory $destdir with the following error: $($_.Exception.Message)." -display $true
            break
        }
    } else {
        Remove-Item -Path "$destdir\$filename" -Force -ErrorAction SilentlyContinue
    }
    sysLog -category "INFO" -message "Downloading $filename from $source to $destdir" -display $true
    $webclient = New-Object System.Net.WebClient
    Try {
        $webclient.DownloadFile("$source/$filename","$destdir\$filename")
    } Catch {
        sysLog -category "ERROR" -message "Failed to download $filename from $source with the following error: $($_.Exception.Message)." -display $true
        break
    }
    return
}

sysLog -category "INFO" -message "Starting $softwarename Installation." -display $true
downloadFile -source $source -destdir $destdir -filename $filename

$arguments = "/i""$destdir\$filename"" /qn REBOOT=ReallySuppress APP_ID=""$($AgentSplat.appid)"""
if ($AgentSplat.appid) {$arguments = "$arguments MSIINSTALLPERUSER="""""}
if ($AgentSplat.disablestart) {$arguments = "$arguments STARTUP=disabled"}
$execute = "msiexec.exe"

If (Test-Path -Path "$destdir\$filename") {
    sysLog -category "INFO" -message "Installing with arguments $arguments." -display $True
    Start-Process -FilePath $execute -ArgumentList $arguments -Wait
    sysLog -category "INFO" -message "Cleaning up installation." -display $true
    Remove-Item -Path $destdir -Recurse -Force
} else {
    sysLog -category "ERROR" -message "The file $filename failed to download or save. Cannot continue." -display $true
}

sysLog -category "INFO" -message "Completed the $softwarename software installation script." -display $true