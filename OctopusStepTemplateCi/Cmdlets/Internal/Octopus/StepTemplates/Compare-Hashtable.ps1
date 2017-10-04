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
    Compare-Hashtable

.SYNOPSIS
    Compares two hashtables.

.DESCRIPTION
    Compares two hashtables.

    The result indicates whether a key-value pair appeared only in the entries from the reference object
    (with a SideIndicator of '<='), or only in the entries from the difference object (with a SideIndicator of '=>').

    If all entries are identical, the function returns $null.

.EXAMPLE
    > Compare-Hashtable -ReferenceObject @{ "aaa"="bbb"; "ccc"="ddd" } -DifferenceObject @{ "aaa"="bbb"; "eee"="fff" }

    Key  Value  SideIndicator
    ---  -----  -------------
    eee  fff    =>
    ccc  ddd    <=

#>
function Compare-Hashtable
{

    param
    (

        [Parameter(Mandatory=$false)]
        [hashtable] $ReferenceObject,

        [Parameter(Mandatory=$false)]
        [hashtable] $DifferenceObject

    )

    $ErrorActionPreference = "Stop";
    Set-StrictMode -Version "Latest";

    # clone the parameters so we can modify them without affecting the original values
    $referenceClone  = if( $ReferenceObject  -eq $null ) { @{} } else { $ReferenceObject.Clone()  };
    $differenceClone = if( $DifferenceObject -eq $null ) { @{} } else { $DifferenceObject.Clone() };

    # remove any entries that match in both clones
    foreach( $differenceEntry in @($differenceClone.GetEnumerator())  )
    {
        if( $referenceClone.ContainsKey($differenceEntry.Key) )
        {
            # both objects contain an entry with this key, so get their values and compare them
            $referenceValue  = $referenceClone[$differenceEntry.Key];
            $differenceValue = $differenceClone[$differenceEntry.Key];
            if( ($referenceValue -eq $null) -and ($differenceValue -eq $null) )
            {
                $match = $true;
            }
            elseif( ($referenceValue -eq $null) -or ($differenceValue -eq $null) )
            {
                $match = $false;
            }
            elseif( ($referenceValue -is [hashtable]) -and ($differenceValue -is [hashtable]) )
            {
                $childDiffs = Compare-Hashtable -ReferenceObject $referenceValue -DifferenceObject $differenceValue;
                $match = ($childDiffs -eq $null);
            }
            else
            {
                $childDiffs = Compare-Object -ReferenceObject $referenceValue -DifferenceObject $differenceValue;
                $match = ($childDiffs -eq $null);
            }
            if( $match )
            {
                # the entry values match, so remove the item from both clones
                $referenceClone.Remove($differenceEntry.Key);
                $differenceClone.Remove($differenceEntry.Key);
            }
        }
    }

    $results = @();

    # add any entries left in the difference object that we didn't find a match for
    foreach( $differenceEntry in @($differenceClone.GetEnumerator()) )
    {
        $results += new-object PSCustomObject -Property ([ordered] @{
            "Key"           = $differenceEntry.Key
            "Value"         = $differenceEntry.Value
            "SideIndicator" = "=>"
        });
    }

    # add any entries  left in the reference object that we didn't find a match for
    foreach( $referenceEntry in @($referenceClone.GetEnumerator()) )
    {
        $results += new-object PSCustomObject -Property ([ordered] @{
            "Key"           = $referenceEntry.Key
            "Value"         = $referenceEntry.Value
            "SideIndicator" = "<="
        });
    }

    if( $results.Length -eq 0 )
    {
        $results = $null;
    }
    else
    {
        $results = @(, $results);
    }

    return $results;

}