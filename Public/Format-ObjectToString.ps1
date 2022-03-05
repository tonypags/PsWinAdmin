function Format-ObjectToString 
{
    <#
    .SYNOPSIS
    Formats a PS Object into a string using custom attributes.
    .DESCRIPTION
    Ingests any PS Object and requires an ordered hashtable to map its key-value pairs to
    control the content of a resultant string from the values in the object.
    The result will be in the form:
    PropertyName1: ExpressionResult1; PropertyName2: ExpressionResult2, etc...
    .PARAMETER Format
    An ORDERED hashtable giving the output formatting of the object properties as a series of strings.

    For the KEY, use the NAME of the property as you would like it displayed in the resultant string.
    Use a single tilde (~) character for the key to hide the property name in the resultant string and
    force that item to be first in the list, regardless of place in the (ordered) hashtable.
    
    For the VALUE, use an EXPRESSION that will give you the value to be displayed after a given
    property's equater, as when using the form of `$Object | Select @{'Name'='Name';Exp=$Format.Key}`
    .PARAMETER Delimiter
    One or more characters that will separate each property along the new string. The default is "; ". 
    The tilde (~) is not allowed.
    .PARAMETER Equater
    One or more characters that will separate the property and the value in each pair in the resultant
    string. The default is ": ".
    .PARAMETER InputObject
    The object with multiple properties you would like to turn into a delimited string.
    .EXAMPLE
    Get-ChildItem | Format-ObjectToString [ordered]@{ '~'={$_.FullName}; 'Modified'={
        $_.LastWriteTime.ToString('yyyyMMdd')} } -Equater ' = '

    "C:\Users\myprofile\Downloads\vote.txt"; Modified = 20161108
    #>
    [CmdletBinding()]
    param (
        
        # An ORDERED hashtable giving the output formatting of the object properties.
        [Parameter(Mandatory=$true,
            Position=0)]
        #[System.Collections.Specialized.OrderedDictionary]
        $Format,

        # One or more characters that will separate each property along the new string.
        [Parameter(Position=1)]
        [ValidateScript({ $_ -ne '~' })]
        [string]
        $Delimiter = '; ',

        # One or more characters will separate the Property Name from the Expression Result.
        [Parameter(Position=2)]
        [string]
        $Equater = ': ',

        # The object with multiple properties you would like to turn into a delimited string.
        [Parameter(ValueFromPipeline=$true)]
        $InputObject
    )
    
    begin {}
    
    process {
    
        Foreach ($object in $InputObject) {

            # Build a string
            [string[]]$thisResultantString = @()

            # The user may have elected to choose a name-less value to be first.
            if ($Format.Keys -contains '~') {

                $thisResultantString += $object | Select-Object @{
                    Name = 'ShortLivedPropertyName'
                    Expression = $Format['~']
                } | Select-Object -ExpandProperty ShortLivedPropertyName -ea Stop
            
            }#if ($Format.Keys -contains '~')

            # Process the remaining Keys
            [string[]]$Keys = $Format.Keys | Where-Object {$_ -ne '~'} 
            Foreach ($Key in $Keys) {

                $thisResultantString += $object | Select-Object @{
                    Name = $Key
                    Expression = $Format[$Key]
                } | Select-Object @{

                    Name = 'ShortLivedPropertyName'
                    Expression = {
                        [string](
                            $Key +
                            $Equater +
                            $_.$Key
                        )
                    }

                } | Select-Object -ExpandProperty ShortLivedPropertyName -ea Stop

            }#Foreach ($object in $InputObject)

            Write-Output ($thisResultantString -join $Delimiter)
            
        }#Foreach ($object in $InputObject)

    }#Process
    
    end {}
}
