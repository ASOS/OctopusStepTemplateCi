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
    ConvertTo-HashtableJsonObject

.SYNOPSIS
    Converts a PowerShell object model that uses instances of
    [System.Collections.Generic.Dictionary[string, Object]] to store json objects
    into an object model that uses hashtables instead.

    This is an internal function intended for use from ConvertFrom-OctopusJson, but
    implemented as a separate function to aid code coverage tests.
#>
function ConvertTo-HashtableJsonObject
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
                $result += ConvertTo-HashtableJsonObject $jsonItem;
            }
            return @(, $result);
        }
	    
        { $InputObject -is [System.Collections.Generic.Dictionary[string, Object]] } {
            $result = @{};
            foreach( $key in $InputObject.Keys )
            {
                $value = ConvertTo-HashtableJsonObject -InputObject $InputObject[$key];
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