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
    Reset-BuildOutputDirectory.Tests

.SYNOPSIS
    Pester tests for Reset-BuildOutputDirectory.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Reset-BuildOutputDirectory" {

        It "Should create a new directory in the specified location" {
            Reset-BuildOutputDirectory -Path "TestDrive:\test";
            Test-Path "TestDrive:\test" | Should Be $true;
        }

        It "Should delete the files within the directory if it already exists" {
            New-Item -Path "TestDrive:\existing\" -Type Directory | Out-Null;
            Set-Content "TestDrive:\existing\existing file.txt" "test file";
            Reset-BuildOutputDirectory -Path "TestDrive:\existing";
            Get-ChildItem -Path "TestDrive:\existing" | Measure-Object | % Count | Should Be 0;
        }

    }

}