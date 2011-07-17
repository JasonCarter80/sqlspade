Function Verify-IsAdmin
{
    $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
    $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin=$prp.IsInRole($adm)
    if ($IsAdmin)
    {
        #"You are currently running with Administrator priviledges"
		#I needed the Out-Null because when -WhatIf or -Confirm are used it produces output to the console
		#that interferes with the return value of the function
        Write-Log -level "Info" -message ("Script running as admin by {0}" -f $prp.Identity.Name) | Out-Null
        return 1
    }
    else
    {
        #"Please launch this script again as an administrator"
        Write-Log -level "Error" -message "User did not run script as Admin" | Out-Null
        return 0
    }
}
