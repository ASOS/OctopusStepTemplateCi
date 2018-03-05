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
    ConvertTo-StepTemplate.Tests

.SYNOPSIS
    Pester tests for ConvertTo-StepTemplate.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "ConvertTo-StepTemplate" {

        Context "When converting a valid script" {

            $stepTemplateScript = @'
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

            It "Should return a new object with the name from the script file" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.Name | Should Be "name";
            }

            It "Should return a new object with the description from the script file" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.Description | Should Be "description";
            }

            It "Should return a new object with the default action type of Octopus.Script" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.ActionType | Should Be "Octopus.Script";
            }

            It "Should return a new object with the specified action type of Octopus.AzurePowerShell" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.ActionType | Should Be "Octopus.Script";
            }

            It "Should return a new object with the property Octopus.Action.Script.ScriptBody from the script file" {
                $expected = @'
function test {
    
    
    
}
'@;
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.Properties["Octopus.Action.Script.ScriptBody"] | Should Be $expected;
            }

            It "Should return a new object with the property Octopus.Action.Script.Syntax of PowerShell" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.Properties["Octopus.Action.Script.Syntax"] | Should Be "PowerShell";
            }

            It "Should return a new object with the parameters from the script file" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "myParameterLabel";
                $result.Parameters[0].HelpText     | Should Be "myParameterHelpText";
                $result.Parameters[0].DefaultValue | Should Be "myDefaultValue";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
            }

            It "Should return a new object with the SensitiveProperties an empty hashtable" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.SensitiveProperties | Should BeOfType [hashtable];
                $result.SensitiveProperties.Count | Should Be 0;
            }

            It "Should return a new object with the metatype of ActionTemplate" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.'$Meta'.Type | Should Be "ActionTemplate";
            }

            It "Should return a new object with the version of 1" {
                $result = ConvertTo-StepTemplate -Script $stepTemplateScript;
                $result.Version | Should Be 1;
            }

        }

        Context "When cleaning up parameter properties" {

            It "Should convert null parameter properties to an empty string" {
                $script = @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = @(
        @{
            "Name" = "myParameterName"
            "Label" = $null
            "HelpText" = $null
            "DefaultValue" = $null
            "DisplaySettings" = @{}
        }
    );
'@;
                $result = ConvertTo-StepTemplate -Script $script;
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "";
                $result.Parameters[0].HelpText     | Should Be "";
                $result.Parameters[0].DefaultValue | Should Be "";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
            }

            It "Should trim space-padded parameter properties" {
                $script = @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = @(
        @{
            "Name" = "myParameterName"
            "Label" = "    myParameterLabel    "
            "HelpText" = "    myParameterHelpText    "
            "DefaultValue" = "    myDefaultValue    "
            "DisplaySettings" = @{}
        }
    );
'@;
                $result = ConvertTo-StepTemplate -Script $script;
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "myParameterLabel";
                $result.Parameters[0].HelpText     | Should Be "myParameterHelpText";
                $result.Parameters[0].DefaultValue | Should Be "myDefaultValue";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
                Assert-VerifiableMock;
            }

            It "Should convert bool default values to strings" {
                $script = @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = @(
        @{
            "Name" = "myParameterName"
            "Label" = "myParameterLabel"
            "HelpText" = "myParameterHelpText"
            "DefaultValue" = $true
            "DisplaySettings" = @{}
        }
    );
'@;
                $result = ConvertTo-StepTemplate -Script $script;
                $result.Parameters.Count           | Should Be 1;
                $result.Parameters[0].Name         | Should Be "myParameterName";
                $result.Parameters[0].Label        | Should Be "myParameterLabel";
                $result.Parameters[0].HelpText     | Should Be "myParameterHelpText";
                $result.Parameters[0].DefaultValue | Should Be "True";
                $result.Parameters[0].DisplaySettings.Count | Should Be 0;
                Assert-VerifiableMock;
            }

        }

        Context "When converting an invalid script" {

            It "Should throw when step template name is not a string" {
                $script = @'
function test {
    $StepTemplateName = 100
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
                {
                    $result = ConvertTo-StepTemplate -Script $script;
                } | Should Throw "The '`$StepTemplateName' variable does not evaluate to a string.";
             }

            It "Should throw when step template description is not a string" {
                $script = @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = 100
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
                {
                    $result = ConvertTo-StepTemplate -Script $script;
                } | Should Throw "The '`$StepTemplateDescription' variable does not evaluate to a string.";
             }

            It "Should throw when step template parameters are not a hashtable" {
                $script = @'
function test {
    $StepTemplateName = "name"
    $StepTemplateDescription = "description"
    $StepTemplateParameters = 100
}
'@;
                {
                    $result = ConvertTo-StepTemplate -Script $script;
                } | Should Throw "The '`$StepTemplateParameters' variable does not evaluate to an array of hashtables.";
             }

        }
	
    }

}
