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
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $json
    )

    # Internalised functions necessary to parse JSON output from .NET serializer to PowerShell Objects
    function ParseItem($jsonItem) {
        if($jsonItem.PSObject.TypeNames -match "Array") {
            return ParseJsonArray($jsonItem)
        }
        elseif($jsonItem.PSObject.TypeNames -match "Dictionary") {
            return ParseJsonObject([HashTable]$jsonItem)
        }
        else {
            return $jsonItem
        }
    }

    function ParseJsonObject($jsonObj) {
        $result = New-Object -TypeName PSCustomObject
        foreach ($key in $jsonObj.Keys) {
            $item = $jsonObj[$key]
            if ($item) {
                    $parsedItem = ParseItem $item
            } else {
                    $parsedItem = $null
            }
            $result | Add-Member -MemberType NoteProperty -Name $key -Value $parsedItem
        }
        return $result
    }

    function ParseJsonArray($jsonArray) {
        $result = @()
        $jsonArray | ForEach-Object {
            $result += , (ParseItem $_)
        }
        return $result
    }

    # .NET JSON Serializer 
    $script:javaScriptSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $script:javaScriptSerializer.MaxJsonLength = [System.Int32]::MaxValue
    $script:javaScriptSerializer.RecursionLimit = 99

    $config = $javaScriptSerializer.DeserializeObject($json)
    return ParseItem($config)
}