###############################################################################################################
# PowerShell Script Template
###############################################################################################################
# For use with the Auto-Install process
#
# When called, the script will recieve a single SQLConfigFileGeneratorLib.ConfigParams object passed as a 
# parameter.  This object contains the following properties:
#	$params.SqlVersion - Version of SQL being installed (SQL2005, SQL2008, SQL2008R2)
#   $params.SqlEdition - Edition of SQL being installed (Standard, Enterprise)
#	$params.ProcessorArch - CPU Architecture (x86, X64)
#	$params.InstanceName - The name that the instance will be installed with (sqldev1)
#   $params.ServiceAccount - The name of the account to run the services under (domain\user)
#   $params.FilePath - path to save the configuration ini file
#	$params.DbaTeam - DBA Team responsible for the server instance - will be added to the extended props for Master and Model
#
# The script must not require any parameters otehr than this object listed above
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
