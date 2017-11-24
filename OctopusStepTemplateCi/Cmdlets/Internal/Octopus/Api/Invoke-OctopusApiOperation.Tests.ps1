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
    Invoke-OctopusApiOperation.Tests

.SYNOPSIS
    Pester tests for Invoke-OctopusApiOperation.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Invoke-OctopusApiOperation" {

        $env:OctopusUri    = "http://example.local";
        $env:OctopusApiKey = "secret";

        Mock -CommandName "Invoke-WebRequest" `
             -MockWith { return @{ "Content" = "" }; };

        Mock -CommandName "Get-OctopusApiCache" `
             -MockWith { return @{}; };

        It "Should call Test-OctopusApiConnectivity" {

            Mock -CommandName "Test-OctopusApiConnectivity" `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Invoke-OctopusApiOperation -Method "GET" -Uri "/api/UserDefined";

            Assert-VerifiableMock;

        }

        It "Should construct the uri based on the object type" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets/100" } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { $Uri -eq "http://example.local/api/ActionTemplates/200" } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { $Uri -eq "http://example.local/api/custom" } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Invoke-OctopusApiOperation -Method "GET" -Uri "/api/LibraryVariableSets/100";
            Invoke-OctopusApiOperation -Method "GET" -Uri "/api/ActionTemplates/200";
            Invoke-OctopusApiOperation -Method "GET" -Uri "/api/custom";

            Assert-VerifiableMock;

        }

        It "Should use the appropriate http method based on the type of request" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "http://example.local/api/LibraryVariableSets/100") -and ($Method -eq "GET") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "http://example.local/api/ActionTemplates/200") -and ($Method -eq "PUT") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { ($Uri -eq "http://example.local/custom") -and ($Method -eq "POST") } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Invoke-OctopusApiOperation -Method "GET"  -Uri "/api/LibraryVariableSets/100";
            Invoke-OctopusApiOperation -Method "PUT"  -Uri "/api/ActionTemplates/200" -Body 200;
            Invoke-OctopusApiOperation -Method "POST" -Uri "/custom";

            Assert-VerifiableMock;

        }

        It "Should add the object to the body of the request as JSON" {

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { $Body -eq "100" } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Invoke-OctopusApiOperation -Method "POST" -Uri "/api/UserDefined" -Body 100;

            Assert-VerifiableMock;

        }

        It "Should use the cache if 'UseCache' is specified" {

            $cache = @{};

            Mock -CommandName "Get-OctopusApiCache" `
                 -MockWith { return $cache; } `
                 -Verifiable;

            Mock -CommandName "Invoke-WebRequest" `
                 -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets/100" } `
                 -MockWith { return @{ "Content" = "" }; } `
                 -Verifiable;

            Invoke-OctopusApiOperation -Method "GET" -Uri "/api/LibraryVariableSets/100" -UseCache;
            Invoke-OctopusApiOperation -Method "GET" -Uri "/api/LibraryVariableSets/100" -UseCache;

            Assert-VerifiableMock;

            $cache.Count | Should Be 1;
            $cache.Keys[0] | Should Be "http://example.local/api/LibraryVariableSets/100-GET";

            Assert-MockCalled "Invoke-WebRequest" -Exactly 1 -Scope It;

        }

    }

}