Function Execute-Powershell
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)] [string] $psScript,
		[Parameter(Position=1, Mandatory=$true)] $configParams
	)
	
	return Invoke-Expression -Command "$psScript `$configParams"
}
