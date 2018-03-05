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

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";


InModuleScope "OctopusStepTemplateCi" {

    Describe "Sync-ScriptModule" {

        Mock -CommandName "Get-Content" `
             -MockWith {
                 return @'
function test {
    $ScriptModuleName = "name"
    $ScriptModuleDescription = "description"
    write-host "test message"
}
'@;
             };

        Mock -CommandName "Invoke-OctopusApiOperation" `
             -MockWith { throw ("should not be called with parameters @{ Method = '$Method', Uri = '$Uri'}!"); };

        Mock Write-TeamCityBuildLogMessage {};

        Context "when variable set does not exist" {
    
            It "Should upload the VariableSet for the script module if it does not exist" {

                Mock -CommandName "Get-OctopusApiLibraryVariableSet" `
                     -ParameterFilter { $ObjectId -eq "All" } `
                     -MockWith { return @{ Name = "another name" } } `
                     -Verifiable;

                Mock -CommandName "New-OctopusApiLibraryVariableSet" `
                     -MockWith { return @{ "Links" = @{ "Variables" = "/api/variables/variableset-LibraryVariableSets-1" } }; } `
                     -Verifiable;

                Mock -CommandName "Get-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-1" } `
                     -MockWith { return @{ "Variables" = @() }; } `
                     -Verifiable;

                Mock -CommandName "Update-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-1" } `
                     -MockWith {} `
                     -Verifiable;

                $result = Sync-ScriptModule -Path "my.scriptmodule.ps1";
                $result.UploadCount | Should Be 2;

                Assert-VerifiableMock;

            }

        }
    
        Context "when script module does not exist" {

            It "Should upload the script module if it does not exist" {

                Mock -CommandName "Get-OctopusApiLibraryVariableSet" `
                     -ParameterFilter { $ObjectId -eq "All" } `
                     -MockWith {
                         return @{
                             "Id" = "LibraryVariableSets-100"
                             "Name" = "name"
                             "Description" = "description"
                             "Links" = @{ "Variables" = "/api/variables/variableset-LibraryVariableSets-100" }
                         };
                      } `
                     -Verifiable;

                Mock -CommandName "Get-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-100" } `
                     -MockWith { @{ Variables = @() } } `
                     -Verifiable;

                Mock -CommandName "Update-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-100" } `
                     -MockWith {}  `
                     -Verifiable;

                $result = Sync-ScriptModule -Path "my.scriptmodule.ps1";
                $result.UploadCount | Should Be 1;

                Assert-VerifiableMock;

            }

        }
    
        Context "when variable set has changed" {

            It "Should upload an updated VariableSet for the script module if it has changed" {

                Mock -CommandName "Get-OctopusApiLibraryVariableSet" `
                     -ParameterFilter { $ObjectId -eq "All" } `
                     -MockWith {
                         return @{
                             "Id" = "LibraryVariableSets-200"
                             "Name" = "name"
                             "Description" = "new description"
                             "Links" = @{ "Variables" = "/api/variables/variableset-LibraryVariableSets-200" }
                         };
                     } `
                     -Verifiable;

                Mock -CommandName "Update-OctopusApiLibraryVariableSet" `
                     -MockWith {} `
                     -Verifiable;

                Mock -CommandName "Get-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-200" } `
                     -MockWith {
                        return @{
                            "Variables" = @(
                                @{
                                    "Value" = @'
function test {
    
    
    write-host "test message"
}
'@
                                }
                            )
                        };
                     } `
                     -Verifiable;

                $result = Sync-ScriptModule -Path "my.scriptmodule.ps1";
                $result.UploadCount | Should Be 1;

                Assert-VerifiableMock;

            }

        }
    
        Context "when script module has changed" {

            It "Should upload an updated script module if it has changed" {

                Mock -CommandName "Get-OctopusApiLibraryVariableSet" `
                     -ParameterFilter { $ObjectId -eq "All" } `
                     -MockWith {
                         return @{
                             "Id" = "LibraryVariableSets-300"
                             "Name" = "name"
                             "Description" = "description"
                             "Links" = @{ "Variables" = "/api/variables/variableset-LibraryVariableSets-300" }
                         };
                      } `
                     -Verifiable;

                Mock -CommandName "Get-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-300" } `
                     -MockWith { return @{ "Variables" = @( @{ "Value" = "a different script" } ) }; } `
                     -Verifiable;

                Mock -CommandName "Update-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-300" } `
                     -MockWith {} `
                     -Verifiable;

                $result = Sync-ScriptModule -Path "my.scriptmodule.ps1";
                $result.UploadCount | Should Be 1;

                Assert-VerifiableMock;

            }

        }

        Context "when nothing has changed" {

            It "Should not upload if nothing has changed" {

                Mock -CommandName "Get-OctopusApiLibraryVariableSet" `
                     -ParameterFilter { $ObjectId -eq "All" } `
                     -MockWith {
                        return @{
                            "Name" = "name"
                            "Description" = "description"
                            "Links" = @{ "Variables" = "/api/variables/variableset-LibraryVariableSets-400" }
                        };
                     } `
                     -Verifiable;

                Mock -CommandName "Get-OctopusApiObject" `
                     -ParameterFilter { $ObjectUri -eq "/api/variables/variableset-LibraryVariableSets-400" } `
                     -MockWith {
                        return @{
                            "Variables" = @(
                                @{
                                    "Value" = @'
function test {
    
    
    write-host "test message"
}
'@
                                }
                            )
                        };
                     } `
                     -Verifiable;

                $result = Sync-ScriptModule -Path "my.scriptmodule.ps1";
                $result.UploadCount | Should Be 0;

                Assert-VerifiableMock;

            }

        }

    }

}