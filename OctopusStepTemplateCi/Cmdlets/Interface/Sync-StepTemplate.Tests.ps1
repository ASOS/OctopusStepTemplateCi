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

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

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

    Mock Write-TeamCityBuildLogMessage {};
    
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
            Assert-VerifiableMock;
        }

    }

    Context "when the step template description has changed" {

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith {
                 return @(, @(
                     @{
                         "Id"          = "ActionTemplates-1"
                         "Name"        = "name"
                         "Description" = "new description"
                         "ActionType"  = "Octopus.Script"
                         "Version"     = 1
                         "Properties"  = @{}
                         "Parameters"  = @()
                     }
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
            Assert-VerifiableMock;
        }

    }
        
    Context "when the step template parameters have changed" {

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith {
                 return @(, @(
                     @{
                         "Id"          = "ActionTemplates-1"
                         "Name"        = "name"
                         "Description" = "description"
                         "ActionType"  = "Octopus.Script"
                         "Version"     = 1
                         "Properties"  = @{
                             "Octopus.Action.Script.ScriptBody" = "function test {
    
    
    
}"
                             "Octopus.Action.Script.Syntax" = "PowerShell"
                         }
                         "Parameters"  = @()
                     }
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
            Assert-VerifiableMock;
        }

    }

    Context "when a step template has not changed" {

        Mock -CommandName "Invoke-OctopusOperation" `
             -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
             -MockWith {
                 return @(, @(
                     @{
                         "Id"          = "ActionTemplates-1"
                         "Name"        = "name"
                         "Description" = "description"
                         "ActionType"  = "Octopus.Script"
                         "Version"     = 1
                         "Properties"  = @{
                             "Octopus.Action.Script.ScriptBody" = "function test {
    
    
    
}"
                             "Octopus.Action.Script.Syntax" = "PowerShell"
                         }
                         "Parameters"  = @(
                             @{
                                 "Name" = "myParameterName"
                                 "Label" = "myParameterLabel"
                                 "HelpText" = "myParameterHelpText"
                                 "DefaultValue" = "myDefaultValue"
                                 "DisplaySettings" = @{}
                             }
                         )
                        "`$Meta"      = @{
			    "Type" = "ActionTemplate"
                        }
                     }
                 ));
             } `
             -Verifiable;

        It "Should not upload a step template which is identical" {
            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 0;
            Assert-VerifiableMock;
        }

    }

    Context "when a template differs only by parameter ids" {

        It "Should not upload a step template which differs only in the parameter ID" {

            Mock -CommandName "Invoke-OctopusOperation" `
	         -ParameterFilter { ($Action -eq "Get") -and ($ObjectType -eq "ActionTemplates") -and ($ObjectId -eq "All") } `
		 -MockWith {
                     $oldTemplate = Read-StepTemplate -Path "my.steptemplate.ps1";
                     $oldTemplate.Add("Id", "Test-Id");
                     $oldTemplate.Parameters[0].Add("Id", "1234");
                     return $oldTemplate;
                 };

            Mock -CommandName "Invoke-OctopusOperation" `
                 -ParameterFilter { ($Action -eq "New") -and ($ObjectType -eq "ActionTemplates") } `
                 -MockWith {};

            Mock -CommandName "Invoke-OctopusOperation" `
                 -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "ActionTemplates" } `
                 -MockWith {};

            $result = Sync-StepTemplate -Path "my.steptemplate.ps1";
            $result.UploadCount | Should Be 0;

        }

    }

}

}