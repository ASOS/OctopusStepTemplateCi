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
    Parameters.Tests
    
.SYNOPSIS
    Pester tests for Parameters.
#>
param ([System.String] $sut, [System.String] $TestResultsFile, [System.Collections.Hashtable]$Settings)
Set-StrictMode -Version Latest

Describe "Step template parameters" {

    $filename = Split-Path -Leaf $sut;

    Context "Step template '$filename' contains metadata parameters" {

        It "Step template should contain metadata variable `$StepTemplateName" {
            {
                $script = Get-Content -LiteralPath $sut -Raw;
                $result = Get-VariableFromScriptText -Script $script -VariableName "StepTemplateName";
            } | Should Not Throw;
        }

        It "Step template should contain metadata variable `$StepTemplateDescription" {
            {
                $script = Get-Content -LiteralPath $sut -Raw;
                $result = Get-VariableFromScriptText -Script $script -VariableName "StepTemplateDescription";
            } | Should Not Throw;
        }

        It "Step template should contain metadata variable `$StepTemplateParameters" {
            {
                $script = Get-Content -LiteralPath $sut -Raw;
                $result = Get-VariableFromScriptText -Script $script -VariableName "StepTemplateParameters";
            } | Should Not Throw;
        }

    }

    Context "Step template should not contain unused parameters" {

        $script     = Get-Content -LiteralPath $sut -Raw;
        $scriptBody = Get-ScriptBodyFromScriptText -Script $script -Type "StepTemplate";
        $variables  = Get-VariableFromScriptText -Script $script -VariableName "StepTemplateParameters";

        foreach( $variable in $variables )
        {

            $variableName = $variable["Name"];

            It "ScriptBody should use variable $variableName, declared in `$StepTemplateParameters" {
                $result = $scriptBody.ToLower().Contains($variableName.ToLower());
                $result | Should Be $true;
            }

            It "ScriptBody should not overwrite input parameter '$variableName'" {

                # This test is here to prevent issues where someone modifies the global part of a step template
                # but inadvertently overwrites an octopus parameter with a local variable
                # As we are testing at the function level rather than the whole step template level, we can't 
                # catch this with our unit tests

                # for example:

                # $StepTemplateName        = "myStepTemplateName";
                # $StepTemplateDescription = "myStepTemplateDescription";
                # $StepTemplateParameters  = @(
                #    @{
                #        "Name" = "MyParameter"
                #        "Label" = "My Parameter Label"
                #        "HelpText" = "My Parameter Help Text"
                #        "DefaultValue" = $null
                #        "DisplaySettings" = @{}
                #    }
                # );
                #
                # function Invoke-StepTemplate
                # {
                #     param
                #     (
                #         $MyParameter
                #     )
                #     $MyParameter = "some other value"; # <-- this assignment should cause the test to fail
                # }
                #
                # if( Test-Path Variable:OctopusParameters )
                # {
                #     Invoke-StepTemplate -MyParameter $OctopusParameters["MyParameter"];
                # }

                $scriptBlock = $null;
                try
                {
                    $scriptBlock = Get-VariableFromScriptText -Script $script -VariableName $variableName -DontResolveVariable;
                }
                catch
                {
                    #all good here
                    #File 'xxx.steptemplate.ps1' does not contain Step Template metadata variable 'yyy'
                }

                if( $scriptBlock )
                {
                    $errorMessage = $null;
                    if( $scriptBlock.ToString() -eq "`$$variableName.ToLower()" )
                    {
                        $errorMessage = "Variable $variableName is overwritten, but only to make it lowercase. Probably should assign it to a different variable:`n`$$variableName = $scriptBlock";
                    }
                    elseif( $scriptBlock.ToString() -match "\`$OctopusParameters\[.$variableName.\]" )
                    {
                        $errorMessage = "Variable $variableName is overwritten, but only to assign it to itself. This is redundant:`n`$$variableName = $scriptBlock";
                    }
                    else
                    {
                        $errorMessage = "Variable $variableName is overwritten:`n`$$variableName = $scriptBlock";
                    }
                    $errorMessage | Should Be $null;
                }

            }
        }
    }

    Context "Step template parameters for '$filename' should contain all required fields" {

        $script     = Get-Content -LiteralPath $sut -Raw;
        $scriptBody = Get-ScriptBodyFromScriptText -Script $script -Type "StepTemplate";
        $variables  = Get-VariableFromScriptText -Script $script -VariableName "StepTemplateParameters";

        $variableCounter = 1;
        foreach( $variable in $variables )
        {

            It "Variable $variableCounter should contain a property 'Name'" {
                $result = $variable.ContainsKey("Name");
                $result | Should be $true;
            }

            $variableCounter = $variableCounter + 1;
            $variableName = $variable["Name"];

            It "Variable '$variableName' should contain a property 'Label'" {
                $result = $variable.ContainsKey("Label");
                $result | Should be $true;
            }

            It "Variable '$variableName' should contain a property 'HelpText'" {
                $result = $variable.ContainsKey("HelpText");
                $result | Should be $true;
            }

            It "Variable '$variableName' should contain a property 'DefaultValue'" {
                $result = $variable.ContainsKey("DefaultValue");
                $result | Should be $true;
            }

            It "Variable '$variableName' should contain a property 'DisplaySettings'" {
                $result = $variable.ContainsKey("DisplaySettings");
                $result | Should be $true;
            }

        }

    }

    Context "Step template '$filename' should not contain undeclared parameters" {

        $script     = Get-Content -LiteralPath $sut -Raw;
        $scriptBody = Get-ScriptBodyFromScriptText -Script $script -Type "StepTemplate";
        $variables  = Get-VariableFromScriptText -Script $script -VariableName "StepTemplateParameters";

        $matches = [regex]::matches($scriptBody, "\`$OctopusParameters\[['`"].*['`"]\]");

        if( $matches -ne $null )
        {

            $foundVariables = $matches.value | Sort-Object | Get-Unique;

            foreach($foundVariable in $foundVariables)
            {
                $variableName = [regex]::Match($foundVariable, "\`$OctopusParameters\[['`"](.*)['`"]\]").Groups[1].Value;
                if( $variableName -match "Octopus\..*" ) {
                    #Don't process Octopus system variables so you can use them in scripts
                }
                else
                {
                    It "`$StepTemplateParameters should declare variable '$variableName', which is used in the script body" {
                        $matched = $variables | where-object {$_["Name"] -eq $variableName };
                        $matched | Should Not Be $null;
                    }
                }  
            }

        }

    }

}