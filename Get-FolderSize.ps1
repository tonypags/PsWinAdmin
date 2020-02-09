function Get-FolderSize {

    <#
    .Synopsis
    Returns the total size in MB of all items in the given paths. 
    .DESCRIPTION
    Returns the total size in MB of all items in the given paths. 
    .EXAMPLE
    Simple usage: 

    PS> Get-FolderSize -Path c:\users

    FolderName FolderSize(MB) LastModifiedDate DateCreated
    ---------- -------------- ---------------- -----------
    users      5,169.47       10/5/2016        7/16/2016     

    .EXAMPLE
    Use the Resolve-Path cmdlet and pipe the string-only result to Get-FolderSize: 

    PS> Resolve-Path c:\users\*\ | select -expand path | Get-FolderSize | Format-Table -autosize

    FolderName       FolderSize(MB) LastModifiedDate DateCreated
    ----------       -------------- ---------------- -----------
    Default.migrated 0.00           10/5/2016        10/30/2015 
    DefaultAppPool   0.00           10/5/2016        10/5/2016  
    user1            0.00           10/5/2016        10/5/2016  
    user2            0.00           4/20/2015        4/20/2015  
    Public           0.26           10/5/2016        7/16/2016  
    abcadmin         0.00           10/5/2016        10/5/2016  
    abcbackup        0.00           10/8/2016        10/5/2016  
    user3            5,169.21       10/25/2016       10/5/2016     

    .EXAMPLE
    Use a scheduled job to run the report daily, to eventually compare growth over time.  

    PS> Get-Content 'C:\Documents and Settings\Administrator\Desktop\UserFolderGrowth\UserFolderGrowth.ps1'

    $path = @(
    'C:\Program Files\Pam'
    'C:\Program Files\Microsoft SQL Server'
    'C:\Windows\Temp'
    'C:\Program Files\CloudBackup'
    'C:\Program Files\Symantec\Symantec Endpoint Protection Manager\Inetpub'
    'C:\Program Files\Symantec\Symantec Endpoint Protection Manager\db'
    'C:\Program Files\Symantec\Symantec Endpoint Protection Manager\data'
    )

    $datestring = (Get-Date).tostring('s')
    Get-FolderSize -Path $Path | 
        Export-Csv -Path "C:\Documents and Settings\Administrator\Desktop\UserFolderGrowth\UserFolderGrowth_$($DateString).csv" -NoTypeInformation -force

    PS> $A = New-ScheduledTaskAction �Execute "C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-executionpolicy bypass -file . 'C:\Documents and Settings\Administrator\Desktop\UserFolderGrowth\UserFolderGrowth.ps1'"
    PS> $T = New-ScheduledTaskTrigger -Daily -At 12pm
    PS> $P = "Contoso\Administrator"
    PS> $D = New-ScheduledTask -Action $A -Principal $P -Trigger $T 
    PS> Register-ScheduledTask UserFolderGrowth -InputObject $D

    #>

    [CmdletBinding()]
    Param
    (
        # Array of full path names (literal, not relative)
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [Alias('FullName')]
        [string[]]
        $Path = '.\'
    )

    Begin {}

    Process {

        Foreach ($P in $Path) {
            Get-Item $P |
                Select-Object Name, 
                    @{Name='FolderSize(MB)';Expression={
                        [double](
                            "{0:N2}" -f ([math]::Round(
                                (
                                    Get-ChildItem $_.fullname -recurse | 
                                    Measure-Object -property length -sum | 
                                    Select-Object -expand sum
                                ) / 1MB,2
                            ))
                        )
                    }},
                    CreationTime,
                    LastWriteTime,
                    FullName 
        }
    }
    
    End {}

}

