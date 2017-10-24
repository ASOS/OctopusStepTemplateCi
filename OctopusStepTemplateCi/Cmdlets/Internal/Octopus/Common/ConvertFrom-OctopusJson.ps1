<#

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
    ConvertFrom-OctopusJson

.SYNOPSIS
    Converts a JSON string into a PowerShell object.
#>
function ConvertFrom-OctopusJson
{

    param
    (

        [Parameter(Mandatory=$false)]
        [string] $InputObject = [string]::Empty

    )

    $ErrorActionPreference = "Stop";
    Set-StrictMode -Version "Latest";

    # convert the json string into an object model using the
    # System.Web.Script.Serialization.JavaScriptSerializer which uses
    # [System.Collections.Generic.Dictionary[string, Object]]
    # to represent key-value pairs
    $dictionaryJsonObject = ConvertTo-DictionaryJsonObject -InputJson $InputObject;

    # convert [System.Collections.Generic.Dictionary[string, Object]]
    # objects in the json object model into hashtables instead
    $hashtableJsonObject = ConvertTo-HashtableJsonObject -InputObject $dictionaryJsonObject;

    return @(, $hashtableJsonObject);

}