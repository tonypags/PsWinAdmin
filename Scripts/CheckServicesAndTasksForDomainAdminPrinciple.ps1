#Requires -Version 2.0

param(
    # The file path to the file exported to TXT as a _Formatted List_
    $Path = (Join-Path $env:TEMP "Domain-Admin_Run-As_$(
        (Get-Date).ToString('yyyyMMddHHmmss')).txt")
)

# Requires -Module ActiveDirectory ("#\Requires -Module" doesn't work in Version 2.0)
$modAD = Get-Module ActiveDirectory
if($modAD){
    # The module is already loaded, Do Nothing
}else{
    $modAD = Get-Module ActiveDirectory -ListAvailable
    if($modAD){
        # The module is Available for import
        Import-Module ActiveDirectory -Force
    }else{
        # The module is Not Available
        $ErrorText = @"
The script requires the ActiveDirectory module. 
Please install RSAT or try running the script on another server.
"@
        Throw $ErrorText
    }
}

# Requires -RunAsAdministrator ("#\Requires -RunAsAdministrator" doesn't work in Version 2.0)
$TestRunAsAdmin = [bool]((whoami /all) -match "S-1-16-12288")
if($TestRunAsAdmin){
    # The session is Elevated, Do Nothing
}else{
    # The session is Not Elevated
    $ErrorText = @"
The script requires elevated privilages. 
Please re-run this script as a user with local admin rights to all servers.
"@
        Throw $ErrorText
}

function Get-AllTaskSubFolders {
    [cmdletbinding()]
    param (
        # Set to use $Schedule as default parameter so it automatically list all files
        # For current schedule object if it exists.
        $FolderRef = $Schedule.getfolder("\"),
        [switch]$RootFolder = $RootFolder
    )
    if ($FolderRef.Path -eq '\') {
        $FolderRef
    }
    if (-not $RootFolder) {
        Try {
            $ArrFolders = @()
            if(($Folders = $folderRef.getfolders(1))) {
                $Folders | ForEach-Object {
                    $ArrFolders += $_
                    if($_.getfolders(1)) {
                        Get-AllTaskSubFolders -FolderRef $_
                    }
                }
            }
            $ArrFolders
        } Catch {
            Write-Warning "$($_.Exception.Message)"
        }
    }
}

function Get-TaskTrigger {
    [cmdletbinding()]
    param (
        $Task
    )
    $Triggers = ([xml]$Task.xml).task.Triggers
    if ($Triggers) {
        $Triggers | Get-Member -MemberType Property | ForEach-Object {
            $Triggers.($_.Name)
        }
    }
}

function Get-ScheduledTask {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$RootFolder
    )
    
    try {
        $Schedule = New-Object -ComObject 'Schedule.Service'
    } catch {
        throw "Schedule.Service COM Object not found, this script requires this object"
    }

    try {
        $ScheduleConnected = $false
        $Schedule.connect($ComputerName) 
        $ScheduleConnected = $true
    }
    catch {
        Write-Warning "Could not connect to Schedule on $ComputerName!"
    }

    # Default if failure
    $item = New-Object -TypeName PSCustomObject -Property @{
        'Name' = $null;
        'Path' = $null;
        'State' = $null;
        'Enabled' = $null;
        'LastRunTime' = $null;
        'LastTaskResult' = $null;
        'NumberOfMissedRuns' = $null;
        'NextRunTime' = $null;
        'Author' =  $null;
        'UserId' = $null
        'Description' = $null
        'Trigger' = $null
        'ComputerName' = $ComputerName
    }
    
    $Result = New-Object System.Collections.ArrayList
    
    if($ScheduleConnected){
        $AllFolders = Get-AllTaskSubFolders

        if($AllFolders){
            foreach ($Folder in $AllFolders) {
                if (($Tasks = $Folder.GetTasks(1))) {
                    $Tasks | Foreach-Object {
                        $item = New-Object -TypeName PSCustomObject -Property @{
                            'Name' = $_.name
                            'Path' = $_.path #<#
                            'State' = switch ($_.State) {
                                0 {'Unknown'}
                                1 {'Disabled'}
                                2 {'Queued'}
                                3 {'Ready'}
                                4 {'Running'}
                                Default {'Unknown'}
                            }#>
                            'Enabled' = $_.enabled #<#
                            'LastRunTime' = $_.lastruntime
                            'LastTaskResult' = $_.lasttaskresult
                            'NumberOfMissedRuns' = $_.numberofmissedruns
                            'NextRunTime' = $_.nextruntime
                            'Author' =  ([xml]$_.xml).Task.RegistrationInfo.Author #>
                            'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
                            'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description #<#
                            'Trigger' = Get-TaskTrigger -Task $_ #>
                            'ComputerName' = $Schedule.TargetServer
                        }
                        [void]($Result.Add($item))
                    }# $Tasks | Foreach-Object 
                }# if (($Tasks = $Folder.GetTasks(1)))
            }# foreach ($Folder in $AllFolders)
        }
        Else{
            $item.Description = "Unable to read task folder on $ComputerName"
            [void]($Result.Add($item))
        }# if($AllFolders)

        Write-Output $Result
    }
    Else {
        $item.Description = "Unable to Connect to $ComputerName"
        [void]($Result.Add($item))
    }# if($ScheduleConnected){
}# function Get-ScheduledTask

function Find-DomainAdminServicesAndTasks {
# This functino should be split into two: 
# # one for finding domain admin users
# # 2d for finding tasks per give user account(s) 
    [CmdletBinding()]
    [OutputType([psobject])]
    param()

    Begin{
        # All AD users with Domain Admin rights
        $User=(
            Get-ADGroupMember "Domain Admins" |
                Get-AdUser -Property LastLogonDate,
                                    PasswordLastSet,
                                    PasswordNeverExpires
        )
        [string[]]$arrUser = $User |
            Select-Object @{Name='Account';Expression={"$($env:USERDOMAIN)\$($_.SamAccountName)"}} |
            Select-Object -ExpandProperty Account

        # All AD Computer objects listed as servers and recently active
        $Computer =
            Get-ADComputer -Filter {
                    operatingSystem -like "*windows*server*"
                } -Properties operatingsystem,LastLogonDate |
                Where-Object {
                    $_.enabled -and 
                    $_.LastLogonDate -gt ((Get-Date).AddMonths(-12))
                }
        [string[]]$ComputerName = $Computer |
            Select-Object -ExpandProperty Name
    }

    Process{
        ForEach ($Device in $ComputerName) {
            Write-Verbose "Starting checks for $Device..."
        
            If ( Test-Connection $Device -Count 2 -ErrorAction SilentlyContinue) {
                Write-Verbose "Checking connectivity..."
            
                # Check services
                $errService = $null
                $ServiceSplat = @{
                    Class = 'win32_service'
                    ComputerName = $Device
                    ErrorAction = 'SilentlyContinue'
                    ErrorVariable = 'errService'
                }
                $Services = Get-WmiObject @ServiceSplat |
                    Where-Object {
                        $arrUser -contains "$($env:USERDOMAIN
                            )\$($_.StartName -replace '.*\\')"
                    }
                if($errService){
                    Write-Warning "WMI error getting services from $(
                        $Device)!`n$($errService.Exception)"
                    $Props = @{
                        ComputerName = $Device
                        Type         = 'Service'
                        Name         = 'N/A'
                        User         = 'N/A'
                        Details      = "WMI Unable to gather any service info on $(
                                        $Device).`n$($errService.Exception)"
                    }
                    New-Object PSObject -Property $Props
                }
                if ( $Services ) {
                    Write-Verbose "Checking services..."
                    ForEach ( $Service in @($Services) ) {
                        $Props = @{
                            ComputerName = $Device
                            Type         = 'Service'
                            Name         = $Service.DisplayName
                            User         = $Service.StartName
                            Details      = $Service.PathName
                        }
                        New-Object PSObject -Property $Props
                    }
                } # $Services
            
                # Check tasks
                Write-Verbose "Checking scheduled tasks..."
                $errTask = $null
                $TaskSplat = @{
                    ComputerName = $Device
                    ErrorAction = 'SilentlyContinue'
                    ErrorVariable = 'errTask'
                }
                $Tasks = Get-ScheduledTask @TaskSplat |
                    Where-Object {$arrUser -contains $_.'UserID'}
                if($errTask){
                    Write-Warning "WMI error getting services from $(
                        $Device)!`n$($errTask.Exception)"
                    $Props = @{
                        ComputerName = $Device
                        Type         = 'Scheduled Task'
                        Name         = 'N/A'
                        User         = 'N/A'
                        Details      = "ComObject Schedule.Service errored out on $(
                                            $Device).`n$($errTask.Exception)"
                    }
                    New-Object PSObject -Property $Props
                }
                if($Tasks){
                    ForEach ($Task in @($Tasks)) {
                        $Props = @{
                            ComputerName = $Device
                            Type         = 'Scheduled Task'
                            Name         = $Task.Name
                            User         = $Task.UserID
                            Details      = $Task.Description
                        }
                        New-Object PSObject -Property $Props
                    }# ForEach ($Task in @($Tasks)) 
                }# if($Tasks)
            }
            Else {
                # Test-Connection failed
                Write-Warning "Unable to ping $Device."

            } # Test-Connection
        }
    }
    End{
    }
}

# Define the order of the columns
$ColumnOrder = @(
    'ComputerName'
    'Type'
    'Name'
    'User'
    'Details'
)

# Make sure the folder for the export exists
$Parent = Split-Path $Path -Parent
if(Test-Path $Parent){
    # Do Nothing
}else{
    [void](New-Item -ItemType Directory -Path $Parent -Force)
}

# Run the functions and export to text file
$Report = Find-DomainAdminServicesAndTasks -Verbose |
    Select-Object $ColumnOrder |
    Sort-Object -Property ComputerName,Type,Name 

# Export formatted list output to file for emails and tickets
$Report | Format-List -GroupBy ComputerName |
    Out-File -FilePath $Path -Force

# Also Export CSV report for Upload and aggrigation
$csvPath = $Path -replace '\.txt$','.csv'
$Report | Export-Csv -Path $csvPath -Force -NoTypeInformation

Write-Host "The result has been exported to..." -f Green -b Black
Write-Output (Get-Item $Path | Select-Object -ExpandProperty FullName)
if (Read-Host "Open File now (Y/N)?" -eq 'y') {Get-Item $Path | Invoke-Item}
