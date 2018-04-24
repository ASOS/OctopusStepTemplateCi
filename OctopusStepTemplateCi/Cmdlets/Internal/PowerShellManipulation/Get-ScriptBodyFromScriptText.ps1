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
    Get-ScriptBodyFromScriptText

.SYNOPSIS
    Returns the powershell script with the metadata variables removed
#>
function Get-ScriptBodyFromScriptText
{

    param
    (

        [Parameter(Mandatory=$true)]
        [string] $Script,

        [Parameter(Mandatory=$true)]
        [ValidateSet("ScriptModule", "StepTemplate")]
        [string] $Type

    )

    $ErrorActionPreference = "Stop";
    Set-StrictMode -Version "Latest";

    switch( $Type )
    {

        "ScriptModule" {
            $variablesToRemove = @( "ScriptModuleName", "ScriptModuleDescription" );
        }

        "StepTemplate" {
            $variablesToRemove = @( "StepTemplateName", "StepTemplateDescription", "StepTemplateActionType", "StepTemplateParameters" );
        }

    }

    $newScript = $Script;
    foreach( $variableName in $variablesToRemove )
    {
        $variableScript = Get-VariableStatementFromScriptText -Script $newScript -VariableName $variableName -Type "Statement";
        if( -not [string]::IsNullOrEmpty($variableScript) )
        {
            $newScript = $newScript.Replace($variableScript, "");
        }
    }
    $newScript = $newScript.Trim();

    return $newScript;

}