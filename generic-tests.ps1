#requires -version 3

# -------------------------------------------------------------------
# Octopus Deploy Generic Tests for Script Modules and Step Templates
# -------------------------------------------------------------------
#
# Ver    Who                             When        What
# 1.00   Matt Richardson (DevOpsGuys)    04-02-16    Initial Version
# -------------------------------------------------------------------

param ([string] $sut)

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

Describe 'Test Naming' {
    $filename = Split-Path -Leaf $sut
    Context "Tests for '$filename' should have unique test names" {
        
        It "should have unique test names" {
            $testResultsFile = (Split-Path $inputFile) + "\..\.BuildOutput\" +  ((Split-Path $inputFile -Leaf).Replace(".ps1", ".TestResults.xml"))
            $doc = [xml](Get-Content $testResultsFile)
            $nodes = $doc.SelectNodes('//test-results/test-suite/results/test-suite/results/test-case')
            if ($nodes -ne $null) {
                $duplicates = ($nodes.name | Group-Object | Where-Object {$_.count -gt 1} | Select-Object Name)

                if ($duplicates -ne $null) {                
                    "The following test names have duplicate 'Describe' and 'It' names, which under Pester 3, confuses TeamCity: $($duplicates.Name -join ',')" | Should be $null
                }
            }
        }
    }
}
