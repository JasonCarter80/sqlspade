Function Execute-Sql
{
	param
	( 
		[Parameter(Position=0, Mandatory=$true)] [string] $sqlScript,
		[Parameter(Position=1, Mandatory=$true)] [AllowEmptyString()] [string] $sqlInstance,
        	[Parameter(Position=2, Mandatory=$false)] [string] $serverName = $Global:LogicalComputerName,
        	[Parameter(Position=3, Mandatory=$false)] [string] $databaseName = "master"
	)
    
	$sqlConn = new-Object System.Data.SqlClient.SqlConnection("Server=$serverName\$sqlInstance;DataBase=$databaseName;Integrated Security=SSPI;")
	
	#### Lets output script output to our log.  
	$handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Log -level "Info" -message $event.Message }; 
	$sqlConn.add_InfoMessage($handler); 
	$sqlConn.FireInfoMessageEventOnUserErrors = $false;
	
	$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$sqlCmd.Connection = $sqlConn
	$sqlCmd.CommandType = [System.Data.CommandType]'Text'
	$sqlCmd.CommandTimeout = 300
	$strCommands = [System.IO.File]::ReadAllText($sqlScript)
    	
	#Look for New Line without Carriage Return and vice versa
	$strCommands = $strCommands  -replace  "`r(?!`n)","`r`n" -replace "`(?<!`r)`n", "`r`n"
     
    	#Improved RegEx - Thanks to the SQLIse module of SQLPSX - sqlpsx.codeplex.com
	#[string[]] $commands =  $strCommands -split "\r?\n[ \t]*\[go\][ \t]*(?=\r?\n)"
	[string[]] $commands = $strCommands -split  "\r?\n[ \t]*go[ \t]*(?=\r?\n)"
        
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
	}

	return $strResult
}
