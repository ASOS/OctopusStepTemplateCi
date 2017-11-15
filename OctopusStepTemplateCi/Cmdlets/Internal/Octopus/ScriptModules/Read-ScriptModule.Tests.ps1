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
    Read-ScriptModule.Tests

.SYNOPSIS
    Pester tests for Read-ScriptModule.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Read-ScriptModule" {

        Mock -CommandName "Get-Content" `
             -MockWith {
                 return @'
function test {
    $ScriptModuleName = "name";
    $ScriptModuleDescription = "description";
    write-host "test";
}
'@;
             };

        It "Should return a new object with the name from the script file" {
            $result = Read-ScriptModule -Path "my.scriptmodule.ps1";
            $result.Name | Should Be "Octopus.Script.Module[name]";
            Assert-VerifiableMock;
        }
    
        It "Should return a new object with the value as the body of the script file" {
            $result = Read-ScriptModule -Path "my.scriptmodule.ps1";
            $result.Value | Should Be @'
function test {
    ;
    ;
    write-host "test";
}
'@;
            Assert-VerifiableMock;
        }

    }

}