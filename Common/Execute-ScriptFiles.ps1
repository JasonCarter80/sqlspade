Function Execute-ScriptFiles
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)] $configParams,
		[Parameter(Position=1, Mandatory=$true)] [ValidateSet("pre", "post")] $sequence
	)
	
	[string] $sqlVersion = $configParams.SqlVersion
	[string] $sqlInstance = $configParams.InstanceName
	
	#Load a list of all files from the appropriate scripts folder (\\ray\dba_public$\cur_installs\SqlScripts) - Added exclusion for files that start with "_"
	if ($sequence -eq "pre")
	{
		#write-log -level "Info" -message ("PreScripts: " + $Global:PreScripts)
		#[array] $files = (get-childitem -path $Global:PreScripts | ?{-not ($_.Name -like "_*")})
		[array] $files = get-childitem -path $Global:PreScripts
        $count = $files.Count
		$message = "Applying $count Standard Pre-Install Scripts"
	}
	else
	{
		#write-log -level "Info" -message ("PostScripts: " + $Global:PostScripts)
		#[array] $files = (get-childitem -path $Global:PostScripts | ?{-not ($_.Name -like "_*")})
		[array] $files = get-childitem -path $Global:PostScripts
		$count = $files.Count
        $message = "Applying $count Standard Post-Install Scripts"
	}
	
	#Sort the list on file name (file name should start with script level - 100 OS, 200 Service, 300 Server, 400 Database, 500 Table, 600 View, 700 Procedure, 800 Agent)
	$files = $files | Sort-Object
	
	#write-log -level "Info"  -message $files
	
	Write-Log -level "Section" -message $message
	
	#Loop through the list
	foreach ($file in $files) 
	{
		#Read the first line of each file (/* 2005,2008,2008R2 */)
		[string] $strSupported = Get-Content -Path $file.FullName -TotalCount 1
		
		#Clean off the /* */ from the first line and split to a string array
		#Original code - .Net method using the replace method of the string object		
		#[array] $arySupported = $strSupported.Replace('/*', '').Replace('*/', '').Trim().Split(',')
		#Code showing the PowerShell + RegEx method of performing the same task
		$arySupported = $strSupported -replace '#' -replace '/\*|\*/' -replace '^\s+|\s+$' -split ','
		
		if (-not ($file.Name -like "_*"))
		{
			#If the current version is contained in the array then execute the script using the appropriate execute function
			if ($arySupported -contains $($sqlVersion -replace "SQL"))
			{
				if ($file.Extension -eq ".sql")
				{
					#Write the script name and results (query results or skipped) to the log
					Write-Log -level "Info" -message "##########################################################################################"
					Write-Log -level "Info" -message "# Executing SQL Script - $file"
					Write-Log -level "Info" -message "##########################################################################################"
					$strResult = Execute-SQL -sqlScript $file.FullName -sqlInstance $sqlInstance
					
					if ($strResult -eq "Command(s) completed successfully.")
					{
						Write-Log -level "Info" -message "$file - $strResult"
					}
					elseif ($strResult -like '*A transport-level error has occurred when sending the request to the server*')
					{
						$strResult = Execute-SQL -sqlScript $file.FullName -sqlInstance $sqlInstance
						
						if ($strResult -eq "Command(s) completed successfully.")
						{
							Write-Log -level "Info" -message "$file - $strResult"
						}
						else
						{
							Write-Log -level "Warning" -message "$file - Failed: $strResult"
						}	
					}
					else
					{
						Write-Log -level "Warning" -message "$file - Failed: $strResult"
					}	
				}
				elseif ($file.Extension -eq ".ps1")
				{
					#Write the script name and results (query results or skipped) to the log
					Write-Log -level "Info" -message "##########################################################################################"
					Write-Log -level "Info" -message "# Executing PowerShell Script - $file"
					Write-Log -level "Info" -message "##########################################################################################"
					
					try
					{
						$strResult = Execute-Powershell -psScript $file.FullName -configParams $configParams
						
						if ($strResult -eq "" -or $strResult -eq $null)
						{
							Write-Log -level "Info" -message "$file - Command(s) completed successfully."
						}
						else
						{
							Write-Log -level "Info" -message "$file - $strResult"
						}
					}
					catch
					{
						$strResult = $_
						Write-Log -level "Warning" -message "$file - Failed: $strResult"
					}
				}
				else
				{
					Write-Log -level "Attention" -message "Skipping Script - $file - Unsupported script type"
				}
			}
			else
			{
				Write-Log -level "Attention" -message "Skipping Script - $file - Does not apply to this SQL version"
			}
		}
		else
		{
			Write-Log -level "Attention" -message "Skipping Script - $file - Script has been marked as excluded (filename starts with '_')"
		}
	#Next
	}
	Write-Log -level "Info" -message "Standard Scripts Complete"
}
