function New-RetentionConfig {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Path to the new config file, it will be created.
        [Parameter(Position=0)]
        [string]
        $ConfigPath = (Join-Path $PSScriptRoot 'retention.cfg.psd1'),

        # Overwrite an existing file with the same name.
        [Parameter()]
        [switch]
        $Force
    )

    $defaultTemplate = @'
## This file must contain a hash table for all paths
## (KEY=pathToParentFolder, VALUE=retentionInDays)
<#
@{
    'c:\users\user\logs\*.log' = 30
    'c:\users\joe\temp\' = 90
}
#>
## This example will delete all .log files older than 30 days from user's 'logs' folder. 
## This example also deletes the files older than 90 days from joe's 'temp' folder. 
## Add as many key=value pairs as paths you need to purge/retain files by date.

@{
    
}
'@
    $defaultTemplate | Out-File $ConfigPath -Force:$Force
}
