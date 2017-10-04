<#
Copyright 2016 ASOS.com Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

<#
.NAME
	ParseJson.Tests

.SYNOPSIS
	Uses .NET JSON serializer to deseralize a JSON string, as an alternaive to
    ConvertFrom-JSON which has different size constraints on various versions of
    PowerShell.
#>
function ParseJsonString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [string] $json
    )

    $ErrorActionPreference = "Stop";
    Set-StrictMode -Version "Latest";

    # Internalised functions necessary to parse JSON output from .NET serializer to PowerShell Objects
    function ParseItem($jsonItem)
    {
        if( $jsonItem -eq $null )
	{
            return $null;
        }
        elseif( $jsonItem.PSObject.TypeNames -match "Array" )
	{
            $result = ParseJsonArray $jsonItem;
            return @(, $result);
        }
        elseif( $jsonItem.PSObject.TypeNames -match "Dictionary" )
	{
            return ParseJsonObject([HashTable]$jsonItem);
        }
        else
	{
            return $jsonItem
        }
    }

    function ParseJsonObject($jsonObj)
    {
        $result = New-Object -TypeName PSCustomObject;
        foreach( $key in $jsonObj.Keys )
	{
            $item = $jsonObj[$key]
            if( $item -eq $null )
            {
                $parsedItem = $null;
            }
	    else
	    {
                $parsedItem = ParseItem $item;
            }
            $result | Add-Member -MemberType NoteProperty -Name $key -Value $parsedItem;
        }
        return @(, $result);
    }

    function ParseJsonArray($jsonArray)
    {
        $result = @();
        foreach( $jsonItem in $jsonArray )
        {
            $result += ParseItem $jsonItem;
        }
        return @(, $result);
    }

    # .NET JSON Serializer
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions") | Out-Null
    $script:javaScriptSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $script:javaScriptSerializer.MaxJsonLength = [System.Int32]::MaxValue
    $script:javaScriptSerializer.RecursionLimit = 99

    $config = $javaScriptSerializer.DeserializeObject($json);

    $result = ParseItem($config);

    # $result will be an empty array if the input was "[]", but powershell converts this to
    # $null when it gets returned from a function. e.g.:
    #
    #   function Get-EmptyArray { return @(); }
    #   write-host ((Get-EmptyArray) -eq $null);
    #
    # so we need to wrap the return value in a "sacrifical array" instead to make sure powershell
    # returns the value unmodified.

    return @(, $result);

}