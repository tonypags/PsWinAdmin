$Public = Get-ChildItem $PSScriptRoot\Public\*.ps1
Foreach ($File in $Public) {
    . $File.FullName
}
Export-ModuleMember -Function * -Alias * -Variable *

$Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ea 0
Foreach ($File in $Private) {
    . $File.FullName
}
