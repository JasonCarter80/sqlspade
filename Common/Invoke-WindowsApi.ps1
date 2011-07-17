##############################################################################
##
## Invoke-WindowsApi
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################
Function Invoke-WindowsApi
{
<#

.SYNOPSIS

Invoke a native Windows API call that takes and returns simple data types.


.EXAMPLE

## Prepare the parameter types and parameters for the CreateHardLink function
PS >$filename = "c:\temp\hardlinked.txt"
PS >$existingFilename = "c:\temp\link_target.txt"
PS >Set-Content $existingFilename "Hard Link target"
PS >$parameterTypes = [string], [string], [IntPtr]
PS >$parameters = [string] $filename, [string] $existingFilename,
    [IntPtr]::Zero

## Call the CreateHardLink method in the Kernel32 DLL
PS >$result = Invoke-WindowsApi "kernel32" ([bool]) "CreateHardLink" `
    $parameterTypes $parameters
PS >Get-Content C:\temp\hardlinked.txt
Hard Link target

#>

	param(
	    ## The name of the DLL that contains the Windows API, such as "kernel32"
	    [string] $DllName,

	    ## The return type expected from Windows API
	    [Type] $ReturnType,

	    ## The name of the Windows API
	    [string] $MethodName,

	    ## The types of parameters expected by the Windows API
	    [Type[]] $ParameterTypes,

	    ## Parameter values to pass to the Windows API
	    [Object[]] $Parameters
	)

	Set-StrictMode -Version Latest

	## Begin to build the dynamic assembly
	$domain = [AppDomain]::CurrentDomain
	$name = New-Object Reflection.AssemblyName 'PInvokeAssembly'
	$assembly = $domain.DefineDynamicAssembly($name, 'Run')
	$module = $assembly.DefineDynamicModule('PInvokeModule')
	$type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit")

	## Go through all of the parameters passed to us.  As we do this,
	## we clone the user's inputs into another array that we will use for
	## the P/Invoke call.
	$inputParameters = @()
	$refParameters = @()

	for($counter = 1; $counter -le $parameterTypes.Length; $counter++)
	{
	    ## If an item is a PSReference, then the user
	    ## wants an [out] parameter.
	    if($parameterTypes[$counter - 1] -eq [Ref])
	    {
	        ## Remember which parameters are used for [Out] parameters
	        $refParameters += $counter

	        ## On the cloned array, we replace the PSReference type with the
	        ## .Net reference type that represents the value of the PSReference,
	        ## and the value with the value held by the PSReference.
	        $parameterTypes[$counter - 1] =
	            $parameters[$counter - 1].Value.GetType().MakeByRefType()
	        $inputParameters += $parameters[$counter - 1].Value
	    }
	    else
	    {
	        ## Otherwise, just add their actual parameter to the
	        ## input array.
	        $inputParameters += $parameters[$counter - 1]
	    }
	}

	## Define the actual P/Invoke method, adding the [Out]
	## attribute for any parameters that were originally [Ref]
	## parameters.
	$method = $type.DefineMethod(
	    $methodName, 'Public,HideBySig,Static,PinvokeImpl',
	    $returnType, $parameterTypes)
	foreach($refParameter in $refParameters)
	{
	    [void] $method.DefineParameter($refParameter, "Out", $null)
	}

	## Apply the P/Invoke constructor
	$ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string])
	$attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName
	$method.SetCustomAttribute($attr)

	## Create the temporary type, and invoke the method.
	$realType = $type.CreateType()

	$realType.InvokeMember(
	    $methodName, 'Public,Static,InvokeMethod', $null, $null,$inputParameters)

	## Finally, go through all of the reference parameters, and update the
	## values of the PSReference objects that the user passed in.
	foreach($refParameter in $refParameters)
	{
	    $parameters[$refParameter - 1].Value = $inputParameters[$refParameter - 1]
	}
}
