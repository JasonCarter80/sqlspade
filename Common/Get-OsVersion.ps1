Function Get-OsVersion
{   
    $comp = (Get-WmiObject Win32_OperatingSystem | Select Caption)
    
    switch -wildcard ($comp.Caption)
    {
        "Microsoft(R) Windows(R) Server 2003*"  {$version = "2003"}
        "Microsoft Windows Server 2008*"        {$version = "2008"}
        "Microsoftr Windows Serverr 2008*"      {$version = "2008"}
        default                                 {$version = "Unknown"}
    }
    return $version
}
