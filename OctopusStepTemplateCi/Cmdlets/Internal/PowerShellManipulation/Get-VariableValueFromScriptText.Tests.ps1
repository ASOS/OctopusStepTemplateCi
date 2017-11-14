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
    Get-VariableValueFromScriptText.Tests

.SYNOPSIS
    Pester tests for Get-VariableValueFromScriptText.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

Describe "Get-VariableValueFromScriptText" {

    It "Should return the value when the variable is `$null" {
        $script = @'
function test {
    $myTestVariable = $null;
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be $null;
    }

    It "Should return the value when the variable is `$true" {
        $script = @'
function test {
    $myTestVariable = $true;
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be $true;
    }

    It "Should return the value when the variable is a `$false" {
        $script = @'
function test {
    $myTestVariable = $false;
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be $false;
    }

    It "Should return the value when the variable is a positive integer" {
        $script = @'
function test {
    $myTestVariable = 100;
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be 100;
    }

    It "Should return the value when the variable is a negative integer" {
        $script = @'
function test {
    $myTestVariable = -100;
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be -100;
    }

    It "Should return the value when the variable is an empty string" {
        $script = @'
function test {
    $myTestVariable = "";
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be "";
    }

    It "Should return the value when the variable is a simple string" {
        $script = @'
function test {
    $myTestVariable = "my string";
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be "my string";
    }

    It "Should return the value when the variable is a simple string concatenation" {
        $script = @'
function test {
    $myTestVariable = "my" + " " + "string";
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        $actual | Should Be "my string";
    }

    It "Should return the value when the variable is an empty array" {
        $script = @'
function test {
    $myTestVariable = @();
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [array];
        $actual.Length | Should Be 0;
    }

    It "Should return the value when the variable is an array with a single item" {
        $script = @'
function test {
    $myTestVariable = @( 100 );
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [array];
        $actual.Length | Should Be 1;
        $actual[0] | Should Be 100;
    }

    It "Should return the value when the variable is an array with multiple items" {
        $script = @'
function test {
    $myTestVariable = @( $null, 100, "my string" );
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [array];
        $actual.Length | Should Be 3;
        $actual[0] | Should Be $null;
        $actual[1] | Should Be 100;
        $actual[2] | Should Be "my string";
    }

    It "Should return the value when the variable is an array with missing commas" {
        $script = @'
function test {
    $myTestVariable = @(
        $null,
        100 # <-- look no comma!
        "my string"
    );
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [array];
        $actual.Length | Should Be 3;
        $actual[0] | Should Be $null;
        $actual[1] | Should Be 100;
        $actual[2] | Should Be "my string";
    }

    It "Should return the value when the variable is an empty hashtable" {
        $script = @'
function test {
    $myTestVariable = @{};
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [hashtable];
        $actual.Count | Should Be 0;
    }

    It "Should return the value when the variable is a hashtable with a single item" {
        $script = @'
function test {
    $myTestVariable = @{ "myKey" = 100 };
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [hashtable];
        $actual.Count | Should Be 1;
        $actual["myKey"] | Should Be 100;
    }

    It "Should return the value when the variable is a hashtable with multiple items" {
$script = @'
function test {
    $myTestVariable = @{ "myKey1" = $null; "myKey2" = 100; "myKey3" = "my string" };
    Write-Host $myTestVariable;
}
'@
        $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myTestVariable";
        @(,$actual) | Should Not Be $null;
        @(,$actual) | Should BeOfType [hashtable];
        $actual.Count | Should Be 3;
        $actual["myKey1"] | Should Be $null;
        $actual["myKey2"] | Should Be 100;
        $actual["myKey3"] | Should Be "my string";
    }

    It "Should throw an exception when the variable isn't defined" {
        $script = @'
function test {
    $myTestVariable = "some value";
    Write-Host $myTestVariable;
}
'@
        {
           $actual = Get-VariableValueFromScriptText -Script $script -VariableName "myUndefinedVariable";
        } | Should Throw "Assignment statement for variable '`$myUndefinedVariable' could not be found in the specified script.";
    }

}

}