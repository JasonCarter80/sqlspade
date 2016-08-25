Import-Module -Force $PSScriptRoot\..\Run-Install.ps1

Describe 'Install SQL 2014 Developer' {

    Context 'Install Options Only' {  

        #Set-StrictMode -Version latest

        It 'Should Install a Base Instance' {
			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2014')                 
			$ht.Add("SqlEdition", 'Developer')   
            $overrides.Add("SQLSYSADMINACCOUNTS","APPVYR-WIN\appveyor")

			Run-Install -Parameters $ht -TemplateOverrides $overrides  -InstallOnly 
        }

        It 'Should Test the Post after a Successful Install' {
			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2014')                 
			$ht.Add("SqlEdition", 'Developer')   
            $overrides.Add("SQLSYSADMINACCOUNTS","APPVYR-WIN\appveyor")

			Run-Install -Parameters $ht -TemplateOverrides $overrides  -PostOnly 
        }

        It 'Should Install a Secondary Instance Named SpadeSql2014' {
			$ht.Add("DataCenter", 'Local')                   
			$ht.Add("SqlVersion", 'Sql2014')                 
			$ht.Add("SqlEdition", 'Developer')   
            $ht.Add("InstanceName", 'SpadeSql2014') 
            $overrides.Add("SQLSYSADMINACCOUNTS","APPVYR-WIN\appveyor")

			Run-Install -Parameters $ht -TemplateOverrides $overrides  -InstallOnly 
        }
        
        BeforeEach  {
            [hashtable] $ht = New-Object hashtable
			[hashtable] $overrides = New-Object hashtable
			$ht.Add("FilePath", 'C:\Code\sqlspade\')
        }
    }
} 