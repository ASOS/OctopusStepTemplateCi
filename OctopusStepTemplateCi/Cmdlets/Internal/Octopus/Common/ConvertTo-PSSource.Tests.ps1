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

Describe "ConvertTo-PSSource" {

    It "when InputObject is null" {
        $input    = $null;
        $expected = "`$null";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is `$true" {
        $input    = $true;
        $expected = "`$true";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is `$false" {
        $input    = $false;
        $expected = "`$false";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty string" {
        $input    = [string]::Empty;
        $expected = "`"`"";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a simple string" {
        $input    = "my simple string";
        $expected = "`"my simple string`"";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string with apostrophes" {
        $input    = "my string with 'apostrophes'";
        $expected = "`"my string with 'apostrophes'`"";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string with special characters" {
        $input    = "my \ `"string`" with `r`n special `t characters";
        $expected = "`"my \ ```"string```" with ``r``n special ``t characters`"";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string with whitespace between curly brackets" {
        $input    = "{    }";
        $expected = "`"{    }`"";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string resembling the json escape sequence for an apostrophe" {
        $input    = "\u0027";
        $expected = "`"\u0027`"";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a positive integer" {
        $input    = 100;
        $expected = "100";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a negative integer" {
        $input    = -100;
        $expected = "-100";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty array" {
        $input    = @();
        $expected = "@()";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a populated array" {
        $input    = @( $null, 100, "my string" );
        $expected = "@(`r`n    `$null,`r`n    100,`r`n    `"my string`"`r`n)";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty hashtable" {
        $input    = @{};
        $expected = "@{}";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a populated hashtable" {
        $input    = @{
            "myNull"     = $null
            "myInt"      = 100
            "myString"   = "text"
	    "myArray"    = @( $null, 200, "string", [PSCustomObject] [ordered] @{ "nestedProperty" = "nestedValue" } )
	    "myPsObject" = [PSCustomObject] [ordered] @{ "childProperty" = "childValue" }
        };
        $expected = @'
@{
    "myArray" = @(
        $null,
        200,
        "string",
        new-object PSCustomObject -Property ([ordered] @{
            "nestedProperty" = "nestedValue"
        })
    )
    "myInt" = 100
    "myNull" = $null
    "myPsObject" = new-object PSCustomObject -Property ([ordered] @{
        "childProperty" = "childValue"
    })
    "myString" = "text"
}
'@
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty PSCustomObject" {
	$input    = new-object PSCustomObject;
        $expected = "new-object PSCustomObject";
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a populated PSCustomObject" {
	$input    = [PSCustomObject] [ordered] @{
            "myNull"     = $null
            "myInt"      = 100
            "myString"   = "text"
	    "myArray"    = @( $null, 200, "string", [PSCustomObject] [ordered] @{ "nestedProperty" = "nestedValue" } )
	    "myPsObject" = [PSCustomObject] [ordered] @{ "childProperty" = "childValue" }
	};
        $expected = @'
new-object PSCustomObject -Property ([ordered] @{
    "myNull" = $null
    "myInt" = 100
    "myString" = "text"
    "myArray" = @(
        $null,
        200,
        "string",
        new-object PSCustomObject -Property ([ordered] @{
            "nestedProperty" = "nestedValue"
        })
    )
    "myPsObject" = new-object PSCustomObject -Property ([ordered] @{
        "childProperty" = "childValue"
    })
})
'@
        # normalize line breaks in "$expected" here-string in case they get mangled on git commit
        if( $expected.IndexOf("`r`n") -eq -1 ) { $expected = $expected.Replace("`n", "`r`n"); }
        ConvertTo-PSSource -InputObject $input `
            | Should Be $expected;
    }

}