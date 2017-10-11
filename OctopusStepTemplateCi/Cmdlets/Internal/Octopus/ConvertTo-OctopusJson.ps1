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
    ConvertTo-OctopusJson

.SYNOPSIS
    Converts an object to JSON notation
#>
function ConvertTo-OctopusJson
{

    param
    (

        [Parameter(Mandatory=$false)]
        [object] $InputObject,

        [Parameter(Mandatory=$false)]
        [string] $Indent = [string]::Empty

    )

    $ErrorActionPreference = "Stop";
    Set-StrictMode -Version "Latest";

    switch( $true )
    {

        { $InputObject -eq $null } {
            return "null";
        }

        { $InputObject -is [bool] } {
            if( $InputObject )
            {
                return "true";
            }
            else
            {
                return "false";
            }
        }

        { $InputObject -is [string] } {
            $value = $InputObject;
            $value = $value.Replace("\",  "\\");
            $value = $value.Replace("`"", "\`"");
            $value = $value.Replace("`r", "\r");
            $value = $value.Replace("`n", "\n");
            $value = $value.Replace("`t", "\t");
            return "`"$value`"";
        }

        { $InputObject -is [int32] } {
            return $InputObject.ToString();
        }

        { $InputObject -is [Array] } {
            $json = new-object System.Text.StringBuilder;
            $items = $InputObject;
            if( $items.Length -eq 0 )
            {
                [void] $json.Append("[]");
            }
            else
            {
                [void] $json.AppendLine("[");
                for( $i = 0; $i -lt $items.Length; $i++ )
                {
                    $itemJson = ConvertTo-OctopusJson -InputObject $items[$i] -Indent ($Indent + "  ");
                    [void] $json.Append("$Indent  $itemJson");
                    if( $i -lt ($items.Length - 1) )
                    {
                        [void] $json.Append(",");
                    }
                    [void] $json.AppendLine();
                }
                [void] $json.Append("$Indent]");
            }
            return $json.ToString();
        }

        { $InputObject -is [Hashtable] } {
            $json = new-object System.Text.StringBuilder;
            $properties = @( $InputObject.GetEnumerator() );
            if( $properties.Length -eq 0 )
            {
                [void] $json.Append("{}");
            }
            else
            {
                [void] $json.AppendLine("{");
                for( $i = 0; $i -lt $properties.Length; $i++ )
                {
                    $property = $properties[$i];
                    $propertyJson = ConvertTo-OctopusJson -InputObject $property.Value -Indent ($Indent + "  ");
                    [void] $json.Append("$Indent  `"$($property.Name)`": $propertyJson");
                    if( $i -lt ($properties.Length - 1) )
                    {
                        [void] $json.Append(",");
                    }
                    [void] $json.AppendLine();
                }
                [void] $json.Append("$Indent}");
            }
            return $json.ToString();
        }

        { $InputObject -is [PSCustomObject] } {
            $json = new-object System.Text.StringBuilder;
            $properties = @( $InputObject.psobject.Properties );
            if( $properties.Length -eq 0 )
            {
                [void] $json.Append("{}");
            }
            else
            {
                [void] $json.AppendLine("{");
                for( $i = 0; $i -lt $properties.Length; $i++ )
                {
                    $property = $properties[$i];
                    $propertyJson = ConvertTo-OctopusJson -InputObject $property.Value -Indent ($Indent + "  ");
                    [void] $json.Append("$Indent  `"$($property.Name)`": $propertyJson");
                    if( $i -lt ($properties.Length - 1) )
                    {
                        [void] $json.Append(",");
                    }
                    [void] $json.AppendLine();
                }
                [void] $json.Append("$Indent}");
            }
            return $json.ToString();
        }

        default {
            $typename = $InputObject.GetType().FullName;
            throw new-object System.InvalidOperationException("Unhandled input object type '$typename'.");
        }

    }

}