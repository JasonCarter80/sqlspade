Import-Module -Force $PSScriptRoot\..\Run-Install.ps1

Describe 'Execute PreOnly' {

    Context 'Pre Install Options Only' {  

        #Set-StrictMode -Version latest

        It 'Should Not Break' {
			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   

			Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly 
        }

        It 'Should Break' {
			$ht.Add("SqlVersion", 'Sql2012')                 
			$ht.Add("SqlEdition", 'Developer')   
			{ Run-Install -Parameters $ht -TemplateOverrides $overrides  -PreOnly } | Should Throw
        } 

        BeforeEach  {
            [hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable
			$ht.Add("FilePath", 'C:\Code\sqlspade\')
        }
    }
} 