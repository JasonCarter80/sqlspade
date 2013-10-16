#/* 2005,2008,2008R2,2012 */

###############################################################################################################
# PowerShell Script Template
###############################################################################################################
# For use with the Auto-Install process
#
# When called, the script will recieve a single hashtable object passed as a 
# parameter.  This object contains the following properties:
#   $params["SqlVersion"] - Version of SQL being installed (SQL2005, SQL2008, SQL2008R2)
#   $params["SqlEdition"] - Edition of SQL being installed (Standard, Enterprise)
#   $params["ProcessorArch"] - CPU Architecture (x86, X64)
#   $params["InstanceName"] - The name that the instance will be installed with (sqldev1)
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

#$instanceName = "SQL2008R2"
$computerName = gc env:computername

$portNumber = Get-PortNumber $configParams

$instanceName = $configParams["InstanceName"]
$SqlVersion = $configParams["SqlVersion"]


Write-Log -level "Info" -message "The SQL TCP port number is being set to $portNumber"


if ($SqlVersion -eq "SQL2005")
{
	#Load the required assembly for 2005
	[system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
}
else
{
	#Load the required assembly for 2008+
	[system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
}

#Get the ManagedComputer instance and set the protocol properties
$wmi = new-object ("Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer") $computerName
$wmi.ServerInstances["$instanceName"].ServerProtocols["Tcp"].IPAddresses["IPAll"].IPAddressProperties["TcpPort"].value = "$portNumber"
$wmi.ServerInstances["$instanceName"].ServerProtocols["Tcp"].IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].value = [System.String]::Empty

#We need to commit the changes by calling the Alter method
$wmi.ServerInstances["$instanceName"].ServerProtocols["Tcp"].Alter()

#Verify the results and write them to the log
$curPort = $wmi.ServerInstances["$instanceName"].ServerProtocols["Tcp"].IPAddresses["IPAll"].IPAddressProperties["TcpPort"].value
$curDynPort = $wmi.ServerInstances["$instanceName"].ServerProtocols["Tcp"].IPAddresses["IPAll"].IPAddressProperties["TcpDynamicPorts"].value

Write-Log -level "Info" -message "The SQL TCP port number is currently set to $curPort"
Write-Log -level "Info" -message "The SQL TCP Dynamic port number is currently set to $curDynPort"
