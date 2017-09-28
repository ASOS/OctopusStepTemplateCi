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
  Convert-HashTableToPsCustomObject.Tests
.SYNOPSIS
  Pester tests for Convert-HashTableToPsCustomObject.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Convert-HashTableToPsCustomObject" {

    It "Should return a PS custom object" {
       Convert-HashTableToPsCustomObject -InputObject @{'Name' = 'Test'} | % GetType | % Name | Should Be 'PSCustomObject'
    }

    It "Should convert all the properties into the PS custom object" {
       (Convert-HashTableToPsCustomObject -InputObject @{'Name' = 'Test'; 'Description' = 'Test'} | gm | ? {$_.MemberType -eq 'NoteProperty'}).Count| Should Be 2
    }

    It "Should return an error if a hashtable is not the input object" {
        { Convert-HashTableToPsCustomObject -InputObject (New-Object -TypeName PSObject -Property (@{test = 1})) } `
            | Should Throw "Object is not a hashtable"
    }

}
