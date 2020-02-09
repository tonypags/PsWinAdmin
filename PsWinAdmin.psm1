# All below copied from PSExcel module, with the DLL part removed. 

#handle PS2
if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

#Get public and private function definition files.
$Public = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue

#Dot source the files
Foreach ($import in @($Public)) {
    Try {
        #PS2 compatibility
        if ($import.fullname) {
            . $import.fullname
        }
    }
    Catch {
        Write-Error "Failed to import function $($import.fullname): $_"
    }
}
    
#Create some aliases, export public functions
### This is now handled in manifest
Export-ModuleMember -Function $($Public | Select -ExpandProperty BaseName) -Alias *

