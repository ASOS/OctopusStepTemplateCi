param
(

    [string] $NuGet,
    [string] $NuGetFeedUrl,

    [string] $OctopusUri,
    [string] $OctopusApiKey,

    [string] $ScriptPath,

    [string] $StepTemplateFilter = "*.steptemplate.ps1",
    [string] $ScriptModuleFilter = "*.scriptmodule.ps1"

)


$ErrorActionPreference = "Stop";
$ProgressPreference = "SilentlyContinue";
Set-StrictMode -Version "Latest";


write-host "powershell version = ";
write-host ($PSVersionTable | ft -AutoSize | out-string);


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

Invoke-NuGetInstall -NuGet           $NuGet `
                    -Source          $NuGetFeedUrl `
                    -PackageId       "OctopusStepTemplateCi" `
                    -OutputDirectory $packagesRoot `
                    -ExcludeVersion;


Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "PSScriptAnalyzer.1.17.1\PSScriptAnalyzer.psd1")) -ErrorAction "Stop";
Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "Pester.4.3.1\Pester.psd1")) -ErrorAction "Stop";
Import-Module -Name ([System.IO.Path]::Combine($packagesRoot, "OctopusStepTemplateCi\OctopusStepTemplateCi.psd1")) -ErrorAction "Stop";


if( -not [string]::IsNullOrEmpty($OctopusUri) )
{
    $env:OctopusUri = $OctopusUri;
}
if( -not [string]::IsNullOrEmpty($OctopusApiKey) )
{
    $env:OctopusApiKey = $OctopusApiKey;
}


write-host "modules loaded at start of script = ";
$modules = Get-Module;
write-host ($modules | ft -AutoSize | out-string);


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
                        -UploadIfSuccessful:$true `
                        -SuppressPesterOutput:$false;


write-host "modules loaded at end of script = ";
$modules = Get-Module;
write-host ($modules | ft -AutoSize | out-string);
