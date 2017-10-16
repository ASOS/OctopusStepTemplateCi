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
    Get-TeamCityEscapedString

.SYNOPSIS
    Formats a string using escape sequences as defined for TeamCity service messages.
    See https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity for more details.
#>
function Get-TeamCityEscapedString
{

    param
    (

        [Parameter(Mandatory=$false)]
        [string] $Value

    )

    if( $null -ne $Value )
    {

        $Value = $Value.Replace("|", "||");
        $Value = $Value.Replace("`n", "|n");
        $Value = $Value.Replace("`r", "|r");
        $Value = $Value.Replace("'", "|'");
        $Value = $Value.Replace("[", "|[");
        $Value = $Value.Replace("]", "|]");

    }

    return $Value;

}