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
$instanceName = $configParams["InstanceName"]
$computerName = (gc env:computername)
$dnsName = (gc env:userdnsdomain)

#Load the script parameters from the config file
[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Add-CMSRegistration"}).SelectNodes("Param")
$cmsServer = ($nodes | ? {$_.Name -eq "CMSServer"}).Value
$cmsInstance = ($nodes | ? {$_.Name -eq "CMSInstance"}).Value

[array] $missing = $nodes | ? {$_.Value -eq ""}
if ($missing.Count -gt 0)
{
	return "Script not executed: please check the Run-Install.config file for missing configuration items"
}

if([string]::IsNullOrEmpty($instanceName))
{
	#Default Instance
	$name = $computerName
}
else
{
	$name = $computerName + "\" + $instanceName
}


$groupId = 0 #Needs to be set to the appropriate group id

$portNumber = Get-PortNumber -instanceName $instanceName -computerName $computerName
$serverName = "$computerName.$dnsName,$portNumber"

#Our standard is to use lower case for server registrations
$serverName = $serverName.ToLower()
$name = $name.ToLower()

$description = "Added by auto-install process"
$serverType = 0
$serverId = 0

$command = "exec msdb.dbo.sp_sysmanagement_add_shared_registered_server
                @name = '$name',
                @server_group_id = $groupId,
                @server_name = '$serverName',
                @description = '$description',
                @server_type = $serverType,
                @server_id = $serverId"

Execute-SqlCommand -sqlScript $command -sqlInstance $cmsInstance -serverName $cmsServer -databaseName "msdb"

Write-Log -level "Info" -message "$serverName has been added to the Central Management Server on $cmsServer\$cmsInstance"
