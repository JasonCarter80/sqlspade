
Function Validate-Strong-Password {

    param(
        [string]$Password = $(throw "Please specify password"),
        [int]$minLength=8,
        [int]$numUpper = 1,
        [int]$numLower = 1,
        [int]$numNumbers = 1, 
        [int]$numSpecial = 1,
        [int]$minGroups = 3
    )


    $upper = [regex]"[A-Z]"
    $lower = [regex]"[a-z]"
    $number = [regex]"[0-9]"
    $special = [regex]"[^a-zA-Z0-9]"
    $groups = 0
    # Check the length.
    
    if ($Password.length -lt $minLength) 
    {
        Write-Log -Level Debug "Password does not meet Minimum Length Requirement of $minLength"
        return $false; 
    }


    # Check for minimum number of occurrences.
    if ($upper.Matches($Password).Count -lt $numUpper ) 
    {
        Write-Log -Level Debug "Password does not meet  Upper Case Letter Requirement of $numUpper"
        return $false; 
    } 
    else 
    { 
        $group += 1 
    }

    if ($lower.Matches($Password).Count -lt $numLower ) 
    {
        Write-Log -Level Debug "Password does not meet Lower Case Letter Requirement of $numLower"
        return $false; 
    } 
    else 
    { 
        $group += 1 
    }
    
    if ($number.Matches($Password).Count -lt $numNumbers ) 
    {
        Write-Log -Level Debug "Password does not meet Numbers Requirement of $numNumbers"
        return $false; 
    } 
    else 
    { 
        $group += 1 
    }
    
    if ($special.Matches($Password).Count -lt $numSpecial ) 
    {
        Write-Log -Level Debug "Password does not meet Special Character Requirement of $numSpecial"
        return $false; 
    } 
    else 
    { 
        $group += 1 
    }

    if ($group -lt $minGroups) 
    { 
        Write-Log -Level Debug "Password does not meet Matches Per Group of $minGroups"
        return $false; 
    }

    
    return $true
}
