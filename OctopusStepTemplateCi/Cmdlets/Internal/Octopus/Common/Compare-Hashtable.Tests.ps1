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
    Compare-Hashtable.Tests

.SYNOPSIS
    Pester tests for Compare-Hashtable.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

    Describe "Compare-Hashtable" {

        It "Should return `$null if both objects are null" {
            $result = Compare-Hashtable -ReferenceObject $null -DifferenceObject $null;
            $result | Should Be $null;
        }

        It "Should return `$null if reference object is null and difference object is an empty hashtable" {
            $result = Compare-Hashtable -ReferenceObject $null -DifferenceObject @{};
            $result | Should Be $null;
        }

        It "Should return `$null if reference object is an empty hashtable and difference object is null" {
            $result = Compare-Hashtable -ReferenceObject $null -DifferenceObject @{};
            $result | Should Be $null;
        }

        It "Should return `$null if reference object is an empty hashtable and difference object is an empty hashtable" {
            $result = Compare-Hashtable -ReferenceObject @{} -DifferenceObject @{};
            $result | Should Be $null;
        }

        It "Should return `$null if reference object is the same as difference object" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"="bbb";"ccc"="ddd"} -DifferenceObject @{"aaa"="bbb";"ccc"="ddd"};
            $result | Should Be $null;
        }

        It "Should return a result if reference object object has additional keys" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"="bbb";"ccc"="ddd"} -DifferenceObject @{"aaa"="bbb"};
            $result | Should Not Be $null;
            $result.Length | Should Be 1;
            $result[0].Key | Should Be "ccc";
            $result[0].Value | Should Be "ddd";
            $result[0].SideIndicator | Should Be "<=";
        }

        It "Should return a result if difference object object has additional keys" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"="bbb"} -DifferenceObject @{"aaa"="bbb";"ccc"="ddd"};
            $result | Should Not Be $null;
            $result.Length | Should Be 1;
            $result[0].Key | Should Be "ccc";
            $result[0].Value | Should Be "ddd";
            $result[0].SideIndicator | Should Be "=>";
        }
    
        It "Should return a result if the objects have the same key with different values" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"="bbb";"ccc"="ddd"} -DifferenceObject @{"aaa"="bbb";"ccc"="eee"};
            $result | Should Not Be $null;
            $result.Length | Should Be 2;
            $result[0].Key | Should Be "ccc";
            $result[0].Value | Should Be "eee";
            $result[0].SideIndicator | Should Be "=>";
            $result[1].Key | Should Be "ccc";
            $result[1].Value | Should Be "ddd";
            $result[1].SideIndicator | Should Be "<=";
        }

        It "Should return a result if reference object's entry value is null" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"=$null} -DifferenceObject @{"aaa"="bbb"};
            $result | Should Not Be $null;
            $result.Length | Should Be 2;
            $result[0].Key | Should Be "aaa";
            $result[0].Value | Should Be "bbb";
            $result[0].SideIndicator | Should Be "=>";
            $result[1].Key | Should Be "aaa";
            $result[1].Value | Should Be $null;
            $result[1].SideIndicator | Should Be "<=";
        }

        It "Should return a result if difference object's entry value is null" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"="bbb"} -DifferenceObject @{"aaa"=$null};
            $result | Should Not Be $null;
            $result.Length | Should Be 2;
            $result[0].Key | Should Be "aaa";
            $result[0].Value | Should Be $null;
            $result[0].SideIndicator | Should Be "=>";
            $result[1].Key | Should Be "aaa";
            $result[1].Value | Should Be "bbb";
            $result[1].SideIndicator | Should Be "<=";
        }

        It "Should return `$null if both object's entries are null" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"=$null} -DifferenceObject @{"aaa"=$null};
            $result | Should Be $null;
        }

        It "Should return `$null if both object's entries are empty nested hashtables" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"=@{}} -DifferenceObject @{"aaa"=@{}};
            $result | Should Be $null;
        }

        It "Should return `$null if both object's entries are populated nested hashtables" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"=@{"bbb"="ccc"}} -DifferenceObject @{"aaa"=@{"bbb"="ccc"}};
            $result | Should Be $null;
        }

        It "Should return a result if both object's entries are different nested hashtables" {
            $result = Compare-Hashtable -ReferenceObject @{"aaa"=@{"bbb"="ccc"}} -DifferenceObject @{"aaa"=@{"ddd"="eee"}};
            $result | Should Not Be $null;
            $result.Length | Should Be 2;
            $result[0].Key | Should Be "aaa";
            $result[0].Value.Count | Should Be 1;
            @($result[0].Value.Keys)[0] | Should Be "ddd";
            @($result[0].Value.Values)[0] | Should Be "eee";
            $result[0].SideIndicator | Should Be "=>";
            $result[1].Key | Should Be "aaa";
            $result[1].Value.Count | Should Be 1;
            @($result[1].Value.Keys)[0] | Should Be "bbb";
            @($result[1].Value.Values)[0] | Should Be "ccc";
            $result[1].SideIndicator | Should Be "<=";
        }

    }

}