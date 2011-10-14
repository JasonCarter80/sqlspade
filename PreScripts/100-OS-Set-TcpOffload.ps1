#/* 2005,2008,2008R2,2012 */

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
	
#Check that the TCP Offload Chimney is disabled.  TOE & the TCP Offload Chimney are disabled by default in Windows 2008, but considering the amount of trouble this has caused us it can’t hurt to double check.  Issue this at the command prompt to verify “netsh int tcp show global” (no quotes).
#If not disabled, run as Administrator of command prompt

#Check the OS version becuase the command is different between 2003 and 2008
$ver = Get-OsVersion

switch ($ver)
{
    "2003" {Netsh int ip set chimney DISABLED}
    "2008" {netsh int tcp set global chimney=disabled}
    "Unknown" {return "Unable to set TCP Offload Chimney on unrecognized OS"}
}

Write-Log -level "Info" -message "TCP Offload Chimney has been disabled"
