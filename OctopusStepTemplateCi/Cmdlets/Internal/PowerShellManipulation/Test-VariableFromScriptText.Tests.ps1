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
    Test-VariableFromScriptText.Tests

.SYNOPSIS
    Pester tests for Test-VariableFromScriptText
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


InModuleScope "OctopusStepTemplateCi" {

    Describe "Test-VariableFromScriptText" {

        It "Should return `$false when the variable is not assigned" {
            $script = @'
function test {
    Write-Host $myTestVariable;
}
'@
            $actual = Test-VariableFromScriptText -Script $script -VariableName "myTestVariable";
            $actual | Should Be $false;
        }

        It "Should return `$true when the variable is assigned" {
            $script = @'
function test {
    $myTestVariable = $null;
    Write-Host $myTestVariable;
}
'@
            $actual = Test-VariableFromScriptText -Script $script -Variable "myTestVariable";
            $actual | Should Be $true;
        }

    }

}