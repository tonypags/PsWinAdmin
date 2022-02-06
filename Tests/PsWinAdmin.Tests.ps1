Describe 'PsWinAdmin Tests' {

    BeforeAll {
        Import-Module "PsWinAdmin" -ea 0 -Force
        $script:thisModule = Get-Module -Name "PsWinAdmin"
        $script:funcNames = $thisModule.ExportedCommands.Values |
            Where-Object {$_.CommandType -eq 'Function'} |
            Select-Object -ExpandProperty Name
    }

    Context 'Test Module import' {

        It 'Ensures module is imported' {
            $script:thisModule.Name | Should -Be 'PsWinAdmin'
        }

    }

    Context 'Test PsWinAdmin Functions' {
        
        BeforeAll {
            $script:info = Get-SeasonInfo
            $script:year = $script:info.SeasonYear
            $script:Sched = Get-GsisScheduleApi
        }
        
        # Remove the tested item from the initial array
        AfterEach {
            $script:funcNames = $script:funcNames | Where-Object {$_ -ne $script:thisName}
        }
        
        It 'Formats JSON objects' {
            $json = Get-Process | ConvertTo-Json -Compress
            $json.gettype().name | Should -Be 'String'
            
            $nice = $json | Format-Json -AsArray
            $nice.Count | Should -BeGreaterThan 10000
            
            $nono = $nice | Format-Json -Compress
            $nono.count | Should -Be 1
            $nono -match '\n' | Should -Be $false

            $nice = $json | Format-Json
            $nice.count | Should -Be 1
            $nice.gettype().name | Should -Be 'String'
            $nice -match '\n' | Should -Be $true

            $script:thisName = 'Format-Json'
        }

    }

    
    Context 'Clean up' {

        It 'Ensures all public functions have tests' {
            $script:funcNames | Should -BeNullOrEmpty
        }
        
    }

}
