Function Ping-Server
{
	param
	(
		[string] $serverName=$(throw "Server Name is required")
	)
	#This uses the ping command line utility and parses the results
#	[array] $pingResults = $(ping $serverName)
#	[string] $formattedResults = "Ping results for $serverName \n "
#	foreach($line in $pingResults)
#	{
#		$formattedResults += ($line + " \n ")
#	}
#	
#	return $formattedResults

	#This uses WMI and requires no parsing
	$statusCode = (get-wmiobject win32_pingstatus -Filter "address='$serverName'").StatusCode
	
	$result = ""
	switch ($statusCode)
	{
		0 {$result = "Success"}
		11001 {$result = "Buffer Too Small"}
		11002 {$result = "Destination Net Unreachable"}
		11003 {$result = "Destination Host Unreachable"}
		11004 {$result = "Destination Protocol Unreachable"}
		11005 {$result = "Destination Port Unreachable"}
		11006 {$result = "No Resources"}
		11007 {$result = "Bad Option"}
		11008 {$result = "Hardware Error"}
		11009 {$result = "Packet Too Big"}
		11010 {$result = "Request Timed Out"}
		11011 {$result = "Bad Request"}
		11012 {$result = "Bad Route"}
		11013 {$result = "TimeToLive Expired Transit"}
		11014 {$result = "TimeToLive Expired Reassembly"}
		11015 {$result = "Parameter Problem"}
		11016 {$result = "Source Quench"}
		11017 {$result = "Option Too Big"}
		11018 {$result = "Bad Destination"}
		11032 {$result = "Negotiating IPSEC"}
		11050 {$result = "General Failure"}
		default {$result = "Unknown Failure"}
	}
	
	return $result
}
