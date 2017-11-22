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
    Get-OctopusApiActionTemplate

.SYNOPSIS
    Invokes a web request against Octopus's API and returns the requested ActionTemplate
#>
function Get-OctopusApiActionTemplate
{

    param
    (

        [Parameter(Mandatory=$false)]
        [string] $OctopusServerUri = $env:OctopusUri,

        [Parameter(Mandatory=$false)]
        [string] $OctopusApiKey = $env:OctopusApiKey,

        [Parameter(Mandatory=$true)]
        [string] $ObjectId,

        [Parameter(Mandatory=$false)]
        [switch] $UseCache

    )

    $results = Invoke-OctopusApiOperation -OctopusUri    $OctopusServerUri `
                                          -OctopusApiKey $OctopusApiKey `
					  -Action        "Get" `
                                          -ObjectType    "ActionTemplates" `
                                          -ObjectId      $ObjectId `
                                          -UseCache:$UseCache;

    return @(, $results);

}