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

$computerName = gc env:computername

#Load the script parameters from the config file
[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Verify-AdminGroup"}).SelectNodes("Param")
$paramDomain = ($nodes | ? {$_.Name -eq "Domain"}).Value
$paramGroup = ($nodes | ? {$_.Name -eq "Group"}).Value

[array] $missing = $nodes | ? {$_.Value -eq ""}
if ($missing.Count -gt 0)
{
	return "Script not executed: please check the Run-Install.config file for missing configuration items"
}

#Verify configured group has been added to local administrators group
$computer = [ADSI]("WinNT://" + $computerName + ",computer")  
$group = $computer.psbase.children.find("Administrators")
[array] $result = $group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name",'GetProperty',$null,$_,$null)} | where {$_ -eq $group}  

if($result -ne "$paramDomain\$paramGroup")
{
	$formatted = "WinNT://{0}/{1}" -f $paramDomain, $paramGroup
    $group.Add($formatted)
    Write-Log -level "Info" -message "$paramGroup account has been added to the local admin group"
}
else
{
    Write-Log -level "Info" -message "$paramGroup account is already present in the local admin group"
}
