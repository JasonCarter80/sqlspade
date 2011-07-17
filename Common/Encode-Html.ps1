Function Encode-Html
{
    param
    (
        [Parameter(Position=0,Mandatory=$true)] [string] $value
    )

    # System.Web.HttpUtility.HtmlEncode() doesn't quite get everything, and 
    # I don't want to load the System.Web assembly just for this.  I'm sure 
    # I missed something here, but these are the characters I saw that needed 
    # to be encoded most often
    $value = $value -replace "&(?![\w#]+;)", "&amp;"
    $value = $value -replace "<(?!!--)", "&lt;"
    $value = $value -replace "(?<!--)>", "&gt;"
    $value = $value -replace "’", "&#39;"
    $value = $value -replace '["“”]', "&quot;"
    
    $value = $value -replace "\\n", "<br />"

    $value
}
