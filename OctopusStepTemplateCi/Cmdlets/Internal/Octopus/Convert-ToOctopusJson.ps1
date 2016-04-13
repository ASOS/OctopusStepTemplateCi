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
	Convert-ToOctopusJson

.SYNOPSIS
    Converts an object to JSON with some adjustments to improve formatting
#>
function Convert-ToOctopusJson {
    param (
        $InputObject,
        $MaximumOctopusApiJsonDepth = 3
    )
    
    ConvertTo-Json -InputObject $InputObject -Depth $MaximumOctopusApiJsonDepth | `
            % Replace "\u0027" "'" | ` # Fix escaped single quotes
            % { $_ -replace '\{\s*\}', '{}' } # Fix odd empty hashtable formatting (or easier comparison in beyond compare)
}