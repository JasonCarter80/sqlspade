Function Create-Folder
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)] [string] $folderPath
	)
	
    if(test-path $folderPath)
    {
        Write-Log -level "Info" -message "$folderPath folder already exists"   
    }
    else
    {
        New-Item $folderPath -itemType Directory | Out-Null
        Write-Log -level "Info" -message "$folderPath folder has been created"
    }
}
