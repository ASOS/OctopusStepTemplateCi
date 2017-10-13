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

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "ConvertFrom-OctopusJson" {

    It "when InputObject is a null json string" {
        $input    = "null";
        $expected = $null;
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is an empty string" {
        $input    = "`"`"";
        $expected = [string]::Empty;
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a simple string" {
        $input    = "`"my simple string`"";
        $expected = "my simple string";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a string with apostrophes" {
        $input    = "`"my string with 'apostrophes'`"";
        $expected = "my string with 'apostrophes'";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a string with special characters" {
        $input    = "`"my \\ \`"string\`" with \r\n special \t characters`"";
        $expected = "my \ `"string`" with `r`n special `t characters";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a string with whitespace between curly brackets" {
        $input    = "`"{    }`"";
        $expected = "{    }";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a string resembling the json escape sequence for an apostrophe" {
        $input    = "`"\\u0027`"";
        $expected = "\u0027";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a positive integer" {
        $input    = "100";
        $expected = 100;
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is a negative integer" {
        $input    = "-100";
        $expected = -100;
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should Be $expected;
    }

    It "when InputObject is an empty array" {
        $input    = "[]";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [array];
        $actual.Length | Should Be 0;
    }

    It "when InputObject is a populated array" {
        $input    = "[`r`n  null,`r`n  100,`r`n  `"my string`"`r`n]";
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [array];
        $actual.Length | Should Be 3;
        $actual[0] | Should Be $null;
        $actual[1] | Should Be 100;
        $actual[2] | Should Be "my string";
    }

    It "when InputObject is an empty json object" {
        $input    = "{}";
        $expected = @{};
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should BeOfType [hashtable];
        $actual.Count | Should Be 0;
    }

    It "when InputObject is a nested json object" {
        $input    = @'
{
    "myNull"   : null,
    "myInt"    : 100,
    "myString" : "text",
    "myArray"  : [ null, 200, "string" ],
    "myObject" : { "childProperty" : "childValue" }
}
'@;
        $actual = ConvertFrom-OctopusJson -InputObject $input;
        $actual | Should BeOfType [hashtable];
        $actual.Count | Should Be 5;
        $actual["myNull"] | Should Be $null;
        $actual["myInt"] | Should Be 100;
        $actual["myString"] | Should Be "text";
        @(,$actual["myArray"]) | Should BeOfType [array];
        $actual["myArray"].Length | Should Be 3;
        $actual["myArray"][0] | Should Be $null;
        $actual["myArray"][1] | Should Be 200;
        $actual["myArray"][2] | Should Be "string";
        $actual["myObject"] | Should BeOfType [hashtable];
        $actual["myObject"]["childProperty"] | Should Be "childValue";
    }

    It "when InputObject is invalid json" {
        { $actual = ConvertFrom-OctopusJson -InputObject "!!!!!"; } `
            | Should Throw;
    }

}
