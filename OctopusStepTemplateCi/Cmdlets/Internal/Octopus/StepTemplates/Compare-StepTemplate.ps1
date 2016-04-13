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
	Compare-StepTemplate

.SYNOPSIS
    Compares two step templates, returning true if they are different, false if they are the same (so it can be used in an if statement)
#>
function Compare-StepTemplate {
    param (
        $OldTemplate,
        $NewTemplate
    )
    #id - wont change
    #name - wont change
    #actiontype - wont change
    #version - will be incremented, shouldn't be checked

    #description
    if ($OldTemplate.Description -ne $NewTemplate.Description) { 
        return $true 
    }
    #Properties['Octopus.Action.Script.Syntax']
    if ($OldTemplate.Properties['Octopus.Action.Script.Syntax'] -ne $NewTemplate.Properties['Octopus.Action.Script.Syntax']) { 
        return $true
    }
    #Properties['Octopus.Action.Script.ScriptBody']
    if ($OldTemplate.Properties['Octopus.Action.Script.ScriptBody'] -ne $NewTemplate.Properties['Octopus.Action.Script.ScriptBody']) { 
        return $true 
    }
    
    #Parameters - check we have the same number of them, with the same names
    if ((($OldTemplate.Parameters | % Name) -join ',') -ne (($NewTemplate.Parameters | % Name) -join ',')) {
        return $true
    }
    
    #loop through the params, and compare each hastable (recursively)
    if ($NewTemplate.Parameters | ? {
        $oldParameter = $OldTemplate.Parameters | ? Name -eq $_.Name
        Compare-HashTable -ReferenceObject $oldParameter -DifferenceObject $_
    }) {
        return $true
    }

    return $false
}