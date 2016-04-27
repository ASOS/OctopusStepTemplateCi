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
    Invoke-TeamCityCiUpload
    
.SYNOPSIS
    Invokes the TeamCity CI pipeline

.DESCRIPTION
    This will take a number of step template & script modules, run the octopus script tests against them, if the tests pass
    then they will be uploaded into Octopus if they are different to the version that currently exists within Octopus
    This is designed to be run from within TeamCity and so formats certain output in a format designed to be understood by it
    
.PARAMETER Path
    The path to search for step templates & script modules to test and upload
    
.PARAMETER BuildDirectory
    The path to the directory to store the Pester results files

.PARAMETER StepTemplateFilter
    A filter to identify the step template files
    
.PARAMETER ScriptModuleFilter
    A filter to identify the script module files

.PARAMETER ProcessingMode
    Batch (default) - All tests must pass for the step templates / script modules must pass before new versions are uploaded
                        This is set as the default as it more conservative in it's approach in case there are inter-dependencies between the step templates / script modules
    Individual - Each step template / script module is processed individually, if each passes it's tests then it is uploaded to Octopus
                    Failing tests for other step templates / script modules don't affect the decision to upload the current item being processed

.PARAMETER TestSettings
    A hash table of settings for the tests that are run against the script module / step template
    
.PARAMETER UploadIfSuccessful
    Enable this swith to turn on the uploading of the step template / script modules into Octopus if the Pester tests pass

.PARAMETER SuppressPesterOutput
    Invoke Pester with the 'Quiet' parameter set

.INPUTS
    None. You cannot pipe objects to Invoke-TeamCityCiUpload.

.OUTPUTS
    None.
#>
function Invoke-TeamCityCiUpload {
    [CmdletBinding()]
    [OutputType()]
    param (
        [Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][System.String]$Path = $PWD,
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][System.String]$BuildDirectory = (Join-Path $PWD "\.BuildOutput"),
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][System.String]$StepTemplateFilter = "*.steptemplate.ps1",
        [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][System.String]$ScriptModuleFilter = "*.scriptmodule.ps1",
        [Parameter(Mandatory=$false)][ValidateSet("Batch", "Individual")][System.String]$ProcessingMode = "Batch",
        [Parameter(Mandatory=$false)][ValidateNotNull()][System.Collections.Hashtable]$TestSettings = @{},
        [Parameter(Mandatory=$false)][System.Management.Automation.SwitchParameter]$UploadIfSuccessful,
        [Parameter(Mandatory=$false)][System.Management.Automation.SwitchParameter]$SuppressPesterOutput
    )

    try {
        Test-OctopusConnectivity -TestConnection
         
        Reset-BuildOutputDirectory -Path $BuildDirectory
        
        Reset-Cache

        switch ($ProcessingMode) {
            "Batch" { $itemsToProcess = @(Get-Item -Path $Path | ? PSIsContainer -EQ $true) }
            "Individual" {
            $itemsToProcess = @(@(Get-ChildItem -Path $Path -File -Recurse -Filter $StepTemplateFilter) + `
                                @(Get-ChildItem -Path $Path -File -Recurse -Filter $ScriptModuleFilter))
            }
        }
        
        $uploadCount = 0
        $passedTests = 0
        $failedTests = 0
        $itemsToProcess | % {
            Write-TeamCityMessage "##teamcity[blockOpened name='$($_.BaseName)']"
            Write-TeamCityMessage "##teamcity[progressMessage 'Running tests for $($_.BaseName)']"
            
            $testResults = Invoke-OctopusScriptTestSuite -Path $_.FullName `
                                        -ResultFilesPath $BuildDirectory `
                                        -StepTemplateFilter $StepTemplateFilter `
                                        -ScriptModuleFilter $ScriptModuleFilter `
                                        -TestSettings $TestSettings `
                                        -SuppressPesterOutput:$SuppressPesterOutput
            $passedTests += $testResults.Passed
            $failedTests += $testResults.Failed
                                            
            if ($testResults.Success -and $UploadIfSuccessful) {
                Write-TeamCityMessage "##teamcity[progressMessage 'Starting sync of $($_.BaseName) to Octopus']"
                
                $uploadCount += Get-ChildItem -Path $_.FullName -File -Recurse | % {
                    if ($_.Name -like $ScriptModuleFilter) { Sync-ScriptModule -Path $_.FullName -UseCache }
                    elseif ($_.Name -like $StepTemplateFilter) { Sync-StepTemplate -Path $_.FullName -UseCache }
                } | % UploadCount | Measure-Object -Sum | % Sum
                if ($uploadCount -gt 0) {
                    Write-TeamCityMessage "##teamcity[progressMessage 'Uploaded $($_.BaseName) to Octopus']"
                }
            }
            
            Write-TeamCityMessage "##teamcity[blockClosed name='$($_.BaseName)']"
        }
        
        if ($UploadIfSuccessful) {
            Write-TeamCityMessage "##teamcity[buildStatus text='{build.status.text}. Scripts uploaded: $uploadCount']"
        }
        Write-TeamCityMessage "$passedTests tests passed. $failedTests tests failed"
    }
    catch {
        Write-TeamCityMessage $_.Exception.Message -ErrorMessage
        Write-TeamCityMessage $_.ScriptStackTrace -ErrorMessage
        throw
    } 
 }
