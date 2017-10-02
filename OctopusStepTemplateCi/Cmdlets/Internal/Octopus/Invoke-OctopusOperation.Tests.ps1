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
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Test-OctopusConnectivity.ps1"
. "$here\ConvertTo-OctopusJson.ps1"
. "$here\Get-Cache.ps1"
. "$here\..\PowerShellManipulation\ParseJson.ps1"

Describe "Invoke-OctopusOperation" {
    Mock Invoke-WebRequest {}
    Mock ParseJsonString {}
    $Env:OctopusUri = "http://example.local"
    $Env:OctopusApiKey = "secret"
    Mock Get-Cache { @{} }
    
    It "Should call Test-OctopusConnectivity" {
        Mock Test-OctopusConnectivity {} -Verifiable
        
        Invoke-OctopusOperation -Action Get -ObjectType UserDefined
        
        Assert-VerifiableMocks
    }
    
    It "Should construct the uri based on the object type" {
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets" } -Verifiable
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/ActionTemplates" } -Verifiable
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/custom" } -Verifiable
        
        Invoke-OctopusOperation -Action New -ObjectType LibraryVariableSets
        Invoke-OctopusOperation -Action New -ObjectType ActionTemplates
        Invoke-OctopusOperation -Action New -ObjectType UserDefined -ApiUri "custom"
        
        Assert-VerifiableMocks
    }
    
    It "Should include the id in get or update requests" {
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets/1" } -Verifiable
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/ActionTemplates/2" } -Verifiable
        
        Invoke-OctopusOperation -Action Get -ObjectType LibraryVariableSets -ObjectId "1"
        Invoke-OctopusOperation -Action Update -ObjectType ActionTemplates -ObjectId "2"
        
        Assert-VerifiableMocks
    }
    
    It "Should use the appropriate http method based on the type of request" {
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets/1" -and $Method -eq "GET" } -Verifiable
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/ActionTemplates/2" -and $Method -eq "PUT" } -Verifiable
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/custom" -and $Method -eq "POST" } -Verifiable
        
        Invoke-OctopusOperation -Action Get -ObjectType LibraryVariableSets -ObjectId "1"
        Invoke-OctopusOperation -Action Update -ObjectType ActionTemplates -ObjectId "2"
        Invoke-OctopusOperation -Action New -ObjectType UserDefined -ApiUri "custom"
        
        Assert-VerifiableMocks
    }
    
    It "Should add the object to the body of the request as JSON" {
        Mock Invoke-WebRequest {} -ParameterFilter { $Body -eq "1" } -Verifiable
        Mock ConvertTo-OctopusJson { "1" } -ParameterFilter { $InputObject -eq 1 } -Verifiable
        
        Invoke-OctopusOperation -Action New -ObjectType UserDefined -ApiUri "custom" -Object 1
        
        Assert-VerifiableMocks
    }
    
    It "Should use the cache if 'UseCache' is specified" {
        $cache = @{}
        Mock Get-Cache { $cache } -Verifiable
        Mock Invoke-WebRequest {} -ParameterFilter { $Uri -eq "http://example.local/api/LibraryVariableSets/1" } -Verifiable
        
        Invoke-OctopusOperation -Action Get -ObjectType LibraryVariableSets -ObjectId "1" -UseCache
        Invoke-OctopusOperation -Action Get -ObjectType LibraryVariableSets -ObjectId "1" -UseCache
        
        Assert-VerifiableMocks
        $cache.Count | Should Be 1
        Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope It
    }
}
