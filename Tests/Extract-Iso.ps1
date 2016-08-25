Function Expand-Iso {
    Param(
        [string]$ISO,
        [string]$Path
    )

    if (!(Test-Path -Path $iso))
    {
        throw "ISO Path Does not exists"
    }

    if (!(Test-Path -Path $path))
    {
        New-Item -ItemType Directory $path -Force
        if (!(Test-Path -Path $path))
        {
            throw "Cannot create path: $path"
        }
    }

    $mount_params = @{ImagePath = $iso; PassThru = $true; ErrorAction = "Ignore"}
    $mount = Mount-DiskImage @mount_params

    if($mount) {
        $volume = Get-DiskImage -ImagePath $mount.ImagePath | Get-Volume
        $source = $volume.DriveLetter + ":\*"
        Write-Output "Extracting '$iso' to '$path'..."
        cp @{Path = $source; Destination = $path; Recurse = $true;}
        $hide = Dismount-DiskImage @mount_params
        Write-Output "ISO Extracted"
    }
    else 
    {
        Write-Output "ERROR: Could not mount " $iso " check if file is already in use"
    }

}