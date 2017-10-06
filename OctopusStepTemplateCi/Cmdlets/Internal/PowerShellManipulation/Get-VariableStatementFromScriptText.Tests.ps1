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
    Get-VariableStatementFromScriptText.Tests

.SYNOPSIS
    Pester tests for Get-VariableStatementFromScriptText.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-VariableStatementFromScriptText" {

    It "Should return the variable statement from a powershell script" {
        $script = @'
function test {
    $myTestVariable = "some value";
    Write-Host $myTestVariable;
}
'@
        $result = Get-VariableStatementFromScriptText -Script $script -VariableName "myTestVariable" -Type "Statement";
        $result | Should Be "`$myTestVariable = `"some value`"";
    }
    
    It "Should return the value of the variable statement from a powershell script" {
        $script = @'
function test {
    $myTestVariable = "some value";
    Write-Host $myTestVariable;
}
'@
        $result = Get-VariableStatementFromScriptText -Script $script -VariableName "myTestVariable" -Type "Value";
        $result | Should Be "`"some value`"" ;
    }
    
    It "Should return nothing if the variable isn't defined" {
        $script = @'
function test {
    $myTestVariable = "some value";
    Write-Host $myTestVariable;
}
'@
        $result = Get-VariableStatementFromScriptText -Script $script -VariableName "myUndefinedVariable" -Type "Value";
        $result | Should Be $null;
    }
}
