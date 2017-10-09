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
    Compare-StepTemplate.Tests

.SYNOPSIS
    Pester tests for Compare-StepTemplate.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Compare-Hashtable.ps1"
. "$here\Read-StepTemplate.ps1"
. "$here\..\ConvertTo-OctopusJson.ps1"
. "$here\..\..\PowerShellManipulation\Get-ScriptBodyFromScriptText.ps1"
. "$here\..\..\PowerShellManipulation\Get-VariableFromScriptText.ps1"
. "$here\..\..\PowerShellManipulation\Get-VariableStatementFromScriptText.ps1"

Describe "Compare-StepTemplate" {

    Mock -CommandName "Get-Content" `
         -MockWith {
             return @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = @(
        @{
            "Name" = "myParameterName"
            "Label" = "myParameterLabel"
            "HelpText" = "myParameterHelpText"
            "DefaultValue" = "myDefaultValue"
            "DisplaySettings" = @{}
        }
    )
}
'@;
         };

    It "Should return false if they are the same" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $false;
    }

    It "Should return true when the description is different" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $newTemplate.Description = "new description";
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $true;
    }

    It "Should return true when the Octopus.Action.Script.Syntax property is different" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $newTemplate.Properties["Octopus.Action.Script.Syntax"] = "new syntax";
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $true;
    }

    It "Should return true when the Octopus.Action.Script.ScriptBody property is different" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $newTemplate.Properties["Octopus.Action.Script.ScriptBody"] = "new script body";
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $true;
    }
    
    It "Should return true when the number of parameters is different" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $newTemplate.Parameters = @();
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $true;
    }

    It "Should return true when the names of parameters are different" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $newTemplate.Parameters[0].Name = "new parameter";
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $true;
    }

    It "Should return true when the values of parameters are different" {
        $oldTemplate = Read-StepTemplate -Path "old.steptemplate.ps1";
        $newTemplate = Read-StepTemplate -Path "new.steptemplate.ps1";
        $newTemplate.Parameters[0].Label = "new label"
        $result = Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate;
        $result | Should Be $true;
    }

}
