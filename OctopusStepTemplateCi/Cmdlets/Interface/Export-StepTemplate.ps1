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
    Export-StepTemplate
    
.SYNOPSIS
    Exports a step template

.DESCRIPTION
    Exports a step template in JSON format for submission to the Octopus community site or manual import into Octopus
    
.PARAMETER Path
    The path to the step template

.PARAMETER ExportPath
    The location to save the step template file
    
.PARAMETER Force
    Overwrites the file if it already exists
    
.PARAMETER ExportToClipboard
    Exports the step template to the system clipboard
    
.INPUTS
    None. You cannot pipe objects to Export-StepTemplate.

.OUTPUTS
    None.
#>
function Export-StepTemplate {
    [CmdletBinding()]
    [OutputType("System.String")]
    param(
        [Parameter(Mandatory=$true)][ValidateScript({ Test-Path $_ })][System.String]$Path,
        [Parameter(Mandatory=$true, ParameterSetName="File")][System.String]$ExportPath,
        [Parameter(Mandatory=$false, ParameterSetName="File")][System.Management.Automation.SwitchParameter]$Force,
        [Parameter(Mandatory=$true, ParameterSetName="Clipboard")][System.Management.Automation.SwitchParameter]$ExportToClipboard
    )
    
    $resolvedPath = Resolve-Path -Path $Path
    $stepTemplate = Convert-ToOctopusJson (New-StepTemplateObject -Path $resolvedPath)
    
    switch ($PSCmdlet.ParameterSetName) {
        "File" {
            if ((Test-Path $ExportPath) -and -not $Force) {
                throw "$ExportPath already exists. Specify -Force to overwrite"
            }
            
            Set-Content -Path $ExportPath -Value $stepTemplate -Force:$Force -Encoding UTF8
            
            "Step Template exported to $ExportPath"
        }
        "Clipboard" {
            Microsoft.PowerShell.Management\Set-Clipboard -Value $stepTemplate
            
            "Step Template exported clipboard"
        }
    }
}