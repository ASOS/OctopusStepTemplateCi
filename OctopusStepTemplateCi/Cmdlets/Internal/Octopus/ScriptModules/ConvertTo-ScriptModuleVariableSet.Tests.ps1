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
    ConvertTo-ScriptModuleVariableSet.Tests

.SYNOPSIS
    Pester tests for ConvertTo-ScriptModuleVariableSet.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Read-ScriptModuleVariableSet" {

        Context "When reading a valid script file" {

            $variableSetScript = @'
function test {
    $ScriptModuleName = "name";
    $ScriptModuleDescription = "description";
    write-host "test";
}
'@;

            It "Should return a new object with the content type of script module" {
                $result = ConvertTo-ScriptModuleVariableSet -Script $variableSetScript;
                $result.ContentType | Should Be "ScriptModule";
                Assert-VerifiableMock;
            }

            It "Should return a new object with the name from the script file" {
                $result = ConvertTo-ScriptModuleVariableSet -Script $variableSetScript;
                $result.Name | Should Be "name";
                Assert-VerifiableMock;
            }

            It "Should return a new object with the description from the script file" {
                $result = ConvertTo-ScriptModuleVariableSet -Script $variableSetScript;
                $result.Description | Should Be "description";
                Assert-VerifiableMock;
            }

        }

        Context "when script module name is not a string" {

            $variableSetScript = @'
function test {
    $ScriptModuleName = 100;
    $ScriptModuleDescription = "description";
    write-host "test";
}
'@;

            It "Should throw when script module name is not a string" {
                {
                    $result = ConvertTo-ScriptModuleVariableSet -Script $variableSetScript;
                } | Should Throw "The '`$ScriptModuleName' variable does not evaluate to a string.";
             }

        }

        Context "when script module description is not a string" {

            $variableSetScript = @'
function test {
    $ScriptModuleName = "name";
    $ScriptModuleDescription = 100;
    write-host "test";
}
'@;

            It "Should throw when script module description is not a string" {
                {
                    $result = ConvertTo-ScriptModuleVariableSet -Script $variableSetScript;
                } | Should Throw "The '`$ScriptModuleDescription' variable does not evaluate to a string.";
             }

        }

    }

}