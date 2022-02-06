function Receive-TcpMessage {
    <#
    .SYNOPSIS
    Listens for request on a port.
    .DESCRIPTION
    This tool allows the adminitrator to open a port and listen for connections.
    .PARAMETER Port
    The port number to listen on for incoming connections.
    .EXAMPLE
    Network Engineering tells you the port 8080 change request you made for
    web1 was completed. Test this by going to the new web server and running:

    PS > Receive-TCPMessage -Port 8080
    _

    Then on another computer, test that connection:

    PS > Test-NetConnection -ComputerName $c -Port 8080

    ComputerName           : web1
    RemoteAddress          : 10.10.10.11
    RemotePort             : 8080
    InterfaceAlias         : Ethernet 2
    SourceAddress          : 10.10.10.81
    PingSucceeded          : True
    PingReplyDetails (RTT) : 137 ms
    TcpTestSucceeded       : False

    Note that the test failed. Check the local firewall settings before
    complaining to Network Engineering.
    #>
    [CmdletBinding()]
    param( 
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()] 
        [int] $Port
    )

    Try { 
        # Set up endpoint and start listening
        $endpoint = new-object System.Net.IPEndPoint([ipaddress]::any,$port) 
        $listener = new-object System.Net.Sockets.TcpListener $EndPoint
        $listener.start() 

        # Wait for an incoming connection 
        $data = $listener.AcceptTcpClient() 
    
        # Stream setup
        $stream = $data.GetStream() 
        $bytes = New-Object System.Byte[] 1024

        # Read data from stream and write it to host
        while (($i = $stream.Read($bytes,0,$bytes.Length)) -ne 0){
            $EncodedText = New-Object System.Text.ASCIIEncoding
            $data = $EncodedText.GetString($bytes,0, $i)
            Write-Output $data
        }
        
        # Close TCP connection and stop listening
        $stream.close()
        $listener.stop()
    } Catch {
        "Receive Message failed with: `n" + $Error[0]
    }

}#END: function Receive-TcpMessage {}
