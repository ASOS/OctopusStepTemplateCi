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
    Test-OctopusApiConnectivity

.SYNOPSIS
    Verifies that the required octopus environment variables are available, and performs a test API call to ensure the Octopus web api is responding
#>
function Test-OctopusApiConnectivity
{

    param
    (

        $OctopusUri = $ENV:OctopusURI,

        $OctopusApiKey = $ENV:OctopusApikey,

        [switch] $TestConnection

    )

    if( [string]::IsNullOrWhiteSpace($OctopusUri) )
    {
        throw "The OctopusUri environment variable is not set, please set this variable and execute again."
    }

    if( [string]::IsNullOrWhiteSpace($OctopusApiKey) )
    {
        throw "The OctopusApiKey environment variables is not set, please set this variable and execute again."
    }

    if( $TestConnection )
    {

        $apiTestCall = Invoke-OctopusApiOperation -Action Get -ObjectType UserDefined -ApiUri "api" | ? Application -eq "Octopus Deploy"

        if( $null -eq $apiTestCall )
        {
            throw "Octopus Deploy Api is not responding correctly"
        }

    }

}