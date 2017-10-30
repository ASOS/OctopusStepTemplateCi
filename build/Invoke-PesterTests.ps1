$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


$thisScript = $MyInvocation.MyCommand.Path;
$thisFolder = [System.IO.Path]::GetDirectoryName($thisScript);
$rootFolder = [System.IO.Path]::GetDirectoryName($thisFolder);


. ([System.IO.Path]::Combine($thisFolder, "scripts\Import-PowerShellGalleryModule.ps1"));


$packageRoot = [System.IO.Path]::Combine($rootFolder, "packages");
Import-PowerShellGalleryModule -Name        "Pester" `
                               -Version     "4.0.8" `
                               -InstallRoot $packageRoot `
                               -ModulePath  "Pester.psd1";


$testPath      = [System.IO.Path]::Combine($rootFolder, "OctopusStepTemplateCi\Cmdlets");
$coverageFiles = (Get-ChildItem -Path "$testPath\*.ps1" -Recurse -Exclude *.Tests.* ).FullName;


$testResults = Invoke-Pester -Path         $testPath `
                             -OutputFile   "PesterTestOutput.xml" `
                             -OutputFormat "NUnitXml" `
                             -CodeCoverage $coverageFiles `
                             -PassThru;

Write-Output "##teamcity[buildStatisticValue key='CodeCoverageAbsLTotal' value='$($testResults.CodeCoverage.NumberOfCommandsAnalyzed)']"
Write-Output "##teamcity[buildStatisticValue key='CodeCoverageAbsLCovered' value='$($testResults.CodeCoverage.NumberOfCommandsExecuted)']"
