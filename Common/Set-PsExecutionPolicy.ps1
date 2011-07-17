Function Set-PsExecutionPolicy
{
    #In both x64 & x86 versions of PowerShell issue a Set-ExecutionPolicy RemoteSigned
    $systemRoot = gc env:systemroot
    cd $systemRoot 
    system32\WindowsPowerShell\v1.0\powershell.exe -NonInteractive -Command {Set-ExecutionPolicy RemoteSigned -force} #64bit
    
    if(test-path "syswow64\WindowsPowerShell\v1.0")
    {
        syswow64\WindowsPowerShell\v1.0\powershell.exe -NonInteractive -Command {Set-ExecutionPolicy RemoteSigned -force} #32bit
    }
    Write-Log -level "Info" -message "PowerShell Execution Policy set to RemoteSigned"
}
