function Test-URL {

   <#
   .SYNOPSIS
   Tests to see if the given URL returns an OK result.
   #>

    param( 
       [string]$url = $NULL
    )
 
    [bool]$validUrl = $false
 
    try {
      $req = [System.Net.HttpWebRequest]::Create($url);
      $res = $req.GetResponse()
 
      if($res.StatusCode -eq "OK") {
         $validUrl = $true
      }
      $res.Close(); 
    } catch {
       Write-Host "Invalid UpdateSource. File Not Found: $url" -ForegroundColor Red
       $validUrl = $false
       throw;
    }
 
    return $validUrl
 }
 # https://github.com/OfficeDev/Office-IT-Pro-Deployment-Scripts
 