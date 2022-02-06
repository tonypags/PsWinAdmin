Describe 'Private Tests' {
    
    # Import Private functions
    BeforeAll {
        $privItems = Get-ChildItem $PSScriptRoot\..\Private\*.ps1
        $privItems | ForEach-Object {. $_.FullName}
        $script:funcNames = @($privItems.BaseName)
    }
    
    Context 'Test Private Functions' {

        # Check for Private Functions in Test Memory Space
        BeforeAll {
            if ($privItems) {
                foreach ($item in $privItems) {
                    (Get-Command $item.BaseName).Name | Should -Be $item.BaseName
                }
            } else {
                1 | Should -Be 1
            }
        }

        # Remove the tested item from the initial array
        AfterEach {
            $script:funcNames = $script:funcNames | Where-Object {$_ -ne $thisName}
        }

        # Unit tests ...

        It 'Checks the placeholder file' {
            $thisName = 'placeholder'
            placeholder | Should -Be $thisName
        }

    }

    Context 'Clean up' {

        It 'Ensures all  private functions have tests' {
            $script:funcNames | Should -BeNullOrEmpty
            $script:funcNames | Should -Be $thisName
        }
    }

}
