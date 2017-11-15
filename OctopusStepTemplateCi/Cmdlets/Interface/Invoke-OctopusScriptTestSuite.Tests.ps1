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
    Invoke-OctopusScriptTestSuite.Tests
    
.SYNOPSIS
    Pester tests for Invoke-OctopusScriptTestSuite

#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

Describe "Invoke-OctopusScriptTestSuite" {

    New-Item "TestDrive:\test.steptemplate.ps1" -ItemType File | Out-Null;
    New-Item "TestDrive:\test.steptemplate.Tests.ps1" -ItemType File | Out-Null;
    New-Item "TestDrive:\test.scriptmodule.ps1" -ItemType File | Out-Null;
    New-Item "TestDrive:\test.scriptmodule.Tests.ps1" -ItemType File | Out-Null;
    New-Item "TestDrive:\Generic" -ItemType Directory | Out-Null;
    New-Item "TestDrive:\StepTemplates" -ItemType Directory | Out-Null;
    New-Item "TestDrive:\ScriptModules" -ItemType Directory | Out-Null;

    Mock -CommandName "Invoke-PesterForTeamCity" `
         -ModuleName  "OctopusStepTemplateCi" `
         -MockWith {};

    Mock -CommandName "Get-ScriptValidationTestsPath" `
         -ModuleName  "OctopusStepTemplateCi" `
         -MockWith { return "TestDrive:\"; };
    
    It "Should run the script's own tests" {

        Mock -CommandName "Invoke-PesterForTeamCity" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $Script -like "*\test.steptemplate.Tests.ps1" } `
             -MockWith {} `
             -Verifiable;
	     
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\";

        Assert-VerifiableMock;

    }
    
    It "Should run the generic tests" {

        Mock -CommandName "Invoke-PesterForTeamCity" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $TestResultsFile -like "*.generic.TestResults.xml" } `
             -MockWith {} `
             -Verifiable;

        Mock -CommandName "Get-ChildItem" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $Path -like "*\Generic\*.ScriptValidationTest.ps1" } `
             -MockWith {
                 return @(
                     @{ "FullName" = "TestDrive:\Generic\1.ScriptValidationTest.ps1" },
                     @{ "FullName" = "TestDrive:\Generic\2.ScriptValidationTest.ps1" });
             } `
	     -Verifiable;
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\";
        
        Assert-VerifiableMock;

    }
    
    It "Should run the step template tests" {

        Mock -CommandName "Invoke-PesterForTeamCity" `
             -ModuleName  "OctopusStepTemplateCi" `
             -MockWith {} `
             -ParameterFilter { $TestResultsFile -like "*.step-template.TestResults.xml" } `
             -Verifiable;

        Mock -CommandName "Get-ChildItem" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $Path -like "*\StepTemplates\*.ScriptValidationTest.ps1" } `
	     -MockWith {
                 return @(
                     @{ "FullName" = "TestDrive:\StepTemplates\1.ScriptValidationTest.ps1" },
                     @{ "FullName" = "TestDrive:\StepTemplates\2.ScriptValidationTest.ps1" });
             } `
            -Verifiable;
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\";
        
        Assert-VerifiableMock;

    }
    
    It "Should run the script module tests" {

        Mock -CommandName "Invoke-PesterForTeamCity" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $TestResultsFile -like "*.script-module.TestResults.xml" } `
             -MockWith {} `
             -Verifiable;

        Mock -CommandName "Get-ChildItem" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $Path -like "*\ScriptModules\*.ScriptValidationTest.ps1" } `
             -MockWith {
                 return @(
                     @{ "FullName" = "TestDrive:\ScriptModules\1.ScriptValidationTest.ps1" },
                     @{ "FullName" = "TestDrive:\ScriptModules\2.ScriptValidationTest.ps1" });
             } `
             -Verifiable;
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\";
        
        Assert-VerifiableMock;

    }
    
    It "Should set success to false if there are any failed tests" {

        Mock -CommandName "Invoke-PesterForTeamCity" `
             -ModuleName  "OctopusStepTemplateCi" `
             -ParameterFilter { $TestResultsFile -like "*.script-module.TestResults.xml" } `
             -MockWith {
                 return New-Object -TypeName PSObject -Property @{
                     "Passed" = 0
                     "Failed" = 1
                 }
             }
        
        $result = Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\";
	$result.Success | Should Be $false;

    }

}