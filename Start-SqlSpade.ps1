#Clear the output window
cls

#Dot-Source the root function
$Invocation = (Get-Variable MyInvocation).Value
$path = Join-Path (Split-Path $Invocation.MyCommand.Path) Run-Install.ps1
. $path

[hashtable] $ht = New-Object hashtable

#Required Parameters
$ht.Add("SqlVersion", 'Sql2005')
$ht.Add("SqlEdition", 'Standard')
$ht.Add("ServiceAccount", 'alfki\SqlService')
$ht.Add("ServicePassword", 'P@ssw0rd1')
$ht.Add("SysAdminPassword", 'P@ssw0rd1')
$ht.Add("FilePath", 'S:\Tools')
$ht.Add("DataCenter", 'Data Center 1')

#Optional Parameters
#$ht.Add("ProcessorArch", '')
#$ht.Add("Debug", 'True')
#$ht.Add("Simulation", 'True')

#Custom Parameters
$ht.Add("DbaTeam", 'DBA-SQL')
$ht.Add("InstanceName", 'sqldev1')
$ht.Add("ProductStringName", 'Default')

[hashtable] $overrides = New-Object hashtable

#Optional values that are used directly in the generation 
#of the configuration INI file.  Anything specified here 
#will superceed values specified in the XML config file
#$overrides.Add("SQLBACKUPDIR", 'C:\$Recycle.Bin')

Run-Install -Parameters $ht -TemplateOverrides $overrides -Verbose -Full