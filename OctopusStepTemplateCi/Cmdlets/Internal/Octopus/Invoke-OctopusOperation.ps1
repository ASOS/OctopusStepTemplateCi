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
    Invoke-OctopusOperation

.SYNOPSIS
    Invoke's a web request against Octopus's API and returns the JSON result converted into an object 
#>
function Invoke-OctopusOperation
{

    param
    (

        [Parameter(Mandatory=$true)]
        [ValidateSet("Get", "New", "Update")]
        [string] $Action,

        [Parameter(Mandatory=$true)]
        [ValidateSet("LibraryVariableSets", "ActionTemplates", "UserDefined")]
        [string] $ObjectType,

        [Parameter(Mandatory=$false)]
        [string] $ObjectId,

        [Parameter(Mandatory=$false)]
        [object] $Object,

        [Parameter(Mandatory=$false)]
        [string] $ApiUri,

        [Parameter(Mandatory=$false)]
        [switch] $UseCache,

        [Parameter(Mandatory=$false)]
        [string] $OctopusUri = $env:OctopusURI,

        [Parameter(Mandatory=$false)]
        [string] $OctopusApiKey = $env:OctopusApikey

    )
    
    Test-OctopusConnectivity;

    switch( $ObjectType )
    {
        "LibraryVariableSets" {
            $uri = "$OctopusUri/api/LibraryVariableSets";
        }
        "ActionTemplates" {
            $uri = "$OctopusUri/api/ActionTemplates";
        }
        "UserDefined" {
            $uri = "$OctopusUri/$ApiUri";
        }
    }

    if( ($ObjectType -in @("LibraryVariableSets", "ActionTemplates")) -and
        ($Action -in @("Get", "Update")) )
    {
        $uri = "$uri/$ObjectId";
    }

    switch( $Action )
    {
        "Get"    { $method = "GET";  }
	"New"    { $method = "POST"; }
	"Update" { $method = "PUT";  }
    }

    $cache = Get-Cache;
    $cacheKey = "$uri-$method";
    if( $UseCache -and $cache.ContainsKey($cacheKey) )
    {
        return $cache.Item($cacheKey);
    }

    # by default, only SSL3 and TLS 1.0 are supported.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType] "Ssl3, Tls, Tls11, Tls12";

    if( $null -eq $Object )
    {
        $response = Invoke-WebRequest -Uri $uri -Method $method -Headers @{ "X-Octopus-ApiKey" = $OctopusApiKey } -UseBasicParsing;
    }
    else
    {
        $requestBody = ConvertTo-OctopusJson -InputObject $Object;
        $response = Invoke-WebRequest -Uri $uri -Method $method -Body $requestBody -Headers @{ "X-Octopus-ApiKey" = $OctopusApiKey } -UseBasicParsing;
    }

    $result = $response | % Content | ParseJsonString;
        
    if( $UseCache )
    {
        $cache.Add($cacheKey, $result);
    }
    
    return $result;

}