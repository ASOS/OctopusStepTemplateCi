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
	Update-XPathValue

.SYNOPSIS
    Updates a given XPath location in an XML file with the given value, can be either an element or an attribute's value
#>
function Update-XPathValue {
    param (
        $Path,
        $XPath,
        $Value
    )

    if (-not (Test-Path $Path)) {
        throw "File '$Path' not found"
    }

    $doc = [xml](Get-Content -Path $Path)
    
    $doc.SelectNodes($XPath) | ? { $null -ne $_ } | % {
        if ($_.NodeType -eq "Element") {
            $_.InnerXml = $Value
        } else {
            $_.Value = $Value
        }
    }

    $doc.Save($Path)
}