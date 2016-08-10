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
    Invoke-OctopusScriptTestSuite
    
.SYNOPSIS
    Invokes the Pester tests to validate the Octopus step template / script module

.DESCRIPTION
    This will run the Pester tests written specifically for the step tempate / script module, along with Pester tests to confirm
    that the format of the step template / script module file is in the correct 
    
.PARAMETER Path
    The path to the step template / script module to run the tests against
    
.PARAMETER ResultFilesPath
    The path of the folder to store the Pester results files in

.PARAMETER StepTemplateFilter
    A filter to identify the step template files

.PARAMETER ScriptModuleFilter
    A filter to identify the script module files

.PARAMETER TestSettings
    A hash table of settings for the tests that are run against the script module / step template
    
.PARAMETER SuppressPesterOutput
    Invoke Pester with the 'Quiet' parameter set

.INPUTS
    None. You cannot pipe objects to Invoke-OctopusScriptTestSuite.

.OUTPUTS
    None.
#>
function Invoke-OctopusScriptTestSuite {
    [CmdletBinding()]
	[OutputType("System.Collections.Hashtable")]
    param (
        [Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][System.String]$Path = $PWD,
        [Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][System.String]$ResultFilesPath = $PWD,
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][System.String]$StepTemplateFilter = "*.steptemplate.ps1",
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][System.String]$ScriptModuleFilter = "*.scriptmodule.ps1",
        [Parameter(Mandatory=$false)][ValidateNotNull()][System.Collections.Hashtable]$TestSettings = @{},
        [Parameter(Mandatory=$false)][System.Management.Automation.SwitchParameter]$SuppressPesterOutput
    )
    
    $stepTemplates = @(Get-ChildItem -Path $Path -File -Recurse -Filter $StepTemplateFilter)
    $scriptModules = @(Get-ChildItem -Path $Path -File -Recurse -Filter $ScriptModuleFilter)

    $results = ($stepTemplates + $scriptModules) | ? Name -NotLike "*.Tests.ps1" | % {
        $sut = $_.FullName
        $testResultsFile = Join-Path $ResultFilesPath $_.Name.Replace(".ps1", ".TestResults.xml")
        Invoke-PesterForCi -TestName $_.Name `
            -Script $_.FullName.Replace(".ps1", ".Tests.ps1") `
            -TestResultsFile $testResultsFile `
            -SuppressPesterOutput:$SuppressPesterOutput
        
        Invoke-PesterForCi -TestName $_.Name `
            -Script @(Get-ChildItem -Path (Join-Path (Get-ScriptValidationTestsPath) "\Generic\*.ScriptValidationTest.ps1") -File | % { @{ Path = $_.FullName; Parameters = @{ sut = $sut; TestResultsFile = $testResultsFile; Settings = $TestSettings } } }) `
            -TestResultsFile (Join-Path $ResultFilesPath $_.Name.Replace(".ps1", ".generic.TestResults.xml")) `
            -SuppressPesterOutput:$SuppressPesterOutput
        
        if ($_.Name -like $ScriptModuleFilter) {
            Invoke-PesterForCi -TestName $_.Name `
                -Script @(Get-ChildItem -Path (Join-Path (Get-ScriptValidationTestsPath) "\ScriptModules\*.ScriptValidationTest.ps1") -File | % { @{ Path = $_.FullName; Parameters = @{ sut = $sut; TestResultsFile = $testResultsFile; Settings = $TestSettings } } }) `
                -TestResultsFile (Join-Path $ResultFilesPath $_.Name.Replace(".ps1", ".script-module.TestResults.xml")) `
                -SuppressPesterOutput:$SuppressPesterOutput
        }
        elseif ($_.Name -like $StepTemplateFilter) {
            Invoke-PesterForCi -TestName $_.Name `
                -Script @(Get-ChildItem -Path (Join-Path (Get-ScriptValidationTestsPath) "\StepTemplates\*.ScriptValidationTest.ps1") -File | % { @{ Path = $_.FullName; Parameters = @{ sut = $sut; TestResultsFile = $testResultsFile; Settings = $TestSettings } } }) `
                -TestResultsFile (Join-Path $ResultFilesPath $_.Name.Replace(".ps1", ".step-template.TestResults.xml")) `
                -SuppressPesterOutput:$SuppressPesterOutput
        }
    } | Measure-Object -Sum -Property @("Passed", "Failed")
    
    @{
        Success = ($results | ? Property -EQ 'Failed' | % Sum | % { $_ -eq 0 })
        Passed = ($results | ? Property -EQ 'Passed' | % Sum)
        Failed = ($results | ? Property -EQ 'Failed' | % Sum)
    }
}