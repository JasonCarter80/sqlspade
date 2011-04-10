Function Get-PortNumber
{
    param(
        [string] $instanceName=$(throw "Instance Name required"),
        [string] $computerName=$(throw "Computer Name required")
    )
    
    $env = ""
    [int]$port = 1433
    
    return $port
}
