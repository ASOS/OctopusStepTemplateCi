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
. "$here\New-StepTemplateObject.ps1"
. "$here\Compare-Hashtable.ps1"
. "$here\..\ConvertTo-OctopusJson.ps1"
. "$here\..\..\PowerShellManipulation\Get-VariableFromScriptFile.ps1"
. "$here\..\..\PowerShellManipulation\Get-ScriptBodyFromScriptFile.ps1"

Describe "Compare-StepTemplate" {
    Mock Get-VariableFromScriptFile { "test name" } -ParameterFilter { $Path -eq "TestDrive:\file.ps1" -and $VariableName -eq "StepTemplateName" }
    Mock Get-VariableFromScriptFile { "test description" } -ParameterFilter { $Path -eq "TestDrive:\file.ps1" -and $VariableName -eq "StepTemplateDescription" }
    Mock Get-ScriptBodyFromScriptFile { "test script" } -ParameterFilter { $Path -eq "TestDrive:\file.ps1" }
    Mock Get-VariableFromScriptFile { @{Name = "test" } } -ParameterFilter { $Path -eq "TestDrive:\file.ps1" -and $VariableName -eq "StepTemplateParameters" }
        
    BeforeEach {        
        $oldTemplate = New-StepTemplateObject -Path "TestDrive:\file.ps1"
        $newTemplate = New-StepTemplateObject -Path "TestDrive:\file.ps1"
    }
    
    It "Should return false if they are the same" {
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $false
    }
    
    It "Should compare the descriptions" {
        $newTemplate.Description = "new description"
        
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $true
    }
    
    It "Should compare the Octopus.Action.Script.Syntax property" {
        $newTemplate.Properties['Octopus.Action.Script.Syntax'] = "batch file"
        
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $true
    }
    
    It "Should compare the Octopus.Action.Script.ScriptBody property" {
        $newTemplate.Properties['Octopus.Action.Script.ScriptBody'] = "new script"
        
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $true
    }
    
    It "Should compare the names of the parameters" {
        $newTemplate.Parameters[0].Name = "new"
        
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $true
    }
    
    It "Should compare the number of parameters" {
        $newTemplate.Parameters = @(@{Name = "Example Parameter"}, @{Name = "New parameter"})
        
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $true
    }
    
    It "Should compare the values of the parameters" {
        $newTemplate.Parameters[0].Label = "new"
        
        Compare-StepTemplate -OldTemplate $oldTemplate -NewTemplate $newTemplate | Should Be $true
    }
}
