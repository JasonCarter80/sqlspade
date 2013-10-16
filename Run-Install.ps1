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
    Set-ExecutionPolicy RemoteSigned -force
	
	#Set the Critical Failure flag
	$Global:CriticalError = $false
	
	#Parse the parameters hashtable
	$sqlVersion 		= $Parameters["SqlVersion"]
	$sqlEdition 		= $Parameters["SqlEdition"]
	$procssorArch 		= $Parameters["ProcessorArch"]
	$dataCenter 		= $Parameters["DataCenter"]
	$serviceAccount 	= $Parameters["ServiceAccount"]
	$servicePassword 	= $Parameters["ServicePassword"]
	$sysAdminPassword 	= $Parameters["SysAdminPassword"]
	$filePath 			= $Parameters["FilePath"]
	$environment		= $Parameters["Environment"]
    	$instanceName       = $Parameters["InstanceName"]

    #Set the Global variables for Physical and Logical computer name
    #Default the logical computer name to the physical name when not provided
    $Global:PhysicalComputerName = $env:COMPUTERNAME
    $Global:LogicalComputerName = $Global:PhysicalComputerName
    if ($Parameters.ContainsKey("ComputerName"))
    {
        $Global:LogicalComputerName = $Parameters["ComputerName"]
    }
    
    #Load the XML configuration file
	$configFilePath = join-path -path $filePath -childPath "Run-Install.config"
    [xml] $settings = gc $configFilePath 
	
	#Store the ScriptConfigs.Script nodes in a global variable
	[array] $Global:ScriptConfigs = $settings.InstallerConfig.ScriptConfigs.Script
	
	#Add parameters from the AppSettings node of the XML config file
	$add = $settings.InstallerConfig.AppSettings.Setting
	
	if ($add -ne $null)
	{
		foreach ($key in $add)
		{
			if (!$Parameters.ContainsKey($key.Name))
			{
				#The user didn't specify a value, so we will use the default from the config file
				$Parameters.Add($key.Name,$key.Value)
			}
		}
	}
	
	#Check for the debug setting
	if ($Parameters["Debug"] -eq "True") 
	{
		$Global:Debug = $true
	} 
	else 
	{
		$Global:Debug = $false
	}
	
	#Check for the simulation setting
	if ($Parameters["Simulation"] -eq "True") 
	{
		$Global:Simulation = $true
	} 
	else 
	{
		$Global:Simulation = $false
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
	
	#Validate DataCenter
	$dcs = $settings.InstallerConfig.DataCenters.DataCenter | ?{$_.Name -eq $dataCenter}
	if ($dcs -eq $null)
	{
		throw "You have selected an invalid Data Center: $dataCenter"
	}
	
	#Validate SqlVerion
	$versions = $settings.InstallerConfig.SqlVersions.Version | ?{$_.Name -eq $sqlVersion}
	if ($versions -eq $null)
	{
		throw "You have selected an invalid/unsupported version of SQL Server: $sqlVersion"
	}
	
	#Add TemplateName to Hashtable
	$template = $versions.ConfigurationTemplate | Select -ExpandProperty Name
	if ($template -eq $null -or $template -eq "")
	{
		throw "Unable to locate configuration template for the specified sql version; $sqlVersion"
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
	if ($category -eq $null -or $category -eq "")
	{
		throw "Unable to locate configuration template category for the specified sql version: $sqlVersion"
	}
	else
	{
		if (!$Parameters.ContainsKey("TemplateCategory"))
		{
			$Parameters.Add("TemplateCategory", $category)
		}
	}

	#Read the ProductStringName or set to default if missing 
	$prod = $Parameters["ProductStringName"]
	if ($prod -eq $null -or $prod -eq "")
	{
		$prod = "Default"
	}
	
	#Validate ProductString
	$productString = $versions.ProductStrings.ProductString | ?{$_.Name -eq $prod} | Select -ExpandProperty Value
	if ($productString -eq $null -or $productString -eq "")
	{
		throw "Unable to locate $prod product string for $sqlVersion in the config file or the product string is invalid"
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
	if ($editions -eq $null)
	{
		throw "You have selected an invalid/unsupported edition of SQL Server: $sqlEdition"
	}
	
	#Validate Product Key
	$key = $editions.Key
	if ($key -eq $null -or $key -eq "")
	{
		#Handle the fact that eval editions don't use keys
		if ($sqlEdition -ne "Evaluation")
		{
			throw "There is no matching product key in the configuration file for $sqlVersion - $sqlEdition edtion"
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
	if ($binaryPath -eq $null -or $binaryPath -eq "")
	{
		throw "The FolderName property is missing in the configuration file for $sqlVersion - $sqlEdition edtion"
	}
	
	#Validate ServiceAccount
	if ($serviceAccount -eq $null -or $serviceAccount -eq "")
	{
		throw "You must specify a service account"
	}
	
	#Validate ServicePassword
	#TODO: Allow for LocalSystem account to be used
	if ($servicePassword -eq $null -or $servicePassword -eq "")
	{
		throw "You must specify a service password"
	}
	
	#Validate SysAdminPassword
	if ($sysAdminPassword -eq $null -or $sysAdminPassword -eq "")
	{
		throw "You must specify a sysadmin password"
	}
	
	#Validate FilePath
	if ($filePath -eq $null -or $filePath -eq "")
	{
		throw "You must specify a file path"
	}
	
	#Validate Environment
	$envs = $settings.InstallerConfig.Environments.Environment | ?{$_.Name -eq $environment}
	if ($envs -eq $null)
	{
		throw "You have selected an invalid Environment: $environment"
	}

    #Use default instance if none is provided
    if ($instanceName -eq "")
    {
        $instanceName -eq "MSSQLSERVER"
    }

    #Cluster Specific Validations
    if($InstallAction -eq "InstallFailoverCluster" -or $InstallAction -eq "AddNode")
    {
        #Validate ClusterInstall Supported
        $clusterSupported = $versions.ClusterInstallSupported | Select -ExpandProperty Value
        if ($clusterSupported -eq $null -or $clusterSupported -eq $false)
        {
            throw "Clustering is not currently supported for: $sqlVersion"
        }

        #Build Passive Node List
        if ($Parameters.ContainsKey("PassiveNodes"))
        {
            [array] $PassiveNodeList = $Parameters["PassiveNodes"].Split(",") 
        }

        #Validate Cluster Disks
        $clusterDisks = $TemplateOverrides["FAILOVERCLUSTERDISKS"]
        if ($clusterDisks -eq $null -or $clusterDisks -eq "")
	    {
		    throw "You must specify the cluster disks when doing a clustered install"
	    }


        #Validate Cluster Name
        $clusterName = $TemplateOverrides["FAILOVERCLUSTERNETWORKNAME"]
        if ($clusterName -eq $null -or $clusterName -eq "")
	    {
		    throw "You must specify a cluster name when doing a clustered install"
	    }

        #Validate Cluster Address
        $clusterAddress = $TemplateOverrides["FAILOVERCLUSTERIPADDRESSES"]
        if ($clusterAddress -eq $null -or $clusterAddress -eq "")
	    {
		    throw "You must specify the cluster IP address when doing a clustered install"
	    }
    }
	
	#Debug code dumps the parameters list to the console
	if ($Global:Debug)
	{
		"Hashtable Contents:"
		$Parameters
		""
	}
	
	#Load Template Overrides from the XML Config file
	if ($TemplateOverrides -eq $null)
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
	
	if ($Global:Debug)
	{
		"Template Overrides:"
		$TemplateOverrides
		""
	}
	
	#Set the script level variables containing path info based on the Data Center location selected
	$Global:SourcePath 		= $dcs.FilePath
	$Global:BinariesPath	= (Join-Path $Global:SourcePath ($binaryPath + "\"))
	$Global:RootPath		= $filePath
	$Global:CommonScripts 	= (Join-Path $Global:RootPath "Common\")
	$Global:PreScripts		= (Join-Path $Global:RootPath "PreScripts\")
	$Global:PostScripts 	= (Join-Path $Global:RootPath "PostScripts\")
	$Global:Modules		 	= (Join-Path $Global:RootPath "Modules\")
	$Global:Packages	 	= (Join-Path $Global:RootPath "Packages\")
	$Global:Templates	 	= (Join-Path $Global:RootPath "Templates\")
	$Global:Install			= (Join-Path $Global:RootPath "Install\")
	$Global:Scripts			= (Join-Path $Global:SourcePath "PowerShellScripts\")
	
	if ($Global:Debug)
	{
		"Source Path:    " + $Global:SourcePath
        	"Binaries Path:  " + $Global:BinariesPath
		"Root Path:      " + $Global:RootPath
		"Common Scripts: " + $Global:CommonScripts
		"PreScripts:     " + $Global:PreScripts
		"PostScripts:    " + $Global:PostScripts
		"Modules:        " + $Global:Modules
		"Packages:       " + $Global:Packages
		"Templates:      " + $Global:Templates
		"Install:        " + $Global:Install
		"Scripts:        " + $Global:Scripts
		""
	}
	
	#Remove the local folders so that they can be re-created to keep scripts in sync
	if (Test-Path (Join-Path $Global:RootPath "Common\"))
	{
		Remove-Item -path (Join-Path $Global:RootPath "Common\") -recurse -force
	}
	
	if (Test-Path (Join-Path $Global:RootPath "PreScripts\"))
	{
		Remove-Item -path (Join-Path $Global:RootPath "PreScripts\") -recurse -force
	}
	
	if (Test-Path (Join-Path $Global:RootPath "PostScripts\"))
	{
		Remove-Item -path (Join-Path $Global:RootPath "PostScripts\") -recurse -force
	}
	
	if (Test-Path (Join-Path $Global:RootPath "Templates\"))
	{
		Remove-Item -path (Join-Path $Global:RootPath "Templates\") -recurse -force
	}
	
	if (Test-Path (Join-Path $Global:RootPath "Modules\"))
	{
		Remove-Item -path (Join-Path $Global:RootPath "Modules\") -recurse -force
	}
	
	if (Test-Path (Join-Path $Global:RootPath "Packages\"))
	{
		Remove-Item -path (Join-Path $Global:RootPath "Packages\") -recurse -force
	}
	
	#Copy the needed files locally with the -Force option to overwrite existing files
	Copy-Item -path (Join-Path $Global:SourcePath "Common\") -destination $Global:RootPath -recurse -Force
	Copy-Item -path (Join-Path $Global:SourcePath "PreScripts\") -destination $Global:RootPath -recurse -Force
	Copy-Item -path (Join-Path $Global:SourcePath "PostScripts\") -destination $Global:RootPath -recurse -Force
	Copy-Item -path (Join-Path $Global:SourcePath "Templates\") -destination $Global:RootPath -recurse -Force
	
	if (Test-Path (Join-Path $Global:SourcePath "Modules\"))
	{
		Copy-Item -path (Join-Path $Global:SourcePath "Modules\") -destination $Global:RootPath -recurse -Force
	}
	
	if (Test-Path (Join-Path $Global:SourcePath "Packages\"))
	{
		Copy-Item -path (Join-Path $Global:SourcePath "Packages\") -destination $Global:RootPath -recurse -Force
	}
	
	#Dot-source everything in the common scripts folder 
	Get-ChildItem ($Global:CommonScripts + "*.ps1") | ForEach-Object {. (Join-Path $Global:CommonScripts $_.Name)}#| Out-Null
	
	#TODO: Validate this code
	#Load Modules from the modules folder
	#Get-ChildItem $Global:Modules | ?{$_.PsIsContainer -eq $true} | ForEach-Object {Import-Module $_.FullName -DisableNameChecking} | Out-Null
	#Get-ChildItem S:\Tools\Modules | ?{$_.PsIsContainer -eq $true} | ForEach-Object {Import-Module $_.FullName -DisableNameChecking} | Out-Null

	#Get the folder path and start building the Log file
    $Global:LogFile = join-path -path $Global:RootPath -childPath "SqlInstallerLog_$($instanceName).html"
    $strComputer 	= gc env:computername
	
    Write-Log -level "Header" -message "SQL Installer Run on $strComputer"
	Write-Log -level "Section" -message "Sample Messages"
	Write-Log -level "Warning" -message "Sample Warning"
    Write-Log -level "Error" -message "Sample Error"
	Write-Log -level "Attention" -message "Sample Notification"
	Write-Log -level "Info" -message "Sample Information"
	Write-Log -level "Info" -message "These styles can be modified by editing the Write-Log.ps1 file in the common scripts folder"
    Write-Log -level "Section" -message "Start Parameters"
	
	foreach ($param in $Parameters.GetEnumerator())
	{
		#For security reasons we will not display any passwords in the log
		if ($param.Key -match "password")
		{
			$message = "{0} - {1}" -f $param.Key, "********"
		}
		else
		{
			$message = "{0} - {1}" -f $param.Key, $param.Value
		}
		Write-Log -level "Info" -message $message
	}

    #Open the log file for the user
	if ($pscmdlet.ShouldProcess("Open installer log file", "Open Installer Log"))
	{
    	#start-process iexplore.exe -argumentlist $Global:LogFile
		$noie = @()
		try
		{
			Invoke-Item -ErrorAction SilentlyContinue -ErrorVariable noie -Path $Global:LogFile 
			
			if ($noie.count > 0)
			{
				start-process qtweb.exe -argumentlist $Global:LogFile
			}
		}
		catch
		{
			start-process qtweb.exe -argumentlist $Global:LogFile
		}
	}
	
	#Make sure that the script is being run with admin rights
	[bool]$Admin = Verify-IsAdmin
    
    if(!$Admin)
    {
        throw "This script requires administrative rights."
    }
    else
    { 
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
		
		Write-Log -level "Info" -message "Configuration file has been created and is located at $configFile" 
     	
		#execute pre-install checklist
		if (($PreOnly -eq $true -or $Full -eq $true) -and $Global:CriticalError -eq $false)
		{
	        Write-Log -level "Section" -message "Starting Pre-Install Checklist"
			if ($pscmdlet.ShouldProcess("Execute Pre-Install Scripts", "Pre-Install")) #if (!$Global:Simulation)
			{
				Execute-ScriptFiles -configParams $Parameters -sequence "pre"
			}
			Write-Log -level "Info" -message "Completed Pre-Install Checklist"
		}
		else
		{
			Write-Log -level "Section" -message "Skipping Pre-Install Checklist"
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
            $arguments = '/SETTINGS {0} /QB SAPWD="{1}" SQLPASSWORD="{2}" AGTPASSWORD="{2}" SQLBROWSERPASSWORD="{2}"' -f $configFile, $sysadminPassword, $servicePassword
        }
        else
        {
            #Format the command to be executed by Invoke-Expression (SQL 2008+ has the option to pass the log to the console to monitor progress)
			$command += 'setup.exe /CONFIGURATIONFILE=`"$configFile`" /SAPWD=`"$sysadminPassword`" /SQLSVCPASSWORD=`"$servicePassword`" /AGTSVCPASSWORD=`"$servicePassword`" /FTSVCPASSWORD=`"$servicePassword`" /ISSVCPASSWORD=`"$servicePassword`"'
        }
        
        if ($Global:Debug)
        {
            "setup command: $command"
			"arguments: $arguments"
			""
        }
		
		[int] $exitCode = 0
		
        #execte command
        if (($InstallOnly -eq $true -or $Full -eq $true) -and $Global:CriticalError -eq $false)
		{
			Write-Log -level "Section" -message "Starting SQL Server Install"
			if($sqlVersion -eq "Sql2005")
	        {
				#Call the GUI (Basic) install process and wait for it to complete
				if ($pscmdlet.ShouldProcess("Start SQL 2005 Installer Package", "Install SQL")) #if (!$Global:Simulation)
				{
		        	Start-Process -FilePath $command -ArgumentList $arguments -Wait
					$exitCode = $lastexitcode
				}
			}
			else
			{
				#Call the queit install process  - because it writes to the console we don't have to force the code to wait
				if ($pscmdlet.ShouldProcess("Start SQL Installer Package", "Install SQL")) #if (!$Global:Simulation)
				{
		        	Invoke-Expression $command
					$exitCode = $lastexitcode
				}
	        }
			
			if ($exitCode -eq 0)
			{
				Write-Log -level "Info" -message "Completed SQL Server Install"
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
			Write-Log -level "Section" -message "Skipping SQL Server Install"
		}
		
        #execute post-install checklist
		if (($PostOnly -eq $true -or $Full -eq $true) -and $Global:CriticalError -eq $false)
		{
			Write-Log -level "Section" -message "Starting Post-Install Checklist"
			if ($pscmdlet.ShouldProcess("Execute Post-Install Scripts", "Post-Install")) #if (!$Global:Simulation)
			{
				$IsSysAdmin = Execute-SqlScalarQuery -sqlScript "select is_srvrolemember('sysadmin')" -sqlInstance $Parameters.InstanceName
			
				if($IsSysAdmin -eq 1)
				{
		    		Execute-ScriptFiles -configParams $Parameters -sequence "post"
				}
				else
				{
					Write-Log -level "Error" -message "The current user does not have sufficient permissions to run the Post-Install Checklist - please check permissions and run the process again with the '-PostOnly' option"
				}
			}
			Write-Log -level "Info" -message "Completed Post-Install Checklist"
		}
		else
		{
			Write-Log -level "Section" -message "Skipping Post-Install Checklist"
		}
        
        #Capture end time
        $end = Get-Date
        $timeResult = ($end - $start)
        
		Write-Log -Level "Section" -Message "Script Time Results"
		Write-Log -Level "Info" -Message "Script Duration: $timeResult"
    }
}