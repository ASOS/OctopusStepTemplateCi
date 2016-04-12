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

New-Variable -Name PSScriptAnalyzerSut -Value $sut -Scope Global # TODO: Pass sut into the PSScriptAnalyzer without using a global
New-Variable -Name PSScriptAnalyzerSettings -Value $Settings -Scope Global # TODO: Pass sut into the PSScriptAnalyzer without using a global

if ((Get-Module -ListAvailable PSScriptAnalyzer) -and $Settings.Item("PSScriptAnalyzer-Enabled") -eq "True") {
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

			$scriptAnalyzerResults | ? { $null -ne $_ -and ($_.RuleSuppressionID -notin @(
                # Step Template Metadata Variables
                "StepTemplateName",
                "StepTemplateDescription",
                "StepTemplateParameters",
                # Script Module Metadata Variables
                "ScriptModuleName",
                "ScriptModuleDescription"
            )) } | % {
				$pesterResult = switch ($_.Severity) {
					# Pester result options: "Failed", "Passed", "Skipped", "Pending", "Inconclusive"
					([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Error) { "Failed" }
					([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Warning) { "Failed" }
					([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticSeverity]::Information) { "Inconclusive" }
				}
				$stackTrace = "at line: $($_.Line) in $($_.ScriptName)`n$($_.Line): $($_.Extent.Text)" # Formatted according to Pester's standard formatting
				#                     Name         Result         Time   FailureMessage StackTrace   ParameterizedSuiteName Parameters ErrorRecord
				$Pester.AddTestResult($_.RuleName, $pesterResult, $null, $_.Message,    $stackTrace, "",                    $null,        $null)
			}

			It "Should pass the PSScriptAnalyzer ruleset" {
				$scriptAnalyzerResult.Count | Should Be 0
			}
		} 
	}
}

Remove-Variable -Name PSScriptAnalyzerSut -Scope Global
Remove-Variable -Name PSScriptAnalyzerSettings -Scope Global