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
    Get-ScriptBodyFromScriptFile

.SYNOPSIS
    Returns the powershell script with the metadata variables removed
#>
function Get-ScriptBodyFromScriptFile {
    param (
       $Path
    )
    
    $fileName = Split-Path $Path -Leaf
    $metadataToRemove = {@()}.Invoke()
    
    if ($fileName.EndsWith(".scriptmodule.ps1")) {
       $metadataToRemove.Add((Get-VariableStatementFromScriptFile -Path $Path -VariableName ScriptModuleName))
       $metadataToRemove.Add((Get-VariableStatementFromScriptFile -Path $Path -VariableName ScriptModuleDescription))
    } elseif ($fileName.EndsWith(".steptemplate.ps1")) {
        $metadataToRemove.Add((Get-VariableStatementFromScriptFile -Path $Path -VariableName StepTemplateName))
        $metadataToRemove.Add((Get-VariableStatementFromScriptFile -Path $Path -VariableName StepTemplateDescription))
        $metadataToRemove.Add((Get-VariableStatementFromScriptFile -Path $Path -VariableName StepTemplateParameters))
    }
    
    $content = Get-Content -Path $Path -Raw 
    $metadataToRemove | ? { $null -ne $_ } | % {
        $content = $content.Replace($_, "")
    }
    
    $content = $content.Trim()
    
    return $content
}