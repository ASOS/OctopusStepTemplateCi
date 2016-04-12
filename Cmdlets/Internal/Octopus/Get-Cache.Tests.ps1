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
	Get-Cache.Tests

.SYNOPSIS
	Pester tests for Get-Cache.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-Cache" {
	Set-Content "TestDrive:\TestModule.psm1" ". `"$here\$sut`""
	Get-Module TestModule | Remove-Module
	Import-Module "TestDrive:\TestModule.psm1"

	InModuleScope TestModule {
        It "Should return a hashtable that can be used as a cache" {
            Get-Cache | % GetType | % Name | Should Be "hashtable"
        }
    }
}
