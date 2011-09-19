@echo off
set curr_path=%~dp0%Start-SqlSpade.ps1
rem echo "%curr_path%"

echo Opening the Start-SqlSpade script using PowerShell ISE 

powershell.exe -NoProfile "start-process PowerShell_ISE.exe -argumentlist %curr_path% -verb RunAs"

IF %ERRORLEVEL% NEQ 0 GOTO Error

:Error
echo Unable to open Start-SqlSpade.ps1 - please verify that the file is present and that the PowerShell ISE is installed
pause