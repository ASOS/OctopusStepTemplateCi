#requires -Version 3.0

param ([string] $sut)


Describe 'Step template parameters' {
 	Context "Step template contains metadata parameters" {

		It "Step template should contain `$StepTemplateName" {
			{ Get-VariableFromScriptFile $sut "StepTemplateName" } | Should Not Throw
		}
		It "Step template should contain `$StepTemplateDescription" {
			{ Get-VariableFromScriptFile $sut "StepTemplateDescription" } | Should Not Throw
		}
		It "Step template should contain `$StepTemplateParameters" {
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
                #$expectedString = "`$OctopusParameters['$variableName']"
                $scriptBody.Contains($variableName) | Should Be $true
            }
        }
    }

    Context "Step template should not contain undeclared parameters" {
        $scriptBody = Get-ScriptBody $sut
        $variables = Get-VariableFromScriptFile $sut "StepTemplateParameters"

        $foundVariables = [regex]::matches($scriptBody, "\`$OctopusParameters\[.*\]")

        foreach($foundVariable in $foundVariables)
        {
            $variableName = [regex]::Match($foundVariable.Value, "\`$OctopusParameters\[['`"](.*)['`"]\]").Groups[1].Value
            if ($variableName -match "Octopus\..*") {
                #Don't process Octopus system variables so you can use them in scripts
            }
            else
            {
                It "`$StepTemplateParameters should declare variable $variableName, which is used in the script body" {
                    $matched = $variables | where-object {$_['Name'] -eq $variableName } | Should Not Be $null
                }
            }  
        }
    }
}