Import-Module -Force $PSScriptRoot\..\Common\Write-Log.ps1 
Import-Module -Force $PSScriptRoot\..\Run-Install.ps1

Describe 'Execute PreOnly' {
    
	Mock Write-Log { 
		Param(
			[string]$Message,
			[string]$Level="Info"
		)  
		$LevelText = $Level.ToString().ToUpper()
		$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		
		Add-AppveyorMessage -Message "$FormattedDate $LevelText $Message"
	}
	
    Context 'Strict mode' { 

        #Set-StrictMode -Version latest

        It 'Should Not Break' {
			[hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable

			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   
			$ht.Add("FilePath", 'C:\projects\sqlspade\')
			Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly 
        }

        It 'Should Break' {
			[hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable

                
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   
			$ht.Add("FilePath", 'C:\projects\sqlspade\')
			Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly 
        }
    }
} 