Function Copy-InstallFiles
{
	param
	(
#		[Parameter(Position=0, Mandatory=$true)] [string] $computerName,
#		[Parameter(Position=1, Mandatory=$true)] [string] $sqlVersion,
#		[Parameter(Position=2, Mandatory=$true)] [string] $sqlEdition,
#		[Parameter(Position=3, Mandatory=$false)] [bool] $isX86 = $false
		[Parameter(Position=0, Mandatory=$true)] [hashtable] $params,
		[Parameter(Position=1, Mandatory=$false)] [switch] $DontCopyLocal
	)
	
	$sqlVersion 		= $params["SqlVersion"]
	$sqlEdition 		= $params["SqlEdition"]
	$scriptFolder 		= $params["WindowsScriptsFolder"]
    $modulesFolder      = $params["PowerShellModulesFolder"]
	[bool] $isX86		= $false
	$installCU			= Join-Path -Path $Global:Install -ChildPath "CU\"
	$installSP			= Join-Path -Path $Global:Install -ChildPath "SP\"
	$installUpdates 	= Join-Path -Path $Global:Install -ChildPath "Updates\"	
	$robocopyLog 		= Join-Path -Path $Global:LogPath -ChildPath "RoboCopyLogInstall.txt"
	$robocopyLogCU 		= Join-Path -Path $Global:LogPath -ChildPath "RoboCopyLogCU.txt"
	$robocopyLogSP 		= Join-Path -Path $Global:LogPath -ChildPath "RoboCopyLogSP.txt"
	$robocopyLogUpdates = Join-Path -Path $Global:LogPath -ChildPath "RoboCopyLogUpdates.txt"
	$copyDoneFlag		= Join-Path -Path $Global:Install -ChildPath 'CopyComplete.txt'
	
	if (Test-Path $copyDoneFlag)
	{
		Write-Log -level "Info" -message "Installation files have already been copied"
		return
	}

    if ($modulesFolder -ne $null)
    {
	    Write-Log -level "Info" -message "Copying PowerShell scripts to $scriptFolder"
	    if($Global:Simulation)
	    {
		    Write-Output "Copy-Item -Path ($Global:Scripts + '*.*') -Destination $scriptFolder -Recurse -Force"
	    }
	    else
	    {
		    if (Test-Path $Global:Scripts)
		    {
			    #Ensure that the script folder is formatted properly
			    if (!$scriptFolder.EndsWith("\"))
			    {
				    $scriptFolder += "\"
			    }
			
			    #Check for the destination folder
			    if (!(Test-Path $scriptFolder))
			    {
				    New-Item -Path $scriptFolder -ItemType Directory
			    }
			
			    Copy-Item -Path ($Global:Scripts + '*.*') -Destination $scriptFolder -Recurse -Force
		    }
	    }
	    Write-Log -level "Info" -message "Copy of PowerShell scripts to $scriptFolder complete"
    }
    else
    {
        Write-Log -level "Attention" -message "AppSetting WindowsScriptsFolder not defined: no scripts deployed"
    }

    if ($modulesFolder -ne $null)
    {
        Write-Log -level "Info" -message "Copying PowerShell modules to $modulesFolder"
	    if($Global:Simulation)
	    {
		    Write-Output "Copy-Item -Path ($Global:Modules + '*.*') -Destination $modulesFolder -Recurse -Force"
	    }
	    else
	    {
		    if (Test-Path $Global:Modules)
		    {
			    #Ensure that the script folder is formatted properly
			    if (!$modulesFolder.EndsWith("\"))
			    {
				    $modulesFolder += "\"
			    }
			
			    #Check for the destination folder
			    if (!(Test-Path $modulesFolder))
			    {
				    New-Item -Path $modulesFolder -ItemType Directory
			    }
			
			    Copy-Item -Path $Global:Modules -Destination ($modulesFolder + "..") -Recurse -Force
		    }
	    }
	    Write-Log -level "Info" -message "Copy of PowerShell modules to $modulesFolder complete"

        #Add the new module folder to the PSModulePath environment variable
        $CurrentPSModulePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
        if ($CurrentPSModulePath.Split(";") -notcontains $modulesFolder)
        {
            #Add module path to current session
            $env:PSModulePath = $env:PSModulePath + ";$modulesFolder"
            
            #Persist module path for future sessions
            [Environment]::SetEnvironmentVariable("PSModulePath", $CurrentPSModulePath + ";$modulesFolder", "Machine")
            Write-Log -level "Info" -message "The following location has been added to PSModulePath: $modulesFolder"
        }
        else
        {
            Write-Log -level "Info" -message "The current PSModulePath already contains: $modulesFolder"
        }
    }
	else
    {
        Write-Log -level "Attention" -message "AppSetting PowerShellModulesFolder not defined: no PowerShell modules deployed"
    }

	if ($DontCopyLocal)
	{
		Write-Log -level "Info" -message 'DontCopyLocal selected - the installation binaries will not be copied to the server'
	}
	else
	{	
#		$copySource = $Global:SourcePath
#		$copySource += $sqlVersion
#		$copySource += '\'
		$copySource = $Global:BinariesPath
	    $copyCU = $Global:SourcePath + $sqlVersion + '\CU'
	    $copySP = $Global:SourcePath + $sqlVersion + '\SP'
		$copyUpdates = $Global:SourcePath + $sqlVersion + '\Updates'
		
#		switch -wildcard ($sqlEdition)
#		{
#			"*32" 	{$copySource += ($sqlEdition -replace "32", "\x86"); $isX86 = $true}
#			"*64" 	{$copySource += ($sqlEdition -replace "64", "\x64")}
#			default {$copySource += $sqlEdition}
#		}
		
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
				#$copyCU += '\x86\*.*'
	            #$copySP += '\x86\*.*'
                $copyCU += '\x86\'
	            $copySP += '\x86\'
			}
			else
			{
				#$copyCU += '\x64\*.*'
	            #$copySP += '\x64\*.*'
                $copyCU += '\x64\'
	            $copySP += '\x64\'
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
					Write-Output "Copy-Item -Path $($copyCU + "*.*") -Destination $Global:Install -Recurse"
					Write-Output "Copy-Item -Path $($copySP + "*.*") -Destination $Global:Install -Recurse"
				}
				else
				{
					Copy-Item -Path ($copyCU + "*.*") -Destination $Global:Install -Recurse
					Copy-Item -Path ($copySP + "*.*") -Destination $Global:Install -Recurse
				}
			}
		}
		elseif ($sqlVersion -gt 'SQL2008R2') # -and (Test-Path $installUpdates))
		{
			#SQL 2012 replaced the SlipStreams functionality with ProductUpdates
			#so you no longer need to build the slipstream media
			if($robocopy)
			{
				if($Global:Simulation)
				{
					Write-Output "robocopy $copyUpdates $installUpdates /R:2 /W:5 /E /MT:8 /NP /LOG+:`"$robocopyLogUpdates`""
				}
				else
				{
					robocopy $copyUpdates $installUpdates /R:2 /W:5 /E /MT:8 /NP /LOG+:"$robocopyLogUpdates"
				}
			}
			else
			{
				if($Global:Simulation)
				{
					Write-Output "Copy-Item -Path $copyUpdates -Destination $Global:Install -Recurse"
				}
				else
				{
					Copy-Item -Path $copyUpdates -Destination $Global:Install -Recurse
				}
			}
		}
		
		if(!$Global:Simulation)
		{
			Get-Date | Set-Content -Path $copyDoneFlag
		}
		
		Write-Log -level "Info" -message "Copy of install files complete"
	}
}
