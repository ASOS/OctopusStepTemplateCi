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
    Invoke-OctopusApiOperation

.SYNOPSIS
    Invokes a web request against Octopus's API and returns the JSON result converted into an object
#>
function Invoke-OctopusApiOperation
{

    param
    (

        [Parameter(Mandatory=$false)]
        [string] $OctopusUri = $env:OctopusURI,

        [Parameter(Mandatory=$false)]
        [string] $OctopusApiKey = $env:OctopusApikey,

        [Parameter(Mandatory=$true)]
        [ValidateSet("GET", "POST", "PUT")]
        [string] $Method,

        [Parameter(Mandatory=$false)]
        [string] $Uri,

        [Parameter(Mandatory=$false)]
        [object] $Body,

        [Parameter(Mandatory=$false)]
        [switch] $UseCache

    )

    Test-OctopusApiConnectivity;

    $Uri      = $OctopusUri + $Uri;
    $cacheKey = "$Uri-$Method";

    $cache = Get-OctopusApiCache;
    if( $UseCache -and $cache.ContainsKey($cacheKey) )
    {
        return $cache.Item($cacheKey);
    }

    # by default, only SSL3 and TLS 1.0 are supported.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType] "Ssl3, Tls, Tls11, Tls12";

    if( $null -eq $Body )
    {
        $response = Invoke-WebRequest -Uri $Uri -Method $Method -Headers @{ "X-Octopus-ApiKey" = $OctopusApiKey } -UseBasicParsing;
    }
    else
    {
        $requestBody = ConvertTo-OctopusJson -InputObject $Body;
        $response = Invoke-WebRequest -Uri $Uri -Method $Method -Body $requestBody -Headers @{ "X-Octopus-ApiKey" = $OctopusApiKey } -UseBasicParsing;
    }

    $result = ConvertFrom-OctopusJson -InputObject $response.Content;

    if( $UseCache )
    {
        $cache.Add($cacheKey, $result);
    }

    return $result;

}