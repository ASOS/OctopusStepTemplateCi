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
    Sync-StepTemplate.Tests
    
.SYNOPSIS
    Pester tests for Sync-StepTemplate
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\New-StepTemplate.ps1"
. "$here\..\Internal\Octopus\Invoke-OctopusOperation.ps1"
. "$here\..\Internal\Octopus\StepTemplates\Convert-PSObjectToHashTable.ps1"
. "$here\..\Internal\Octopus\StepTemplates\Compare-StepTemplate.ps1"
. "$here\..\Internal\Octopus\StepTemplates\Read-StepTemplate.ps1"
. "$here\..\Internal\TeamCity\Write-TeamCityMessage.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableFromScriptFile.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableFromScriptText.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableStatementFromScriptFile.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableStatementFromScriptText.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-ScriptBodyFromScriptFile.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-ScriptBodyFromScriptText.ps1"
. "$here\..\Internal\Octopus\StepTemplates\Convert-HashTableToPSCustomObject.ps1"
. "$here\..\Internal\Octopus\StepTemplates\Compare-Hashtable.ps1"

Describe "Sync-StepTemplate" {

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

    Mock -CommandName "Invoke-OctopusOperation" `
         -MockWith {
             throw ("should not be called with parameters @{ Action = '$Action', ObjectType = '$ObjectType'}!");
         };

    Mock Write-TeamCityMessage {} 
    
    Context "Testing for uploads" {
        It "Should upload the step template if it does not exist" {
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "New" -and $ObjectType -eq "ActionTemplates" } -Verifiable
            
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should be 1;
            Assert-VerifiableMocks
        }
        
        It "Should upload an updated step template if it has changed" {
            Mock Invoke-OctopusOperation { @{Name = "test"; Properties = @{}; Parameters = @(); Version = "1"; Id = "1" }} -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "ActionTemplates" } -Verifiable
            Mock Compare-StepTemplate { $true } -Verifiable
            
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should be 1;
            Assert-VerifiableMocks
        }
        
        It "Should update the step template parameters" {
            Mock Invoke-OctopusOperation { @{Name = "test"; Properties = @{}; Parameters = @("1"); Version = "1"; Id = "1" }} -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Compare-StepTemplate { $false } 
            Mock Convert-PSObjectToHashTable { @{ DisplaySettings = @{} } } -Verifiable
            
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should be 1;
            Assert-VerifiableMocks
        }
        
        It "Should return `$true for the create operation" {
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "New" -and $ObjectType -eq "ActionTemplates" }
            
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 1;
        }
        
        It "Should return an upload count for each create/upload operation" {
            Mock Invoke-OctopusOperation { @{Name = "test"; Properties = @{}; Parameters = @(); Version = "1"; Id = "1" }} -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "ActionTemplates" }
            Mock Compare-StepTemplate { $true }
            
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 1;
        }
    }
    Context "Testing for NOT uploading" {
        It "Should not upload a step template which is identical" {
            Mock Invoke-OctopusOperation {
                $oldTemplate = Read-StepTemplate -Path "my.steptemplate.ps1";
                $oldTemplate.Parameters = Convert-HashTableToPsCustomObject $oldTemplate.Parameters
                $oldTemplate.Properties = Convert-HashTableToPsCustomObject $oldTemplate.Properties
                $oldTemplate.Parameters.DisplaySettings = New-Object PSCustomObject
                $oldTemplate | Add-Member -MemberType 'NoteProperty' -Name 'Id' -Value 'Test-Id'
                return $oldTemplate
            } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "New" -and $ObjectType -eq "ActionTemplates" }
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "ActionTemplates" }
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 0;
        }
        It "Should not upload a step template which differs only in the parameter ID" {
            Mock Invoke-OctopusOperation {
                $oldTemplate = Read-StepTemplate -Path "my.steptemplate.ps1";
                $oldTemplate.Parameters = Convert-HashTableToPsCustomObject $oldTemplate.Parameters
                $oldTemplate.Properties = Convert-HashTableToPsCustomObject $oldTemplate.Properties
                $oldTemplate.Parameters.DisplaySettings = New-Object PSCustomObject
                $oldTemplate | Add-Member -MemberType 'NoteProperty' -Name 'Id' -Value 'Test-Id'
                $oldTemplate.Parameters | Add-Member -MemberType 'NoteProperty' -Name 'Id' -Value '1234'
                return $oldTemplate
            } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "ActionTemplates" -and $ObjectId -eq "All" } 
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "New" -and $ObjectType -eq "ActionTemplates" }
            Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "ActionTemplates" }
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 0;
        }           
    }
}