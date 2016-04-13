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
    Parameters.Tests
    
.SYNOPSIS
    Pester tests for Parameters.
#>
param ([System.String] $sut, [System.String] $TestResultsFile, [System.Collections.Hashtable]$Settings)
Set-StrictMode -Version Latest

Describe 'Script Module parameters' {
 	Context "Script Module contains metadata parameters" {
        $filename = Split-Path -Leaf $sut

		It "Script Module '$filename' should contain metadata variable `$ScriptModuleName" {
			{ Get-VariableFromScriptFile $sut "ScriptModuleName" } | Should Not Throw
		}

        It "Script Module '$filename' should contain metadata variable `$ScriptModuleDescription" {
			{ Get-VariableFromScriptFile $sut "ScriptModuleDescription" } | Should Not Throw
		}
    }
}