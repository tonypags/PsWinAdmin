$FileName = "AllClientsLatestDomainAdminRunAs_$((Get-Date).ToString('yyyyMMddHHmmss')).csv"
$EmailTo = @('')
$EmailSubject = 'All Clients Domain Admin RunAs Report'
$Smtp = ''
$From = ''

###################################
### DO NOT EDIT BELOW THIS LINE ###
###################################

# Set up variables
$ExportPath = Join-Path 'C:\Reports' "DomainAdminRunAs\$($FileName)"
$Folder = 'C:\LTShare\Uploads'
$ClientFolders = Resolve-Path "$Folder\*" | Select -ExpandProperty Path

# Find all latest files for each client
$AllReportFiles = Foreach ($Path in $ClientFolders) {
    Resolve-Path "$Path\*\Domain-Admin_Run-As_*.csv" |
        Select-Object -ExpandProperty Path | Get-Item |
        Sort-Object -Property TimeGenerated |
        Select-Object -Last 1 -ExpandProperty FullName
}

# Bring all contents into a single object
$AllReports = Foreach ($Path in $AllReportFiles) {
    $ClientName = $Path -replace
        'C\:\\LTShare\\Uploads\\' -replace '\\.*'
    Import-Csv -Path $Path |
        Select-Object @{Name='ClientName';Exp={$ClientName}},*
}

# Export to file
$AllReports | Export-Csv -Path $ExportPath -NoTypeInformation

# Set up email
$MailSplat = @{
    SmtpServer = $Smtp
    From = $From
    To = $EmailTo
    Subject = $EmailSubject
    Attachments = $ExportPath
    Body = @"
The attached report contians Scheduled Tasks and Services running under an account with domain admin rights. Please review the report to make sure no services are using accounts with more privilages than required. Please ensure that the admin service account is not used on any services nor tasks.

Thank you

"@
}

# Send the email
Send-MailMessage @MailSplat
