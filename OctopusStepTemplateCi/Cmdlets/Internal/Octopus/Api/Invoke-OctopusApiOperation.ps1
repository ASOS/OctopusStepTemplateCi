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

    $ErrorActionPreference = "Stop";
    $ProgressPreference = "SilentlyContinue";
    Set-StrictMode -Version "Latest";

    Test-OctopusApiConnectivity;

    $Uri      = $OctopusUri + $Uri;
    $cacheKey = "$Uri-$Method";

    $cache = Get-OctopusApiCache;
    if( $UseCache -and $cache.ContainsKey($cacheKey) )
    {
        return $cache.Item($cacheKey);
    }

    # by default, only SSL3 and TLS 1.0 are supported.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType] "Tls, Tls11, Tls12, Tls13";

    #write-host "Invoke-OctopusApiOperation";
    #write-host "    uri    = '$Uri'";
    #write-host "    method = '$Method'";

    $splat = @{
        "Uri"             = $Uri
        "Method"          = $Method
        "Headers"         = @{ "X-Octopus-ApiKey" = $OctopusApiKey }
        "UseBasicParsing" = $true
    };

    if( $null -ne $Body )
    {
        $requestBody = ConvertTo-OctopusJson -InputObject $Body;
        #write-host "    body = ";
        #write-host "-----------";
        #write-host $requestBody;
        #write-host "-----------";
        $splat.Add("Body", $requestBody);
    }

    try
    {
        $response = Invoke-WebRequest @splat;
    }
    catch [System.Net.WebException]
    {

        $ex = $_.psbase.Exception;
        $response = $ex.Response;
        $responseStream = $response.GetResponseStream();
        $responseReader = new-object System.IO.StreamReader($responseStream);
        $responseText = $responseReader.ReadToEnd();
        $responseReader.Dispose();
        $responseStream.Dispose();
        $response.Dispose();

        $message = $ex.Message + "`r`n" +
                   "The response body was:`r`n" +
                   "------------`r`n" +
                   $responseText + "`r`n" +
                   "------------`r`n";

        throw new-object System.Net.WebException($message, $ex, $ex.Status, $ex.Response);

    }

    $result = ConvertFrom-OctopusJson -InputObject $response.Content;

    if( $UseCache )
    {
        $cache.Add($cacheKey, $result);
    }

    return $result;

}