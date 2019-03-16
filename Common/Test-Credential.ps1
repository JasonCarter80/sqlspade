function Test-Credential {
    <#
    .SYNOPSIS
        Takes a PSCredential object and validates it against the domain (or local machine, or ADAM instance).

    .PARAMETER Credential
        Optional - PScredential object with the username/password you wish to test. Typically this is generated using the Get-Credential cmdlet. Accepts pipeline input.

	.PARAMETER UserName
        Optional - Plain-Text username to be tested.		

	.PARAMETER Password
        Optional - Plain-Text Password to be tested
		
    .PARAMETER context
        An optional parameter specifying what type of credential this is. Possible values are 'Domain','Machine',and 'ApplicationDirectory.' The default is 'Domain.'

    .OUTPUTS
        A boolean, indicating whether the credentials were successfully validated.

    #>
    param(
        [Parameter(ParameterSetName='Credentials',
            ValueFromPipeline=$True,
            Mandatory=$True)]
            [System.Management.Automation.PSCredential]$Credential,
        [Parameter(ParameterSetName='Details',
            ValueFromPipeline=$True,
            Mandatory=$True)]
            [string]$UserName,
        [Parameter(ParameterSetName='Details',
            ValueFromPipeline=$True,
            Mandatory=$True)]
            [string]$Password,
        [parameter()]
            [validateset('Domain','Machine','ApplicationDirectory')]
            [string]$context = 'Domain'
    )
    begin {
        Add-Type -assemblyname system.DirectoryServices.accountmanagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::$context) 
    }
    process {
        if (!$credential)
        {
            $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
        }
        
        $DS.ValidateCredentials($credential.UserName, $credential.GetNetworkCredential().password)
    }
}