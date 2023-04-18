function Test-Ping {
    <#
    .SYNOPSIS
    Allows ping testing with variable timeout and count
    .DESCRIPTION
    Ping with variable millisecond timeout and max count
    .EXAMPLE
    Test-Ping 'server01.domain.local', '127.0.0.1'
    .EXAMPLE
    Test-Ping -Computer $Server
    .EXAMPLE
    Test-Ping -IPAddress $Server -Timeout 250
    .EXAMPLE
    Test-Ping -IPAddress $Server -Timeout 250 -Quiet
    .NOTES
    Ping Object
    (New-Object System.Net.NetworkInformation.Ping|gm send|% Definition) -split ', (?=System\.Net\.NetworkInformation\.PingReply)' -join "`n`n`n"
    #>
    [CmdletBinding()]
    [Alias('psping')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)]
        [Alias('ComputerName','Server')]
        [string]
        $IPAddress,

        # Time, in milliseconds
        [Parameter()]
        [ValidateNotNull()]
        [Alias('Wait','Milliseconds')]
        [int]
        $Timeout=1200,

        [Parameter()]
        [ValidateNotNull()]
        [Alias('Max','Times')]
        [int]
        $Count=1,

        [Parameter()]
        [ValidateRange(1,128)]
        [Alias('Hops')]
        [int]
        $Ttl=24,

        [Parameter()]
        [switch]
        $Quiet
    )

    begin {

        $ping = New-Object System.Net.NetworkInformation.Ping
        $byteBuffer = [byte[]](@(0) * 32)
    
        $options = New-Object System.Net.NetworkInformation.PingOptions(24, $true)
        <# PingOptions
        Ttl          Property   int Ttl {get;set;}
        DontFragment Property   bool DontFragment {get;set;}
        #>
    }

    process {

        if ($ttl -ne 24) {$options.Ttl = $Ttl}
        foreach ($item in $IPAddress) {

            foreach ($send in 1..$count) {
                <# Send() Method
                System.Net.NetworkInformation.PingReply Send(
                    string hostNameOrAddress, 
                    int timeout, 
                    byte[] buffer, 
                    System.Net.NetworkInformation.PingOptions options
                )
                #>
                $result = $ping.Send($item,$timeout,$byteBuffer,$options)

                if ($Quiet.IsPresent) {
                    $result.Status -eq 'Success'
                } else {
                    $result
                }
            }
        }
    }
}#END: function Test-Ping
