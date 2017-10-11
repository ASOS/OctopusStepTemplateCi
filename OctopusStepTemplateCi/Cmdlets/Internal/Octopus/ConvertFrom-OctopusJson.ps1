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

    function ConvertFrom-JsonObject
    {

        param
        (

            [Parameter(Mandatory=$false)]
            [object] $InputObject

        )

        switch( $true )
        {

            { $InputObject -eq $null } {
                return $null;
            }

            { $InputObject -is [bool] } {
                return $InputObject;
            }

            { $InputObject -is [string] } {
                return $InputObject;
            }

            { $InputObject -is [int32] } {
                return $InputObject;
            }

            { $InputObject -is [Array] } {
                $result = @();
                foreach( $jsonItem in $InputObject )
                {
                    $result += ConvertFrom-JsonObject $jsonItem;
                }
                return @(, $result);
            }
	    
	    { $InputObject -is [System.Collections.Generic.Dictionary[string, Object]] } {
                $result = @{};
                foreach( $key in $InputObject.Keys )
                {
                    $value = ConvertFrom-JsonObject -InputObject $InputObject[$key];
                    $result.Add($key, $value);
                }
                return @(, $result);
            }

            default {
                $typename = $InputObject.GetType().FullName;
                throw new-object System.InvalidOperationException("Unhandled input object type '$typename'.");
            }

        }

    }

    # .NET JSON Serializer
    if( ([System.Management.Automation.PSTypeName] "System.Web.Script.Serialization.JavaScriptSerializer").Type -eq $null )
    {
        $assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions");
    }
    $serializer = new-object System.Web.Script.Serialization.JavaScriptSerializer;
    $serializer.MaxJsonLength = [System.Int32]::MaxValue;
    $serializer.RecursionLimit = 9999;

    $jsonObject = $serializer.DeserializeObject($InputObject);

    $result = ConvertFrom-JsonObject -InputObject $jsonObject;

    return @(, $result);

}