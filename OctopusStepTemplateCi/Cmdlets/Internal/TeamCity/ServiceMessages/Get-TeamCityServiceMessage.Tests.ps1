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
    Get-TeamCityServiceMessage.Tests

.SYNOPSIS
    Pester tests for Get-TeamCityServiceMessage
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-TeamCityEscapedString.ps1"

Describe "Get-TeamCityServiceMessage" {

    Context "when generating a single-attribute messages" {

        It "Should return a service message with no value" {
            $result = Get-TeamCityServiceMessage -MessageName "progressMessage";
            $result | Should Be "##teamcity[progressMessage '']";
        }

        It "Should return a service message with a null value" {
            $result = Get-TeamCityServiceMessage -MessageName "progressMessage" -Value $null;
            $result | Should Be "##teamcity[progressMessage '']";
        }

        It "Should return a service message with an empty string value" {
            $result = Get-TeamCityServiceMessage -MessageName "progressMessage" -Value "";
            $result | Should Be "##teamcity[progressMessage '']";
        }

        It "Should return a service message with a string value" {
            $result = Get-TeamCityServiceMessage -MessageName "progressMessage" -Value "my progress message";
            $result | Should Be "##teamcity[progressMessage 'my progress message']";
        }

        It "Should return a service message with a string value containing special characters" {
            $result = Get-TeamCityServiceMessage -MessageName "progressMessage" -Value "[my | progress ' message]";
            $result | Should Be "##teamcity[progressMessage '|[my || progress |' message|]']";
        }

    }

    Context "when generating a multiple-attribute messages" {

        It "Should return a service message with null values" {
            $result = Get-TeamCityServiceMessage -MessageName "blockOpened" -Values $null;
            $result | Should Be "##teamcity[blockOpened]";
        }

        It "Should return a service message with empty values" {
            $result = Get-TeamCityServiceMessage -MessageName "blockOpened" -Values @{};
            $result | Should Be "##teamcity[blockOpened]";
        }

        It "Should return a service message with one attribute" {
            $result = Get-TeamCityServiceMessage -MessageName "blockOpened" -Values @{ "name" = "myBlockName" };
            $result | Should Be "##teamcity[blockOpened name='myBlockName']";
        }

        It "Should return a service message with many attributes" {
            $result = Get-TeamCityServiceMessage -MessageName "myMessageName" -Values @{ "name1" = "value1"; "name2" = "value2"; "name3" = "value3" };
            $result | Should Be "##teamcity[myMessageName name1='value1' name2='value2' name3='value3']";
        }

        It "Should return a service message with attributes containing special characters" {
            $result = Get-TeamCityServiceMessage -MessageName "myMessageName" -Values @{ "name1" = "[value1]"; "name2" = "val'ue2"; "name3" = "value3" };
            $result | Should Be "##teamcity[myMessageName name1='|[value1|]' name2='val|'ue2' name3='value3']";
        }

    }

}
