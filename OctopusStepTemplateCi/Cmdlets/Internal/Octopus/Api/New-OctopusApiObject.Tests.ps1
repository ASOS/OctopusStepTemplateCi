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
    New-OctopusApiObject.Tests

.SYNOPSIS
    Pester tests for New-OctopusApiObject.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "New-OctopusApiObject" {

        $env:OctopusUri    = "http://example.local";
        $env:OctopusApiKey = "secret";

        Mock -CommandName "Invoke-WebRequest" `
             -MockWith { throw "Invoke-WebRequest should be mocked with a ParameterFilter!" };

        It "Should construct the uri based on the object type" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "http://example.local/api/UserDefined") -and ($Method -eq "POST") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            New-OctopusApiObject -ObjectUri "/api/UserDefined" -Object @{};

            Assert-VerifiableMock;

        }

        It "Should use the appropriate http method based on the type of request" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "http://example.local/api/UserDefined") -and ($Method -eq "POST") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            New-OctopusApiObject -ObjectUri "/api/UserDefined" -Object @{};

            Assert-VerifiableMock;

        }

    }

}