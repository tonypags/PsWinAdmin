#Requires -Version 2.0
param(
    [timespan]$Timeframe = (New-TimeSpan -Days 120),
    [string]$CsvPath = "C:\temp\$($env:USERDOMAIN)-NewAdUsers120Days.csv"
)

# Requires -Module ActiveDirectory ("#\Requires -Module" doesn't work in Version 2.0)
$modAD = Get-Module ActiveDirectory
if($modAD){
    # The module is already loaded, Do Nothing
}else{
    $modAD = Get-Module ActiveDirectory -ListAvailable
    if($modAD){
        # The module is Available for import
        Try { 
            Import-Module ActiveDirectory -Force
        } Catch {
            Throw "AD Module import error!"
        }
    }else{
        # The module is Not Available
        $ErrorText = @"
The script requires the ActiveDirectory module. 
Please install RSAT or try running the script on another server.
"@
        Throw $ErrorText
    }
}#if($modAD){

# Define the column Output
$ColumnOrder = @(
    @{n='Domain';e={$env:USERDNSDOMAIN.tolower()}}
    'SamAccountName'
    @{n='Created';e={
        $LatestDate=0 -as [datetime];@($_.whenCreated,$_.Created,$_.createTimeStamp)|
        Foreach-Object {if($_ -gt $LatestDate){$LatestDate = $_}};$LatestDate.tostring('u')
    }}
    'Name'
)

# Calculate the timeframe for result
$PastDate = (Get-Date) - $Timeframe

# Get resultant object
$adProps = @(
    'whenCreated'
    'Created'
    'createTimeStamp'
)
$NewUsers = Get-ADUser -Filter * -Properties $adProps -ea 0 |
    Select-Object $ColumnOrder |
    Where-Object {(Get-Date $_.Created) -gt $PastDate}
Write-Verbose "$($NewUsers.count) new accounts found."



# Make sure this folder exists
$Parent = (Split-Path $CsvPath -Parent)
if (Test-Path $Parent) {}else {
    New-Item -Path $Parent -ItemType Directory -Force | Out-Null
}    

#Create the temp CSV
$NewUsers | Export-Csv -Path $CsvPath -NoTypeInformation -Force

# Return the file path to the pipeline for consumption (and aggregation)
Get-Item $CsvPath | Select-Object -ExpandProperty FullName
