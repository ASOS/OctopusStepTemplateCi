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
    New-ScriptModule
    
.SYNOPSIS
    Creates a new script module and test file

.DESCRIPTION
    To increase consistency between script modules this will create a script module powershell file and Pester test file
    with the necessary boilerplate code needed to function, these files can then be used as a starting point for new development.
    
.PARAMETER Name
    The name of the script module

.INPUTS
    None. You cannot pipe objects to New-ScriptModule.

.OUTPUTS
    None.
#>
function New-ScriptModule {
    [CmdletBinding()]
	[OutputType("System.String")]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][System.String]$Name,
        [Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ })][System.String]$Path = $PWD      
    )
     
    $fileName = Join-Path $Path ("{0}.scriptmodule.ps1" -f ($Name -replace '\s', '-'))
    $testFileName = [System.IO.Path]::ChangeExtension($fileName, "Tests.ps1")
      
    if (Test-Path $fileName) {
        throw "Script Module file '$fileName' already exists"
    }
    
    Set-Content -Path $fileName -Value @"
`$ScriptModuleName = "$Name"
`$ScriptModuleDescription = "$Name description"
Set-StrictMode -Version Latest

throw "Script Module not implemented"
"@

    Set-Content -Path $testFileName -Value @"
Set-StrictMode -Version Latest
`$here = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$sut = (Split-Path -Leaf `$MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "`$here\`$sut"

Describe "$Name" {
    It "does something useful" {
        `$true | Should Be `$false
    }
}
"@

@"
New Script Module File created: $fileName
Script Module test file: $testFileName
"@
}