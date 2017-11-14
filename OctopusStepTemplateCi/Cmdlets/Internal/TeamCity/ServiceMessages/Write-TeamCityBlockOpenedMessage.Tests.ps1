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
    Write-TeamCityBlockOpenedMessage.Tests

.SYNOPSIS
    Pester tests for Write-TeamCityBlockOpenedMessage.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Write-TeamCityBlockOpenedMessage" {

        Mock -CommandName "Write-Host" `
             -MockWith {
                 throw "write-host should not be called with (`$Object='$Object')";
             };

        It "Should write the message to the powershell host" {
            Mock -CommandName "Write-Host" `
                 -ParameterFilter { $Object -eq "##teamcity[blockOpened name='myBlock']" } `
                 -MockWith {} `
                 -Verifiable;
            Write-TeamCityBlockOpenedMessage -BlockName "myBlock";
            Assert-VerifiableMock;
        }

    }

}