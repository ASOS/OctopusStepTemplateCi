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
    Sync-ScriptModule
    
.SYNOPSIS
    Uploads the script module into Octopus if it has changed

.DESCRIPTION
    This will only upload if the script module has changed
    
.PARAMETER Path
    The path to the script module to upload
    
.PARAMETER UseCache
    If Octopus Retrieval Operations should be cached, this is used when called from Invoke-TeamCityCiUpload where this function is called mulitple times
    When being run interactivley the use of the cache could cause unexpected behaviour

.INPUTS
    None. You cannot pipe objects to  Sync-ScriptModule.

.OUTPUTS
    None.
#>
function Sync-ScriptModule {
    [CmdletBinding()]
	[OutputType("System.Collections.Hashtable")]
    param (
        [Parameter(Mandatory=$true)][ValidateScript({ Test-Path $_ })][System.String]$Path,
        [Parameter(Mandatory=$false)][System.Management.Automation.SwitchParameter]$UseCache
    )

    $moduleName = Get-VariableFromScriptFile -Path $Path -VariableName ScriptModuleName
    $moduleDescription = Get-VariableFromScriptFile -Path $Path -VariableName ScriptModuleDescription
    
    $result = @{UploadCount = 0} 
    
    $scriptModuleVariableSet = Invoke-OctopusOperation -Action Get -ObjectType LibraryVariableSets -ObjectId "All" -UseCache:$UseCache | ? Name -eq $moduleName
    
    if ($null -eq $scriptModuleVariableSet) {
        Write-TeamCityMessage "VariableSet for script module '$moduleName' does not exist. Creating"
        
        $scriptModuleVariableSet = Invoke-OctopusOperation -Action New -ObjectType LibraryVariableSets -Object (New-ScriptModuleVariableSetObject -Path $Path)
        $result.UploadCount++
    }
    elseif ($scriptModuleVariableSet.Description -ne $moduleDescription) {
        Write-TeamCityMessage "VariableSet for script module '$moduleName' has different metadata. Updating."
        
        $scriptModuleVariableSet.Description = $moduleDescription
        Invoke-OctopusOperation -Action Update -ObjectType UserDefined -ApiUri $scriptModuleVariableSet.Links.Self -Object $scriptModuleVariableSet | Out-Null
        $result.UploadCount++
    }

    $scriptModule = Invoke-OctopusOperation -Action Get -ObjectType UserDefined -ApiUri $scriptModuleVariableSet.Links.Variables -UseCache:$UseCache

    if ($scriptModule.Variables.Count -eq 0)
    {
        Write-TeamCityMessage "Script module '$moduleName' does not exist. Creating"

        $scriptModule.Variables += New-ScriptModuleObject -Path $Path
        Invoke-OctopusOperation -Action Update -ObjectType UserDefined -ApiUri $scriptModuleVariableSet.Links.Variables  -Object $scriptModule | Out-Null
        $result.UploadCount++
    } else {
        $moduleScript = Get-ScriptBody -Path $Path
        if  ($scriptModule.Variables[0].Value -ne $moduleScript) {
            Write-TeamCityMessage "Script module '$moduleName' has changed. Updating"

            $scriptModule.Variables[0].Value = $moduleScript
            Invoke-OctopusOperation -Action Update -ObjectType UserDefined -ApiUri $scriptModuleVariableSet.Links.Variables -Object $scriptModule | Out-Null
            $result.UploadCount++
        }  
    }
    
    $result
}