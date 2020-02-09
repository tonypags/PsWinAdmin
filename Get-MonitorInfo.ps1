function Get-MonitorInfo {

    <#
    .SYNOPSIS
    Returns Monitor/LCD information.
    .DESCRIPTION
    Returns Monitor/LCD information via WMI.
    .EXAMPLE
    Get-MonitorInfo | Select-Object -ExpandProperty SerialNumberID
    #>
    
    Get-CimInstance -ClassName WmiMonitorID -Namespace root\wmi -pv screen| ForEach-Object {

        $data = @{}

        $screen.PSObject.Properties.Name | ForEach-Object {

            $data[$_] = if ($screen.$_ -is [array])
            {
                try
                {
                    [System.Text.Encoding]::UTF8.GetString($screen.$_)
                }
                catch
                {
                    $screen.$_
                }
            }
            else
            {
                $screen.$_
            }

        }

        [PSCustomObject]$data
    }
}
