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
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\..\Internal\Tests\Invoke-PesterForTeamCity.ps1"
. "$here\..\Internal\Tests\Get-ScriptValidationTestsPath.ps1"

Describe "Invoke-OctopusScriptTestSuite" {
    New-Item "TestDrive:\test.steptemplate.ps1" -ItemType File | Out-Null
    New-Item "TestDrive:\test.steptemplate.Tests.ps1" -ItemType File | Out-Null
    New-Item "TestDrive:\test.scriptmodule.ps1" -ItemType File | Out-Null
    New-Item "TestDrive:\test.scriptmodule.Tests.ps1" -ItemType File | Out-Null
    Mock Invoke-PesterForTeamCity {}
    Mock Get-ScriptValidationTestsPath {"TestDrive:\"}
    
    It "Should run the script's own tests" {
        Mock Invoke-PesterForTeamCity {} -ParameterFilter { $Script -like "*\test.steptemplate.Tests.ps1" } -Verifiable
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\"
        
        Assert-VerifiableMocks
    }
    
    It "Should run the generic tests" {
        Mock Invoke-PesterForTeamCity {} -ParameterFilter { $Script.Path -like "*\Generic\*" } -Verifiable
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\"
        
        Assert-VerifiableMocks
    }
    
    It "Should run the step template tests" {
        Mock Invoke-PesterForTeamCity {} -ParameterFilter { $Script.Path -like "*\StepTemplates\*" } -Verifiable
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\"
        
        Assert-VerifiableMocks
    }
    
    It "Should run the script module tests" {
        Mock Invoke-PesterForTeamCity {} -ParameterFilter { $Script.Path -like "*\ScriptModules\*" } -Verifiable
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\"
        
        Assert-VerifiableMocks
    }
    
    It "Should set success to false if there are any failed tests" {
        Mock Invoke-PesterForTeamCity { New-Object -TypeName PSObject -Property @{ Passed = 0; Failed = 1 } } -ParameterFilter { $Script.Path -like "*\ScriptModules\*" }
        
        Invoke-OctopusScriptTestSuite -Path "TestDrive:\" -ResultFilesPath "TestDrive:\" | % Success | Should Be $false
    }
}