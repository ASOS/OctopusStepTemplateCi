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
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Compare-Hashtable" {
    It "Should return false if they are the same" {
        Compare-Hashtable -ReferenceObject @{test = 1} -DifferenceObject @{test = 1} | Should Be $false
    }
    
    It "Should return true if the ref object has additional keys" {
        Compare-Hashtable -ReferenceObject @{test = 1; extra = 2} -DifferenceObject @{test = 1} | Should Be $true
    }
    
    It "Should return true if the diff object has additional keys" {
        Compare-Hashtable -ReferenceObject @{test = 1} -DifferenceObject @{test = 1; extra = 2} | Should Be $true
    }
    
    It "Should return true if the objects have the same key with different values" {
        Compare-Hashtable -ReferenceObject @{test = 1} -DifferenceObject @{test = 2} | Should Be $true
    }
    
    It "Should return false if the objects have a hashtable in them which is the same" {
        Compare-Hashtable -ReferenceObject @{test = @{test2 = 1}} -DifferenceObject @{test = @{test2 = 1}} | Should Be $false
    }
    
    It "Should return true if the objects have a hashtable in them which is different" {
        Compare-Hashtable -ReferenceObject @{test = @{test2 = 1}} -DifferenceObject @{test = @{test2 = 2}} | Should Be $true
    }
}
