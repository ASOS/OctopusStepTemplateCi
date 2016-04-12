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
    TestNaming.Tests
    
.SYNOPSIS
    Pester tests for TestNaming.
#>
param ([System.String] $sut, [System.String] $TestResultsFile, [System.Collections.Hashtable]$Settings)
Set-StrictMode -Version Latest

Describe 'Test Naming' {
    $filename = Split-Path -Leaf $sut
    Context "Tests for '$filename' should have unique test names" {
        
        It "should have unique test names" {
            $doc = [xml](Get-Content $TestResultsFile)
            $nodes = $doc.SelectNodes('//test-results/test-suite/results/test-suite/results/test-case')
            if ($nodes -ne $null) {
                $duplicates = ($nodes.name | Group-Object | Where-Object {$_.count -gt 1} | Select-Object Name)

                if ($duplicates -ne $null) {                
                    "The following test names have duplicate 'Describe' and 'It' names, which under Pester 3, confuses TeamCity: $($duplicates.Name -join ',')" | Should be $null
                }
            }
        }
    }
}