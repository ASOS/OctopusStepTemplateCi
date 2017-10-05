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
    New-StepTemplateObject

.SYNOPSIS
    Creates a new step template object
#>
function New-StepTemplateObject
{

    param
    (
        [Parameter(Mandatory=$true)]
        [string] $Path
    )

    $stepTemplateName = Get-VariableFromScriptFile -Path $Path -VariableName "StepTemplateName";
    if( ($stepTemplateName -ne $null) -and
        ($stepTemplateName -isnot [string]) )
    {
        throw new-object System.InvalidOperationException("The '`$StepTemplateName' variable in file '$Path' does not evaluate to a string.");
    }

    $stepTemplateDescription = Get-VariableFromScriptFile -Path $Path -VariableName "StepTemplateDescription";
    if( ($stepTemplateDescription -ne $null) -and
        ($stepTemplateDescription -isnot [string]) )
    {
        throw new-object System.InvalidOperationException("The '`StepTemplateDescription' variable in file '$Path' does not evaluate to a string.");
    }

    $stepTemplateParameters = @(Get-VariableFromScriptFile -Path $Path -VariableName "StepTemplateParameters");
    if( ($stepTemplateParameters -isnot [array]) -or
        (($stepTemplateParameters | where-object { $_ -isnot [hashtable] }) -ne $null)  )
    {
        throw new-object System.InvalidOperationException("The '`$StepTemplateParameters' variable in file '$Path' does not evaluate to an array of hashtables.");
    }

    # read the step template from file
    $stepTemplate = new-object -TypeName "PSObject" `
                               -Property @{
                                   "Name"        = $stepTemplateName
                                   "Description" = $stepTemplateDescription
                                   "ActionType"  = "Octopus.Script"
                                   "Properties"  = @{
                                       "Octopus.Action.Script.ScriptBody" = Get-ScriptBodyFromScriptFile -Path $Path
                                       "Octopus.Action.Script.Syntax"     = "PowerShell"
                                   }
                                   "Parameters"  = $stepTemplateParameters
                                   "SensitiveProperties" = @{}
                                   "`$Meta"      = @{ "Type" = "ActionTemplate" }
                                   "Version"     = 1
                               };

    # Octopus cleans up some of the Parameter properties when a step template is uploaded.
    # this means that when it is downloaded again for comparison against the local template
    # it won't match, and will be considered "different", which will trigger an other upload.
    # we'll try to fix up some Parameter properties so that they round-trip properly
    $propertyNames = @( "Label", "HelpText", "DefaultValue" );
    foreach( $parameter in $stepTemplate.Parameters )
    {
	foreach( $propertyName in $propertyNames )
        {
            if( $parameter.ContainsKey($propertyName) )
            {

                if( $parameter[$propertyName] -eq $null )
                {
                    # Octopus converts null values into an empty string when a step template is uploaded
                    $parameter[$propertyName] = "";
                }
                elseif( $parameter[$propertyName] -is [string] )
                {
                    if( -not [string]::IsNullOrEmpty($parameter[$propertyName]) )
                    {
                        # Octopus trims property values when  a step template is uploaded
                        $parameter[$propertyName] = $parameter[$propertyName].Trim();
                    }
                }
                elseif( $parameter[$propertyName] -is [bool] )
                {
                    # Octopus ignores booleans, so we'll convert them to string representations instead
                    $parameter[$propertyName] = $parameter[$propertyName].ToString();
                }

            }
        }
    }

    # return the result;
    return $stepTemplate;

}