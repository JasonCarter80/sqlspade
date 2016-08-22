#/* 2005,2008,2008R2,2012,2014,2016 */

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

$filePath 		= $configParams["FilePath"]
$scriptFolder 	= $configParams["WindowsScriptsFolder"]
$dbaDrive 		= $filePath.Substring(0,2)
$scriptsDrive	= $scriptFolder.Substring(0,2)

#Load the script parameters from the config file
[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Verify-Drives"}).SelectNodes("Param")
$paramFailOnFileSystem = ($nodes | ? {$_.Name -eq "FailOnFileSystem"}).Value
$paramFailOnDiskAlign = ($nodes | ? {$_.Name -eq "FailOnDiskAlign"}).Value
$paramFailOnCompressed = ($nodes | ? {$_.Name -eq "FailOnCompressed"}).Value

[array] $missing = $nodes | ? {$_.Value -eq ""}
if ($missing.Count -gt 0)
{
	return "Script not executed: please check the Run-Install.config file for missing configuration items"
}

# [array] $drives = gwmi win32_logicaldisk | where {$_.DriveType -eq 3 -or $_.Drive.Type -eq 4}
# foreach($drive in $drives)
# {
    # $path = $drive.DeviceID + "\test_file.txt"
    # New-Item $path -itemType File | out-null
    # Write-Log -level "Info" -message "Test file written - $path"
    # Remove-Item $path
    # Write-Log -level "Info" -message "Test file deleted - $path"
    
    # if($drive.DeviceID -eq "C:")
    # {
    	# Create-Folder 'C:\Windows\Script'
    # }
	
	# if($drive.DeviceID -eq $dbaDrive)
    # {
		# Create-Folder "$dbaDrive\Tools" 
		# Create-Folder "$dbaDrive\Tools\Install" 
		# Create-Folder "$dbaDrive\sqlrec" 
    # }
# }

[array] $drives = gwmi win32_Volume | where {$_.DriveType -eq 3 -or $_.Drive.Type -eq 4}
foreach($drive in $drives)
{
    #Check File System
    if ($drive.FileSystem -ne "NTFS")
    {
        if ($paramFailOnFileSystem -eq 1)
		{
			write-log -level "Error" -message "The $($drive.DriveLetter) drive is formatted as $($drive.FileSystem)"
		}
		else
		{
			write-log -level "Warning" -message "The $($drive.DriveLetter) drive is formatted as $($drive.FileSystem)"
		}
    }
    else
    {
        write-log -level "Info" -message "The $($drive.DriveLetter) drive is formatted as $($drive.FileSystem)"
    }
    
    #Check disk alignment
    if ($drive.BlockSize -ne "4096")
    {
        if ($paramFailOnDiskAlign -eq 1)
		{
			write-log -level "Error" -message "The $($drive.DriveLetter) drive does not appear to be disk aligned - Block Size:$($drive.BlockSize)"
		}
		else
		{
			write-log -level "Warning" -message "The $($drive.DriveLetter) drive does not appear to be disk aligned - Block Size:$($drive.BlockSize)"
		}
    }
    else
    {
        write-log -level "Info" -message "The $($drive.DriveLetter) drive appears to be disk aligned - Block Size:$($drive.BlockSize)"
    }
    
    #Check disk compression
    if ($drive.Compressed -eq $true)
    {
        if ($paramFailOnCompressed -eq 1)
		{
			write-log -level "Error" -message "The $($drive.DriveLetter) drive is compressed - SQL Server cannot use a compressed drive"
		}
		else
		{
			write-log -level "Warning" -message "The $($drive.DriveLetter) drive is compressed - SQL Server cannot use a compressed drive"
		}
    }
    else
    {
        write-log -level "Info" -message "The $($drive.DriveLetter) drive is not compressed"
    }

    $path = $drive.DriveLetter + "\test_file.txt"
    New-Item $path -itemType File | out-null
    Write-Log -level "Info" -message "Test file written - $path"
    Remove-Item $path
    Write-Log -level "Info" -message "Test file deleted - $path"
    
    if($drive.DriveLetter -eq $scriptsDrive)
    {
    	Create-Folder $scriptFolder
    }
	
	if($drive.DriveLetter -eq $dbaDrive)
    {
		Create-Folder "$filePath" 
		Create-Folder "$filePath\Install" 
		Create-Folder "$dbaDrive\sqlrec" 
    }
}