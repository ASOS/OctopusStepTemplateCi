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
	Convert-PSObjectToHashTable.Tests

.SYNOPSIS
	Pester tests for Convert-PSObjectToHashTable.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Convert-PSObjectToHashTable" {
    It "Should return a hashtable" {
       Convert-PSObjectToHashTable -InputObject (New-Object -TypeName PSObject -Property (@{test = 1})) | % GetType | % Name | Should Be 'hashtable'
    }
    
    It "Should convert all the properties into the hashtable" {
       Convert-PSObjectToHashTable -InputObject (New-Object -TypeName PSObject -Property (@{test = 1})) | % test | Should Be 1
    }
}
