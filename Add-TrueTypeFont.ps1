# issue discovered here: 
# https://eddiejackson.net/wp/?p=16137

function Add-TrueTypeFont {
    
    <#
    .SYNOPSIS
    Adds TTF files to Windows.
    .DESCRIPTION
    Adds TTF files to Windows Control Panel on the local computer only. Must run as admin.
    .EXAMPLE
    dir \\server\share\fonts\*.ttf | Add-TrueTypeFont
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [ValidatePattern('.+\.ttf$')]
        [Alias('FilePath','FullName')]
        [string[]]
        $Path
    )
    
    begin {
        
        # Namespace ID
        $FONTS = 0x14
        
        Set-Variable -Name ErrorActionPreference -Scope Script -Value 'Stop'

        Try {

            $objShell = New-Object -ComObject Shell.Application

        } Catch {
            
            throw "Missing COMObject: Shell.Application"

        }

        Try {
            
            $objFolder = $objShell.Namespace($FONTS)
            
        } Catch {
            
            throw "Unable to load Font Namespace:`n$($_.Exception.Message)"
            
        }
        
        Set-Variable -Name ErrorActionPreference -Scope Script -Value 'SilentlyContinue'
        
    }
    
    process {

        Foreach ($p in $Path) {

            $objFile = Get-Item $p
            $FontName = $objFile.name
            if (Test-Path "c:\windows\fonts\$FontName") {

                Write-Verbose "Font already installed: $($FontName)"

            } else {

                if (Test-Path $objFile.FullName) {

                    $CopyOptions = 4 + 16; # from https://www.reddit.com/r/sysadmin/comments/a64lax/windows_1809_breaks_powershell_script_to_install/ebs68wj?utm_source=share&utm_medium=web2x
                    [void]($ObjFolder.CopyHere($objFile.fullname, $CopyOptions));
                    $regPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
                    New-ItemProperty -Name $objFile.fullname -Path $regPath -PropertyType string -Value ($objFile.fullname)
                    
                    # Test each action
                    $Installed = Get-Font $FontName
                    if ($Installed) {
                        Write-Verbose "Font successfully installed: $($FontName)"
                    } else {
                        Write-Warning "Font not installed: $($FontName)!"
                    }

                } else {
        
                    Write-Warning "Path not found: $($objFile.fullname)"
                
                }

            }

        }

    }
    
    end {

        if ($Error) {

            $Error | ForEach-Object { Write-Verbose $_.Exception.Message }

        }

    }

}

