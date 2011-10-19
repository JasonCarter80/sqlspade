Function Write-Log
{
    param(
        [string] $level=$(throw "Level required"), 
        [string] $message=$(throw "Message required")
    )
    
	$attentionColor = "lime"
    $warningColor = "yellow"
    $errorColor = "red"
    
	$messageHtml = Encode-Html $message
    $messageHtml = (Get-Date).ToString() + ": $messageHtml"
    
    switch ($level)
    {
        "Info"     {$string = "$messageHtml<br/>"}
		"Attention"{$string = "<span style='background-color:$attentionColor;'><i>$messageHtml*</i></span><br/>"}
        "Warning"  {$string = "<span style='background-color:$warningColor;'><b>$messageHtml</b></span><br/>"}
        "Error"    {$string = "<font color='$errorColor'><b>$messageHtml</b></font><br/>"; if ($message -ne "Sample Error"){$Global:CriticalError = $true}}
        "Header"   {$string = "<h1>$messageHtml</h1>"}
        "Section"  {$string = "<h2>$messageHtml</h2>"}
    }
    
#	if ($pscmdlet.ShouldProcess("Write Log Entry", "Write Log"))
#	{
    	$string >> $Global:LogFile
#	}
#	else
#	{
#		Write-Output $message
#	}
}
