function Write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path='c:\Logs\Path.log', 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Warning","Attention","Info","Header","Section","Debug")] 
        [string]$Level="Info", 

        [Parameter(Mandatory=$false)] 
        [string]$Continuous=$true, 
		
		[Parameter(Mandatory=$false)] 
        [ValidateSet("FLAT","HTML","ALL")] 
        [string]$LogType="FLAT"
    )
    ## Use Parameters based on order, Passed-In, Global, then Default
    if (!$PSBoundParameters.ContainsKey("LogType") -and $Global:LogType)
    {
        $LogType = $Global:LogType
    }
    
    ## Use Parameters based on order, Passed-In, Global, then Default
    if (!$PSBoundParameters.ContainsKey("LogPath") -and $Global:LogPath)
    {
        $LogPath = $Global:LogPath
    }

    ## Use Parameters based on order, Passed-In, Global, then Default
    if (!$PSBoundParameters.ContainsKey("Continuous") -and $Global:LogContinuous)
    {
        $Continuous = $Global:LogContinuous
    }

    if (($Level -eq "Debug" -and !$Global:Debug)) {  return } 
    Write-To-Console -PassThru |  Write-To-Flat-Log -PassThru | Write-To-Html -PassThru

}
 
function CreateLogFile {
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true)] 
        [string]$LogType
    )
    process { 

        $FormattedDate = Get-Variable -Name StartTime -Scope Global -ValueOnly -ErrorAction SilentlyContinue
        if ($Continuous -and !$FormattedDate)
        {
            $FormattedDate = Get-Date -Format "yyyyMMddHHmmss"
            Set-Variable -Name StartTime -Scope Global -Value $FormattedDate 
        } 
        else 
        {
            $FormattedDate = ""
        }
        
        switch($LogType)
        {
            "HTML" { $extension = "html" }
            default { $extension = "log" } 
        }
        
        
        $logFile = (Join-Path $LogPath "SpadeInstaller_$($LogType)_$($FormattedDate).$($extension)")
        if (!(Test-Path $logFIle)) 
        { 
            $NewLogFile = New-Item $logFile -Force -ItemType File -WhatIf:$false
        }
        $logFile
    }
}

function Write-To-Console {
    param(
        [switch] $PassThru
    )

    process { 
        # Pass the the input to the next processor
        if($PassThru) {$_}
        
        
        # Leave if we're not writing this type of log
        if ((@('ALL','CONSOLE') | Where-Object { $LogType -Split ',' -contains $_ }).Length -eq 0) {  return }
        # Create our log file
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level.ToString().ToUpper()) { 
	        'Error' { 
		        Write-Host -ForegroundColor Black -BackgroundColor Red "$FormattedDate $($_): $Message" 

		        } 
	        { @('Warn','Warning') -contains $_ } { 
		        Write-Host -ForegroundColor Black -BackgroundColor Yellow "$FormattedDate $($_): $Message" 
		        } 
	        'Attention' { 
                Write-Host -ForegroundColor White -BackgroundColor Cyan "$FormattedDate $($_): $Message"
		        } 
	        'Info' { 
                Write-Host "$FormattedDate $($_): $Message"
		        } 
	        'Debug' { 
                Write-Host -ForegroundColor White -BackgroundColor Green "$FormattedDate $($_): $Message"
		        } 
	        { @('Section','Header') -contains $_ } { 
                Write-Host "$FormattedDate $($_): ------------ $Message -----------------"
		        
		        } 
	        } 
    }
			 
}

function Write-To-Flat-Log {
    param(
        [switch] $PassThru
    )
    process 
    {
        # Pass the the input to the next processor
        if($PassThru) {$_}
        
        # Leave if we're not writing this type of log
        if ((@('ALL','Flat') | Where-Object { $LogType -Split ',' -contains $_ }).Length -eq 0) { return }

        # Create our log file
        $logFile = CreateLogFile "FLAT"
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
		switch ($Level.ToString().ToUpper()) { 
			'Error' { 
				$LevelText = 'ERROR:' 
				} 
			{ @('Warn','Warning') -contains $_ } { 
				$LevelText = 'WARN:' 
				} 
			'Attention' { 
				$LevelText = 'ATTENTION:' 
				} 
			'Info' { 
				$LevelText = 'INFO:' 
				} 
			'Debug' { 
				$LevelText = 'Debug:' 
				} 
			{ @('Section','Header') -contains $_ } { 
				$LevelText = $_ 
				} 
			} 

        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 			 
		# Write log entry to $Path 
		"$FormattedDate $LevelText $Message" | Out-File -FilePath $logFile -Append  -WhatIf:$false
    }
}

function Write-To-Html {
    param(
        [switch] $PassThru
    )
    process 
    { 
        # Pass the the input to the next processor
        if($PassThru) {$_}

        # Leave if we're not writing this type of log
        if ((@('ALL','Html') | Where-Object { $LogType -Split ',' -contains $_ }).Length -eq 0) { return }

        # Create our log file
        $logFile = CreateLogFile "HTML"
        
        if (@('HTML') -contains $LogType -and !$Global:HtmlInitialized) 
        {
            $Global:HtmlInitializated = $true
            '<meta http-equiv="refresh" content="5">' | Out-File -FilePath $logFile -Append 
            Write-Log -level "Header" -message "SQL Installer Run on $strComputer"
	        Write-Log -level "Section" -message "Sample Messages"
	        Write-Log -level "Warning" -message "Sample Warning"
            Write-Log -level "Error" -message "Sample Error"
	        Write-Log -level "Attention" -message "Sample Notification"
	        Write-Log -level "Info" -message "Sample Information"
	        Write-Log -level "Info" -message "These styles can be modified by editing the Write-Log.ps1 file in the common scripts folder"
            Write-Log -level "Section" -message "Start Parameters"

            #Open the log file for the user
    	    #start-process iexplore.exe -argumentlist $Global:LogFile
		    $noie = @()
		    try
		    {
			    Invoke-Item -ErrorAction SilentlyContinue -ErrorVariable noie -Path $logFile  -WhatIf:$false
			    
		    }
		    catch
		    {
			    Write-Log -Level "Attention" -Message "Cound not start IE"
		    }             
	    }

        $debugColor = "green"
        $attentionColor = "yellow"
        $warningColor = "orange"
        $errorColor = "red"
			
        Add-Type -AssemblyName System.Web
        $messageHtml = [System.Web.HttpUtility]::HtmlEncode($Message)
			
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 			 			
        switch ($level.ToString().ToUpper())
        {
            "Debug"    {$string = "<span style='background-color:$debugColor;'>$FormattedDate $($_): $messageHtml</span><br/>"}
            "Info"     {$string = "$FormattedDate $($_): $messageHtml<br/>"}
            "Attention"{$string = "<span style='background-color:$attentionColor;'>$FormattedDate $($_): <i>$messageHtml*</i></span><br/>"}
            "Warning"  {$string = "<span style='background-color:$warningColor;'>$FormattedDate $($_): <b>$messageHtml</b></span><br/>"}
            "Error"    {$string = "<font color='$errorColor'>$FormattedDate $($_): <b>$messageHtml</b></font><br/>"; if ($message -ne "Sample Error"){$Global:CriticalError = $true}}
            "Header"   {$string = "<h1>$messageHtml</h1>"}
            "Section"  {$string = "<h2>$messageHtml</h2>"}
        }
        $string | Out-File -FilePath $logFile -Append  -WhatIf:$false
        
    }
}