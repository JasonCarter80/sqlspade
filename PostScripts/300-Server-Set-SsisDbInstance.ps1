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

###############################################################################################################################
#<?xml version="1.0" encoding="utf-8"?>
#<DtsServiceConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
#  <StopExecutingPackagesOnShutdown>true</StopExecutingPackagesOnShutdown>
#  <TopLevelFolders>
#    <Folder xsi:type="SqlServerFolder">
#      <Name>MSDB</Name>
#      <ServerName>.</ServerName>
#    </Folder>
#    <Folder xsi:type="SqlServerFolder">
#        <Name>File System</Name>
#      <StorePath>..\Packages</StorePath>
#    </Folder>
#  </TopLevelFolders>  
#</DtsServiceConfiguration>
###############################################################################################################################

$configParams = $args[0]
$instanceName = $configParams["InstanceName"]
$sqlVersion = $configParams["SqlVersion"]
$productString = $configParams["ProductString"]

##Debug
#$instanceName = "SQL2008R2"
#$sqlVersion = "SQL2008R2"

if ($productString -contains "SQL_DTS" -or $productString -contains "IS")
{
	switch ($sqlVersion)
	{
	    "SQL2012" {$filePath = "C:\Program Files\Microsoft SQL Server\110\DTS\Binn\MsDtsSrvr.ini.xml"}
	    "SQL2008R2" {$filePath = "C:\Program Files\Microsoft SQL Server\100\DTS\Binn\MsDtsSrvr.ini.xml"}
	    "SQL2008" {$filePath = "C:\Program Files\Microsoft SQL Server\100\DTS\Binn\MsDtsSrvr.ini.xml"}
	    "SQL2005" {$filePath = "C:\Program Files\Microsoft SQL Server\90\DTS\Binn\MsDtsSrvr.ini.xml"}
	}

	if (Test-Path $filePath)
	{
	    $xml = [xml](gc $filePath)
	    $root = $xml.SelectSingleNode("./DtsServiceConfiguration/TopLevelFolders/Folder[1]/ServerName")

	    #If there is no instance name then use the default instance
	    if ($instanceName -ne "")
	    {
	        $root.InnerText = ".\$instanceName"
	    }
	    else
	    {
	        $root.InnerText = "."
	    }

	    $xml.Save($filePath)
	    
	    Write-Log -level "Info" -message "The SSIS configuration has been updated to use the $instanceName instance"
	}
	else
	{
	    throw "Unable to locate the SSIS configuration file at $filePath"
	}
}
else
{
	Write-Log -level "Attention" -message "The SSIS configuration file has not been updated becuase Integration Services was not selected to be installed"
}