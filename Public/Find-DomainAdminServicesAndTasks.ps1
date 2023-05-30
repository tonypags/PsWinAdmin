function Find-DomainAdminServicesAndTasks {
# This function should be split into two: 
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
            Foreach-Object {"$($env:USERDOMAIN)\$($_.SamAccountName)"}

        # All AD Computer objects listed as servers and recently active
        $Computer =
            Get-ADComputer -Filter {
                    operatingSystem -like "*server*"
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
                $Services = Get-CimInstance @ServiceSplat |
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
