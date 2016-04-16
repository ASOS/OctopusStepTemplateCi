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
    New-ScriptValidationTest
    
.SYNOPSIS
    Creates a new script validation test file

.DESCRIPTION
    To increase consistency between script validation tests this will create a script validation test powershell file
    with the necessary boilerplate code needed to function, this file can then be used as a starting point for new development.
    
.PARAMETER Name
    The name of the script validation test

.INPUTS
    None. You cannot pipe objects to New-ScriptValidationTest.

.OUTPUTS
    None.
#>
function New-ScriptValidationTest {
    [CmdletBinding()]
    [OutputType("System.String")]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.String]$Name,
        [Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][System.String]$Path = $PWD
    )
    
    $fileName = Join-Path $Path ("{0}.ScriptValidationTest.ps1" -f ($Name -replace '\s', '-'))
    
    if (Test-Path $fileName) {
        throw "Script Validation Test file '$fileName' already exists"
    }
    
    Set-Content -Path $fileName -Value @"
param ([System.String] `$sut, [System.String] `$TestResultsFile, [System.Collections.Hashtable]`$TestSettings)
Set-StrictMode -Version Latest

Describe "$Name" {
    `$filename = Split-Path -Leaf `$sut
    
    It "does something useful" {
        `$true | Should Be `$false
    }
}
"@
    
@"
New Script Validation Test File created: $fileName
"@
}