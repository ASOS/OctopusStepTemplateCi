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
    Compare-StepTemplate

.SYNOPSIS
    Compares two step templates, returning true if they are different, false if they are the same (so it can be used in an if statement)
#>
function Compare-StepTemplate
{

    param
    (

        [Parameter(Mandatory=$true)]
        [hashtable] $OldTemplate,

        [Parameter(Mandatory=$true)]
        [hashtable] $NewTemplate

    )

    $ErrorActionPreference = "Stop";

    #id - wont change
    #version - will be incremented, shouldn't be checked

    # name
    if( $OldTemplate.Name -ne $NewTemplate.Name )
    {
        return $true;
    }

    # description
    if( $OldTemplate.Description -ne $NewTemplate.Description )
    {
        return $true;
    }

    # action type
    if( $OldTemplate.ActionType -ne $NewTemplate.ActionType )
    {
        return $true;
    }

    # Properties['Octopus.Action.Script.Syntax']
    if( $OldTemplate.Properties['Octopus.Action.Script.Syntax'] -ne $NewTemplate.Properties['Octopus.Action.Script.Syntax'] )
    {
        return $true;
    }

    # Properties['Octopus.Action.Script.ScriptBody']
    if( $OldTemplate.Properties['Octopus.Action.Script.ScriptBody'] -ne $NewTemplate.Properties['Octopus.Action.Script.ScriptBody'])
    {
        return $true;
    }

    # Parameters - check we have the same number of them, with the same names (in the same order!)
    if( (($OldTemplate.Parameters | % Name) -join ',') -ne (($NewTemplate.Parameters | % Name) -join ',') )
    {
        return $true;
    }

    # loop through the parameters, and compare each hashtable
    foreach( $newParameter in $NewTemplate.Parameters )
    {
        $oldParameter = $OldTemplate.Parameters | where-object { $_.Name -eq $newParameter.Name };
        $diffs = Compare-StepTemplateParameter -ReferenceObject $oldParameter -DifferenceObject $newParameter;
        if( $null -ne $diffs )
	{
	    return $true;
	}
    }

    return $false;

}