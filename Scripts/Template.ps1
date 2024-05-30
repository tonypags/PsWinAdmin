## Requires -Modules MyEmailTools, PsWinAdmin, PsDevTools, etc
## Requires -Modules @{ModuleName="Connectimo"; RequiredVersion="0.0.2"},@{ModuleName="Dashimo"; MaximumVersion="0.0.17"}
<#
.SYNOPSIS
Brief description of what this script does, should be copied to the scheduled task description.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('DEV','TEST','PROD')]
    [Alias('env')]
    [string]
    $Environment,

    [Parameter(Mandatory)]
    [PsCredential]
    $Credential,

    # Tell the script that it was invoked from the web
    [Parameter()]
    [switch]
    $WebTool
)

#region Pre-Code
######### STOPWATCH ##########
$stopwatch = [System.Diagnostics.Stopwatch]::new()
$objRuntimeInfo = [System.Collections.Generic.List[System.Object]]@()
$sbRuntimeInfo = {
    param(
        [string]$Message,
        [System.Diagnostics.Stopwatch]$stopwatch = $stopwatch
    )

    if (Get-Variable prevEndRuntime -Scope Global -ea:ignore) {} else {
        $global:prevEndRuntime = 0,0
    }

    $EndTime = ([math]::Truncate($stopwatch.Elapsed.TotalMinutes)),
        ($stopwatch.Elapsed.Seconds)

    $minutesToSubtract = 0
    $durSecs = $EndTime[1] - $global:prevEndRuntime[1]
    if ($durSecs -lt 0) {
        $durSecs = 60 + $durSecs
        $minutesToSubtract = 1
    }
    $durMins = $EndTime[0] - $global:prevEndRuntime[0] - $minutesToSubtract
    $Duration = ($durMins),($durSecs)
    $global:prevEndRuntime = $EndTime

    [PSCustomObject]@{
        Duration = '{0}:{1:00}' -f $Duration
        EndTime  = '{0}:{1:00}' -f $EndTime
        Message  = $Message
    }
}
$stopwatch.Start()
# Place a line like this at the end of each section:
## $objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'Initial Setup'))
# Replace older "+=" logic for the ".Add()" logic:
## \$objRuntimeInfo \+= Invoke-Command \$sbRuntimeInfo -Arg ["|'](.+?)["|']\s*?
## $objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg '$1'))
######### STOPWATCH ##########

$Now = Get-Date
$strDateFormat = 'yyyyMMdd_HHmmss.fff'
$strDateNow = $Now.ToString($strDateFormat)

######### BASE FOLDERS ##########
$homeFolder = if ($webtool.IsPresent) {'C:\Users\ps5.websvc'} else {$env:USERPROFILE}
$moduleFolder = 'C:\Program Files\WindowsPowerShell\Modules'
######### BASE FOLDERS ##########
######### TRANSCRIPT ##########
$TranscriptPath = "$homeFolder\Documents\WindowsPowerShell\Transcripts"
if (Test-Path $TranscriptPath) {} else {
    New-Item $TranscriptPath -ItemType Directory -Force
}
$scriptName = if ($WebTool.IsPresent) {
    'Manually-Add-Script-Name' # Manually Add Script Name, only really needed for webtool cases
} else {
    $myInvocation.MyCommand.Name -replace '\.[\w\d]+?$' -replace '\s'
}
if ([string]::isnullorempty($scriptName)) {$scriptName = 'Console'}
$FileName = "$($scriptName)_$($strDateNow).txt"
$TranscriptFilePath = Join-Path $TranscriptPath $FileName
if ($Environment -ne 'dev' -and -not $WebTool.IsPresent) {
    Write-Host "Restarting transcript under ""$($TranscriptFilePath)"""
}
Try{Stop-Transcript -ea stop -ev NaN} catch {}
if ($Environment -ne 'dev') {
    $respNewTS = Start-Transcript -Path $TranscriptFilePath -Force|Out-String
    if (-not $WebTool.IsPresent) {Write-Host $respNewTS}
}
######### TRANSCRIPT ##########
######################## Paths setup ##################################

$workingDIR = $PSScriptRoot

if ($env:COMPUTERNAME -like 'TST*') {
    $webIntDomain = 'toolbox.test'
    if ($Environment -eq 'dev') {
        $webDir = "C:\Scripts\Tests\ToolBox"
        $webPort = '8088'
    } else {
        $webDir = "C:\inetpub\wwwroot\ToolBox"
        $webPort = '8081'
    }
    $webPort = '8081'
} elseif ($env:COMPUTERNAME -like 'PRD*') {
    $webIntDomain = 'toolbox'
    if ($Environment -eq 'prod') {
        $webDir = "C:\inetpub\wwwroot\ToolBox"
        $webPort = '8080'
    } else {
        $webDir = "C:\Scripts\Tests\ToolBox"
        $webPort = '8081'
    }
}

$logPart = if ($Environment -eq 'prod') {'PROD'} else {'TEST'}

# Folder name, for organizing exports by type of data source
$RefType = 'Patching' # Patching|SQL|DNS|Circuits|Backups|Inventory|Internal|MSOnline|Exchange|GameOps|GSIS|ADDS|Environmental|Networks

# Name for both paths, required for publishing to WEB AND SAN (use date string only if saving history)
$ReportFilename = "$($scriptName)_$($Now.ToString('yyyyMMdd')).html"

$resultSubDir      = 'Sub-Folder-Name' # For web archive only
$webToolScriptPath = Join-Path $webDir "tools\$resultSubDir\tool.ps1"
$webResults        = Join-Path $webDir "Results\$resultSubDir"
$htmlResultPath    = Join-Path $webResults $ReportFilename
$webHost           = "$($webIntDomain).domain.local"
$webRootUri        = "https://$($webHost):$($webPort)"
$ReportUri         = "$($webRootUri)/Results/$($resultSubDir)/$($ReportFilename)"


$baseDir    = '\\san01.domain.local\devops$'
$logdir     = Join-Path $baseDir "Logs\$scriptName\$logpart"
$errLogPath = Join-Path $logdir "$($env:COMPUTERNAME)_$($strDateNow)_Errors.txt"
$nfoLogPath = Join-Path $logdir "$($env:COMPUTERNAME)_$($strDateNow)_Info.txt"

if ($Environment -eq 'prod') {
    # Raw Exports for Automated Consumption/Dashboards/Formatted Reports
    $dataDir   = Join-Path $baseDir "\Data\$($RefType)\$($scriptName)"
    # Formatted Reports for Human Consumption/Email
    $reportDir = Join-Path $baseDir "\Reports\$($RefType)\$($scriptName)"
} else {$reportDir = $dataDir = $env:TEMP}
$ReportPath = Join-Path $reportDir "$($scriptName).csv" # csv html xlsx etc
$DataPath   = Join-Path $dataDir "$($scriptName).xml" # xml json etc

if(Test-Path -Path $webResults){}else{mkdir $webResults -Force}
if(Test-Path -Path $reportDir){}else{mkdir $reportDir -Force}
if(Test-Path -Path $dataDir){}else{mkdir $dataDir -Force}
if(Test-Path -Path $logdir){}else{mkdir $logdir -Force}
$Attachments = @()
######################## Paths setup ##################################
######## GIT HISTORY ##########
Push-Location
Set-Location $PSScriptRoot
$cmts = 10 # how many commits to show in the log
$rnd =  (97..122|foreach-object{[char]$_} | Get-Random -Count 3) -join ''
$gitLogPath = Join-Path $logdir ('gitlog{0}_{1}-{2}.txt' -f $cmts,$strDateNow,$rnd)
git --no-pager log --max-count=$cmts -- "$($myInvocation.MyCommand.Name)" | Out-File $gitLogPath
if ((Test-Path $gitLogPath)) {$Attachments += $gitLogPath}
Pop-Location
######## GIT HISTORY ##########
######## Web Resource Init ##########
[Net.ServicePointManager]::SecurityProtocol =
[enum]::GetNames([Net.SecurityProtocolType]) | Foreach-Object {
    [Net.SecurityProtocolType]::$_
}
[System.Net.ServicePointManager]::Expect100Continue = $false
[System.Net.ServicePointManager]::MaxServicePointIdleTime = 5000
if (
    (whoami) -ne 'nt authority\iusr' -and
    [System.Net.ServicePointManager]::CertificatePolicy -ne
    'System.Net.TrustAllCertsPolicy' -and
    [System.Net.ServicePointManager]::CertificatePolicy.ToString() -ne
    'TrustAllCertsPolicy'
) {
    add-type '
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
    '
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
######## Web Resource Init ##########
$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'Initial Setup'))
#endRegion Pre-Code

#region Code
######################## Begin Variables ##############################
$Subject = 'Automated Report'
if ($Environment -ne 'prod') {$Subject = "$($Environment.ToUpper()) - $Subject"}

$EmailTo = if ($Environment -eq 'prod') {
    @(
        'prod.email@domain.net'
    )
} else {
    'dev.email@domain.net'
}
$EmailBody = 'Hello,<br>'

# How to load an image for an email and a webpage in the same tag
# "<img src='cid:my-logo-56px.jpg' onerror='if (this.src != ''/img/my-logo-56px.jpg'') this.src = ''/img/my-logo-56px.jpg'';' alt='MY Logo' style='padding:1px' >"
# OR: <img src='cid:my-logo-56px.jpg' onerror='if (this.src != `"/images/my-logo-56px.jpg`") this.src = `"/images/my-logo-56px.jpg`";' alt='MY Logo' style='padding:1px' >

# Disable certain Apple funny-business 
# <head><meta name='x-apple-disable-message-reformatting' /></head>

# ArrayContruct - This is now the preferred syntax
$list = [System.Collections.Generic.List[System.Object]]@()
$list.Add([PSCustomObject]@{name='value'})
$Strings = [System.Collections.Generic.List[String]]@()
$Strings.Add('example')

# The Write-Log Function lives under PsWinAdmin
if (-not $WebTool.IsPresent) {Write-Host "Logging to path '$nfoLogPath'"}
$nfoLog = @{
    FilePath = $nfoLogPath
    PassHost = $Environment -ne 'prod' -or -not $webtool.IsPresent
    EntryType = 'INFO'
}
# Write-Log @nfoLog -c "comment"
$wrnLog = @{
    FilePath = $nfoLogPath
    PassHost = $Environment -ne 'prod' -or -not $webtool.IsPresent
    EntryType = 'WARN'
}
# Write-Log @wrnLog -c "message"
$errLog = @{
    FilePath = $nfoLogPath
    PassHost = $Environment -ne 'prod' -or -not $webtool.IsPresent
    EntryType = 'ERROR'
}
# Write-Log @errLog -c "message"
$faiLog = @{
    FilePath = $nfoLogPath
    PassHost = $Environment -ne 'prod' -or -not $webtool.IsPresent
    EntryType = 'FAIL'
}
# Write-Log @faiLog -c "message"
Write-Log @nfoLog -c "Parameter.Environment: $Environment"
Write-Log @nfoLog -c "Parameter.Credential: $($Credential.Username)"
Write-Log @nfoLog -c "Parameter.Date: $Date"
Write-Log @nfoLog -c "Parameter.WebTool: $WebTool"

# Do not use #Require statement for tools used in IIS
Import-Module -Force "$moduleFolder\PsWinAdmin\PsWinAdmin.psd1"
Import-Module -Force "$moduleFolder\PsDevTools\PsDevTools.psd1" -Function 'Remove-HtmlTags'

# Import a credential
$baseCredPath = "$homeFolder\Documents\WindowsPowerShell\Credentials"
$baseNameOfCred = 'alerts@domain.local'
$credPath = "$baseCredPath\$baseNameOfCred.xml"
$RunAsCred = Import-CliXml $credPath -ea 'Stop'
Write-Log @nfoLog -c "Using credential: '$($RunAsCred.UserName)'"

# As many as you want....
$baseNameOfCred = 'dbreadonly@platform'
$credPath = "$baseCredPath\$baseNameOfCred.xml"
$dbCred = Import-Clixml $credPath -ea 'Stop' # critical, stop
#
$baseNameOfCred = 'it.read.only@vsphere.local'
$credPath = "$baseCredPath\$baseNameOfCred.xml"
$vmwareCred = Import-Clixml $credPath -ea 0 # not critical, go
#

# Emojis - https://emojipedia.org/
$example = '&#000000;'
$construction = '&#128679;'
$hardHatGuy = '&#128119;'
$redPhone = '&#128222;'
$stopSign = '&#128721;'
$manRunning = '&#127939;'
$fingerRight = '&#128073;'
$fingerDown = '&#128071;'
$folder = '&#128193;'
$happy1 = '&#128578;'
$happy2 = '&#128515;'
$clock830 = '&#128355;'
$redX = '&#10060;'
$greenCheck = '<span style="color:green;">&#10004;</span>'

$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'Variables'))
######################## End Variables ################################

######################## Begin Section1 ###############################
Write-Host 'Starting Section1'

$allItems = [System.Collections.Generic.List[System.Object]]@()
$allItems.Add([PSCustomObject]@{name='value'})

Write-Host "Section1 items: $($allItems.Count)"
$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'Section1'))
######################## End Section1 #################################
#OR
######################## Begin Section2 ###############################
Write-Log @nfoLog -c 'Starting Section2'

$allItems = [System.Collections.Generic.List[System.Object]]@()
$allItems.Add([PSCustomObject]@{name='value'})

Write-Log @nfoLog -c "Section2 items: $($allItems.Count)"
$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'Section2'))
######################## End Section2 #################################

######################## Begin RunScriptBeingWrappedByThisFile ###############################
Write-Host 'Starting RunScriptBeingWrappedByThisFile'
if ($Environment -eq 'dev') {Write-Debug 'Calling another script' -Debug}


# Call the other script which will run as normal
& "$workingDir\The-Other-Script.ps1" -env $Environment -Params 'etc'


# Restart/append Transcript after called script kills and restarts the one started here
if ($Environment -ne 'dev' -and -not $WebTool.IsPresent) {
    Write-Host "Restarting transcript under ""$($TranscriptFilePath)"""
}
try {Stop-Transcript -ea stop -ev NaN} catch {}
if ($Environment -ne 'dev') {
    $respNewTS = Start-Transcript -Path $TranscriptFilePath -Append|Out-String
    if (-not $WebTool.IsPresent) {Write-Host $respNewTS}
}
#NOTE: All transcript logic in this^ section is copied directly from the top of the file BUT
#      THE APPEND SWITCH REPLACES THE FORCE SWITCH IN THE Start-Transcript FUNCTION CALL!!!!

$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'RunScriptBeingWrappedByThisFile'))
######################## End RunScriptBeingWrappedByThisFile #################################

######################## Begin ForceTryCatch ###############################

    # SAMPLE CODE
    Try {
        $origEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        # DO SOMETHING
        
        $ErrorActionPreference = $origEAP
    } Catch {
        $ErrorActionPreference = $origEAP
        Write-Error ($_.Exception.Message)
    }

$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'ForceTryCatch'))
######################## End ForceTryCatch #################################

######################## Begin Export ###############################
Write-Host 'Starting Export'

$Table | Export-Csv -Path $ReportPath -NoTypeInformation -Force
$Table | Export-CliXml -Path $DataPath -Depth 99 -Force
$Table | ConvertTo-Html | Out-File $htmlResultPath

$files = $ReportPath,$htmlResultPath,$DataPath
Write-Host (Get-Item $files | Format-Table | Out-String)

$null = "<a href='$($ReportUri)' alt='Report Webpage'>Report Webpage</a>"

$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'Export'))
######################## End Export #################################

######################## Begin SendEmail #############################
Write-Host 'Starting SendEmail'

# Make a helpful blurb about the script for reference
$props = @{
    ScriptLocation = "\\$($env:COMPUTERNAME)\$($PSScriptRoot -replace ':','$')\$($MyInvocation.MyCommand.Name)"
    TranscriptLocation = "\\$($env:COMPUTERNAME)\$($TranscriptFilePath -replace ':','$')"
    ReportFileLocation = $ReportPath
    ReportSiteLocation = $ReportUri
    Date = $Now
}
$ScriptInfo = Get-EmailFooter @props

$MailSplat = Get-MyMailSplat -wa 0
$MailSplat.To = $EmailTo
if ($EmailCc) {$MailSplat.Cc = $EmailCc}
if ($EmailBcc) {$MailSplat.Bcc = $EmailBcc}
$MailSplat.Subject = $Subject
$MailSplat.Body = $EmailBody + (Get-MyEmailSignature) + $ScriptInfo
if ($Attachments) {$MailSplat.Attachments = $Attachments}
$MailSplat.Priority = 'Normal' # High|Normal|Low

$msg = "[$(Get-Date)] Sending email with subject '$($MailSplat.Subject)' to $($MailSplat.To -join '; ')"
if ($Environment -eq 'dev') {Write-Debug $msg -Debug} else {Write-Host $msg}
Send-MailMessage @MailSplat

$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'SendEmail'))
######################## End SendEmail ###############################

#endregion Code
$objRuntimeInfo.Add((Invoke-Command $sbRuntimeInfo -Arg 'End of Logic'))
##########################Out Logs ####################################
$rErr=$error|Where-Object{$_-notlike'*not currently transcribing*'};if($rErr){$rErr|Out-File $errLogPath -Append}

Write-Host ($objRuntimeInfo|Format-Table EndTime, Duration, Message -AutoSize -Wrap|Out-String)
#OR
Write-Log @nfoLog -c ($objRuntimeInfo|Format-Table EndTime,Duration,Message -a -wrap|Out-String)
##########################Out Logs ####################################
$stopwatch.Stop()
Write-Host 'Final script runtime:';Write-Host ($stopwatch.Elapsed|Format-List *|Out-String)
#OR
Write-Log @nfoLog -c 'Final script runtime:';Write-Log @nfoLog -c ($stopwatch.Elapsed|Format-List *|Out-String)
Write-Debug 'End of Script' -Debug:($Environment -eq 'dev')
Remove-Variable 'stopwatch'
