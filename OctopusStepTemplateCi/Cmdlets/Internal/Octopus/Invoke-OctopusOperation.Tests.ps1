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
	Invoke-OctopusOperation.Tests

.SYNOPSIS
	Pester tests for Invoke-OctopusOperation.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

Describe "Invoke-OctopusOperation" {

    $env:OctopusUri    = "http://example.local";
    $env:OctopusApiKey = "secret";

    Mock -CommandName "Invoke-WebRequest" `
         -MockWith { return @{ "Content" = "" }; };

    Mock -CommandName "Get-Cache" `
         -MockWith { return @{}; };
    
    It "Should call Test-OctopusConnectivity" {

        Mock -CommandName "Test-OctopusConnectivity" `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;
        
        Invoke-OctopusOperation -Action "Get" -ObjectType "UserDefined";

        Assert-VerifiableMock;

    }
    
    It "Should construct the uri based on the object type" {

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets" } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { $Uri -eq "http://example.local/api/ActionTemplates" } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { $Uri -eq "http://example.local/custom" } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;
        
        Invoke-OctopusOperation -Action "New" -ObjectType "LibraryVariableSets";
        Invoke-OctopusOperation -Action "New" -ObjectType "ActionTemplates";
        Invoke-OctopusOperation -Action "New" -ObjectType "UserDefined" -ApiUri "custom";
        
        Assert-VerifiableMock;

    }
    
    It "Should include the id in get or update requests" {

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { ($Uri -eq "http://example.local/api/LibraryVariableSets/1") -and ($Method -eq "GET") } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { ($Uri -eq "http://example.local/api/ActionTemplates/2") -and ($Method -eq "PUT") } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Invoke-OctopusOperation -Action "Get" -ObjectType "LibraryVariableSets" -ObjectId "1";
        Invoke-OctopusOperation -Action "Update" -ObjectType "ActionTemplates" -ObjectId "2";

        Assert-VerifiableMock;

    }
    
    It "Should use the appropriate http method based on the type of request" {

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { ($Uri -eq "http://example.local/api/LibraryVariableSets/1") -and ($Method -eq "GET") } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { ($Uri -eq "http://example.local/api/ActionTemplates/2") -and ($Method -eq "PUT") } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { ($Uri -eq "http://example.local/custom") -and ($Method -eq "POST") } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Invoke-OctopusOperation -Action "Get" -ObjectType "LibraryVariableSets" -ObjectId "1";
        Invoke-OctopusOperation -Action "Update" -ObjectType "ActionTemplates" -ObjectId "2";
        Invoke-OctopusOperation -Action "New" -ObjectType "UserDefined" -ApiUri "custom";
        
        Assert-VerifiableMock;

    }
    
    It "Should add the object to the body of the request as JSON" {

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { $Body -eq "1" } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;

        Invoke-OctopusOperation -Action "New" -ObjectType "UserDefined" -ApiUri "custom" -Object 1;
        
        Assert-VerifiableMock;

    }
    
    It "Should use the cache if 'UseCache' is specified" {

        $cache = @{};

        Mock -CommandName "Get-Cache" `
             -MockWith { return $cache; } `
             -Verifiable;

        Mock -CommandName "Invoke-WebRequest" `
             -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets/1" } `
             -MockWith { return @{ "Content" = "" }; } `
             -Verifiable;
        
        Invoke-OctopusOperation -Action "Get" -ObjectType "LibraryVariableSets" -ObjectId "1" -UseCache;
        Invoke-OctopusOperation -Action "Get" -ObjectType "LibraryVariableSets" -ObjectId "1" -UseCache;
        
        Assert-VerifiableMock;

        $cache.Count | Should Be 1;
        Assert-MockCalled "Invoke-WebRequest" -Exactly 1 -Scope It;

    }

}

}