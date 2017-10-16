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
    Get-TeamCityEscapedString.Tests

.SYNOPSIS
    Pester tests for Get-TeamCityEscapedString.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-TeamCityEscapedString" {

    It "Should escape a null value" {
        $result = Get-TeamCityEscapedString -Value $null;
        $result | Should Be "";
    }

    It "Should escape an empty string" {
        $result = Get-TeamCityEscapedString -Value "";
        $result | Should Be "";
    }

    It "Should escape a string containing no special characters" {
        $result = Get-TeamCityEscapedString -Value "my string";
        $result | Should Be "my string";
    }

    It "Should escape a string containing special characters" {
        $result = Get-TeamCityEscapedString -Value "my | string [ with ] special ' characters `r and `n line `n breaks";
        $result | Should Be "my || string |[ with |] special |' characters |r and |n line |n breaks";
    }

}
