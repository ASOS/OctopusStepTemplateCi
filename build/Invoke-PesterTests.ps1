param
(

    [Parameter(Mandatory=$true)]
    [string] $NuGet

)


$ErrorActionPreference = "Stop";
$ProgressPreference = "SilentlyContinue";
Set-StrictMode -Version "Latest";


$thisScript   = $MyInvocation.MyCommand.Path;
$thisFolder   = [System.IO.Path]::GetDirectoryName($thisScript);
$rootFolder   = [System.IO.Path]::GetDirectoryName($thisFolder);
$packagesRoot = [System.IO.Path]::Combine($rootFolder, "packages");


. ([System.IO.Path]::Combine($thisFolder, "scripts\Invoke-NuGetInstall.ps1"));


Invoke-NuGetInstall -NuGet           $NuGet `
                    -Source          "https://www.powershellgallery.com/api/v2" `
                    -PackageId       "PSScriptAnalyzer" `
                    -Version         "1.17.1" `
                    -OutputDirectory $packagesRoot;

Invoke-NuGetInstall -NuGet           $NuGet `
                    -Source          "https://www.powershellgallery.com/api/v2" `
                    -PackageId       "Pester" `
                    -Version         "4.3.1" `
                    -OutputDirectory $packagesRoot;


Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "PSScriptAnalyzer.1.17.1\PSScriptAnalyzer.psd1")) -ErrorAction "Stop";
Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "Pester.4.3.1\Pester.psd1")) -ErrorAction "Stop";


$testPath      = [System.IO.Path]::Combine($rootFolder, "OctopusStepTemplateCi\Cmdlets");
$coverageFiles = (Get-ChildItem -Path "$testPath\*.ps1" -Recurse -Exclude *.Tests.* ).FullName;


Import-Module -Name "$rootFolder\OctopusStepTemplateCi" -ErrorAction "Stop";


write-host "invoking pester tests";
$testResults = Invoke-Pester -Path         $testPath `
                             -OutputFile   "PesterTestOutput.xml" `
                             -OutputFormat "NUnitXml" `
                             -CodeCoverage $coverageFiles `
                             -PassThru;


Write-Output "##teamcity[buildStatisticValue key='CodeCoverageAbsLTotal' value='$($testResults.CodeCoverage.NumberOfCommandsAnalyzed)']";
Write-Output "##teamcity[buildStatisticValue key='CodeCoverageAbsLCovered' value='$($testResults.CodeCoverage.NumberOfCommandsExecuted)']";
