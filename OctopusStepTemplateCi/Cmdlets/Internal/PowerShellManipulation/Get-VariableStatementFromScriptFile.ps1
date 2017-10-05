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
    Get-VariableStatementFromScriptFile

.SYNOPSIS
    Returns the variable assignment statement for a given variable name that is in a powershell script file
#>
function Get-VariableStatementFromScriptFile {
    param (
        $Path,
        $VariableName,
        [ValidateSet("Statement", "Value")]$Type = "Statement"
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref] $tokens, [ref] $parseErrors)

    $filter = {
        $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] -and
        $args[0].Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $args[0].Left.VariablePath.UserPath -eq $VariableName
    }

    $variableStatement = $ast.Find($filter, $true)
    
    if ($variableStatement -eq $null) {
        return $null
    }

    switch ($Type) {
        Statement { return $variableStatement | % Extent | % Text }
        Value { return $variableStatement | % Right | % Extent | % Text }
    }
}