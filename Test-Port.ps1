function Test-Port {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [Alias('ComputerName')]
        [string]
        $IPAddress,

        [Parameter(Mandatory)]
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
