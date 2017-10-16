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
    Get-TeamCityServiceMessage

.SYNOPSIS
    Formats a string that can be used as a TeamCity service message
    See https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity for more details.
#>
function Get-TeamCityServiceMessage
{

    [CmdletBinding(DefaultParametersetName="SingleAttributeMessage")] 
    param
    (

        [Parameter(Mandatory=$true)]
        [string] $MessageName,

        [Parameter(Mandatory=$false, ParameterSetName="SingleAttributeMessage")]
        [string] $Value,

        [Parameter(Mandatory=$false, ParameterSetName="MultipleAttributeMessage")]
        [hashtable] $Values

    )

    $message = new-object System.Text.StringBuilder;

    [void] $message.Append("##teamcity[");

    [void] $message.Append($MessageName);

    switch( $PsCmdlet.ParameterSetName )
    {

        "SingleAttributeMessage" {
            if( $null -ne $Value )
            {
                    [void] $message.Append(" ");
                    [void] $message.Append("'");
                    [void] $message.Append((Get-TeamCityEscapedString -Value $Value));
                    [void] $message.Append("'");
            }
	}

        "MultipleAttributeMessage" {
            if( $null -ne $Values )
            {
                $keys = @($Values.Keys | sort-object);
                foreach( $key in $keys )
                {
                    [void] $message.Append(" ");
                    [void] $message.Append($key);
                    [void] $message.Append("='");
                    [void] $message.Append((Get-TeamCityEscapedString -Value $Values[$key]));
                    [void] $message.Append("'");
                }
            }
	}

    }

    [void] $message.Append("]");

    return $message.ToString();

}