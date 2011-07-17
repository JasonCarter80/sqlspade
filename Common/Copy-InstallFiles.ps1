Function Copy-InstallFiles
{
	param
	(
#		[Parameter(Position=0, Mandatory=$true)] [string] $computerName,
#		[Parameter(Position=1, Mandatory=$true)] [string] $sqlVersion,
#		[Parameter(Position=2, Mandatory=$true)] [string] $sqlEdition,
#		[Parameter(Position=3, Mandatory=$false)] [bool] $isX86 = $false
		[Parameter(Position=0, Mandatory=$true)] [hashtable] $params
	)
	
	$sqlVersion 	= $params["SqlVersion"]
	$sqlEdition 	= $params["SqlEdition"]
	$scriptFolder 	= $params["WindowsScriptsFolder"]
	[bool] $isX86	= $false
	$installCU		= Join-Path -Path $Global:Install -ChildPath "CU\"
	$installSP		= Join-Path -Path $Global:Install -ChildPath "SP\"
	$robocopyLog 	= Join-Path -Path $Global:RootPath -ChildPath "RoboCopyLogInstall.txt"
	$robocopyLogCU 	= Join-Path -Path $Global:RootPath -ChildPath "RoboCopyLogCU.txt"
	$robocopyLogSP 	= Join-Path -Path $Global:RootPath -ChildPath "RoboCopyLogSP.txt"
	$copyDoneFlag	= Join-Path -Path $Global:Install -ChildPath 'CopyComplete.txt'
	
	if (Test-Path $copyDoneFlag)
	{
		Write-Log -level "Info" -message "Installation files have already been copied"
		return
	}
	
	Write-Log -level "Info" -message "Copying PowerShell scripts to $scriptFolder"
	if($Global:Simulation)
	{
		Write-Output "Copy-Item -Path ($Global:Scripts + '*.*') -Destination $scriptFolder -Recurse"
	}
	else
	{
		if (Test-Path $Global:Scripts)
		{
			Copy-Item -Path ($Global:Scripts + '*.*') -Destination $scriptFolder -Recurse
		}
	}
	Write-Log -level "Info" -message "Copy of PowerShell scripts to $scriptFolder complete"
	
	$copySource = $Global:SourcePath
	$copySource += $sqlVersion
	$copySource += '\'
    $copyCU = $copySource + 'CU'
    $copySP = $copySource + 'SP'
	
	switch -wildcard ($sqlEdition)
	{
		"*32" 	{$copySource += ($sqlEdition -replace "32", "\x86"); $isX86 = $true}
		"*64" 	{$copySource += ($sqlEdition -replace "64", "\x64")}
		default {$copySource += $sqlEdition}
	}
	
	Write-Log -level "Info" -message ('Beginning copy of install files from ' + $copySource)
	
	#Robo copy took the operation from 16 minutes to 4 minutes for SQL 2008 SP 1 Slipstream
	#Copy-Item -Path $copySource -Destination 'S:\Tools\Install' -ErrorAction Stop -Recurse -WarningAction Stop
    #Check for RoboCopy (part of the resource kit since NT4 and standard on Server 2008 an up)
	if (Test-Path "C:\Windows\System32\Robocopy.exe")
	{
		$robocopy = $true
	}
	else
	{
		$robocopy = $false
		Write-Log -level "Warning" -message "RoboCopy is not present on this server, so the copy operations will take much longer."
	}
	
	if ($robocopy)
	{
		if($Global:Simulation)
		{
			Write-Output "robocopy $copySource $Global:Install /R:2 /W:5 /E /MT:8 /NP /LOG+:`"$robocopyLog`""
		}
		else
		{	
			robocopy $copySource $Global:Install /R:2 /W:5 /E /MT:8 /NP /LOG+:"$robocopyLog"
		}
	}
	else
	{
		if($Global:Simulation)
		{
			Write-Output "Copy-Item -Path $copySource -Destination $Global:Install -Recurse"
		}
		else
		{
			Copy-Item -Path $copySource -Destination $Global:Install -Recurse
		}
	}
    
    #2005 doesn't support slipstream, so we need to copy the SP and CU installs seperately
	if ($sqlVersion -eq 'SQL2005')
	{
		if($isX86)
		{
			$copyCU += '\x86\*.*'
            $copySP += '\x86\*.*'
		}
		else
		{
			$copyCU += '\x64\*.*'
            $copySP += '\x64\*.*'
		}
        
        if($robocopy)
		{
			if($Global:Simulation)
			{
				Write-Output "robocopy $copyCU $installCU /R:2 /W:5 /E /MT:8 /NP /LOG+:`"$robocopyLogCU`""
				Write-Output "robocopy $copySP $installSP /R:2 /W:5 /E /MT:8 /NP /LOG+:`"$robocopyLogSP`""
			}
			else
			{
				robocopy $copyCU $installCU /R:2 /W:5 /E /MT:8 /NP /LOG+:"$robocopyLogCU"
	        	robocopy $copySP $installSP /R:2 /W:5 /E /MT:8 /NP /LOG+:"$robocopyLogSP"
			}
		}
		else
		{
			if($Global:Simulation)
			{
				Write-Output "Copy-Item -Path $copyCU -Destination $Global:Install -Recurse"
				Write-Output "Copy-Item -Path $copySP -Destination $Global:Install -Recurse"
			}
			else
			{
				Copy-Item -Path $copyCU -Destination $Global:Install -Recurse
				Copy-Item -Path $copySP -Destination $Global:Install -Recurse
			}
		}
	}
	
	if(!$Global:Simulation)
	{
		Get-Date | Set-Content -Path $copyDoneFlag
	}
	
	Write-Log -level "Info" -message "Copy of install files complete"
}
