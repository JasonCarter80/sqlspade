#Clear the output window
cls

#Dot-Source the root function
$Invocation = (Get-Variable MyInvocation).Value
$path = Join-Path (Split-Path $Invocation.MyCommand.Path) Run-Install.ps1
. $path


[hashtable] $ht = New-Object hashtable
[hashtable] $overrides = New-Object hashtable

#Required Parameters
$ht.Add("SqlVersion", 'SQL2008R2') 	#Valid values - Sql2005, Sql2008, Sql2008R2, Sql2012, Sql2014, Sql2016
$ht.Add("SqlEdition", 'Standard') 	#Valid values - Standard, Enterprise, Developer (2008R2+)
$ht.Add("SP", 'SP3') 				#Valid values - Varies by Version
$ht.Add("DataCenter", 'RDP') 		#Valid values - Values setup in .Config DataCenter section

Run-Install -Parameters $ht -TemplateOverrides $overrides  -Full  -Confirm:$false 