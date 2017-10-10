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
    
    Context "when the step template does not exist" {

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith { return @(, @()); } `
             -Verifiable;

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "New") -and ($ObjectType -eq "ActionTemplates") } `
             -MockWith {} `
             -Verifiable;
            
        It "Should upload the step template if it does not exist" {
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should be 1;
            Assert-VerifiableMocks;
        }

    }

    Context "when the step template description has changed" {

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith {
                 return @(, @(
                     new-object PSCustomObject -Property ([ordered] @{
                         "Id"          = "ActionTemplates-1"
                         "Version"     = 1
                         "Name"        = "name"
                         "Description" = "new description"
                         "Properties"  = new-object PSCustomObject
                         "Parameters"  = @()
                     })
                 ));
             } `
             -Verifiable;;

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Update") -and ($ObjectType -eq "ActionTemplates") } `
             -MockWith {} `
             -Verifiable;

        It "Should upload an updated step template if it has changed" {
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should be 1;
            Assert-VerifiableMocks;
        }

    }
        
    Context "when the step template parameters have changed" {

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith {
                 return @(, @(
                     new-object PSCustomObject -Property ([ordered] @{
                         "Id"          = "ActionTemplates-1"
                         "Version"     = 1
                         "Name"        = "name"
                         "Description" = "description"
                         "Properties"  = new-object PSCustomObject -Property ([ordered] @{
                             "Octopus.Action.Script.ScriptBody" = "function test {
    
    
    
}"
                             "Octopus.Action.Script.Syntax" = "PowerShell"
                         })
                         "Parameters"  = @()
                     })
                 ));
             } `
             -Verifiable;

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Update") -and ($ObjectType -eq "ActionTemplates") } `
             -MockWith {} `
             -Verifiable;

        It "Should update the step template parameters" {
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should be 1;
            Assert-VerifiableMocks;
        }

    }

    Context "when a step template has not changed" {
fs
        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith {
                 return @(, @(
                     new-object PSCustomObject -Property ([ordered] @{
                         "Id"          = "ActionTemplates-1"
                         "Version"     = 1
                         "Name"        = "name"
                         "Description" = "description"
                         "Properties"  = new-object PSCustomObject -Property ([ordered] @{
                             "Octopus.Action.Script.ScriptBody" = "function test {
    
    
    
}"
                             "Octopus.Action.Script.Syntax" = "PowerShell"
                         })
                         "Parameters"  = @(
                              new-object PSCustomObject -Property ([ordered] @{
                                 "Name" = "myParameterName"
                                 "Label" = "myParameterLabel"
                                 "HelpText" = "myParameterHelpText"
                                 "DefaultValue" = "myDefaultValue"
                                 "DisplaySettings" = new-object PSCustomObject
                             })
                         )
                     })
                 ));
             } `
             -Verifiable;

        It "Should not upload a step template which is identical" {
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 0;
            Assert-VerifiableMocks;
        }

    }

    Context "when a template differs only by parameter ids" {

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