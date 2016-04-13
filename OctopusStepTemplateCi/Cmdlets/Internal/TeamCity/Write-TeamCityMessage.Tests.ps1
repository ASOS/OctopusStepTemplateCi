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
	Write-TeamCityMessage.Tests

.SYNOPSIS
	Pester tests for Write-TeamCityMessage.
#>
Set-StrictMode -Version Latest

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Write-TeamCityMessage" {
    It "Should write the message to the powershell host" {
        Mock Write-Host {} -ParameterFilter { $Object -eq "test" } -Verifiable
        
        Write-TeamCityMessage -Message "test"
        
        Assert-VerifiableMocks
    }
    
    It "Should write error messages to the powershell host in a red colour" {
        Mock Write-Host {} -ParameterFilter { $Object -eq "Error" -and $ForegroundColor -eq "Red" } -Verifiable
        
        Write-TeamCityMessage -Message "Error" -ErrorMessage
        
        Assert-VerifiableMocks
    }
}
