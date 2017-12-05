param
(

    [string] $NuGet,
    [string] $NuGetFeedUrl,

    [string] $OctopusUri,
    [string] $OctopusApiKey,

    [string] $ScriptPath,

    [string] $StepTemplateFilter = "*.steptemplate.ps1",
    [string] $ScriptmoduleFilter = "*.scriptmodule.ps1"

)


$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


$thisScript   = $MyInvocation.MyCommand.Path;
$thisFolder   = [System.IO.Path]::GetDirectoryName($thisScript);
$rootFolder   = [System.IO.Path]::GetDirectoryName($thisFolder);
$packagesRoot = [System.IO.Path]::Combine($rootFolder, "packages");


. ([System.IO.Path]::Combine($thisFolder, "scripts\Invoke-NuGetInstall.ps1"));


Invoke-NuGetInstall -NuGet           $NuGet `
                    -Source          "https://www.powershellgallery.com/api/v2" `
                    -PackageId       "PSScriptAnalyzer" `
                    -OutputDirectory $packagesRoot `
                    -ExcludeVersion;

Invoke-NuGetInstall -NuGet           $NuGet `
                    -Source          "https://www.powershellgallery.com/api/v2" `
                    -PackageId       "Pester" `
                    -Version         "4.0.8" `
                    -OutputDirectory $packagesRoot `
                    -ExcludeVersion;

Invoke-NuGetInstall -NuGet           $NuGet `
                    -Source          $NuGetFeedUrl `
                    -PackageId       "OctopusStepTemplateCi" `
                    -OutputDirectory $packagesRoot `
                    -ExcludeVersion;


Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "PSScriptAnalyzer"))      -ErrorAction "Stop";
Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "Pester"))                -ErrorAction "Stop";
#Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "OctopusStepTemplateCi")) -ErrorAction "Stop";
Import-Module -Name ([System.IO.Path]::Combine($rootFolder, "OctopusStepTemplateCi"))   -ErrorAction "Stop";


if( -not [string]::IsNullOrEmpty($OctopusUri) )
{
    $env:OctopusUri = $OctopusUri;
}
if( -not [string]::IsNullOrEmpty($OctopusApiKey) )
{
    $env:OctopusApiKey = $OctopusApiKey;
}


Invoke-TeamCityCiUpload -Path               $ScriptPath `
                        -ProcessingMode     "Individual" `
                        -StepTemplateFilter $StepTemplateFilter `
                        -ScriptModuleFilter $ScriptModuleFilter `
                        -TestSettings @{
                            "PSScriptAnalyzer-Enabled"      = "True";
                            "PSScriptAnalyzer-ExcludeRules" = @(
                                "PSAvoidUsingWMICmdlet",
                                "PSAvoidUsingWriteHost",
                                "PSAvoidUsingPlainTextForPassword",
                                "PSAvoidUsingConvertToSecureStringWithPlainText",
                                "PSAvoidUsingUserNameAndPassWordParams",
                                "PSShouldProcess"
                            )
                        } `
                        -UploadIfSuccessful:$false `
                        -SuppressPesterOutput:$true;
