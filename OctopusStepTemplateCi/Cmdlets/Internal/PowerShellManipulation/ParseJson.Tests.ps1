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
	ParseJson.Tests

.SYNOPSIS
	Pester tests for ParseJson
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

$jsonObjectTestData = @"
{
    "foo": {
        "bar": "foobar"
    }
}
"@

$jsonArrayTestData = @"
[
    {
        "foo": {
            "bar": "foobar"
        }
    },
    {
        "bar": {
            "foo": "barfoo"
        }
    }
]
"@

Describe "ParseJson" {

    It "should convert a null value" {
        $result = ParseJsonString -json "null";
        $result | Should Be $null;
    }

    It "should convert an empty string" {
        $result = ParseJsonString -json "{ `"DefaultValue`" : `"`" }";
        $result.DefaultValue | Should Be "";
    }

    It "should convert an empty array" {
        $result = ParseJsonString -json "[]";
        # n.b. using pipeline with sacrificial array because it unrolls arrays
        @(,$result) | Should BeOfType [System.Array];
        $result.Length | Should Be 0;
    }

    It "should convert a populated array" {
        $result = ParseJsonString -json "[10, 20, 30, 40]";
        # n.b. using pipeline with sacrificial array because it unrolls arrays
        @(,$result) | Should BeOfType [System.Array];
        $result.Length | Should Be 4;
        $result[0]     | Should Be 10;
        $result[1]     | Should Be 20;
        $result[2]     | Should Be 30;
        $result[3]     | Should Be 40;
    }

    Context "When not using the pipeline" {

        $res_obj = ParseJsonString -json $jsonObjectTestData

        It "should return a PSObject" {
            $res_obj | Should BeOfType PSCustomObject
        }

        It "should handle a JSON Object document" {
            ($res_obj | Get-Member).Name -icontains 'foo' | Should Be $true
            $res_obj.foo.bar | Should Be 'foobar'
        }

        It "should handle a JSON Array document" {
            $res_arr = ParseJsonString -json $jsonArrayTestData
            $res_arr.Count | Should Be 2
            ($res_arr[1] | Get-Member).Name -icontains 'bar' | Should Be $true
            $res_arr[1].bar.foo | Should Be 'barfoo'
        }

    }
    
    Context "When using the pipeline" {

        It "should return a PSObject" {
            $jsonObjectTestData | ParseJsonString | Should BeOfType PSCustomObject
        }

        It "should handle a JSON Object document" {
            ($jsonObjectTestData | ParseJsonString | Get-Member).Name -icontains 'foo' | Should Be $true
            ($jsonObjectTestData | ParseJsonString).foo.bar | Should Be 'foobar'
        }

        It "should handle a JSON Array document" {
            ($jsonArrayTestData | ParseJsonString).Count | Should Be 2
            (($jsonArrayTestData | ParseJsonString)[1] | Get-Member).Name -icontains 'bar' | Should Be $true
            ($jsonArrayTestData | ParseJsonString)[1].bar.foo | Should Be 'barfoo'
        }

    }

}