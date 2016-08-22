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
# 900-Management-[ScriptName].ps1
###############################################################################################################

$configParams = $args[0]
$instanceName = $configParams["InstanceName"]

#Load the script parameters from the config file
[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Resize-TempDB"}).SelectNodes("Param")
$maxFileCount = ($nodes | ? {$_.Name -eq "MaxFileCount"}).Value
$maxFileInitialSizeMB = ($nodes | ? {$_.Name -eq "MaxFileInitialSizeMB"}).Value
$maxFileGrowthSizeMB = ($nodes | ? {$_.Name -eq "MaxFileGrowthSizeMB"}).Value
$fileGrowthMB = ($nodes | ? {$_.Name -eq "FileGrowthMB"}).Value
$coreMultiplier = ($nodes | ? {$_.Name -eq "CoreMultiplier"}).Value

[array] $missing = $nodes | ? {$_.Value -eq ""}
if ($missing.Count -gt 0)
{
	return "Script not executed: please check the Run-Install.config file for missing configuration items"
}

$wmi = Get-WmiObject Win32_OperatingSystem
[array] $procs = Get-WmiObject Win32_Processor

#get the number of physical procs and cores
$totalProcs = $procs.Count
$totalCores = 0

foreach ($proc in $procs)
{
    $totalCores = $totalCores + $proc.NumberOfCores
}

#get the amount of total memory (MB) 
$totalMemory = ($wmi.TotalVisibleMemorySize / 1024)

#calculate the number of files needed (= number of procs)
$fileCount = $totalCores * $coreMultiplier

if ($fileCount -gt $maxFileCount)
{
    $fileCount = $maxFileCount
}

#calculate file size (total memory / number of files)
$fileSize = $totalMemory / $fileCount

if ($fileSize -gt $maxFileInitialSizeMB)
{
    $fileSize = $maxFileInitialSizeMB
}

#build the sql command
$command = "
declare @data_path varchar(300);

select 
	@data_path = replace([filename], '.mdf','')
from 
	sysaltfiles s
where
	name = 'tempdev';

ALTER DATABASE [tempdb] MODIFY FILE ( NAME = N'tempdev', SIZE = {0}MB , MAXSIZE = {1}MB, FILEGROWTH = {2}MB );
" -f $fileSize, $maxFileGrowthSizeMB, $fileGrowthMB

for ($i = 2; $i -le $fileCount; $i++)
{
    $command =  $command + "
declare @stmnt{3} nvarchar(500)
select @stmnt{3} = N'ALTER DATABASE [tempdb] ADD FILE ( NAME = N''tempdev{3}'', FILENAME = ''' + @data_path + '{3}.mdf'' , SIZE = {0}MB , MAXSIZE = {1}MB, FILEGROWTH = {2}MB )';
exec sp_executesql @stmnt{3};
    " -f $fileSize, $maxFileGrowthSizeMB, $fileGrowthMB, $i        
}

#execute the sql command
Write-Log -level "Info" -message "Resizing TempDB to contain $fileCount files that are each $fileSize MB in size"

Execute-SqlCommand -sqlScript $command -sqlInstance $instanceName

Write-Log -level "Info" -message "Resizing TempDB Complete"
