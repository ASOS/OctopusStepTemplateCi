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
    Read-ScriptModuleVariableSet.Tests

.SYNOPSIS
    Pester tests for Read-ScriptModuleVariableSet.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Read-ScriptModuleVariableSet" {

        Context "When reading a valid script file" {

            Mock -CommandName "Get-Content" `
                 -MockWith {
                     return @'
function test {
    $ScriptModuleName = "name";
    $ScriptModuleDescription = "description";
    write-host "test";
}
'@
                 };

            It "Should return a new object with the content type of script module" {
                $result = Read-ScriptModuleVariableSet -Path "my.variableset.ps1";
                $result.ContentType | Should Be "ScriptModule";
                Assert-VerifiableMock;
            }

            It "Should return a new object with the name from the script file" {
                $result = Read-ScriptModuleVariableSet -Path "my.variableset.ps1";
                $result.Name | Should Be "name";
                Assert-VerifiableMock;
            }

            It "Should return a new object with the description from the script file" {
                $result = Read-ScriptModuleVariableSet -Path "my.variableset.ps1";
                $result.Description | Should Be "description";
                Assert-VerifiableMock;
            }

        }

        Context "when script module name is not a string" {

            Mock -CommandName "Get-Content" `
                 -MockWith {
                     return @'
function test {
    $ScriptModuleName = 100;
    $ScriptModuleDescription = "description";
    write-host "test";
}
'@
            }

            It "Should throw when script module name is not a string" {
                {
                    $result = Read-ScriptModuleVariableSet -Path "my.scriptmodule.ps1";
                } | Should Throw "The '`$ScriptModuleName' variable does not evaluate to a string.";
             }

        }

        Context "when script module description is not a string" {

            Mock -CommandName "Get-Content" `
                 -MockWith {
                     return @'
function test {
    $ScriptModuleName = "name";
    $ScriptModuleDescription = 100;
    write-host "test";
}
'@
            }

            It "Should throw when script module description is not a string" {
                {
                    $result = Read-ScriptModuleVariableSet -Path "my.scriptmodule.ps1";
                } | Should Throw "The '`$ScriptModuleDescription' variable does not evaluate to a string.";
             }

        }

    }

}