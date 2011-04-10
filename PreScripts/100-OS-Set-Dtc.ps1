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
	
#Verify Local DTC has been installed and enabled for network access (Will be set-up the same way as MSDTC in Win2003 / SQL2005 http://support.microsoft.com/default.aspx?scid=kb;en-us;816701)

Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccess" -value 1                #Network DTC Access
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessTransactions" -value 1    #Allow inbound
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessInbound" -value 1         #Allow inbound
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessOutbound" -value 1        #Allow Outbound
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessAdmin" -value 1           #Allow Remote Administration
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessClients" -value 1         #Allow Remote Clients
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "XaTransactions" -value 1                  #Enable XA Transactions
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC" -name "AllowOnlySecureRpcCalls" -value 0                  #No Authentication Required
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC" -name "FallbackToUnsecureRPCIfNecessary" -value 0         #No Authentication Required
Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC" -name "TurnOffRpcSecurity" -value 1                       #No Authentication Required
Write-Log -level "Info" -message "DTC has been configured for network access"
