$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


$thisScript = $MyInvocation.MyCommand.Path;
$thisFolder = [System.IO.Path]::GetDirectoryName($thisScript);
$rootFolder = [System.IO.Path]::GetDirectoryName($thisFolder);


. ([System.IO.Path]::Combine($thisFolder, "scripts\Import-PowerShellGalleryModule.ps1"));


# LOCAL
$nuget           = "[nuget exe path]";
$nugetFeedUrl    = "[nuget feed url]";
$pesterModule    = "[pester module path]";
$octopusModule   = "[octopus module path]"
$excludeRules    = @(
    "PSAvoidUsingWMICmdlet",
    "PSAvoidUsingWriteHost",
    "PSAvoidUsingPlainTextForPassword",
    "PSAvoidUsingConvertToSecureStringWithPlainText",
    "PSAvoidUsingUserNameAndPassWordParams",
    "PSShouldProcess"
);
$scriptPath         = "[script path]";
$OctopusUri         = "[octopus uri]";
$OctopusApiKey      = "[octopus api key]";

$stepTemplateFilter = "*.steptemplate.ps1";
$scriptmoduleFilter = "*.scriptmodule.ps1";


$packageRoot = [System.IO.Path]::Combine($rootFolder, "packages");
Import-PowerShellGalleryModule -Name        "PSScriptAnalyzer" `
                               -InstallRoot $packageRoot `
                               -ModulePath  "PSScriptAnalyzer.psd1";


if( $false )
{
    write-host "installing OctopusStepTemplateCi nuget package";
    $cmdLine = $nuget;
    $cmdArgs = @(
        "Install", "OctopusStepTemplateCi"
        "-Source", "`"$nugetFeedUrl`"",
        "-ExcludeVersion"
    );
    write-host "cmdLine = '$cmdLine'";
    write-host "cmdArgs = ";
    write-host ($cmdArgs | fl * | out-string);
    $process = Start-Process -FilePath $cmdLine -ArgumentList $cmdArgs -Wait -NoNewWindow -PassThru;
    if( $process.ExitCode -ne 0 )
    {
        throw new-object System.InvalidOperationException("process terminated with exit code $($process.ExitCode)");
    }
}


if( -not [string]::IsNullOrEmpty($pesterModule) )
{
    Import-Module -Name $pesterModule -ErrorAction "Stop";
}
Import-Module -Name $octopusModule -ErrorAction "Stop";


if( -not [string]::IsNullOrEmpty($OctopusUri) )
{
    $env:OctopusUri = $OctopusUri;
}
if( -not [string]::IsNullOrEmpty($OctopusApiKey) )
{
    $env:OctopusApiKey = $OctopusApiKey;
}


$env:PSModulePath += ";$($PWD.Path)";

Invoke-TeamCityCiUpload -Path               $scriptPath `
                        -ProcessingMode     "Individual" `
                        -StepTemplateFilter $stepTemplateFilter `
                        -ScriptModuleFilter $scriptModuleFilter `
                        -TestSettings @{
                            "PSScriptAnalyzer-Enabled"      = "True";
                            "PSScriptAnalyzer-ExcludeRules" = $excludeRules
                        } `
                        -UploadIfSuccessful:$false `
                        -suppressPesterOutput:$false;
