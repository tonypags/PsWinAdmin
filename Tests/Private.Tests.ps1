Describe 'Private Tests' {
    
    # Import Private functions
    BeforeAll {
        $script:privItems = Get-ChildItem $PSScriptRoot\..\Private\*.ps1
        $script:privItems | ForEach-Object {. $_.FullName}
        $script:funcNames = @($script:privItems.BaseName)
    }
    
    Context 'Test Private Functions' {

        # Check for Private Functions in Test Memory Space
        BeforeAll {
            if ($script:privItems) {
                foreach ($item in $script:privItems) {
                    (Get-Command $item.BaseName).Name | Should -Be $item.BaseName
                }
            } else {
                1 | Should -Be 1
            }
        }

        # Remove the tested item from the initial array
        AfterEach {
            $script:funcNames = $script:funcNames | Where-Object {$_ -ne $script:thisName}
        }

        # Unit tests ...

        It 'Checks the placeholder file' {
            placeholder | Should -Be $thisName

            $script:thisName = 'placeholder'
        }

    }

    Context 'Clean up' {

        It 'Ensures all  private functions have tests' {
            $script:funcNames | Should -BeNullOrEmpty
        }
    }

}
