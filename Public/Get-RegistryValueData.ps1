function Get-RegistryValueData {
    <#
    .SYNOPSIS
    Gets value from remote computer registry.
    .EXAMPLE
    Get-RegistryValueData -ComputerName Server01, Member01, testcomp -RegistryHive LocalMachine -RegistryKeyPath SYSTEM\CurrentControlSet\Services\USBSTOR -ValueName 'Start'
    .NOTES
    Borrowed and made better, from http://vcloud-lab.com/entries/powershell/powershell-get-registry-value-data
        #[Microsoft.Win32.RegistryHive]::ClassesRoot
        #[Microsoft.Win32.RegistryHive]::CurrentUser
        #[Microsoft.Win32.RegistryHive]::LocalMachine
        #[Microsoft.Win32.RegistryHive]::Users
        #[Microsoft.Win32.RegistryHive]::CurrentConfig
    #>
    [CmdletBinding()]
    Param
    ( 
        [parameter(Position=0, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('Computer')]
        [String[]]$ComputerName = '.',

        [Parameter(Position=1, Mandatory=$True, ValueFromPipelineByPropertyName=$True)] 
        [alias('Hive')]
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'CurrentConfig')]
        [String]$RegistryHive,

        [Parameter(Position=2, Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
        [alias('KeyPath')]
        [String]$RegistryKeyPath,

        [parameter(Position=3, Mandatory=$True, ValueFromPipelineByPropertyName=$true)]
        [alias('Value')]
        [String]$ValueName
    )
    Begin {
    }
    Process {
        $RegistryRoot= "[{0}]::{1}" -f 'Microsoft.Win32.RegistryHive', $RegistryHive
        try {
            $RegistryHive = Invoke-Expression $RegistryRoot -ErrorAction Stop
        }
        catch {
            Write-Host "Incorrect Registry Hive mentioned, $RegistryHive does not exist" 
        }

        Foreach ($Computer in $ComputerName) {
            if (Test-Connection $computer -Count 2 -Quiet) {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $Computer)
                $key = $reg.OpenSubKey($RegistryKeyPath)
                $Data = $key.GetValue($ValueName)
                [pscustomobject]@{
                    Computer = $Computer
                    RegistryValueName = "$RegistryKeyPath\$ValueName"
                    RegistryValueData = $Data
                }
            } else {
                Write-Warning "$Computer not reachable"
            }
        }
    }
    End {
    }
}

