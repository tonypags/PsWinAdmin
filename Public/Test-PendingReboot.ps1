function Test-PendingReboot {
    [CmdletBinding()]
    param(
        [Parameter( Position = 0,
                    ValueFromPipeline,
                    ValueFromPipelineByPropertyName)]
        [Alias("CN", "Computer")]
        [String[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [Switch]
        $Detailed,

        [Parameter()]
        [Switch]
        $SkipConfigurationManagerClientCheck,

        [Parameter()]
        [Switch]
        $SkipPendingFileRenameOperationsCheck
    )

    begin {
        $hklm = [UInt32]"0x80000002"
        $invokeWmiMethodParameters = @{
            Namespace    = 'root/default'
            Class        = 'StdRegProv'
            Name         = 'EnumKey'
            ErrorAction  = 'Stop'
        }
    }

    process {

        if ($Credential) {$invokeWmiMethodParameters.Credential = $Credential}

        foreach ($computer in $ComputerName) {

            $invokeWmiMethodParameters.ComputerName = $computer

            try {
                ## Query the Component Based Servicing Reg Key
                $invokeWmiMethodParameters.ArgumentList = @($hklm,'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\')
                $registryComponentBasedServicing = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootPending'

                ## Query WUAU from the registry
                $invokeWmiMethodParameters.ArgumentList = @($hklm,'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')
                $registryWindowsUpdateAutoUpdate = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootRequired'

                ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
                $invokeWmiMethodParameters.ArgumentList = @($hklm,'SYSTEM\CurrentControlSet\Services\Netlogon')
                $registryNetlogon = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames
                $pendingDomainJoin = ($registryNetlogon -contains 'JoinDomain') -or ($registryNetlogon -contains 'AvoidSpnSet')

                ## Query ComputerName and ActiveComputerName from the registry and setting the MethodName to GetMultiStringValue
                $invokeWmiMethodParameters.Name = 'GetMultiStringValue'
                $invokeWmiMethodParameters.ArgumentList = @($hklm,'SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\','ComputerName')
                $registryActiveComputerName = Invoke-WmiMethod @invokeWmiMethodParameters

                $invokeWmiMethodParameters.ArgumentList = @($hklm,'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\','ComputerName')
                $registryComputerName = Invoke-WmiMethod @invokeWmiMethodParameters

                $pendingComputerRename = $registryActiveComputerName -ne $registryComputerName -or $pendingDomainJoin

                ## Query PendingFileRenameOperations from the registry
                if (-not $SkipPendingFileRenameOperationsCheck.IsPresent) {
                    $invokeWmiMethodParameters.ArgumentList = @($hklm,'SYSTEM\CurrentControlSet\Control\Session Manager\','PendingFileRenameOperations')
                    $registryPendingFileRenameOperations = (Invoke-WmiMethod @invokeWmiMethodParameters).sValue
                    $registryPendingFileRenameOperationsBool = [bool]$registryPendingFileRenameOperations
                }

                ## Query ClientSDK for pending reboot status, unless SkipConfigurationManagerClientCheck is present
                if (-not $SkipConfigurationManagerClientCheck.IsPresent) {
                    $invokeWmiMethodParameters.NameSpace = 'ROOT\ccm\ClientSDK'
                    $invokeWmiMethodParameters.Class = 'CCM_ClientUtilities'
                    $invokeWmiMethodParameters.Name = 'DetermineifRebootPending'
                    $invokeWmiMethodParameters.Remove('ArgumentList')

                    try {
                        $sccmClientSDK = Invoke-WmiMethod @invokeWmiMethodParameters
                        $systemCenterConfigManager = $sccmClientSDK.ReturnValue -eq 0 -and ($sccmClientSDK.IsHardRebootPending -or $sccmClientSDK.RebootPending)
                    } catch {
                        $systemCenterConfigManager = $null
                        Write-Warning -Message "CCM Error on '$($computer)': $($_.Exception.Message)"
                    }
                }

                $isRebootPending = $registryComponentBasedServicing -or
                    $pendingComputerRename -or
                    $pendingDomainJoin -or
                    $registryPendingFileRenameOperationsBool -or
                    $systemCenterConfigManager -or
                    $registryWindowsUpdateAutoUpdate

                if ($Detailed.IsPresent) {
                    [PSCustomObject]@{
                        ComputerName                     = $computer
                        ComponentBasedServicing          = $registryComponentBasedServicing
                        PendingComputerRenameDomainJoin  = $pendingComputerRename
                        PendingFileRenameOperations      = $registryPendingFileRenameOperationsBool
                        PendingFileRenameOperationsValue = $registryPendingFileRenameOperations
                        SystemCenterConfigManager        = $systemCenterConfigManager
                        WindowsUpdateAutoUpdate          = $registryWindowsUpdateAutoUpdate
                        IsRebootPending                  = $isRebootPending
                    }
                } else {
                    [PSCustomObject]@{
                        ComputerName    = $computer
                        IsRebootPending = $isRebootPending
                    }
                }
            } catch {
                Write-Error "$($Computer): $($_.Exception.Message)"
            }
        }
    }
}#END: function Test-PendingReboot
