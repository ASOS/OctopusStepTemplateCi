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
    ConvertTo-DictionaryJsonObject

.SYNOPSIS
    Converts a JSON string into a PowerShell object model that uses instances of
    [System.Collections.Generic.Dictionary[string, Object]] to store json objects.

    This is an internal function intended for use from ConvertFrom-OctopusJson, but
    implemented as a separate function to aid code coverage tests.
#>
function ConvertTo-DictionaryJsonObject
{

    param
    (

        [Parameter(Mandatory=$false)]
        [string] $InputJson

    )

    # .NET JSON Serializer
    if( ([System.Management.Automation.PSTypeName] "System.Web.Script.Serialization.JavaScriptSerializer").Type -eq $null )
    {
        $assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions");
    }

    $serializer = new-object System.Web.Script.Serialization.JavaScriptSerializer;
    $serializer.MaxJsonLength = [System.Int32]::MaxValue;
    $serializer.RecursionLimit = 9999;

    $jsonObject = $serializer.DeserializeObject($InputObject);

    return @(, $jsonObject);

}