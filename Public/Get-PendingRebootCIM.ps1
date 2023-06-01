function Get-PendingRebootCIM {
    <#
    .NOTES
    This function replaces Get-PendingReboot and no longer requires WMI/RPC/DCOM
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNull()]
        [Microsoft.Management.Infrastructure.CimSession]
        $CimSession=(New-CimSession -ComputerName 'localhost')
    )

    ## Querying WMI for build version
    $WMI_OS = Get-CimInstance -CimSession $cimSession -Class Win32_OperatingSystem -Property BuildNumber, CSName -ErrorAction Stop

    ## Making registry connection to the local/remote computer
    $cimProps = @{
        CimSession = $CimSession
        # Namespace  = 'ROOT\CIMv2'
        Namespace  = 'root\default'
        ClassName  = 'StdRegProv'
    }

    $HKLM = [UInt32] "0x80000002" # MI type MI_STRING
    # https://learn.microsoft.com/en-us/windows/win32/wmisdk/mapping-a-registry-data-type-to-a-wmi-data-type?redirectedfrom=MSDN
    <# EXAMPLES
    HKEY_CLASSES_ROOT (2147483648 (0x80000000))
    HKEY_CURRENT_USER (2147483649 (0x80000001))
    HKEY_LOCAL_MACHINE (2147483650 (0x80000002))
    HKEY_USERS (2147483651 (0x80000003))
    HKEY_CURRENT_CONFIG (2147483653 (0x80000005))
    #>

    ## If Vista/2008 & Above query the CBS Reg Key
    if ([Int32]$WMI_OS.BuildNumber -ge 6001) {
        $Arguments = @{
            hDefKey = $HKLM
            sSubKeyName = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
        }
        $cimProps.MethodName = 'EnumKey'
        $ReturnValue = (Invoke-CimMethod @cimProps -Arguments $Arguments).ReturnValue
        $CBSRebootPend = if ($ReturnValue -eq 2) {
            $false
        } elseif ($ReturnValue -eq 1) {
            $true
        } elseif ($ReturnValue -eq 0) {
            $false
        } else {
            Write-Error "Unhandled ReturnValue: $($ReturnValue)"
            $null
        }
    } else {
        $CBSRebootPend = $null
    }

    ## Query WUAU from the registry
    $Arguments = @{
        hDefKey = $HKLM
        sSubKeyName = 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\RebootPending\Auto Update\RebootRequired'
    }
    $cimProps.MethodName = 'EnumKey'
    $Result = Invoke-CimMethod @cimProps -Arguments $Arguments
    $WUAURebootReq = if ($Result.ReturnValue -eq 2) {$false} else {$true}

    ## Query PendingFileRenameOperations from the registry
    $Arguments = @{
        hDefKey = $HKLM
        sSubKeyName = 'SYSTEM\CurrentControlSet\Control\Session Manager\'
        sValueName = 'PendingFileRenameOperations'
    }
    $cimProps.MethodName = 'GetMultiStringValue'
    $Result = Invoke-CimMethod @cimProps -Arguments $Arguments
    $RegValuePFRO = $Result.sValue
    $PendFileRename = $null -ne $RegValuePFRO

    ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
    $Arguments = @{
        hDefKey = $HKLM
        sSubKeyName = 'SYSTEM\CurrentControlSet\Services\Netlogon\'
    }
    $cimProps.MethodName = 'EnumKey'
    $Netlogon = (Invoke-CimMethod @cimProps -Arguments $Arguments).sNames
    $PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

    ## Query ComputerName and ActiveComputerName from the registry
    $Arguments = @{
        hDefKey = $HKLM
        sSubKeyName = 'SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\'
        sValueName = 'ComputerName'
    }
    $cimProps.MethodName = 'GetStringValue'
    $ActCompNm = (Invoke-CimMethod @cimProps -Arguments $Arguments).sValue
    $Arguments.sSubKeyName = "SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\"
    $CompNm = (Invoke-CimMethod @cimProps -Arguments $Arguments).sValue

    ## Compare results and set output value
    $CompPendRen = ($ActCompNm -ne $CompNm) -or $PendDomJoin

    ## Determine SCCM 2012 Client Reboot Pending Status
    ## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
    $CCMClientSDK = $null
    $CCMSplat = @{
        CimSession = $CimSession
        NameSpace  = 'ROOT\ccm\ClientSDK'
        ClassName  = 'CCM_ClientUtilities'
        MethodName = 'DetermineIfRebootPending'
    }
    ## Try CCMClientSDK
    Try {
        $CCMClientSDK = Invoke-CimMethod @CCMSplat -ea Stop
    } Catch [System.UnauthorizedAccessException] {
        $CcmStatus = Get-CimInstance -CimSession $cimSession -ClassName 'win32_service' -Filter 'Name="CcmExec"'
        if ($CcmStatus.State -ne 'Running') {
            Write-Warning "$($WMI_OS.CSName)`: Error - CcmExec service is not running."
            $CCMClientSDK = $null
        }
    } Catch {
        $CCMClientSDK = $null
    }

    if ($CCMClientSDK) {
        if ($CCMClientSDK.ReturnValue -ne 0) {
            Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
        }
        $SCCM = $CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending
    } else {
        $SCCM = $null
    }

    ## Creating Custom PSObject and Select-Object Splat
    $SelectSplat = @{Property=(
        'Computer',
        'CBServicing',
        'WindowsUpdate',
        'CCMClientSDK',
        'PendComputerRename',
        'PendFileRename',
        'PendFileRenVal',
        'RebootPending'
    )}
    New-Object -TypeName PSObject -Property @{
        Computer           = $WMI_OS.CSName
        CBServicing        = $CBSRebootPend
        WindowsUpdate      = $WUAURebootReq
        CCMClientSDK       = $SCCM
        PendComputerRename = $CompPendRen
        PendFileRename     = $PendFileRename
        PendFileRenVal     = $RegValuePFRO
        RebootPending      = ($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
    } | Select-Object @SelectSplat

}## End Function Get-PendingRebootCIM
