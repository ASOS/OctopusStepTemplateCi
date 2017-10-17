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
	Invoke-PesterForTeamCity.Tests

.SYNOPSIS
	Pester tests for Invoke-PesterForTeamCity.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Update-XPathValue.ps1"
. "$here\..\TeamCity\ServiceMessages\Get-TeamCityEscapedString.ps1"
. "$here\..\TeamCity\ServiceMessages\Get-TeamCityServiceMessage.ps1"
. "$here\..\TeamCity\ServiceMessages\Write-TeamCityBuildLogMessage.ps1"
. "$here\..\TeamCity\ServiceMessages\Write-TeamCityImportDataMessage.ps1"
. "$here\..\TeamCity\ServiceMessages\Write-TeamCityServiceMessage.ps1"

Describe "Invoke-PesterForTeamCity" {

    Mock -CommandName "Write-TeamCityBuildLogMessage" `
         -MockWith {
              throw "Write-TeamCityBuildLogMessage should not be called with `$Message = '$Message'";
         };

    Context "validate that parameters are passed to Pester correctly" {

        Mock -CommandName "Invoke-Pester" `
             -ParameterFilter { $Script -eq "TestDrive:\test.Tests.ps1" -and $OutputFile -eq "TestDrive:\results.xml" } `
             -MockWith { return @{ "PassedCount" = 1; "FailedCount" = 1 }; } `
             -Verifiable;

        Mock -CommandName "Update-XPathValue" `
             -MockWith {} `
             -Verifiable;

        Mock -CommandName "Write-TeamCityImportDataMessage" `
             -ParameterFilter { ($Type -eq "nunit") -and ($Path -eq "TestDrive:\results.xml") -and ($VerboseMessage -eq $true) } `
             -MockWith {} `
             -Verifiable;

        It "Invokes pester with the provided arguments" {
            $result = Invoke-PesterForTeamCity -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml";
            Assert-VerifiableMocks;
        }

    }

    Context "validate that the test name is updated for TeamCity" {

        Mock -CommandName "Invoke-Pester" `
	     -MockWith { return @{ "PassedCount" = 1; "FailedCount" = 1 }; };

        Mock -CommandName "Update-XPathValue" `
             -ParameterFilter { ($Path -eq "TestDrive:\results.xml") -and ($XPath -eq '//test-results/test-suite/@name') -and ($Value -eq "test") } `
             -MockWith {} `
             -Verifiable;

        Mock -CommandName "Write-TeamCityImportDataMessage" `
             -ParameterFilter { ($Type -eq "nunit") -and ($Path -eq "TestDrive:\results.xml") -and ($VerboseMessage -eq $true) } `
             -MockWith {} `
             -Verifiable;

        It "Should update the test name so it renders correctly in TeamCity" {
            $result = Invoke-PesterForTeamCity -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml";
            Assert-VerifiableMocks;
        }

    }

    Context "validate that a TeamCity importData message is written" {

        Mock -CommandName "Invoke-Pester" `
             -MockWith { return @{ "PassedCount" = 1; "FailedCount" = 1 }; };

        Mock -CommandName "Update-XPathValue" `
             -MockWith {};

        Mock -CommandName "Write-TeamCityImportDataMessage" `
             -ParameterFilter { ($Type -eq "nunit") -and ($Path -eq "TestDrive:\results.xml") -and ($VerboseMessage -eq $true) } `
             -MockWith {} `
             -Verifiable;

        It "Should write out a teamcity message to import the test results file" {
            $result = Invoke-PesterForTeamCity -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml";
            Assert-VerifiableMocks;
        }

    }

    Context "validate that the return value is correct" {

        Mock -CommandName "Invoke-Pester" `
             -MockWith { return @{ "PassedCount" = 1; "FailedCount" = 1 }; };

        Mock -CommandName "Update-XPathValue" `
             -MockWith {};

        Mock -CommandName "Write-TeamCityImportDataMessage" `
             -ParameterFilter { ($Type -eq "nunit") -and ($Path -eq "TestDrive:\results.xml") -and ($VerboseMessage -eq $true) } `
             -MockWith {} `
             -Verifiable;

        It "Should return a hashtable containing the passed and failed count" {
            $results = Invoke-PesterForTeamCity -TestName "test" -Script "TestDrive:\test.Tests.ps1" -TestResultsFile "TestDrive:\results.xml";
            $results.Passed | Should Be 1;
            $results.Failed | Should Be 1;
            Assert-VerifiableMocks;
        }

    }

}
