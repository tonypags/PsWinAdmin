function Test-PasswordComplexity {
    <#
    .SYNOPSIS
    Checks a secure string to ensure it will meet M$FT default password requirements.
    .DESCRIPTION
    Checks a secure string to ensure it will meet M$FT default
    password requirements. The username may not be part of the
    password. The rule for Unicode Characters will not apply.
    Only the 4 rules for A-Z, a-z, 0-9, and any symbol on a
    standard US keyboard... of which 3 must be satisfied.
    .EXAMPLE
    Test a previously saved cred
    Test-PasswordComplexity -Credential $Cred
    .EXAMPLE
    Save a new cred and immediately test it for complexity.
    Get-Credential -ov Cred | Test-PasswordComplexity -Quiet
    .NOTES
    M$FT Documentation:
    https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
    Just on or off. Per my ADDS SME, admins can do some things with fine grained password policies, but they are a ton of work.

    The choice to not test for Unicode Characters was made to simplify this function. Streamlined for production use. 2/23/24 -TP

    A copy of this function may live in another module, but this file should be considered the truth-copy.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [PsCredential[]]
        $Credential,

        # Return only a boolean result for the given cred/secret
        [Parameter()]
        [switch]
        $Quiet
    )#END: param()

    begin {
        # ArrayContruct - This is now the preferred syntax
        $OutputObject = [System.Collections.Generic.List[System.Object]]@()
        $thisSecret = ''

        $ptnRule1 = '[A-Z]'
        $ptnRule2 = '[a-z]'
        $ptnRule3 = '\d'
        $ptnRule4 = '''|-|!|"|#|\$|%|&|\(|\)|\*|,|\.|\/|:|;|\?|@|\[|\]|\^|_|`|\{|\||\}|~|\+|<|=|>' # via M$FT doc
    }

    process {
        foreach ($item in $Credential) {
            
            $score = 0
            $thisSecret = $item.GetNetworkCredential().Password
            $likeUsername = $thisSecret -like "*$($item.Username)*"
            if ($thisSecret -cmatch $ptnRule1) {$score++}
            if ($thisSecret -cmatch $ptnRule2) {$score++}
            if ($thisSecret -match  $ptnRule3) {$score++}
            if ($thisSecret -match  $ptnRule4) {$score++}
            Remove-Variable -Name 'thisSecret' -Force
            $OutputObject.Add([PSCustomObject]@{
                Username = $item.Username
                Password = $item.Password
                Pass     = $score -ge 3 -and -not $likeUsername
                Score    = $score
                LikeUser = $likeUsername
            })
        }#END: foreach ($item in $Credential)
    }#END process {}

    end {
        if ($Quiet.IsPresent) {
            $OutputObject.Pass
        } else {
            $OutputObject
        }
    }
}#END: function Test-PasswordComplexity
