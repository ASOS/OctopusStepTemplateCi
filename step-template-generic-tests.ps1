#requires -version 3

# ------------------------------------------------
# Octopus Deploy Step Template Generic Tests
# ------------------------------------------------
#
# Ver    Who                             When        What
# 1.00   Matt Richardson (DevOpsGuys)    14-08-15    Initial Version
# 1.01   Matt Richardson (DevOpsGuys)    07-10-15    Adding tests for required fields on parameters
# 1.02   Matt Richardson (DevOpsGuys)    24-11-15    Add validation to ensure a script module description is supplied
# 1.03   Matt Richardson (DevOpsGuys)    30-11-15    Adding new test to ensure we dont overwrite passed in parameters
# 1.04   Matt Richardson (DevOpsGuys)    01-12-15    Write warning messages as teamcity build warnings
# 1.05   Matt Richardson (DevOpsGuys)    03-12-15    Add comment to explain why a given test exists
# 1.06   Matt Richardson (DevOpsGuys)    09-12-15    Updating generic tests to have unique test names
# 1.07   Matt Richardson (DevOpsGuys)    14-01-16    Convert warnings to test failures, as warnings are not having the required impact
# 1.08   Matt Richardson (DevOpsGuys)    02-02-16    Add new test for non-ascii characters - getting failures due to bad dashes
# 1.09   Matt Richardson (DevOpsGuys)    03-02-16    Dont print out teamcity warnings - showing up out of order
# 1.10   Matt Richardson (DevOpsGuys)    03-02-16    Ensure testing for variables is only done once for each variable
# 1.11   Matt Richardson (DevOpsGuys)    03-02-16    Add test to ensure pester test names are unique
# 1.12   Matt Richardson (DevOpsGuys)    04-02-16    Extract tests that are common to step templates and script modules to separate file
# ------------------------------------------------

param ([string] $sut)

Describe 'Step template parameters' {
    $filename = Split-Path -Leaf $sut
 	
    Context "Step template '$filename' contains metadata parameters" {

		It "Step template should contain metadata variable `$StepTemplateName" {
			{ Get-VariableFromScriptFile $sut "StepTemplateName" } | Should Not Throw
		}
		It "Step template should contain metadata variable `$StepTemplateDescription" {
			{ Get-VariableFromScriptFile $sut "StepTemplateDescription" } | Should Not Throw
		}
		It "Step template should contain metadata variable `$StepTemplateParameters" {
			{ Get-VariableFromScriptFile $sut "StepTemplateParameters" } | Should Not Throw
		}
    }

    Context "Step template should not contain unused parameters" {
        $scriptBody = Get-ScriptBody $sut

        $variables = Get-VariableFromScriptFile $sut "StepTemplateParameters"
        foreach($variable in $variables)
        {
            $variableName = $variable['Name']
            It "ScriptBody should use variable $variableName, declared in `$StepTemplateParameters" {
                $scriptBody.ToLower().Contains($variableName.ToLower()) | Should Be $true
            }

            It "ScriptBody should not overwrite input parameter '$variableName'" {

                #This test is here to prevent issues where someone modifies the global part of a step template
                #but inadvertently overwrites an octopus parameter with a local variable
                #As we are testing at the function level rather than the whole step template level, we cant 
                #catch this with our unit tests

                $scriptBlock = $null
                try {
                    $scriptBlock = Get-VariableFromScriptFile -Path $sut -VariableName $variableName -ResolveVariable $false
                }
                catch {
                    #all good here
                    #File 'xxx.steptemplate.ps1' does not contain Step Template metadata variable 'yyy'
                }
                if ($scriptBlock) {
                    $errorMessage = $null
                    if ($scriptBlock.ToString() -eq "`$$variableName.ToLower()") {
                        $errorMessage = "Variable $variableName is overwritten, but only to make it lowercase. Probably should assign it to a different variable:`n`$$variableName = $scriptBlock"
                    }
                    elseif ($scriptBlock.ToString() -match "\`$OctopusParameters\[.$variableName.\]") {
                        $errorMessage = "Variable $variableName is overwritten, but only to assign it to itself. This is redundant:`n`$$variableName = $scriptBlock"
                    }
                    else {
                        $errorMessage = "Variable $variableName is overwritten:`n`$$variableName = $scriptBlock"
                    }
                    $errorMessage | Should Be $null
                }
            }
        }
    }

    Context "Step template parameters for '$filename' should contain all required fields" {
        $scriptBody = Get-ScriptBody $sut

        $variables = Get-VariableFromScriptFile $sut "StepTemplateParameters"

        $variableCounter = 1
        foreach($variable in $variables)
        {
            It "Variable $variableCounter should contain a property 'Name'" {
                $variable.ContainsKey("Name") | Should be $true
            }
            $variableCounter = $variableCounter + 1
            $variableName = $variable['Name']
            It "Variable '$variableName' should contain a property 'Label'" {
                $variable.ContainsKey("Label") | Should be $true
            }
            It "Variable '$variableName' should contain a property 'HelpText'" {
                $variable.ContainsKey("HelpText") | Should be $true
            }
            It "Variable '$variableName' should contain a property 'DefaultValue'" {
                $variable.ContainsKey("DefaultValue") | Should be $true
            }
            It "Variable '$variableName' should contain a property 'DisplaySettings'" {
                $variable.ContainsKey("DisplaySettings") | Should be $true
            }
        }
    }

    Context "Step template '$filename' should not contain undeclared parameters" {
        $scriptBody = Get-ScriptBody $sut
        $variables = Get-VariableFromScriptFile $sut "StepTemplateParameters"

        $matches = [regex]::matches($scriptBody, "\`$OctopusParameters\[['`"].*['`"]\]")
        if ($matches -ne $null) {
            $foundVariables = ($matches.value | Sort-Object | Get-Unique)

            foreach($foundVariable in $foundVariables)
            {
                $variableName = [regex]::Match($foundVariable, "\`$OctopusParameters\[['`"](.*)['`"]\]").Groups[1].Value
                if ($variableName -match "Octopus\..*") {
                    #Don't process Octopus system variables so you can use them in scripts
                }
                else
                {
                    It "`$StepTemplateParameters should declare variable '$variableName', which is used in the script body" {
                        $matched = $variables | where-object {$_['Name'] -eq $variableName } | Should Not Be $null
                    }
                }  
            }
        }
    }
}