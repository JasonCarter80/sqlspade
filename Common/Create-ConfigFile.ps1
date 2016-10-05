Function Create-ConfigFile
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)][hashtable] $params,
		[Parameter(Position=1, Mandatory=$false)][hashtable] $overrides
	)
	
	#Get the template path from params
	$templateName = $params["TemplateName"]
	$category = $params["TemplateCategory"]
	
	#Define the required variables
	#Handle the fact that Evaluation editions don't use keys
	if ($params["SqlEdition"] -ne "Evaluation")
	{
		#PID="$Key"
		$Key = $params["ProductKey"]
	}
	
	#INSTANCENAME="$InstanceName"
	$InstanceName = $overrides["InstanceName"]
	
	#INSTANCEID="$InstanceId" 
	$InstanceId = $overrides["InstanceName"]
	

	#FEATURES="$ProductString"
	$ProductString = $params["ProductString"]
	
	#X86="$X86"
	switch ($params["ProcessorArch"])
	{
		"X86" 	{$X86 = "True"}
		"X64" 	{$X86 = "False"}
		default	{$X86 = "False"}
	}

 	#SQLSVCACCOUNT="$SqlSvcAccount"
 	$sqlSvcAccount = $overrides["sqlSvcAccount"]
  	
  	#AGTSVCACCOUNT="$AgtSvcAccount"
 	$agtSvcAccount = $overrides["agtSvcAccount"]
  	
  	#ISSVCACCOUNT="$IsSvcAccount"
 	$isSvcAccount = $overrides["isSvcAccount"]
    
  	#RSSVCACCOUNT="$rsSvcAccount"
 	$rsSvcAccount = $overrides["rsSvcAccount"]

  	#AsSVCACCOUNT="$asSvcAccount"
 	$asSvcAccount = $overrides["asSvcAccount"]   	

  	#FTSVCACCOUNT="$FTSvcAccount"
 	$ftSvcAccount = $overrides["ftSvcAccount"]
	
	#Load the Config File Template into an array
	$templateFile = Join-Path -Path $Global:Templates -ChildPath $templateName
	[array] $template = gc $templateFile
	
	#copy the file to the destination path
	$configFile = Join-Path -Path $Global:RootPath -ChildPath "Configuration.ini"
	Copy-Item -Path $templateFile -Destination $configFile -Force
	Set-Content -Path $configFile -Value "" -Force
	
	#Load key/value pairs from the array into the $ini hashtable
	$ini = New-Object hashtable

foreach ($line in $template)
	{
		if ($line -like "*=*")
		{
			$pair = $line -split "="

            
			if (!$ini.ContainsKey($pair[0]))
			{	
				# Invoke-Expression allows us to evaluate any variables stored in the template
				$val = Invoke-Expression $pair[1]
				Write-Log -Level Debug "Adding from Template: $($pair[0]) = $val"
                $ini.Add($pair[0], $val)
			} 
		}
	}
	
	#Set the Slipstream update locations for installs other than SQL 2005
	if ($params["SqlVersion"] -ne "SQL2005")
	{
		$folders = Get-ChildItem -Path $Global:BinariesPath
	
		foreach ($folder in $folders)
		{	
			if ($folder.Attributes -eq "Directory")
			{
				if ($folder.Name -like "SP*")
				{
					if ($ini.ContainsKey("PCUSOURCE"))
					{
						$ini["PCUSOURCE"] = $folder.FullName
                        Write-Log -Level Debug "Found SP Folder, overriding:  PCUSOURCE = $($folder.FullName)"
					}
					else
					{
						$ini.Add("PCUSOURCE", $folder.FullName)
                        Write-Log -Level Debug "Found SP Folder, adding:  PCUSOURCE = $($folder.FullName)"
					}
				}
				elseif ($folder.Name -like "CU*")
				{
					if ($ini.ContainsKey("CUSOURCE"))
					{
						$ini["CUSOURCE"] = $folder.FullName
                        Write-Log -Level Debug "Found CU Folder, overriding:  CUSOURCE = $($folder.FullName)"
					}
					else
					{
						$ini.Add("CUSOURCE", $folder.FullName)
                        Write-Log -Level Debug "Found CU Folder, adding:  CUSOURCE = $($folder.FullName)"
					}
				}
			}
		}
		
		#Remove the SP/CU configuration if there is nothing set
		if ($ini["PCUSOURCE"] -eq "")
		{
			$ini.Remove("PCUSOURCE")
            Write-Log -Level Debug "Removing PCUSOURCE: Empty"						
		}
		if ($ini["CUSOURCE"] -eq "")
		{
			$ini.Remove("CUSOURCE")
            Write-Log -Level Debug "Removing CUSOURCE: Empty"						
		}
		
		#Remove the PID if there is nothing set
		if ($params["SqlEdition"] -eq "Evaluation")
		{
			$ini.Remove("PID")
            Write-Log -Level Debug "Removing PID - Evaluation Version"						
		}
	}
	#Add any entries from the overrides hastable
	foreach ($override in $overrides.GetEnumerator())
	{
		if ($ini.ContainsKey($override.Key))
		{
            Write-Log -Level Debug "Overriding:  $($override.Key) = $($override.Value)"			
            $ini[$override.Key] = $override.Value
		}
		else
		{
            Write-Log -Level Debug "Adding:  $($override.Key) = $($override.Value)"						
            $ini.Add($override.Key, $override.Value)
		}
	}
	
	#Loop thorugh the $ini hashtable writing each key/value pair to the ini file
	foreach($item in $ini.GetEnumerator() | sort -Property name)
	{	
		#Special handling for Directory settings that may contain spaces and aren't already quoted
		if (($item.Key -like "*DIR" -OR $item.Key -like "*ACCOUNT")  -and $item.Value -match '^[^/"]*$')
		{ 
			$value = "`"" + $item.Value + "`""
		} 
		else 
		{
			$value = $item.Value
		}
		
		Set-PrivateProfileString -file $configFile -category $category -key $item.Key.ToString().ToUpper() -value $value 
	}
	
	#Return the path of the ini file
	return $configFile
}
