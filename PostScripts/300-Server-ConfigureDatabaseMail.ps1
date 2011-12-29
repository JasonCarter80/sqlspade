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
# 900-Management-[ScriptName].ps1
###############################################################################################################

$configParams = $args[0]
#$instanceName = "SQL2008R2"
$computerName = gc env:computername
$instanceName = $configParams["InstanceName"]

#Load the script parameters from the config file
[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Configure-DatabaseMail"}).SelectNodes("Param")
$email = ($nodes | ? {$_.Name -eq "Email"}).Value
$relay = ($nodes | ? {$_.Name -eq "Relay"}).Value
$replyTo = ($nodes | ? {$_.Name -eq "ReplyTo"}).Value
$displayName = ($nodes | ? {$_.Name -eq "DisplayName"}).Value
$profileName = ($nodes | ? {$_.Name -eq "ProfileName"}).Value

#Handle expanding the computername alias if used
$email = $email.Replace("[computername]", $computerName)
$displayName = $displayName.Replace("[computername]", $computerName)
$profileName = $profileName.Replace("[computername]", $computerName)

[array] $missing = $nodes | ? {$_.Value -eq ""}
if ($missing.Count -gt 0)
{
	Write-Log -level "Attention" -message "Port number not set - please check the Run-Install.config file for missing configuration items"
}

$command = @"
USE [master];

/* Enable Database Mail for this instance */
EXECUTE sp_configure 'show advanced', 1;
RECONFIGURE;
EXECUTE sp_configure 'Agent XPs', 1;
RECONFIGURE;
EXECUTE sp_configure 'Database Mail XPs', 1;
RECONFIGURE;

/* Create a Database Mail account */
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'Primary Account',
    @description = 'Account used by all mail profiles.',
    @email_address = '$email',
    @replyto_address = '$replyTo',
    @display_name = '$displayName',
    @mailserver_name = '$relay';
 
/* Create a Database Mail profile */
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = '$profileName',
    @description = 'Default public profile for all users';
 
/* Add the account to the profile */
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = '$profileName',
    @account_name = 'Primary Account',
    @sequence_number = 1;
 
/* Grant access to the profile to all msdb database users */
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = '$profileName',
    @principal_name = 'public',
    @is_default = 1;
"@

#write-log -level "Info" -message "Debug Command: $command"

$result = Execute-SqlCommand -sqlScript $command -sqlInstance $instanceName

if ($result -ne "Command(s) completed successfully.")
{
	throw $result
}
