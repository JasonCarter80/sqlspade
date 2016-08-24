#Clear the output window
cls

#Dot-Source the root function
$Invocation = (Get-Variable MyInvocation).Value
$path = Join-Path (Split-Path $Invocation.MyCommand.Path) Run-Install.ps1
. $path

[hashtable] $ht = New-Object hashtable
[hashtable] $overrides = New-Object hashtable

#Required Parameters
$ht.Add("DataCenter", 'Local')                   #Must be setup in Data Center node of Config
$ht.Add("SqlVersion", 'Sql2012')                 #Must be setup in SQLVersions node of Config
$ht.Add("SqlEdition", 'Developer')               #Must be setup in SQLVersions/Editions node of Config


#Optional regularly used Parameters
#$ht.Add("SysAdminPassword", 'SQL4tw!ABC')           #Must be STRONG PASSWOD,  will be generated if not provided
#$ht.Add("sqlServiceAccount", 'SQLFTW\SQLService')
#$ht.Add("sqlServicePassword", 'SQL4tw!')
#$ht.Add("InstanceName", 'SQLDEV2')                  #Will default to the default instance if not provided
#$ht.Add("ProductStringName", 'Default')             #Will default to 'DEFAULT' which must be setup in each SQLVERSION/ProductStrings node
#$ht.Add("Environment", 'Prod')                      #Will default to PROD, can be used in Pre/Post scripts, not used by Installer


#$overrides.Add("SQLBACKUPDIR", 'C:\$Recycle.Bin')
#$overrides.Add("SQLUSERDBDIR", 'H:\MSSQL10\MSSQL\Data')
#$overrides.Add("SQLUSERDBLOGDIR", 'H:\MSSQL10\MSSQL\Logs')

Run-Install -Parameters $ht -TemplateOverrides $overrides -Verbose -PreOnly 