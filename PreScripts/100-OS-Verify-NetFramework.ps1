#/* 2005,2008,2008R2,2012,2014,2016 */

###############################################################################################################
# PowerShell Script Template
###############################################################################################################
# For use with the Auto-Install process
#
# When called, the script will recieve a single hashtable object passed as a 
# parameter.  This object contains the following properties:
#	$params["SqlVersion"] - Version of SQL being installed (SQL2005, SQL2008, SQL2008R2)
#   $params["SqlEdition"] - Edition of SQL being installed (Standard, Enterprise)
#	$params["ProcessorArch"] - CPU Architecture (x86, X64)
#	$params["InstanceName"] - The name that the instance will be installed with (sqldev1)
#   $params["ServiceAccount"] - The name of the account to run the services under (domain\user)
#   $params["FilePath"] - path to save the configuration ini file
#
# To add additional parameters - add them to the hashtable passed to the Run-Install function
#
# This script should be placed in the appropriate scripts folder and will be automatically called during the 
# auto-install process.
#
# The script should be saved using the following naming convention:
# 
# Pre Install Script (Save to PreScripts Folder) -
# -------------------------------------------------
# Pre-100-OS-[ScriptName].ps1
# Pre-200-Service-[ScriptName].ps1
#
# Post Install Script (Save to SQLScripts Folder) -
# -------------------------------------------------
# 100-OS-[ScriptName].ps1
# 200-Service-[ScriptName].ps1
# 300-Server-[ScriptName].ps1
# 400-Database-[ScriptName].ps1
# 500-Table-[ScriptName].ps1
# 600-View-[ScriptName].ps1
# 700-Procedure-[ScriptName].ps1
# 800-Agent-[ScriptName].ps1
###############################################################################################################

$configParams = $args[0]
	
#Verify .NetFramework 3.5 SP1 is installed 
$framework = Get-ItemProperty -path "HKLM:\Software\Microsoft\NET Framework Setup\ndp\v3.5" -name "SP"
if($framework.SP -ge 1)
{
    #Correct version installed
    Write-Log -level "Info" -message ("The .net framework 3.5 is at SP 1 or greater - SP{0}" -f $framework.SP)
}
else
{
    #Not the correct version
    Write-Log -level "Error" -message ("The .net framework 3.5 needs to be SP 1 or greater - SP{0}" -f $framework.SP)
}
