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
    Batch (default) - All tests must pass for all step templates / script modules before any new versions are uploaded.
                      This is set as the default as it more conservative in it's approach in case there are inter-dependencies between the step templates / script modules.
    Individual - Each step template / script module is processed individually, if each passes it's tests then it is uploaded to Octopus.
                 Failing tests for other step templates / script modules don't affect the decision to upload the current item being processed.

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
function Invoke-TeamCityCiUpload
{

    [CmdletBinding()]
    [OutputType()]
    param
    (

        [Parameter(Mandatory=$false)]
        [ValidateScript({ Test-Path $_ })]
        [string] $Path = $PWD,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $BuildDirectory = (Join-Path $PWD "\.BuildOutput"),

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $StepTemplateFilter = "*.steptemplate.ps1",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $ScriptModuleFilter = "*.scriptmodule.ps1",

        [Parameter(Mandatory=$false)]
        [ValidateSet("Batch", "Individual")]
        [string] $ProcessingMode = "Batch",

        [Parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [hashtable] $TestSettings = @{},

        [Parameter(Mandatory=$false)]
        [switch]
        $UploadIfSuccessful,

        [Parameter(Mandatory=$false)]
        [switch] $SuppressPesterOutput

    )

    try
    {

        if( $UploadIfSuccessful )
        {
            Test-OctopusApiConnectivity -TestConnection;
        }

        Reset-BuildOutputDirectory -Path $BuildDirectory;

        Reset-OctopusApiCache;

        switch( $ProcessingMode )
        {
            "Batch" {
                $folderToProcess = @(Get-Item -Path $Path | where-object { $_.PSIsContainer });
                $itemsToProcess  = $folderToProcess;
            }
            "Individual" {
                $stepTemplates  = @(Get-ChildItem -Path $Path -File -Recurse -Filter $StepTemplateFilter);
                $scriptModules  = @(Get-ChildItem -Path $Path -File -Recurse -Filter $ScriptModuleFilter);
                $itemsToProcess = @($stepTemplates + $scriptModules);
            }
        }

        $uploadCount = 0;
        $passedTests = 0;
        $failedTests = 0;

        $itemsToProcess | % {

            $itemToProcess = $_;

            Write-TeamCityBlockOpenedMessage -BlockName $itemToProcess.BaseName;

            Write-TeamCityProgressMessage -Message "Running tests for $($itemToProcess.BaseName)";

            try
            {
                $testResults = Invoke-OctopusScriptTestSuite -Path               $itemToProcess.FullName `
                                                             -ResultFilesPath    $BuildDirectory `
                                                             -StepTemplateFilter $StepTemplateFilter `
                                                             -ScriptModuleFilter $ScriptModuleFilter `
                                                             -TestSettings       $TestSettings `
                                                             -SuppressPesterOutput:$SuppressPesterOutput;
            }
            catch [Exception]
            {
                $ex = $_.psbase.Exception;
                $message = "'$($itemToProcess.BaseName)' failed with error`r`n$($ex.ToString())";
                Write-TeamCityBuildProblemMessage -Description $message;
                Write-Warning $message;
                $testResults = @{
                    "Success" = $false
                    "Passed"  = 0
                    "Failed"  = 1
                };
            }

            $passedTests += $testResults.Passed;
            $failedTests += $testResults.Failed;

            if( $testResults.Success )
            {
                if( $UploadIfSuccessful )
                {

                    Write-TeamCityProgressMessage -Message "Starting sync of $($itemToProcess.BaseName) to Octopus";

                    $uploadCount += Get-ChildItem -Path $itemToProcess.FullName -File -Recurse | % {
                        if( $_.Name -like $ScriptModuleFilter )
                        {
                            Sync-ScriptModule -Path $_.FullName -UseCache;
                        }
                        elseif( $_.Name -like $StepTemplateFilter )
                        {
                            Sync-StepTemplate -Path $_.FullName -UseCache;
                        }
                    } | % UploadCount | Measure-Object -Sum | % Sum;

                    if( $uploadCount -gt 0 )
                    {
                        Write-TeamCityProgressMessage -Message "Uploaded $($itemToProcess.BaseName) to Octopus";
                    }

                }
                else
                {
                    Write-TeamCityBuildLogMessage -Message "UploadIfSuccessful is false. Skipping comparison with server.";
                }
            }
            else
            {
                $message = "One or more PSScriptAnalyzer tests failed. Skipping upload.";
                Write-TeamCityBuildLogMessage -Message $message;
                Write-Warning $message;
            }

            Write-TeamCityBlockClosedMessage -BlockName $itemToProcess.BaseName;

        }

        if( $UploadIfSuccessful )
        {
            Write-TeamCityBuildStatusMessage -Text "{build.status.text}. Scripts uploaded: $uploadCount";
        }

        Write-TeamCityBuildLogMessage "$passedTests tests passed. $failedTests tests failed";

        if( $failedTests -ge 0 )
        {
            $message = "One or more files failed to synchronise. Check the build logs for details.";
            Write-TeamCityBuildProblemMessage -Description $message;
            throw $message;
        }

    }
    catch
    {

        Write-TeamCityBuildLogMessage $_.Exception.Message -ErrorMessage;
        Write-TeamCityBuildLogMessage $_.ScriptStackTrace -ErrorMessage;
        throw;

    }

}
