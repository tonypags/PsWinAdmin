function Get-MdmHardwareId {
    [CmdletBinding()]
    param (
        # Name of the device to query
        [Parameter(Position=0)]
        [string[]]
        $ComputerName = $env:COMPUTERNAME
    )
    
    begin {
        Confirm-RequiresAdmin -ea Stop
        $cimSplat = @{
            Namespace = 'root/cimv2/mdm/dmmap'
            Class = 'MDM_DevDetail_Ext01'
            Filter = "InstanceID='Ext' AND ParentID='./DevDetail'"
            ErrorAction = 'Stop'
        }    
    }
    
    process {

        Foreach ($Computer in $ComputerName) {

            # Add computername if not this computer
            if (@($env:COMPUTERNAME,'localhost') -notcontains $Computer) {
                $cimSplat.Add('ComputerName',$Computer)
            }
    
            $HardwareID = Try {

                Get-CimInstance @cimSplat | Select-Object -ExpandProperty DeviceHardwareData

            } Catch {

                Try {

                    Get-WmiObject @cimSplat | Select-Object -ExpandProperty DeviceHardwareData

                } Catch {

                    Throw "Data Collection Failed on $($Computer): $($_.Exception.Message)"

                }

            } Finally {

                if ($cimSplat.Keys -contains 'ComputerName') {
                    $cimSplat.Remove('ComputerName')
                }

            }

            if ($HardwareID) {

                [pscustomobject]@{
                    ComputerName = $Computer
                    DeviceHardwareData = $HardwareID
                }

            }
    
        }
        
    }
    
    end {
        
    }
}
