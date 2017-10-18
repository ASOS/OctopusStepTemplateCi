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
    Write-TeamCityBuildLogMessage.Tests

.SYNOPSIS
    Pester tests for Write-TeamCityBuildLogMessage.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-TeamCityEscapedString.ps1"
. "$here\Write-TeamCityBuildLogMessage.ps1"

Describe "Write-TeamCityBuildLogMessage" {

    Mock -CommandName "Write-Host" `
         -MockWith {
             throw "write-host should not be called with (`$Object='$Object')";
         };

    It "Should write the message to the powershell host" {
        Mock -CommandName "Write-Host" `
             -ParameterFilter { $Object -eq "##teamcity[buildStatus text='my message']" } `
             -MockWith {} `
             -Verifiable;
        Write-TeamCityBuildLogMessage -Message "##teamcity[buildStatus text='my message']";
        Assert-VerifiableMock;
    }

    It "Should write error messages to the powershell host in a red colour" {
        Mock -CommandName "Write-Host" `
             -ParameterFilter { ($Object -eq "##teamcity[Error '']") -and ($ForegroundColor -eq "Red") } `
             -MockWith {} `
             -Verifiable;
        Write-TeamCityBuildLogMessage -Message "##teamcity[Error '']" -ErrorMessage;
        Assert-VerifiableMock;
    }

}
