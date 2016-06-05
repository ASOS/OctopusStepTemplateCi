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
    Export-StepTemplate.Tests
    
.SYNOPSIS
    Pester tests for Export-StepTemplate

#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\..\Internal\Octopus\StepTemplates\New-StepTemplateObject.ps1"
. "$here\..\Internal\Octopus\Convert-ToOctopusJson.ps1"

Describe "Export-StepTemplate" {
    BeforeEach {
        if (Test-Path "TestDrive:\test.ps1") {
            Remove-Item "TestDrive:\test.ps1" -Force
        }
    }
        
    Mock New-StepTemplateObject { "steptemplate" }
    Mock Convert-ToOctopusJson { "steptemplate" }
    Set-Content "TestDrive:\steptemplate.ps1" "steptemplate" 
    
    It "Should convert the step template to json" {
        Export-StepTemplate -Path "TestDrive:\steptemplate.ps1" -ExportPath "TestDrive:\test.ps1"
        
        Assert-MockCalled Convert-ToOctopusJson
    }    
    
    It "Should return a message to the user" {
        Export-StepTemplate -Path "TestDrive:\steptemplate.ps1" -ExportPath "TestDrive:\test.ps1" | % GetType | % Name | Should Be "string"
    }
    
    Context "File" {
        
        It "Should export the steptemplate to a file" {
            Export-StepTemplate -Path "TestDrive:\steptemplate.ps1" -ExportPath "TestDrive:\test.ps1"
            
           "TestDrive:\test.ps1" | Should Contain "steptemplate"   
        }
        
        It "Should throw an exception if the file already exists" {
            Set-Content "TestDrive:\test.ps1" -Value "existing"
            
            { Export-StepTemplate -Path "TestDrive:\steptemplate.ps1" -ExportPath "TestDrive:\test.ps1" } | Should Throw
        }
        
        It "Should overwrite the file if it already exists and -Force is specified" {
            Set-Content "TestDrive:\test.ps1" -Value "existing"
                        
            Export-StepTemplate -Path "TestDrive:\steptemplate.ps1" -ExportPath "TestDrive:\test.ps1" -Force
            
           "TestDrive:\test.ps1" | Should Contain "steptemplate"   
        }
    }
    
    Context "Clipboard" {
        It "Should export the steptemplate to the system clipboard" {           
            Export-StepTemplate -Path "TestDrive:\steptemplate.ps1" -ExportToClipboard
            
            [System.Windows.Forms.Clipboard]::GetText() | Should Be "steptemplate"
        }
    }
}