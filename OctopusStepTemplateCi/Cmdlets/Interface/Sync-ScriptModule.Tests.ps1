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
    Sync-ScriptModule.Tests
    
.SYNOPSIS
    Pester tests for Sync-ScriptModule  
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\New-ScriptModule.ps1"
. "$here\..\Internal\Octopus\Invoke-OctopusOperation.ps1"
. "$here\..\Internal\Octopus\ScriptModules\New-ScriptModuleObject.ps1"
. "$here\..\Internal\Octopus\ScriptModules\Read-ScriptModuleVariableSet.ps1"
. "$here\..\Internal\TeamCity\Write-TeamCityMessage.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableFromScriptFile.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableFromScriptText.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableStatementFromScriptFile.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-VariableStatementFromScriptText.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-ScriptBodyFromScriptFile.ps1"
. "$here\..\Internal\PowerShellManipulation\Get-ScriptBodyFromScriptText.ps1"

Describe "Sync-ScriptModule" {

    BeforeEach {
        $tempFile = "{0}\test.scriptmodule.ps1" -f [System.IO.Path]::GetTempPath() # Cant use the testdrive as $doc.Save($Path) doesn't support 'TestDrive:\'
        New-ScriptModule -Name "test" -Path ([System.IO.Path]::GetTempPath())
    }

    AfterEach {
        Remove-Item $tempFile
    }
    
    Mock -CommandName "Get-Content" `
         -MockWith {
             return @'
$ScriptModuleName = "name"
$ScriptModuleDescription = "description"

write-host "test message";
'@;
         };

    Mock Write-TeamCityMessage {} 
    
    It "Should upload the VariableSet for the script module if it does not exist" {
        Mock Invoke-OctopusOperation { @{ Name = "another test" } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "LibraryVariableSets" -and $ObjectId -eq "All" }
        Mock Invoke-OctopusOperation { @{ Links = @{ Variables = "script module" } } } -ParameterFilter { $Action -eq "New" -and $ObjectType -eq "LibraryVariableSets" } -Verifiable
        Mock Invoke-OctopusOperation { @{ Variables = @() } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "UserDefined" } 
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" }        
        Sync-ScriptModule -Path $tempFile
        Assert-VerifiableMocks
    }
    
    It "Should upload the script module if it does not exist" {
        Mock Invoke-OctopusOperation { @{ Name = "test"; Description = "test description"; Links = @{ Variables = "script module" } } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "LibraryVariableSets" -and $ObjectId -eq "All" }
        Mock Invoke-OctopusOperation { @{ Variables = @() } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "UserDefined" } 
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" }  -Verifiable
        Sync-ScriptModule -Path $tempFile
        Assert-VerifiableMocks
    }
    
    It "Should upload an updated VariableSet for the script module if it has changed" {
        Mock Invoke-OctopusOperation { @{ Name = "test"; Description = "different description"; Links = @{ Variables = "script module"; Self = "variableset" } } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "LibraryVariableSets" -and $ObjectId -eq "All" }
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" -and $ApiUri -eq "variableset" } -Verifiable
        Mock Invoke-OctopusOperation { @{ Variables = @() } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "UserDefined" } 
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" -and $ApiUri -eq "script module" }
        Sync-ScriptModule -Path $tempFile
        Assert-VerifiableMocks
    }
    
    It "Should upload an updated script module if it has changed" {
        Mock Invoke-OctopusOperation { @{ Name = "test"; Description = "test description"; Links = @{ Variables = "script module" } } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "LibraryVariableSets" -and $ObjectId -eq "All" }
        Mock Invoke-OctopusOperation { @{ Variables = @( @{ Value = "a different script" } ) } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "UserDefined" } 
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" }  -Verifiable
        Sync-ScriptModule -Path $tempFile
        Assert-VerifiableMocks
    }
    
    It "Should return an upload count for each create/upload operation" {
        Mock Invoke-OctopusOperation { @{ Name = "test"; Description = "different description"; Links = @{ Variables = "script module"; Self = "variableset" } } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "LibraryVariableSets" -and $ObjectId -eq "All" }
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" -and $ApiUri -eq "variableset" } -Verifiable
        Mock Invoke-OctopusOperation { @{ Variables = @( @{ Value = "a different script" } ) } } -ParameterFilter { $Action -eq "Get" -and $ObjectType -eq "UserDefined" } 
        Mock Invoke-OctopusOperation {} -ParameterFilter { $Action -eq "Update" -and $ObjectType -eq "UserDefined" }
        Sync-ScriptModule -Path $tempFile | % UploadCount | Should Be 2
    }

}