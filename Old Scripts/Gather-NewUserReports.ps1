$FileName = "AllClientsNewUsers_$((Get-Date).ToString('yyyyMMddHHmmss')).csv"
$EmailTo = @('')
$EmailSubject = 'All Clients New Users Report'
$Smtp = ''
$From = ''

###################################
### DO NOT EDIT BELOW THIS LINE ###
###################################

# Set up variables
$ExportPath = Join-Path 'C:\Reports' "NewDomainUsers\$($FileName)"
$Folder = 'C:\LTShare\Uploads'
$ClientFolders = Resolve-Path "$Folder\*" | Select -ExpandProperty Path

# Find all latest files for each client
$AllReportFiles = Foreach ($Path in $ClientFolders) {
    Resolve-Path "$Path\*\*-NewAdUsers120Days.csv" |
        Select-Object -ExpandProperty Path | Get-Item |
        Select-Object -ExpandProperty FullName
}
Write-Verbose "Found $($AllReportFiles.count) CSV files." -Verbose

# PURGE: # $AllReportFiles | Remove-Item -Force

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
The attached report contians User Accounts with mailboxes created in the last 120 days. 

Thank you

"@
}

# Send the email
Send-MailMessage @MailSplat
