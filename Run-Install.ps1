function Run-Install
{
<#
.SYNOPSIS
    Executes the SQL Server Auto-Install process.
.DESCRIPTION
    Copies the required files from the configured source location, runs any 
    pre-install tasks, installs the specified version of SQL Server, and then 
    runs any post-install tasks. Supports common parameters -verbose, -whatif, and -confirm.
.PARAM Parameters
    A hashtable containing the installation parameters.
.PARAM TemplateOverrides
    A hashtable containing any SQL configuration file elements that need to be overriden.  
    These entries will superceed both the configuration template and the config xml file.
#>
	[CmdletBinding(SupportsShouldProcess=$true)]
    param
	(
		[Parameter(Position=0,Mandatory=$true)][hashtable] $Parameters,
		[Parameter(Position=1,Mandatory=$false)][hashtable] $TemplateOverrides,
        [Parameter(Position=2,Mandatory=$false)][ValidateSet("Install", "InstallFailoverCluster", "AddNode")][string] $InstallAction = "Install",
		[Parameter(Position=3,Mandatory=$false)][switch] $Full,
		[Parameter(Position=4,Mandatory=$false)][switch] $PreOnly,
		[Parameter(Position=5,Mandatory=$false)][switch] $PostOnly,
		[Parameter(Position=6,Mandatory=$false)][switch] $InstallOnly,
		[Parameter(Position=7,Mandatory=$false)][switch] $DontCopyLocal,
        [Parameter(Position=8,Mandatory=$false)][switch] $ForceBinariesOverwrite
        
    )

    #Capture the start time 
    $start = Get-Date
    	
	#Ensure that the execution policy is set correctly
    #Set-ExecutionPolicy RemoteSigned -force
	
	#Set the Critical Failure flag
	$Global:CriticalError = $false

	#Parse the parameters hashtable
	$sqlVersion 		= $Parameters["SqlVersion"]
	$sqlEdition 		= $Parameters["SqlEdition"]

	$procssorArch 		= $Parameters["ProcessorArch"]
	$dataCenter 		= $Parameters["DataCenter"]
	$sysAdminPassword 	= $Parameters["SysAdminPassword"]
	$environment		= $Parameters["Environment"]

    $sqlSvcAccount      = $TemplateOverrides["SqlSvcAccount"]
    $sqlSvcPassword     = $TemplateOverrides["SqlSvcPassword"]
    $agtSvcAccount      = $TemplateOverrides["agtSvcAccount"]
 	$agtSvcPassword     = $TemplateOverrides["agtSvcPassword"]
 	$FTSvcAccount       = $TemplateOverrides["ftSvcAccount"]
 	$ftSvcPassword      = $TemplateOverrides["ftSvcPassword"]
 	$isSvcAccount       = $TemplateOverrides["isSvcAccount"]
 	$isSvcPassword      = $TemplateOverrides["isSvcPassword"]
 	$rsSvcAccount       = $TemplateOverrides["rsSvcAccount"]
 	$rsSvcPassword      = $TemplateOverrides["rsSvcPassword"]
    $instanceName       = $TemplateOverrides["InstanceName"]

    #Add InstanceName to Parameters hash table, as it's expected by $IsSysAdmin check, and post-scripts
    $Parameters.Add("InstanceName", $instanceName)

    $Global:Debug       = ($Parameters["Debug"] -eq "True" -or $PSBoundParameters['Debug']) 
	$Global:Simulation  = ($Parameters["Simulation"] -eq "True" -or $PSBoundParameters['WhatIf'] ) 
    
    Write-Output "SPADE Installer Starting...."

    #Set the Global variables for Physical and Logical computer name
    #Default the logical computer name to the physical name when not provided
    $strComputer 	= gc env:computername
    $Global:PhysicalComputerName = $env:COMPUTERNAME
    $Global:LogicalComputerName = $Global:PhysicalComputerName
    if ($Parameters.ContainsKey("ComputerName"))
    {
        $Global:LogicalComputerName = $Parameters["ComputerName"]
    }

    ## Assume Local if not present 
    if 	($Parameters["FilePath"])
    {
        $filePath = $Parameters["FilePath"]
    }
    else 
    {
        $filePath = Join-Path (Split-Path -Path $MyInvocation.ScriptName) "\"
    }
    Set-Location $filePath
     
    #Load the XML configuration file
	$configFilePath = join-path -path $filePath -childPath "Run-Install.config"
    if ($Global:Debug) {Write-Output "Reading Config file: $configFilePath" }
    [xml] $settings = gc $configFilePath 
	
	#Store the ScriptConfigs.Script nodes in a global variable
	[array] $Global:ScriptConfigs = $settings.InstallerConfig.ScriptConfigs.Script

	#Add parameters from the AppSettings node of the XML config file
	$add = $settings.InstallerConfig.AppSettings.Setting
	if ($add)
	{
		foreach ($key in $add)
		{
			if (!$Parameters.ContainsKey($key.Name))
			{
                
                $var = Get-Variable -Name "$($key.Name)" -Scope Global -ValueOnly -ErrorAction silentlycontinue
                if (!$var)
                {
                    if ($Global:Debug) {Write-Output "Adding Global Variable $($key.Name) = $($key.Value)"}
                    New-Variable -Name "$($key.Name)" -Value $key.Value -Scope Global
                } else 
                {
                    if ($Global:Debug) {Write-Output "Setting Global Variable $($key.Name) = $($key.Value)"}
                    Set-Variable -Name "$($key.Name)" -Scope Global -Value $key.Value 
                }
				#The user didn't specify a value, so we will use the default from the config file
				$Parameters.Add($key.Name,$key.Value)
			}
		}
	}

	## Validate DataCenter - minimum we need to get started
	$dcs = $settings.InstallerConfig.DataCenters.DataCenter | ?{$_.Name -eq $dataCenter}
	if (!($dcs))
	{
		throw "You have selected an invalid Data Center: $dataCenter"
	}

    #Set the script level variables containing path info based on the Data Center location selected
	$Global:SourcePath 		= $dcs.FilePath

    ## Allow for an alternate Binary Location outside of Spade Sources, can be the same, or alternate
	$Global:RootPath		= $filePath
	$Global:CommonScripts 	= (Join-Path $Global:RootPath "Common\")
	$Global:PreScripts		= (Join-Path $Global:RootPath "PreScripts\")
	$Global:PostScripts 	= (Join-Path $Global:RootPath "PostScripts\")
	$Global:Modules		 	= (Join-Path $Global:RootPath "Modules\")
	$Global:Packages	 	= (Join-Path $Global:RootPath "Packages\")
	$Global:Templates	 	= (Join-Path $Global:RootPath "Templates\")
	$Global:Install			= (Join-Path $Global:RootPath "Install\")
	$Global:Scripts			= (Join-Path $Global:SourcePath "PowerShellScripts\")
	
	$RootPathFolders        = GCI -Path $Global:RootPath | Where-Object {$_.PSIsContainer -and $_.Name -ne "Install" -and $_.Name -notlike 'SQL*' } 
    $SourcePathFolders      = GCI -Path $Global:SourcePath | Where-Object {$_.PSIsContainer }
    
    ## Loop Through and Copy all folders found in Source
    foreach ($folder in $SourcePathFolders)
    {
        $target = $folder.FullName.Replace($Global:SourcePath, $Global:RootPath)
        if (Test-Path -Path $target)
        {
            if ($Global:Debug) { Write-Output "Removing $target" }
            Remove-Item -path $target -recurse -force 

        }

        Copy-Item -path $folder.FullName -destination $target -recurse -Force

        #Dot-source everything in the common scripts folder 
        if ($folder.Name -eq "Common")
        {
            
            Get-ChildItem "$target\*.ps1" | ForEach-Object {. $_.FullName; if ($Global:Debug) {Write-Output "Loading $($_.FullName)"} }#| Out-Null
        }

    }
    Write-Log -Level Info "Folders copied from source, modules loaded"
	
	#Make sure that the script is being run with admin rights
	[bool]$Admin = Verify-IsAdmin
    if(!$Admin)
    {
        Write-Log -Level Error  "This script requires administrative rights."
        return
    }


	#Special Handling for SQL 2005 (seperate installers for 32 and 64 bit)
	if ($sqlVersion -eq "Sql2005")
	{
		switch ($procssorArch)
		{
			"X86" 	{$sqlEdition += "32"}
			"X64" 	{$sqlEdition += "64"}
			default {$sqlEdition += "64"}
		}
		$Parameters["SqlEdition"] = $sqlEdition
	}
	
	#Validate SqlVerion
	$versions = $settings.InstallerConfig.SqlVersions.Version | ?{$_.Name -eq $sqlVersion}
	if (!($versions))
	{
		Write-Log -Level Error "You have selected an invalid/unsupported version of SQL Server: $sqlVersion"
        return
	}

	#Add TemplateName to Hashtable
	$template = $versions.ConfigurationTemplate | Select -ExpandProperty Name
	if (!($template))
	{
		Write-Log -Level Error "Unable to locate configuration template for the specified sql version; $sqlVersion"
        return
	}
	else
	{
		if ($Parameters.ContainsKey("TemplateName"))
		{
			$Parameters["TemplateName"] = $template
		}
		else
		{
			$Parameters.Add("TemplateName", $template)
		}
	}
	
	#Add Template INI Category to Hashtable
	$category = $versions.ConfigurationTemplate | Select -ExpandProperty Category
	if (!($category))
	{
		Write-Log -Level Error  "Unable to locate configuration template category for the specified sql version: $sqlVersion"
        return
	}
	else
	{
		if (!$Parameters.ContainsKey("TemplateCategory"))
		{
			$Parameters.Add("TemplateCategory", $category)
		}
	}

	#Read the ProductStringName or set to default if missing 
	$prod = (&{If($Parameters["ProductStringName"]) {$Parameters["ProductStringName"]} Else {"Default"}})
	
	#Validate ProductString
	$productString = $versions.ProductStrings.ProductString | ?{$_.Name -eq $prod} | Select -ExpandProperty Value
	if (!($productString))
	{
		Write-Log -Level Error "Unable to locate $prod product string for $sqlVersion in the config file or the product string is invalid"
        return
	}
	else
	{
		if ($Parameters.ContainsKey("ProductString"))
		{
			$Parameters["ProductString"] = $productString
		}
		else
		{
			$Parameters.Add("ProductString", $productString)
		}
	}
	
	#Validate SqlEdition
	$editions = $versions.Editions.Edition | ?{$_.Name -eq $sqlEdition};
	if (!($editions))
	{
		Write-Log -Level Error "You have selected an invalid/unsupported edition of SQL Server: $sqlEdition"
        return
	}
	
	#Validate Product Key
	$key = $editions.Key
	if (!($key))
	{
		#Handle the fact that eval editions don't use keys
		if ($sqlEdition -ne "Evaluation")
		{
			Write-Log -Level Error "There is no matching product key in the configuration file for $sqlVersion - $sqlEdition edtion"
            return
		}
	}
	else
	{
		if (!$Parameters.ContainsKey("ProductKey"))
		{
			$Parameters.Add("ProductKey", $key)
		}
	}
	
	#Validate path to Install Binaries
    $binaryPath = $editions.FolderName
	if (!($binaryPath))
	{
		Write-Log -Level Error "The FolderName property is missing in the configuration file for $sqlVersion - $sqlEdition edtion"
        return
	}

    ## Allow for an alternate Binary Location outside of Spade Sources, can be the same, or alternate
    if (!($dcs.BinaryPath))
    {
       $Global:BinariesPath	= (Join-Path $Global:SourcePath ($binaryPath + "\"))
    } 
        else 
    {
       $Global:BinariesPath =  (Join-Path $dcs.BinaryPath ($binaryPath + "\")) 
    }
	
   #Validate SQLServiceAccount
	if (!$sqlSvcAccount)
  	{
		if (@('SQL2005', 'SQL2008','SQL2008R2') -contains $sqlVersion )
		{
			$sqlSvcAccount = "NT AUTHORITY\NETWORK SERVICE"
            
		} 
		else 
		{
			if (!$instanceName )
			{
				$sqlSvcAccount = "NT Service\MSSQLSERVER"
			}
			else 
			{
				$sqlSvcAccount = "NT Service\MSSQL$" + $instanceName 
			}
		}
        Write-Log -Level Info "Defaulting SQLSERVICEACCOUNT = $sqlSvcAccount"
	}
    else 
    {
        if (!$sqlSvcPassword)
        {
            Write-Log -Level Error "sqlServiceAccount specified but sqlSvcPassword is blank"
        }
        else 
        {
            if (!Test-Credential -UserName $sqlSvcAccount -Password $sqlSvcPassword)
            {
                Write-Log -Level Error "sqlSvcPassword does not appear to be valid"
            }
        }
    }
    

	#Validate AgtServiceAccount
	if (!$agtSvcAccount)
	{
		if (@('SQL2005', 'SQL2008','SQL2008R2') -contains $sqlVersion )
		{
			$agtSvcAccount = "NT AUTHORITY\NETWORK SERVICE"
		} 
		else 
		{
			if (!$instanceName )
 		{
				$agtSvcAccount = "NT Service\SQLSERVERAGENT"
 			}
 			else 
 			{
 				$agtSvcAccount = "NT SERVICE\SQLAGENT$" + $instanceName 
    		}
 		}
        Write-Log -Level Info "Defaulting AgtServiceAccount = $agtSvcAccount"
 	}
    else 
    {
        if (!$agtSvcAccount)
        {
            Write-Log -Level Error "agtServiceAccount specified but agtSvcPassword is blank"
        }
        else 
        {
            if (!Test-Credential -UserName $agtSvcAccount -Password $agtSvcPassword)
            {
                Write-Log -Level Error "agtSvcPassword does not appear to be valid"
            }
        }
    }
 
 	#Validate ftServiceAccount
 	if (!$FTSvcAccount)
 	{
 		if (@('SQL2005', 'SQL2008') -contains $sqlVersion )
 		{
 			$FTSvcAccount = "NT AUTHORITY\NETWORK SERVICE"
 		} 
 		else 
 		{
 			if (!$instanceName )
 			{
 				$FTSvcAccount = "NT Service\MSSQLFDLauncher"
 			}
 			else 
 			{
 				$FTSvcAccount = "NT Service\MSSQLFDLauncher$" + $instanceName 
 			}
 		}
        Write-Log -Level Info "Defaulting ftServiceAccount = $FTSvcAccount"
 	}	
    else 
    {
        if (!$ftSvcPassword)
        {
            Write-Log -Level Error "ftServiceAccount specified but ftSvcPassword is blank"
        }
        else 
        {
            if (!Test-Credential -UserName $FTSvcAccount -Password $ftSvcPassword)
            {
                Write-Log -Level Error "ftSvcPassword does not appear to be valid"
            }
        }
    }
 
 	#Validate isServiceAccount
 	if (!$isSvcAccount)
 	{
 		switch($sqlVersion)
 		{
			'SQL2017' { $isSvcAccount = 'NT SERVICE\MsDtsServer140';break } 
 			'SQL2016' { $isSvcAccount = 'NT SERVICE\MsDtsServer130';break }
 			'SQL2014' { $isSvcAccount = 'NT SERVICE\MsDtsServer120';break }
 			'SQL2012' { $isSvcAccount = 'NT SERVICE\MsDtsServer110';break }
 			#'SQL2008R2' { $isSvcAccount = 'NT SERVICE\MsDtsServer100';break }
 			default { $isSvcAccount = "NT AUTHORITY\NETWORK SERVICE"; break;}
 		}
        Write-Log -Level Info "Defaulting isSvcAccount = $isSvcAccount"
 		
 	} 
    else 
    {
        if (!$isSvcPassword)
        {
            Write-Log -Level Error "isServiceAccount specified but isSvcPassword is blank"
        }
        else 
        {
            if (!Test-Credential -UserName $isSvcAccount -Password $isSvcPassword)
            {
                Write-Log -Level Error "ISServiceAccount does not appear to be valid"
            }
        }
    }

    #Validate RsServiceAccount
	if (!$rsSvcAccount)
	{
		if (@('SQL2005', 'SQL2008','SQL2008R2') -contains $sqlVersion )
		{
			$rsSvcAccount = "NT AUTHORITY\NETWORK SERVICE"
		} 
		else 
		{
			if (!$instanceName )
 		{
				$rsSvcAccount = "NT Service\ReportServer"
 			}
 			else 
 			{
 				$rsSvcAccount = "NT SERVICE\ReportServer$" + $instanceName 
    		}
 		}
        Write-Log -Level Info "Defaulting RsServiceAccount = $rsSvcAccount"
 	}
    else 
    {
        if (!$rsSvcAccount)
        {
            Write-Log -Level Error "rsServiceAccount specified but agtSvcPassword is blank"
        }
        else 
        {
            if (!Test-Credential -UserName $rsSvcAccount -Password $rsSvcPassword)
            {
                Write-Log -Level Error "rsSvcPassword does not appear to be valid"
            }
        }
    }

    #Validate asServiceAccount
	if (!$asSvcAccount)
	{
		if (@('SQL2005', 'SQL2008') -contains $sqlVersion )
		{
			$asSvcAccount = "NT AUTHORITY\NETWORK SERVICE"
		} 
		else 
		{
			if (!$instanceName )
 		{
				$asSvcAccount = "NT Service\SQLServerMSASUser$" + $strComputer + '$MSSQLSERVER'
 			}
 			else 
 			{
 				$asSvcAccount = "NT SERVICE\SQLServerMSASUser$" + $strComputer + '$' + $instanceName 
    		}
 		}
        Write-Log -Level Info "Defaulting asServiceAccount = $asSvcAccount"
 	}
    else 
    {
        if (!$asSvcAccount)
        {
            Write-Log -Level Error "asSvcAccount specified but asSvcPassword is blank"
        }
        else 
        {
            if (!Test-Credential -UserName $asSvcAccount -Password $asSvcPassword)
            {
                Write-Log -Level Error "asSvcPassword does not appear to be valid"
            }
        }
    }

    $TemplateOverrides["sqlSvcAccount"] = $sqlSvcAccount
    $TemplateOverrides["agtSvcAccount"] = $agtSvcAccount
    $TemplateOverrides["ftSvcAccount"] = $ftSvcAccount
    $TemplateOverrides["isSvcAccount"] = $isSvcAccount
    $TemplateOverrides["rsSvcAccount"] = $rsSvcAccount	
    $TemplateOverrides["asSvcAccount"] = $asSvcAccount

	#Validate SysAdminPassword
	if (!$sysAdminPassword)
	{
        $sysAdminPassword = Get-Strong-Password
        while (!(Validate-Strong-Password $sysAdminPassword))
        {
            $sysAdminPassword = Get-Strong-Password		
        }
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
        $pwSavePath = (Join-Path $Global:LogPath "details.txt") 
        $a = New-Item -Type File -Force -Path $pwSavePath
        "$($FormattedDate): $sysAdminPassword" | Out-File $pwSavePath -Append
        Write-Log -Level Attention "SysAdmin password missing, strong password created and saved $pwSavePath"
	}

    ## Validate Strong Password
    $strong = Validate-Strong-Password $sysAdminPassword
    if (!($strong))
    {
        Write-Log -Level Error "SysAdmin Password does not meet minimum standards"
        return
    }

    
	
	#Validate FilePath
	if (!($filePath))
	{
		Write-Log -Level Error "You must specify a file path"
        return
	}
	
	#Validate Environment
	$envs = $settings.InstallerConfig.Environments.Environment | ?{$_.Name -eq $environment}
	if (!($envs))
	{
        $envs = "PROD"
        Write-Log -Level Attention "Environment Not Provided: Defaulting to PROD"    
	}

    #Use default instance if none is provided
    if (!($instanceName))
    {
        $instanceName = "MSSQLSERVER"
    }
    $TemplateOverrides['InstanceName'] = $instanceName
    
    #Cluster Specific Validations
    if($InstallAction -eq "InstallFailoverCluster" -or $InstallAction -eq "AddNode")
    {
        #Validate ClusterInstall Supported
        $clusterSupported = $versions.ClusterInstallSupported | Select -ExpandProperty Value
        if ($clusterSupported -eq $null -or $clusterSupported -eq $false)
        {
            Write-Log -Level Error "Clustering is not currently supported for: $sqlVersion"
            return
        }

        #Build Passive Node List
        if ($Parameters.ContainsKey("PassiveNodes"))
        {
            [array] $PassiveNodeList = $Parameters["PassiveNodes"].Split(",") 
        }

        #Validate Cluster Disks
        $clusterDisks = $TemplateOverrides["FAILOVERCLUSTERDISKS"]
        if (!($clusterDisks))
	    {
		    Write-Log -Level Error "You must specify the cluster disks when doing a clustered install"
            return
	    }


        #Validate Cluster Name
        $clusterName = $TemplateOverrides["FAILOVERCLUSTERNETWORKNAME"]
        if (!($clusterName))
	    {
		    Write-Log -Level Error "You must specify a cluster name when doing a clustered install"
            return
	    }

        #Validate Cluster Address
        $clusterAddress = $TemplateOverrides["FAILOVERCLUSTERIPADDRESSES"]
        if (!($clusterAddress))
	    {
		    Write-Log -Level Error "You must specify the cluster IP address when doing a clustered install"
            return
	    }
    }
	
	if ($TemplateOverrides.Count -gt 0)
    {
        Write-Log -Level Debug "-------------- Template Override Contents - Command Line ----------------------"
        foreach	($key in $TemplateOverrides.Keys)
        {
           Write-Log -Level Debug "$Key = $($TemplateOverrides[$Key])" 
        }
    }
	
	#Load Template Overrides from the XML Config file
	if (!($TemplateOverrides))
	{
		$TemplateOverrides = New-Object hashtable
	}
	
	$to = $versions.TemplateOverrides.Setting
	
	foreach ($setting in $to)
	{
		if (!$TemplateOverrides.ContainsKey($setting.Name))
		{
			$TemplateOverrides.Add($setting.Name,$setting.Value)
		}
	}

	Write-Log -Level Debug "-------------- Template Override Contents - From Settings ----------------------"
    foreach	($key in $TemplateOverrides.Keys)
    {
       $message = "{0,-25} = {1,-40}" -f $Key, $TemplateOverrides[$Key]
       Write-Log -Level Debug $message
    }
	

	
    Write-Log -Level Info "-------------- Parameters Contents ----------------------"	
    foreach ($param in $Parameters.GetEnumerator())
	{
		#For security reasons we will not display any passwords in the log
		if ($param.Key -match "password")
		{
			$message = "{0,-25} = {1,-40}"  -f $param.Key, "********"
		}
		else
		{
			$message = "{0,-25} = {1,-40}" -f $param.Key, $param.Value
		}
		Write-Log -level Info -message $message
	}

	
		if ($ForceBinariesOverwrite) 
        {
            #Remove the CopyComplete flag to force the SQL install files to be re-copied
            if (Test-Path (Join-Path $Global:Install "CopyComplete.txt"))
            {
                Remove-Item -path (Join-Path $Global:Install "CopyComplete.txt")
            }
        }

        if ($DontCopyLocal)
		{
			Copy-InstallFiles -params $Parameters -DontCopyLocal
		}
		else
		{
			Copy-InstallFiles -params $Parameters
		}
	
		#Call the code that generates the configuration ini file
        $configFile = Create-ConfigFile -params $Parameters -overrides $TemplateOverrides
		
		Write-Log -level INFO -message "Configuration file has been created and is located at $configFile" 
     	
		#execute pre-install checklist
		if (($PreOnly -eq $true -or $Full -eq $true) -and $Global:CriticalError -eq $false)
		{
	        Write-Log -level SECTION -message "Starting Pre-Install Checklist"
			if ($pscmdlet.ShouldProcess("Execute Pre-Install Scripts", "Pre-Install")) #if (!$Global:Simulation)
			{
				Execute-ScriptFiles -configParams $Parameters -sequence "pre"
			}
			Write-Log -level INFO -message "Completed Pre-Install Checklist"
		}
		else
		{
			Write-Log -level SECTION -message "Skipping Pre-Install Checklist"
		}
        
		#This flag prevents the installation binaries from being copied to the server
		if ($DontCopyLocal)
		{
			[string] $command = $Global:BinariesPath
		}
		else
		{
			[string] $command = $Global:Install
		}
		
		[string] $arguments = ''
        
        if($sqlVersion -eq "Sql2005")
        {
			#Format the command to be executed by Start-Process (SQL 2005 has no output to console mode so we display a passive GUI to monitor progress)
            $command += 'Servers\setup.exe'
            $arguments = '/SETTINGS {0} /QB SAPWD="{1}" SQLPASSWORD="{2}" AGTPASSWORD="{2}" SQLBROWSERPASSWORD="{2}"' -f $configFile, $sysadminPassword, $sqlSvcAccount
        }
        else
        {
            #Format the command to be executed by Invoke-Expression (SQL 2008+ has the option to pass the log to the console to monitor progress)
            $command += 'setup.exe '
            $arguments = '/CONFIGURATIONFILE=`"$configFile`"  /SAPWD=`"$sysadminPassword`"'
            if ($sqlSvcAccount -and $sqlSvcPassword) 
            {
                $arguments += ' /SQLSVCPASSWORD=`"$sqlSvcPassword`"'
            }
            if ($agtSvcAccount -and $agtSvcPassword) 
            {
                $arguments += ' /AGTSVCPASSWORD=`"$agtSvcPassword`"'
            }
            if ($FTSvcAccount -and $ftSvcPassword) 
            {
                $arguments += ' /FTSVCPASSWORD=`"$ftSvcPassword`"'
            }
            if ($isSvcAccount -and $isSvcPassword) 
            {
                $arguments += ' /ISSVCPASSWORD=`"$isSvcPassword`"'
            }
            if ($rsSvcAccount -and $rsSvcPassword) 
            {
                $arguments += ' /RSSVCPASSWORD=`"$rsSvcPassword`"'
            }
        }
        
        Write-Log -level DEBUG "Setup Command: $command"
		Write-Log -Level DEBUG "Arguments: $arguments"
		
		[int] $exitCode = 0
		
        #execte command
        if (($InstallOnly -eq $true -or $Full -eq $true) -and $Global:CriticalError -eq $false)
		{
			Write-Log -level SECTION -message "Starting SQL Server Install"
			if($sqlVersion -eq "Sql2005")
	        {
				#Call the GUI (Basic) install process and wait for it to complete
				if ($pscmdlet.ShouldProcess("Start SQL 2005 Installer Package", "Install SQL")) #if (!$Global:Simulation)
				{
                    Write-Log -Level Debug "Starting $command"
		        	Start-Process -FilePath $command -ArgumentList $arguments -Wait
					$exitCode = $lastexitcode
                    Write-Log -Level Debug "Installer Exit Code:  $exitCode"
				}
			}
			else
			{
				#Call the queit install process  - because it writes to the console we don't have to force the code to wait
				if ($pscmdlet.ShouldProcess("Start SQL Installer Package", "Install SQL")) #if (!$Global:Simulation)
				{
                    
                    Write-Log -Level Debug "Starting $command"		        	
                    Write-Log -Level Debug "Arguments $arguments"
                    Write-Log -Level Debug "ConfigFile: $configFile"
                    $command += $arguments 
                    Invoke-Expression $command
					$exitCode = $lastexitcode
                    Write-Log -Level Debug "Installer Exit Code:  $exitCode"
				}
	        }
			
			if ($exitCode -eq 0)
			{
				Write-Log -level INFO -message "Completed SQL Server Install"
				$Global:CriticalError = $false
			}
			else
			{
				Write-Log -level "Error" -message "SQL Server Install failed - please check the console output"
				$Global:CriticalError = $true
			}
		}
		else
		{
			Write-Log -level SECTION -message "Skipping SQL Server Install"
		}
		
        #execute post-install checklist
        
		if (($PostOnly -eq $true -or $Full -eq $true) -and $Global:CriticalError -eq $false)
		{
			Write-Log -level SECTION -message "Starting Post-Install Checklist"
               
			if ($pscmdlet.ShouldProcess("Execute Post-Install Scripts", "Post-Install")) #if (!$Global:Simulation)
			{
                $IsSysAdmin = Execute-SqlScalarQuery -sqlScript "select is_srvrolemember('sysadmin')" -sqlInstance $Parameters.InstanceName
			
				if($IsSysAdmin -eq 1)
				{
		    		Execute-ScriptFiles -configParams $Parameters -sequence "post"
				}
				else
				{
					Write-Log -level ERROR -message "The current user does not have sufficient permissions to run the Post-Install Checklist - please check permissions and run the process again with the '-PostOnly' option"
				}
			}
			Write-Log -level INFO -message "Completed Post-Install Checklist"
		}
		else
		{
			Write-Log -level SECTION -message "Skipping Post-Install Checklist"
		}
        
        #Capture end time
        $end = Get-Date
        $timeResult = ($end - $start)
        
		Write-Log -Level SECTION -Message "Script Time Results"
		Write-Log -Level INFO -Message "Script Duration: $timeResult"
    
}