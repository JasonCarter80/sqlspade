@echo off
set curr_path=%~dp0%Run-Install.ps1
rem echo "%curr_path%" 

echo Opening the Run-Install Script Using PowerShell ISE

powershell.exe -NoProfile "start-process PowerShell_ISE.exe -argumentlist %curr_path% -verb RunAs"