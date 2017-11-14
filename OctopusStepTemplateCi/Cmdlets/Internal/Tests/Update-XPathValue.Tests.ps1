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
	Update-XPathValue.Tests

.SYNOPSIS
	Pester tests for Update-XPathValue.
#>

$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

InModuleScope "OctopusStepTemplateCi" {

Describe "Update-XPathValue" {
    It "Should update the value at the given XPath location" {
        $tempFile = [System.IO.Path]::GetTempFileName() # Cant use the testdrive as $doc.Save($Path) doesn't support 'TestDrive:\'
        
        Set-Content $tempFile "<results>original</results>"
        
        Update-XPathValue -Path $tempFile -XPath "//results" -Value "replacement"
        
        Get-Content $tempFile | Should Be "<results>replacement</results>"
        
        Remove-Item $tempFile
    }
    
    It "Should update attributes at the given XPath location" {
        $tempFile = [System.IO.Path]::GetTempFileName() # Cant use the testdrive as $doc.Save($Path) doesn't support 'TestDrive:\'
        
        Set-Content $tempFile "<results attr=`"old`">original</results>"
        
        Update-XPathValue -Path $tempFile -XPath "//results/@attr" -Value "new"
        
        Get-Content $tempFile | Should Be "<results attr=`"new`">original</results>"
        
        Remove-Item $tempFile
    }
    
    It "Should throw if the path does not exist" {
        { Update-XPathValue -Path "TestDrive:\not-here.xml" -XPath "//results" -Value "replacement" } | Should Throw "File 'TestDrive:\not-here.xml' not found"
    }
    
    It "Should throw an exception if the xml is invalid" {
        $tempFile = [System.IO.Path]::GetTempFileName() # Cant use the testdrive as $doc.Save($Path) doesn't support 'TestDrive:\'
        
        Set-Content $tempFile "<resuldkasts attr=`"old`">original</results>"
        
        { Update-XPathValue -Path $tempFile -XPath "//results/@attr" -Value "new" } | Should Throw 
        
        Remove-Item $tempFile
    }
}

}
