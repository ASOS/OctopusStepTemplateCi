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
    Get-ScriptBodyFromScriptFile.Tests

.SYNOPSIS
    Pester tests for Get-ScriptBodyFromScriptFile.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-ScriptBodyFromScriptText.ps1"
. "$here\Get-VariableStatementFromScriptFile.ps1"
. "$here\Get-VariableStatementFromScriptText.ps1"

Describe "Get-ScriptBodyFromScriptFile" {

    Context "Script module" {

        BeforeEach {
            $tempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), "scriptmodule.ps1") # Cant use the testdrive as $doc.Save($Path) doesn't support 'TestDrive:\'
            Set-Content $tempFile @"
function test {
    `$ScriptModuleName = 'name'
    `$ScriptModuleDescription = 'description'
}
"@
        }

        AfterEach {
            Remove-Item $tempFile
        }

        It "Removes the StepTemplateName, StepTemplateDescription, StepTemplateParameters variables from the script" {
            Get-ScriptBodyFromScriptFile -Path $tempFile | % Replace "`n" "" | % Replace "`r" "" | % Replace " " "" | Should Be "functiontest{}"
        } 

    }

    Context "Step template" {

        BeforeEach {
        $tempFile = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), "steptemplate.ps1") # Cant use the testdrive as $doc.Save($Path) doesn't support 'TestDrive:\'
        Set-Content $tempFile @"
function test {
    `$StepTemplateName = 'name'
    `$StepTemplateDescription = 'description'
    `$StepTemplateParameters = 'parameters'
}
"@
        }

        AfterEach {
            Remove-Item $tempFile
        }

        It "Removes the StepTemplateName, StepTemplateDescription, StepTemplateParameters variables from the script" {
            Get-ScriptBodyFromScriptFile -Path $tempFile | % Replace "`n" "" | % Replace "`r" "" | % Replace " " "" | Should Be "functiontest{}"
        } 

    }

}
