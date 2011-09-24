Function Get-PortNumber
{
    param(
		[hashtable] $configParams
    )
	
	#Load the script parameters from the config file
	[array] $nodes = ($Global:ScriptConfigs | ?{$_.Name -eq "Get-PortNumber"}).SelectNodes("Param")
	$portNumber = ($nodes | ? {$_.Name -eq "PortNumber"}).Value
	
	[array] $missing = $nodes | ? {$_.Value -eq ""}
	if ($missing.Count -gt 0)
	{
		Write-Log -level "Attention" -message "Port number not set - please check the Run-Install.config file for missing configuration items"
	}
    
    #Read the PortNumber or set to default value if missing 
	$port = $configParams["PortNumber"]
	if ($port -eq $null -or $port -eq "")
	{
		$port = $portNumber
	}
	
	$instanceName = $configParams["InstanceName"]
	$sqlVersion = $configParams["SqlVersion"]

    #If for some reason we still don't have a valid port number then use the SQL default
	if ($port -isnot [int])
	{
		$port = 1433
    }
	
    return $port
}
