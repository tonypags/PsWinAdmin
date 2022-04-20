function Test-Port {
    <#
    .SYNOPSIS
    Allows port testing with variable timeout
    .DESCRIPTION
    Allows TCP port testing with variable timeout
    .EXAMPLE
    Test-Port Server1 443
    .EXAMPLE
    Test-Port -Computer Server1 -Port 443
    .EXAMPLE
    Test-Port -IPAddress Server1 -Port 443 -Timeout 250
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('ComputerName')]
        [string]
        $IPAddress,

        [Parameter(Mandatory,Position=1)]
        [Alias('TcpPort')]
        [int]
        $Port,

        # Time, in milliseconds
        [Parameter()]
        [ValidateNotNull()]
        [Alias('Wait')]
        [int]
        $Timeout=1200
    )

    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.ConnectAsync($IPAddress, $Port).Wait($Timeout)

}#END: function Test-Port
