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
    Compare-StepTemplateParameter.Tests

.SYNOPSIS
    Pester tests for Compare-StepTemplateParameter.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


InModuleScope "OctopusStepTemplateCi" {

    Describe "Compare-StepTemplateParameter" {

        $oldParameter = @{
            "Name"            = "myParameterName"
            "Label"           = "myParameterLabel"
            "HelpText"        = "myParameterHelpText"
            "DefaultValue"    = "myDefaultValue"
            "DisplaySettings" = @{}
        };

        It "Should return false if they are the same" {
            $result = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $oldParameter;
            $result | Should Be $null;
        }

        It "Should return true when the Name is different" {
            $newParameter = @{
                "Name"            = "NEW_NAME"
                "Label"           = "myParameterLabel"
                "HelpText"        = "myParameterHelpText"
                "DefaultValue"    = "myDefaultValue"
                "DisplaySettings" = @{}
            };
            $result = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $newParameter;
            $result | Should Not Be $null;
        }

        It "Should return true when the Label is different" {
            $newParameter = @{
                "Name"            = "myParameterName"
                "Label"           = "NEW_LABEL"
                "HelpText"        = "myParameterHelpText"
                "DefaultValue"    = "myDefaultValue"
                "DisplaySettings" = @{}
            };
            $result = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $newParameter;
            $result | Should Not Be $null;
        }

        It "Should return true when the HelpText is different" {
            $newParameter = @{
                "Name"            = "myParameterName"
                "Label"           = "myParameterLabel"
                "HelpText"        = "NEW_HELPTEXT"
                "DefaultValue"    = "myDefaultValue"
                "DisplaySettings" = @{}
            };
            $result = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $newParameter;
            $result | Should Not Be $null;
        }

        It "Should return true when the DefaultValue is different" {
            $newParameter = @{
                "Name"            = "myParameterName"
                "Label"           = "myParameterLabel"
                "HelpText"        = "myParameterHelpText"
                "DefaultValue"    = "NEW_DEFAULTVALUE"
                "DisplaySettings" = @{}
            };
            $result = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $newParameter;
            $result | Should Not Be $null;
        }

        It "Should return true when the DisplaySettings is different" {
            $newParameter = @{
                "Name"            = "myParameterName"
                "Label"           = "myParameterLabel"
                "HelpText"        = "myParameterHelpText"
                "DefaultValue"    = "myDefaultValue"
                "DisplaySettings" = $null
            };
            $result = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $newParameter;
            $result | Should Not Be $null;
        }

    }

}