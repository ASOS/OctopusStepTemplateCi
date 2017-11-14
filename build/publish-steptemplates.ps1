$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


$thisScript = $MyInvocation.MyCommand.Path;
$thisFolder = [System.IO.Path]::GetDirectoryName($thisScript);
$rootFolder = [System.IO.Path]::GetDirectoryName($thisFolder);


. ([System.IO.Path]::Combine($thisFolder, "scripts\Import-PowerShellGalleryModule.ps1"));




# LOCAL
$nuget           = "C:\src\github\pester\pester\vendor\tools\NuGet.exe";
$progetFeedUrl  = "https://proget.services.kingsway.asos.com/nuget/ASOSPackages";
$pesterModule    = "C:\src\github\pester\pester";
$octopusModule   = "C:\src\github\mikeclayton\OctopusStepTemplateCi\OctopusStepTemplateCi\OctopusStepTemplateCi.psm1"
$excludeRules    = @(
    "PSAvoidUsingWMICmdlet",
    "PSAvoidUsingWriteHost",
    "PSAvoidUsingPlainTextForPassword",
    "PSAvoidUsingConvertToSecureStringWithPlainText",
    "PSAvoidUsingUserNameAndPassWordParams",
    "PSShouldProcess"
);
$scriptPath         = "C:\src\asos-tfs\ASOS\BRB\OctopusDeployStepTemplates\Release\src";
$OctopusUri         = "https://dev-octopus.services.kingsway.asos.com";
$OctopusApiKey      = "API-PS9GLUF2EMM6ZM3ZXLVC8DLR5E";

$stepTemplateFilter = "*.steptemplate.ps1";
#$stepTemplateFilter = "xxx.steptemplate.ps1";
#$stepTemplateFilter = "azure-activedirectory-add-application-key.steptemplate.ps1";
#$stepTemplateFilter = "azure-deployment-check-instance-status.steptemplate.steptemplate.ps1";
#$stepTemplateFilter = "azure-cosmosdb-account-create.steptemplate.ps1";

$scriptmoduleFilter = "*.scriptmodule.ps1";
#$scriptmoduleFilter = "xxx.scriptmodule.ps1";
#$scriptmoduleFilter  = "azurespnv2.scriptmodule.ps1";


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
        "-Source", "`"$progetFeedUrl`"",
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
