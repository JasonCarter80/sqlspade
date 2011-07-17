Function Execute-Sql
{
	param
	( 
		[Parameter(Position=0, Mandatory=$true)] [string] $sqlScript,
		[Parameter(Position=1, Mandatory=$false)] [string] $sqlInstance,
        [Parameter(Position=2, Mandatory=$false)] [string] $serverName = ".",
        [Parameter(Position=3, Mandatory=$false)] [string] $databaseName = "master"
	)
    if ($sqlInstance)
	{
		$sqlConn = new-Object System.Data.SqlClient.SqlConnection("Server=$serverName\$sqlInstance;DataBase=$databaseName;Integrated Security=SSPI;")
	}
	else
	{
		$sqlConn = new-Object System.Data.SqlClient.SqlConnection("Server=$serverName;DataBase=$databaseName;Integrated Security=SSPI;")
	}
	$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$sqlCmd.Connection = $sqlConn
	$sqlCmd.CommandType = [System.Data.CommandType]'Text'
	$sqlCmd.CommandTimeout = 300
	$strCommands = [System.IO.File]::ReadAllText($sqlScript)
	[string[]] $commands =  $strCommands -split "\r?\n[ \t]*\[go\][ \t]*(?=\r?\n)"
        
    try
	{	
		if ($commands.Length -eq 0)
    	{
    		throw "Script does not contain any commands to execute"
    	}
        
        $sqlConn.Open()
        
        foreach ($cmd in $commands)
		{
            $sqlCmd.CommandText = $cmd
			$sqlCmd.ExecuteNonQuery() | Out-Null
		}
		$strResult = "Command(s) completed successfully."
	}
	catch [System.Exception]
	{
		$strResult = $_.Exception
	}
	finally
	{
		if ($sqlConn.State -ne [System.Data.ConnectionState]'Closed')
		{
			$sqlConn.Close()
		}
        return $strResult
	}
}
