function Get-ADAdminPwdHistory {

    param ()

    if (!(Get-Module ActiveDirectory)) {
        Throw "ActiveDirectory module required!"
    }

    Get-ADGroupMember -Identity "Domain Admins" | 
    Get-ADUser -Properties PasswordLastSet, PasswordNeverExpires |
    Select-Object Name, PasswordLastSet, PasswordNeverExpires

}


