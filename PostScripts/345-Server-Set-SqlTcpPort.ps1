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
$sqlVersion = $configParams["SqlVersion"]
#$instanceName = "SQL2008R2"
$computerName = gc env:computername

$portNumber = Get-PortNumber -instanceName $instanceName -computerName $computerName

#if ($sqlVersion -eq "SQL2005")
#{
	$command = @"
	exec xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp\IPAll', N'TcpPort', REG_SZ, '$portNumber';
	/*exec xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp\IPAll', N'TcpDynamicPorts', REG_SZ, '""';*/	
"@
	
	Execute-SqlCommand -sqlScript $command -sqlInstance $instanceName
#}
#else
#{
#	[system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null
#	$wmi = new-object ("Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer") $computerName
#	$wmi.ServerInstances["$instanceName"].ServerProtocols["Tcp"].IPAddresses["IPAll"].IPAddressProperties["TcpPort"].value = "$portNumber"
#}

Write-Log -level "Info" -message "The SQL TCP port number has been set to $portNumber"
