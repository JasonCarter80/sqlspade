Function Get-Strong-Password() {
    Param(
        [int]$length=12
    )

    $a = [Reflection.Assembly]::LoadWithPartialName("System.Web") 
    $([System.Web.Security.Membership]::GeneratePassword($length,$length/4))
}


