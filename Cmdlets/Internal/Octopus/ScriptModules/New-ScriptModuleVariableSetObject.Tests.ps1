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
	New-ScriptModuleVariableSetObject.Tests

.SYNOPSIS
	Pester tests for New-ScriptModuleVariableSetObject.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\..\..\PowerShellManipulation\Get-VariableFromScriptFile.ps1"

Describe "New-ScriptModuleVariableSetObject" {
    It "Should return a new object with the content type of script module" {
        Mock Get-VariableFromScriptFile { }
        
        New-ScriptModuleVariableSetObject -Path "TestDrive:\file.ps1" | % ContentType | Should Be "ScriptModule"
        
        Assert-VerifiableMocks
    }
    
    It "Should return a new object with the name from the script file" {
        Mock Get-VariableFromScriptFile { "test name" } -ParameterFilter { $Path -eq "TestDrive:\file.ps1" -and $VariableName -eq "ScriptModuleName" } -Verifiable
        
        New-ScriptModuleVariableSetObject -Path "TestDrive:\file.ps1" | % Name | Should Be "test name"
        
        Assert-VerifiableMocks
    }
    
    It "Should return a new object with the description from the script file" {
        Mock Get-VariableFromScriptFile { "test description" } -ParameterFilter { $Path -eq "TestDrive:\file.ps1" -and $VariableName -eq "ScriptModuleDescription" } -Verifiable
        
        New-ScriptModuleVariableSetObject -Path "TestDrive:\file.ps1" | % Description | Should Be "test description"
        
        Assert-VerifiableMocks
    }
}
