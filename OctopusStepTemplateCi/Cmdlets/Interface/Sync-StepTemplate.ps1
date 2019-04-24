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
    Sync-ScriptTemplate
    
.SYNOPSIS
    Uploads the step template into Octopus if it has changed

.DESCRIPTION
    This will only upload if the step template has changed
    
.PARAMETER Path
    The path to the step template to upload
    
.PARAMETER UseCache
    If Octopus Retrieval Operations should be cached, this is used when called from Invoke-TeamCityCiUpload where this function is called mulitple times
    When being run interactivley the use of the cache could cause unexpected behaviour

.INPUTS
    None. You cannot pipe objects to  Sync-StepTemplate.

.OUTPUTS
    None.
#>
function Sync-StepTemplate
{

    [CmdletBinding()]
    [OutputType("System.Collections.Hashtable")]
    param
    (

        [Parameter(Mandatory=$true)]
        [string] $Path,

        [Parameter(Mandatory=$false)]
        [switch] $UseCache

    )

    $ErrorActionPreference = "Stop";
    $ProgressPreference = "SilentlyContinue";
    Set-StrictMode -Version "Latest";

    $newStepTemplate = Read-StepTemplate -Path $Path;
    $templateName = $newStepTemplate.Name;

    $stepTemplates = Get-OctopusApiActionTemplate -ObjectId "All" -UseCache:$UseCache;
    $stepTemplate  = $stepTemplates | where-object { $_.Name -eq $templateName };

    $result = @{ "UploadCount" = 0 };
    
    if( $null -eq $stepTemplate )
    {
        Write-TeamCityBuildLogMessage "Step template '$templateName' does not exist. Creating";
        $stepTemplate = New-OctopusApiActionTemplate -Object $newStepTemplate;
        $result.UploadCount++;
    }
    else
    {

        # Strip out unneccessary keys such as Id and links.
        try
	{
            $keysToRemove = $stepTemplate.Parameters.Keys | Select -Unique | ? {$_ -notin ("DefaultValue", "Label", "HelpText", "Name", "DisplaySettings")};
            foreach( $key in $keysToRemove )
            {
                $paramCount = ($stepTemplate.Parameters.Count) - 1;
                while( $paramCount -ge 0 )
	        {
                    ($stepTemplate.Parameters[$paramCount]).Remove($key);
                    $paramCount = $paramCount - 1;
                }
            }
        }
        catch
        {
            Write-Verbose "No parameter keys to remove";
        }

        if( Compare-StepTemplate -OldTemplate $stepTemplate -NewTemplate $newStepTemplate )
        {

            Write-TeamCityBuildLogMessage "Step template '$templateName' has changed. Updating";

            if( $newStepTemplate.ContainsKey("Version") )
            {
                $newStepTemplate.Remove("Version");
            }

            $stepTemplate = Update-OctopusApiActionTemplate -ObjectId $stepTemplate.Id -Object $newStepTemplate;
            $result.UploadCount++;

        }
        else
        {
            Write-TeamCityBuildLogMessage "Step template '$templateName' has not changed. Skipping.";
        }

    }

    return $result;

}