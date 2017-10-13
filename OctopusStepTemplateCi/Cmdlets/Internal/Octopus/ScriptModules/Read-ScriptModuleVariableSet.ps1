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
    Read-ScriptModuleVariableSet

.SYNOPSIS
    Reads a script module variable set from a powershell script file
#>
function Read-ScriptModuleVariableSet
{

    param
    (

        [Parameter(Mandatory=$true)]
        [string] $Path

    )

    $script = Get-Content -LiteralPath $Path -Raw;

    $scriptModuleName = Get-VariableFromScriptText -Script $script -VariableName "ScriptModuleName";
    if( ($scriptModuleName -ne $null) -and
        ($scriptModuleName -isnot [string]) )
    {
        throw new-object System.InvalidOperationException("The '`$ScriptModuleName' variable in file '$Path' does not evaluate to a string.");
    }

    $scriptModuleDescription = Get-VariableFromScriptText -Script $script -VariableName "ScriptModuleDescription";
    if( ($scriptModuleDescription -ne $null) -and
        ($scriptModuleDescription -isnot [string]) )
    {
        throw new-object System.InvalidOperationException("The '`ScriptModuleDescription' variable in file '$Path' does not evaluate to a string.");
    }

    $variableSet = @{
                       "ContentType" = "ScriptModule"
                       "Name"        = $scriptModuleName
                       "Description" = $scriptModuleDescription
                   };

    return $variableSet;

}