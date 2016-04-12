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
    New-ScriptModule.Tests
    
.SYNOPSIS
    Pester tests for New-ScriptModule
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-ScriptModule" {
   It "Should throw an exception if the script module already exists" {
       New-Item "TestDrive:\test.scriptmodule.ps1" -ItemType File | Out-Null
       
       { New-ScriptModule -Name "test" -Path "TestDrive:\" } | Should Throw
   }
   
   It "Should create a new script module file" {
       New-ScriptModule -Name "test1" -Path "TestDrive:\"
       
       "TestDrive:\test1.scriptmodule.ps1" | Should Exist
   }
   
   It "Should create a test file for the sccript module" {
       New-ScriptModule -Name "test2" -Path "TestDrive:\"
       
       "TestDrive:\test2.scriptmodule.Tests.ps1" | Should Exist
   }
   
   It "Should output a message to the user" {
       New-ScriptModule -Name "test3" -Path "TestDrive:\" | % GetType | % Name | Should Be "String"
   }
}