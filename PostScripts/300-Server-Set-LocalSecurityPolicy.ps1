#/* 2005,2008,2008R2,2012,2014,2016,2017 */

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
# 900-Management-[ScriptName].ps1
###############################################################################################################

$configParams = $args[0]
$serviceAccount = $configParams["ServiceAccount"]	
$ntrights = Join-Path -Path $Global:Packages -ChildPath "ntrights.exe"

#Sample executions with output
#.\ntrights.exe -u "alfki\Sql_Service" +r SeLockMemoryPrivilege
# Granting SeLockMemoryPrivilege to alfki\Sql_Service   ... successful
#.\ntrights.exe -u "administrators" +r SeLockMemoryPrivilege
# Granting SeLockMemoryPrivilege to administrators   ... successful
#.\ntrights.exe -u "alfki\Sql_Service" +r SeServiceLogonRight
# Granting SeServiceLogonRight to alfki\Sql_Service   ... successful
#.\ntrights.exe -u "administrators" +r SeServiceLogonRight
# Granting SeServiceLogonRight to administrators   ... successful

if (Test-Path $ntrights)
{
	$result = Invoke-Expression "$ntrights -u `"Administrators`" +r SeLockMemoryPrivilege"
	Write-Log -level "Info" -message "Local Security Policy - Admin - Lock Pages: $result"
	$result = Invoke-Expression "$ntrights -u `"$serviceAccount`" +r SeLockMemoryPrivilege"
	Write-Log -level "Info" -message "Local Security Policy - Service Acct - Lock Pages: $result"
	$result = Invoke-Expression "$ntrights -u `"Administrators`" +r SeServiceLogonRight"
	Write-Log -level "Info" -message "Local Security Policy - Admin - Logon As Service: $result"
	$result = Invoke-Expression "$ntrights -u `"$serviceAccount`" +r SeServiceLogonRight"
	Write-Log -level "Info" -message "Local Security Policy - Service Acct - Logon As Service: $result"
}
else
{
	Write-Log -level "Attention" -message "Unable to locate ntrights.exe - please ensure that it is located in the Packages folder"	
}
