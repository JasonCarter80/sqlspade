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

#Load the script parameters from the config file
[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Verify-MgmtServerAccess"}).SelectNodes("Param")
$paramServers = ($nodes | ? {$_.Name -eq "Servers"}).Value

[array] $missing = $nodes | ? {$_.Value -eq ""}
if ($missing.Count -gt 0)
{
	return "Script not executed: please check the Run-Install.config file for missing configuration items"
}

#Split the comma separated list of services into an array
[array] $checks = $paramServers.Split(',')

#Loop through the array to perform the check
foreach($check in $checks)
{
	$ping_result = Ping-Server $check
	if($ping_result -eq "Success")
	{
		Write-Log -level "Info" -message ("Ping Results for $check : " + $ping_result)
	}
	else
	{
		Write-Log -level "Warning" -message ("Ping Results for $check : " + $ping_result)
	}
}

#$computerName = gc env:computername
#	
##Verify access to management servers
#$ping_result = Ping-Server "stegodon1"
#	if($ping_result -eq "Success")
#	{
#		Write-Log -level "Info" -message ("Ping Results for Stegodon1: " + $ping_result)
#	}
#	else
#	{
#		Write-Log -level "Warning" -message ("Ping Results for Stegodon1: " + $ping_result)
#	}
#
#
#$dataCenter = $configParams["DataCenter"]
#
#if ($dataCenter -eq "St Pete")
#{
#	$ping_result = Ping-Server "walrus1xa"
#	if($ping_result -eq "Success")
#	{
#		Write-Log -level "Info" -message ("Ping Results for Walrus1xa: " + $ping_result)
#	}
#	else
#	{
#		Write-Log -level "Warning" -message ("Ping Results for Walrus1xa: " + $ping_result)		
#	}
#}
#elseif ($dataCenter -eq "Southfield")
#{
#	$ping_result = Ping-Server "walrus1xb"
#	if($ping_result -eq "Success")
#	{
#		Write-Log -level "Info" -message ("Ping Results for Walrus1xb: " + $ping_result)
#	}
#	else
#	{
#		Write-Log -level "Warning" -message ("Ping Results for Walrus1xb: " + $ping_result)		
#	}	
#}
