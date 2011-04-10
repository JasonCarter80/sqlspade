Function Execute-SqlScriptFiles
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)] [string] $sqlVersion,
		[Parameter(Position=1, Mandatory=$true)] [string] $sqlInstance
	)
	
	#$tempPath 		= [environment]::GetEnvironmentVariable("temp","machine")
	#$tempPath
	#$Script:LogFile = join-path -path $tempPath -childPath "SqlInstallerLog_ScriptTest.html"
	
	#Load a list of all files from the scripts folder (\\ray\dba_public$\cur_installs\SqlScripts)
	[array] $files = get-childitem -path '\\walrus1xb\f$\cur_installs\sqlscripts' -filter '*.sql'
	
	#Sort the list on file name (file name should start with script level - 100 OS, 200 Service, 300 Server, 400 Database, 500 Table, 600 View, 700 Procedure, 800 Agent)
	$files = $files | Sort-Object
	
	Write-Log -level "Section" -message "Aplying Standard SQL Scripts"
	
	#Loop through the list
	foreach ($file in $files) 
	{
		#Read the first line of each file (/* 2005,2008,2008R2 */)
		[string] $strSupported = Get-Content -Path $file.FullName -TotalCount 1
		
		#Clean off the /* */ from the first line and split to a string array
		#Original code - .Net method using the replace method of the string object		
		#[array] $arySupported = $strSupported.Replace('/*', '').Replace('*/', '').Trim().Split(',')
		
		#Code showing the PowerShell + RegEx method of performing the same task
		$arySupported = $strSupported -replace '/\*|\*/' -replace '^\s+|\s+$' -split ','
		
		#If the current version is contained in the array then execute the script using the Execute-Sql function
		if ($arySupported -contains $($sqlVersion -replace "sql"))
		{
			#Write the script name and results (query results or skipped) to the log
			Write-Log -level "Info" -message "Executing SQL Script - $file"
			$strResult = Execute-SQL -sqlScript $file.FullName -sqlInstance $sqlInstance
			if ($strResult -eq "Command(s) completed successfully.")
			{
				Write-Log -level "Info" -message "$file - $strResult"
			}
			else
			{
				Write-Log -level "Warning" -message "$file - Failed: $strResult"
           		if ($sqlConn.State -ne [System.Data.ConnectionState]'Closed')
        		{
        			$sqlConn.Close()
        			Write-Log -level "Info" -message "Closing Connection"
        		}
			}
		}
		else
		{
			Write-Log -level "Feature" -message "Skipping SQL Script - $file"
		}
	#Next
	}
	Write-Log -level "Info" -message "Standard SQL Scripts Complete"
}
