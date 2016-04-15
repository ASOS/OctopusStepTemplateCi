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
    PSScriptAnalyzer.Tests
    
.SYNOPSIS
    Pester tests for PSScriptAnalyzer.
#>
param ([System.String] $sut, [System.String] $TestResultsFile, [System.Collections.Hashtable]$Settings)
Set-StrictMode -Version Latest

if ($Settings.Item("PSScriptAnalyzer-Enabled") -eq "True") {
    New-Variable -Name PSScriptAnalyzerSut -Value $sut -Scope Global # TODO: Pass sut into the PSScriptAnalyzer without using a global
    New-Variable -Name PSScriptAnalyzerSettings -Value $Settings -Scope Global # TODO: Pass sut into the PSScriptAnalyzer without using a global

	InModuleScope Pester { # This is how Pester tests itself. To add each failed rule as it's own test result it allows runtime access to $Pester.AddTestResult
		Describe 'PSScriptAnalyzer' {  
			if (-not (Get-Module PSScriptAnalyzer)) {
				Import-Module -Name PSScriptAnalyzer
			}

			$excludeRules = @()            
			if ($PSScriptAnalyzerSettings.ContainsKey('PSScriptAnalyzer-ExcludeRules')) {
				$excludeRules = @($PSScriptAnalyzerSettings.Item('PSScriptAnalyzer-ExcludeRules'))
			}
			$excludeRules += "PSAvoidUsingCmdletAliases"
			$excludeRules += "PSUseShouldProcessForStateChangingFunctions"
            
			$scriptAnalyzerResults = Invoke-ScriptAnalyzer -Path $PSScriptAnalyzerSut -ExcludeRule $excludeRules

            Get-ScriptAnalyzerRule | % {
                $Pester.EnterTest($_.RuleName)
                $ruleViolations = $scriptAnalyzerResults | ? RuleName -eq $_.RuleName | ? { $_.RuleSuppressionID -notin @(
                                                                                        # Step Template Metadata Variables
                                                                                        "StepTemplateName",
                                                                                        "StepTemplateDescription",
                                                                                        "StepTemplateParameters",
                                                                                        # Script Module Metadata Variables
                                                                                        "ScriptModuleName",
                                                                                        "ScriptModuleDescription"
                                                                                    ) }
                if ($ruleViolations) {
                    $pesterResult = switch ($_.Severity) {
                        # Pester result options: "Failed", "Passed", "Skipped", "Pending", "Inconclusive"
                        ([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error) { "Failed" }
                        ([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning) { "Failed" }
                        ([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Information) { "Inconclusive" }
                    }
                    # TODO: Aggregate all ruleViolations so multiple violations of the same rule are reported in the same run rather than requiring multiple builds
                    $reportedRule = $ruleViolations | Select-Object -First 1
                    
                    $pesterFailureMessage = $reportedRule.Message
                    $pesterStackTrace =  "at line: $($reportedRule.Line) in $($reportedRule.ScriptName)`n$($reportedRule.Line): $($reportedRule.Extent.Text)" # Formatted according to Pester's standard formatting
                    $lineText = Get-Content -Path ($reportedRule | % Extent | % File) -TotalCount $reportedRule.Line | Select-Object -First 1 -Skip ($reportedRule.Line-1) | % Trim
                    $pesterErrorRecord = New-ShouldErrorRecord -Message $reportedRule.Message -File $reportedRule.ScriptName -Line $reportedRule.Line -LineText $lineText
                    # ScriptStackTrace is read by pester and is normally set when the ErrorRecord is thrown, however this would report the error being in this script
                    # so we set the _scriptStackTrace field manually with a stacktrace that points to where the rule violation occured
                    [System.Management.Automation.ErrorRecord].GetField('_scriptStackTrace', [System.Reflection.BindingFlags]'Instance,NonPublic').SetValue($pesterErrorRecord, $pesterStackTrace)
                } else {
                    $pesterResult = "Passed"
                    $pesterFailureMessage = ""
                    $pesterStackTrace = ""
                    $pesterErrorRecord = $null
                }
                
                #                     Name         Result         Time   FailureMessage         StackTrace         ParameterizedSuiteName Parameters ErrorRecord
				$Pester.AddTestResult($_.RuleName, $pesterResult, $null, $pesterFailureMessage, $pesterStackTrace, "",                    $null,     $pesterErrorRecord)
                
                Write-PesterResult -TestResult $Pester.testresult[-1]
                $Pester.LeaveTest()
            }

			It "Should pass the PSScriptAnalyzer ruleset" {
				$scriptAnalyzerResult.Count | Should Be 0
			}
		} 
	}
    
    Remove-Variable -Name PSScriptAnalyzerSut -Scope Global
    Remove-Variable -Name PSScriptAnalyzerSettings -Scope Global
}
