#/* 2005,2008,2008R2,2012,2014,2016,2017 */

###############################################################################################################
# PowerShell Script Template
###############################################################################################################
# For use with the Auto-Install process
#
# When called, the script will recieve a single hashtable object passed as a parameter.
# This object contains the following items by default:
#	SqlVersion - version being installed
#	SqlEdition - edition being installed
#	ServiceAccount - service account being used
#	ServicePassword - password for service account
#	SysAdminPassword - SA password
#	FilePath - working folder for auto-install
#	DataCenter - data center the server is located in
#	DbaTeam - responsible DBA team
#	InstanceName - SQL instance name
#	ProductStringName - product features being installed
#	Environment - environment for server (dev, qa, bcp, prod)
#
# Additional items can be added by using the Add method on the $ht object in the Start-SqlSpade.ps1 script
#
# You can access any of these items using the following syntax: $configParams["SqlVersion"]
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
# 900-Management-ScriptName.ps1
###############################################################################################################

$configParams = $args[0]
$instance = $configParams["InstanceName"]
$computerName = gc env:computername
$instanceName = $computerName + '\' + $instance
Enable-SqlAlwaysOn -ServerInstance $instanceName -Force