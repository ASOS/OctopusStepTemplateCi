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
function Invoke-OctopusOperation {
    param(
        [Parameter(Mandatory=$true)][ValidateSet("Get", "New", "Update")]$Action,
        [Parameter(Mandatory=$true)][ValidateSet("LibraryVariableSets", "ActionTemplates", "UserDefined")]$ObjectType,
        $ObjectId,
        $Object,
        $ApiUri,
        [switch]$UseCache,
        $OctopusUri = $ENV:OctopusURI,
        $OctopusApiKey = $ENV:OctopusApikey
    )
    
    Test-OctopusConnectivity

    $uri = switch ($ObjectType) {
        "LibraryVariableSets" { "{0}/api/LibraryVariableSets" -f $OctopusUri }
        "ActionTemplates" { "{0}/api/ActionTemplates" -f $OctopusUri }
        "UserDefined" { "{0}/{1}" -f $OctopusUri, $ApiUri }
    }
    if ($ObjectType -ne "UserDefined" -and ($Action -eq "Get" -or $Action -eq "Update")) {
        $uri = "{0}/{1}" -f $uri, $ObjectId
    }
    
    $method = switch ($Action) {
        "Get" { "GET" }
        "New" { "POST" }
        "Update" { "PUT" }
    }

    $cache = Get-Cache
    $cacheKey = "$uri-$method"
    if ($UseCache -and $cache.ContainsKey($cacheKey)) {
        return $cache.Item($cacheKey)
    }
    
    if ($null -ne $Object) {
        $jsonObject = ConvertTo-OctopusJson -InputObject $Object
    } else {
        $jsonObject = $null
    }
    
    #by default, only SSL3 and TLS 1.0 are supported.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType] "Ssl3, Tls, Tls11, Tls12"

    $result = Invoke-WebRequest -Uri $uri -Method $method -Body $jsonObject -Headers @{"X-Octopus-ApiKey" = $OctopusApiKey} -UseBasicParsing |  `
        % Content | ParseJsonString
        
    if ($UseCache) {
        $cache.Add($cacheKey, $result)
    }
    
    $result
}