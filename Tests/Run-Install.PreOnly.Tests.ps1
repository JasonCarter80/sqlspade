<<<<<<< HEAD
Import-Module -Force $PSScriptRoot\..\Run-Install.ps1

Describe 'Execute PreOnly' {

    Context 'Pre Install Options Only' { 
=======
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
>>>>>>> 194f1630edcc4e4825f3066ef45940185565f01c

        #Set-StrictMode -Version latest

        It 'Should Not Break' {
<<<<<<< HEAD
			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   

=======
			[hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable

			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   
			$ht.Add("FilePath", 'C:\projects\sqlspade\')
>>>>>>> 194f1630edcc4e4825f3066ef45940185565f01c
			Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly 
        }

        It 'Should Break' {
<<<<<<< HEAD
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   
			{ Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly } | Should Throw
        } 

        BeforeEach  {
            [hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable
			$ht.Add("FilePath", 'C:\Code\sqlspade\')
=======
			[hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable

                
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   
			$ht.Add("FilePath", 'C:\projects\sqlspade\')
			Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly 
>>>>>>> 194f1630edcc4e4825f3066ef45940185565f01c
        }
    }
} 