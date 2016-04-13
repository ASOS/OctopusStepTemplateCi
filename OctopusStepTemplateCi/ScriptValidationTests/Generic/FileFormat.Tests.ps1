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
    FileFormat.Tests
    
.SYNOPSIS
    Pester tests for FileFormat.
#>
param ([System.String] $sut, [System.String] $TestResultsFile, [System.Collections.Hashtable]$Settings = @{})
Set-StrictMode -Version Latest

Describe 'File format' {
    $filename = Split-Path -Leaf $sut
    Context "File '$filename' should not contain non-ascii characters" {
        $script = Get-Content $sut
        $separator = "`r","`n"
        $lines = $script.split($separator, [System.StringSplitOptions]::None)

        It "File should not have any non-ascii chars" {
            $errorMessage = $null
            for ($i = 0; $i -lt $lines.length; $i++) {
                $line = $lines[$i] -replace '\t', '  '
                if ([System.Text.Encoding]::UTF8.GetByteCount($line) -ne $line.Length) {
                    for ($j = 0; $j -le $line.length; $j++) {
                        $linePrefix = $line.substring(0, $J)
                        if ([System.Text.Encoding]::UTF8.GetByteCount($linePrefix) -ne $linePrefix.Length) {
                            $pointer = ('-' * ($J - 1)) + '^'
                            $errorMessage = "Line $($i + 1), column $($j - 2) of $filename is not a valid ascii character`n$line`n$pointer"
                            break;
                        }
                    }
                }
            }

            $errorMessage | should be $null
        }
    }
}