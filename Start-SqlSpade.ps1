#Clear the output window
cls

#Dot-Source the root function
$Invocation = (Get-Variable MyInvocation).Value
$path = Join-Path (Split-Path $Invocation.MyCommand.Path) Run-Install.ps1
. $path

[hashtable] $ht = New-Object hashtable

#Required Parameters
$ht.Add("SqlVersion", 'Sql2012') #Valid values - Sql2005, Sql2008, Sql2008R2, Sql2012
$ht.Add("SqlEdition", 'Developer') #Valid values - Standard, Enterprise, Developer (2008R2 and 2012 only)
$ht.Add("sqlServiceAccount", 'SQLFTW\SQLService')
$ht.Add("sqlServicePassword", 'SQL4tw!')
$ht.Add("SysAdminPassword", 'SQL4tw!')
$ht.Add("FilePath", 'S:\Tools')
$ht.Add("DataCenter", 'Data Center 1')

#Optional Parameters
#$ht.Add("ProcessorArch", '')
#$ht.Add("Debug", 'True')
#$ht.Add("Simulation", 'True')

#Custom Parameters - (Required)
$ht.Add("DbaTeam", 'DBA-SQL')
$ht.Add("InstanceName", 'SQLDEV2')
$ht.Add("ProductStringName", 'Default')
$ht.Add("Environment", 'Prod') #Valid values - Dev, QA, BCP, PreProd, Prod

[hashtable] $overrides = New-Object hashtable

#Optional values that are used directly in the generation 
#of the configuration INI file.  Anything specified here 
#will superceed values specified in the XML config file

#for a complete list of parameters please review the BOL topic
#for installing SQL Server from the command line

#$overrides.Add("SQLBACKUPDIR", 'C:\$Recycle.Bin')
#$overrides.Add("SQLUSERDBDIR", 'H:\MSSQL10\MSSQL\Data')
#$overrides.Add("SQLUSERDBLOGDIR", 'H:\MSSQL10\MSSQL\Logs')

Run-Install -Parameters $ht -TemplateOverrides $overrides -Verbose -Full