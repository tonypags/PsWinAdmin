function Install-DotNet35 {
<# 
.EXAMPLE
Install-DotNet35
.NOTES
Run this command as a local admin. 
From https://raw.githubusercontent.com/LabtechConsulting/LabTech-Powershell-Module/master/LabTech.psm1
#>
	$DotNET = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse -EA 0 | Get-ItemProperty -name Version,Release -EA 0 | Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} | Select-Object -ExpandProperty Version -EA 0
	If (-not ($DotNet -like '3.5.*')){
		Write-Output ".NET Framework 3.5 installation needed."
		#Install-WindowsFeature Net-Framework-Core
		$OSVersion = [System.Environment]::OSVersion.Version

		If ([version]$OSVersion -gt [version]'6.2'){
			Try{
				If ( $PSCmdlet.ShouldProcess('NetFx3', 'Enable-WindowsOptionalFeature') ) {
					$Install = Get-WindowsOptionalFeature -Online -FeatureName 'NetFx3'
					If (!($Install.State -eq 'EnablePending')) {
						$Install = Enable-WindowsOptionalFeature -Online -FeatureName 'NetFx3' -All -NoRestart
					}
					If ($Install.RestartNeeded -or $Install.State -eq 'EnablePending') {
						Write-Output ".NET Framework 3.5 installed but a reboot is needed."
					}
				}
			}
			Catch{
				Write-Error "ERROR: Line $(LINENUM): .NET 3.5 install failed." -ErrorAction Continue
				If (!($Force)) { Write-Error ("Line $(LINENUM):",$Install) -ErrorAction Stop }
			}
		}
		ElseIf ([version]$OSVersion -gt [version]'6.1'){
			If ( $PSCmdlet.ShouldProcess("NetFx3", "Add Windows Feature") ) {
				Try {$Result=& "$env:windir\system32\Dism.exe" /English /NoRestart /Online /Enable-Feature /FeatureName:NetFx3 2>''}
				Catch {Write-Output "Error calling Dism.exe."; $Result=$Null}
				Try {$Result=& "$env:windir\system32\Dism.exe" /English /Online /Get-FeatureInfo /FeatureName:NetFx3 2>''}
				Catch {Write-Output "Error calling Dism.exe."; $Result=$Null}
				If ($Result -contains 'State : Enabled'){
					Write-Warning "WARNING: Line $(LINENUM): .Net Framework 3.5 has been installed and enabled."
				} ElseIf ($Result -contains 'State : Enable Pending'){
					Write-Warning "WARNING: Line $(LINENUM): .Net Framework 3.5 installed but a reboot is needed."
				} Else {
					Write-Error "ERROR: Line $(LINENUM): .NET Framework 3.5 install failed." -ErrorAction Continue
					If (!($Force)) { Write-Error ("ERROR: Line $(LINENUM):",$Result) -ErrorAction Stop }
				}#End If
			}#End If
		}#End If

		$DotNET = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | Get-ItemProperty -name Version -EA 0 | Where-Object{ $_.PSChildName -match '^(?!S)\p{L}'} | Select-Object -ExpandProperty Version
	}#End If

	If (-not ($DotNet -like '3.5.*')){
		If (($Force)) {
			If ($DotNet -match '(?m)^[2-4].\d'){
				Write-Error "ERROR: Line $(LINENUM): .NET 3.5 is not detected and could not be installed." -ErrorAction Continue
			} Else {
				Write-Error "ERROR: Line $(LINENUM): .NET 2.0 or greater is not detected and could not be installed." -ErrorAction Stop
			}#End If
		} Else {
			Write-Error "ERROR: Line $(LINENUM): .NET 3.5 is not detected and could not be installed." -ErrorAction Stop
		}#End If
	}#End If
}