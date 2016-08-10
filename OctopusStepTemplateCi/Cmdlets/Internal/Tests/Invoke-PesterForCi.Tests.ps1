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
	Invoke-PesterForCi.Tests

.SYNOPSIS
	Pester tests for Invoke-PesterForCi.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Update-XPathValue.ps1"
. "$here\..\TeamCity\Write-TeamCityMessage.ps1"

Describe "Invoke-PesterForCi" {
    It "Invokes pester with the provided arguments" {
        Mock Update-XPathValue {}
        Mock Write-TeamCityMessage {}
        Mock Invoke-Pester { @{PassedCount = 1; FailedCount = 1} } -ParameterFilter { $Script -eq "TestDrive:\test.Tests.ps1" -and $OutputFile -eq "TestDrive:\results.xml" } -Verifiable
        
        Invoke-PesterForCi -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml"
        
        Assert-VerifiableMocks
    }
    
    It "Should update the test name so it renders correctly in TeamCity" {
        Mock Update-XPathValue {} -ParameterFilter { $Path -eq "TestDrive:\results.xml" -and $XPath -eq '//test-results/test-suite/@name' -and $Value -eq "test" } -Verifiable
        Mock Write-TeamCityMessage {}
        Mock Invoke-Pester { @{PassedCount = 1; FailedCount = 1} }
        
        Invoke-PesterForCi -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml"
        
        Assert-VerifiableMocks
    }
    
    It "Should write out a teamcity message to import the test results file" {
        Mock Update-XPathValue {}
        Mock Write-TeamCityMessage {} -ParameterFilter { $Message -eq "##teamcity[importData type='nunit' path='TestDrive:\results.xml' verbose='true']" } -Verifiable
        Mock Invoke-Pester { @{PassedCount = 1; FailedCount = 1} }
        
        Invoke-PesterForCi -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml" -CiTool "TeamCity"
        
        Assert-VerifiableMocks
    }
    
    It "Should return a hashtable containing the passed and failed count" {
        Mock Update-XPathValue {}
        Mock Write-TeamCityMessage {} 
        Mock Invoke-Pester { @{PassedCount = 1; FailedCount = 1} }
        
        $results = Invoke-PesterForCi -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml"
        
        $results.Passed | Should Be 1
        $results.Failed | Should Be 1
    }
}
