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
    Read-StepTemplate.Tests

.SYNOPSIS
    Pester tests for Read-StepTemplate.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Read-StepTemplate" {

        Context "When reading a valid script file" {

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
'@
                 };

            It "Should return a new object with the name from the script file" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Name | Should Be "name";
            }

            It "Should return a new object with the description from the script file" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Description | Should Be "description";
            }

            It "Should return a new object with the action type of Octopus.Script" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.ActionType | Should Be "Octopus.Script";
            }

            It "Should return a new object with the property Octopus.Action.Script.ScriptBody from the script file" {
                $expected = @'
function test {
    
    
    
}
'@;
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Properties["Octopus.Action.Script.ScriptBody"] | Should Be $expected;
            }

            It "Should return a new object with the property Octopus.Action.Script.Syntax of PowerShell" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Properties["Octopus.Action.Script.Syntax"] | Should Be "PowerShell";
            }

            It "Should return a new object with the parameters from the script file" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "myParameterLabel";
                $result.Parameters[0].HelpText     | Should Be "myParameterHelpText";
                $result.Parameters[0].DefaultValue | Should Be "myDefaultValue";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
            }

            It "Should return a new object with the SensitiveProperties an empty hashtable" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.SensitiveProperties | Should BeOfType [hashtable];
                $result.SensitiveProperties.Count | Should Be 0;
            }

            It "Should return a new object with the metatype of ActionTemplate" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.'$Meta'.Type | Should Be "ActionTemplate";
            }

            It "Should return a new object with the version of 1" {
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Version | Should Be 1;
            }

        }

        Context "When cleaning up properties" {

            It "Should convert null parameter properties to an empty string" {
                Mock -CommandName "Get-Content" `
                     -MockWith {
                         return @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = @(
        @{
            "Name" = "myParameterName"
            "Label" = $null
            "HelpText" = $null
            "DefaultValue" = $null
            "DisplaySettings" = @{}
        }
    );
'@
                     };
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "";
                $result.Parameters[0].HelpText     | Should Be "";
                $result.Parameters[0].DefaultValue | Should Be "";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
            }

            It "Should trim space-padded parameter properties" {
                Mock -CommandName "Get-Content" `
                     -MockWith {
                         return @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = @(
        @{
            "Name" = "myParameterName"
            "Label" = "    myParameterLabel    "
            "HelpText" = "    myParameterHelpText    "
            "DefaultValue" = "    myDefaultValue    "
            "DisplaySettings" = @{}
        }
    );
'@
                     };
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "myParameterLabel";
                $result.Parameters[0].HelpText     | Should Be "myParameterHelpText";
                $result.Parameters[0].DefaultValue | Should Be "myDefaultValue";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
                Assert-VerifiableMock;
            }

            It "Should convert bool default values to strings" {
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
            "DefaultValue" = $true
            "DisplaySettings" = @{}
        }
    );
'@
                     };
                $result = Read-StepTemplate -Path "my.steptemplate.ps1";
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "myParameterLabel";
                $result.Parameters[0].HelpText     | Should Be "myParameterHelpText";
                $result.Parameters[0].DefaultValue | Should Be "True";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
                Assert-VerifiableMock;
            }

        }

    }

}