@echo off
REM Set the window title
title Start SQL SPADE
REM Clear the console
cls

REM *********************************************************************************
REM * Set path to script file
REM *********************************************************************************
set curr_path=%~dp0%Start-SqlSpade.ps1
REM echo "%curr_path%"

REM *********************************************************************************
REM * Check to see if we are on a Server 2003 installation
REM *********************************************************************************
ver | find "[Version 5." > nul
if %ERRORLEVEL% == 0 goto RunNonCore

ver | find "2003" > nul
if %ERRORLEVEL% == 0 goto RunNonCore

REM *********************************************************************************
REM * Check to see if we are on a Server Core installation
REM *********************************************************************************
FOR /F "tokens=*" %%A IN ('WMIC OS Get OperatingSystemSKU /Value ^| FIND "="') DO (SET %%A)

REM ECHO OperatingSystemSKU=%OperatingSystemSKU%

IF %OperatingSystemSKU% gtr 11 IF %OperatingSystemSKU% lss 15 GOTO RunCore
GOTO RunNonCore


REM *********************************************************************************
REM * Core - so the PowerShell ISE is not available
REM *********************************************************************************
:RunCore
echo Opening the Start-SqlSpade script using Notepad
powershell.exe -NoProfile "start-process notepad.exe -wait -argumentlist %curr_path% -verb RunAs"
GOTO RunCoreMenu

REM *********************************************************************************
REM * Core Menu - are you ready to execute the script
REM *********************************************************************************
:RunCoreMenu
echo.
set /p web=Would you like to (R)un the script or (E)xit SPADE?
if "%web%"=="R" goto LaunchScript
if "%web%"=="r" goto LaunchScript
if "%web%"=="L" goto LaunchScriptLogged
if "%web%"=="l" goto LaunchScriptLogged
if "%web%"=="E" goto End 
if "%web%"=="e" goto End
echo.
echo Invalid Selection
GOTO RunCoreMenu

REM *********************************************************************************
REM * Launch the start-sqlspade.ps1 script directly
REM *********************************************************************************
:LaunchScript
echo Running Script...
REM powershell.exe "start-process PowerShell.exe -wait -argumentlist %curr_path% -verb RunAs"
powershell.exe %curr_path%
GOTO End

REM *********************************************************************************
REM * Launch the start-sqlspade.ps1 script directly with logging
REM *********************************************************************************
:LaunchScriptLogged
echo Running Script...
REM powershell.exe "start-process PowerShell.exe -wait -argumentlist %curr_path% -verb RunAs"
powershell.exe %curr_path% > SetupLog.txt
GOTO End

REM *********************************************************************************
REM * Not Core - so we have the PowerShell ISE available
REM *********************************************************************************
:RunNonCore
echo Opening the Start-SqlSpade script using PowerShell ISE 

powershell.exe -NoProfile "start-process PowerShell_ISE.exe -argumentlist %curr_path% -verb RunAs"

REM IF %ERRORLEVEL% NEQ 0 GOTO ErrorNonCore
GOTO End

REM *********************************************************************************
REM * An error ocurred when trying to launch the ISE
REM *********************************************************************************
:ErrorNonCore
echo Unable to open Start-SqlSpade.ps1 - please verify that the file is present 
echo and that the PowerShell ISE is installed then run again
pause

REM *********************************************************************************
REM * Exit the batch
REM *********************************************************************************
:End
PAUSE