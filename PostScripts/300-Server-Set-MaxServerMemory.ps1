#/* 2005,2008,2008R2 */

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
	
#Verify that proper amount of memory was installed on server
$winOS = Get-WMIObject Win32_OperatingSystem
$serverMem = $winOS.TotalVisibleMemorySize

if ($serverMem -ge 4194304) #4GB
{
    #Server mem - 2GB
    $maxMem = $serverMem - 2097152  
}
elseif ($serverMem -le 1048576) #4GB
{
    #Server mem - 512MB 
    $maxMem = $serverMem - 524288 
}
else
{
    #Server mem - 1GB 
    $maxMem = $serverMem - 1048576 
}

#convert to MB and drop any decimal places
[int] $maxMem = $maxMem / 1024
[int] $serverMem = $serverMem / 1024

$command = "exec sp_configure 'show advanced options', 1;
RECONFIGURE;
exec sp_configure 'max server memory', $maxMem;
RECONFIGURE;"

Write-Log -level "Info" -message "The server has $serverMem MB of total memory"
Write-Log -level "Info" -message "Setting Max Server Memory to $maxMem MB"

$instance = $configParams["InstanceName"]

Execute-SqlCommand -sqlScript $command -sqlInstance $instance
