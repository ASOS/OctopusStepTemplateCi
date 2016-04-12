#requires -version 4

# TODO
# * add some unit tests
# * make it a module?

# ------------------------------------------------
# Octopus Deploy Step Template Tester and Uploader
# ------------------------------------------------
#
# Ver     Who         When      What
# 1.0     DevOpsGuys  14-08-15  Initial Version


#credit to Dave Wyatt for the Get-VariableFromScriptFile piece of magic
function Get-VariableFromScriptFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf))
            {
                throw "Path '$_' does not exist."
            }
            
            $item = Get-Item -LiteralPath $_
            if ($item -isnot [System.IO.FileInfo])
            {
                throw "Path '$_' does not refer to a file."
            }

            return $true
        })]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $VariableName
    )

    $tokens = $null
    $parseErrors = $null

    $_path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($_path, [ref] $tokens, [ref] $parseErrors)
    if ($parseErrors) {
        throw "File '$Path' contained parse errors: `r`n$($parseErrors | Out-String)"
    }

    $filter = {
        $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] -and
        $args[0].Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $args[0].Left.VariablePath.UserPath -eq $VariableName
    }

    $assignment = $ast.Find($filter, $true)

    if ($assignment) {
        $scriptBlock = [scriptblock]::Create($assignment.Right.Extent.Text)
        return & $scriptBlock
    }
    else {
        throw "File '$Path' does not contain Step Template metadata variable '$VariableName'"
    }
}

function Remove-VariableFromScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ScriptBody,

        [Parameter(Mandatory)]
        [string] $VariableName
    )

    $tokens = $null
    $parseErrors = $null

    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content $tempFile $ScriptBody

    $_path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($tempFile)

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($_path, [ref] $tokens, [ref] $parseErrors)
    if ($parseErrors)
    {
        throw "File '$Path' contained parse errors: `r`n$($parseErrors | Out-String)"
    }

    $filter = {
        $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst] -and
        $args[0].Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $args[0].Left.VariablePath.UserPath -eq $VariableName
    }

    $assignment = $ast.Find($filter, $true)

    if ($assignment)
    {
        return $ScriptBody.Replace($assignment.Extent.Text, "")
    }
}

function Convert-PSObjectToHashTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSObject] $PsObject
    )
    $result = @{}
    foreach ($propL1 in $PsObject.psobject.properties.name)
    {
        $result[$propL1] = $PsObject.$propL1
    }
    return $result
}

function Download-StepTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $octopusURI,
        [Parameter(Mandatory)]
        [string] $apikey,
        [Parameter(Mandatory)]
        [string] $templateName
    )

    $response = Invoke-WebRequest -Uri "$octopusURI/api/actiontemplates/all" -Headers @{"X-Octopus-ApiKey"=$apikey} -UseBasicParsing
    $allTemplates = ($response.Content | ConvertFrom-Json)
    $oldTemplate = $null

    foreach($template in $allTemplates)
    {
        if ($templateName -eq $template.Name) {
            $oldTemplate = $template
        
            $oldtemplate.Properties = Convert-PSObjectToHashTable $template.Properties

            $parameters = $template.Parameters
            $oldtemplate.Parameters = @()
            foreach ($param in $parameters)
            {
                $newParam = Convert-PSObjectToHashTable $param
                $newParam.DisplaySettings = Convert-PSObjectToHashTable $newParam.DisplaySettings
                $oldtemplate.Parameters += $newParam
            }
        }
    }
    return $oldTemplate
}

function Get-ScriptBody {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $inputFile
    )
    $scriptBody = [IO.File]::ReadAllText($inputFile)
    #remove 'metadata' parameters
    if ($inputFile -match ".*\.scriptmodule\.ps1")
    {
        $scriptBody = Remove-VariableFromScript -ScriptBody $scriptBody -VariableName ScriptModuleName    
    }
    elseif ($inputFile -match ".*\.steptemplate\.ps1")
    {
        $scriptBody = Remove-VariableFromScript -ScriptBody $scriptBody -VariableName StepTemplateName
        $scriptBody = Remove-VariableFromScript -ScriptBody $scriptBody -VariableName StepTemplateDescription
        $scriptBody = Remove-VariableFromScript -ScriptBody $scriptBody -VariableName StepTemplateParameters
    }
    $scriptBody = $scriptBody.TrimStart("`r", "`n")
    return $scriptBody
}

function Convert-ToJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $newTemplate
    )
    $json = ($newTemplate | ConvertTo-Json -depth 3)
    $json = $json.Replace("\u0027", "'") #fix escaped single quotes
    $json = $json -replace '\{\s*\}', '{}' #fix odd empty hashtable formatting (or easier comparison in beyond compare)
    return $json
}

function Clone-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $oldTemplate,
        [Parameter(Mandatory)]
        [string] $inputFile
    )

    #take a copy of the template
    $newTemplate = $oldTemplate.PsObject.Copy()
    $newTemplate.Properties = $oldTemplate.Properties.PsObject.Copy()

    $newTemplate.Version = $oldTemplate.Version + 1

    $newTemplate.Properties["Octopus.Action.Script.ScriptBody"] = Get-ScriptBody -inputFile $inputFile
    $newTemplate.Description = Get-VariableFromScriptFile -Path $inputFile -VariableName StepTemplateDescription;

    [Array]$parameters = Get-VariableFromScriptFile -Path $InputFile -VariableName StepTemplateParameters

    $newTemplate.Parameters = $parameters;
    $newTemplate.PsObject.Properties.Remove('Links')
    return $newTemplate
}

function Create-Template {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $InputFile
    )

    
    [Array]$parameters = Get-VariableFromScriptFile -Path $InputFile -VariableName StepTemplateParameters

    $properties = @{
        'Name' = Get-VariableFromScriptFile -Path $InputFile -VariableName StepTemplateName;
        'Description' = Get-VariableFromScriptFile -Path $InputFile -VariableName StepTemplateDescription;
        'ActionType' = 'Octopus.Script';
        'Properties' = @{
            'Octopus.Action.Script.ScriptBody' = Get-ScriptBody -inputFile $InputFile;
            'Octopus.Action.Script.Syntax' = 'PowerShell'
            };
        'Parameters' = $parameters;
        'SensitiveProperties' = @{};
        '$Meta' = @{'Type' = 'ActionTemplate'}
    }

    $newTemplate = New-Object -TypeName PSObject -Property $properties

    return $newTemplate
}

#Compare-Hashtable borrowed from http://stackoverflow.com/a/7060358
function Compare-Hashtable(
  [Hashtable]$ReferenceObject,
  [Hashtable]$DifferenceObject,
  [switch]$IncludeEqual
) {
  # Creates a result object.
  function result( [string]$side ) {
    New-Object PSObject -Property @{
      'InputPath'= "$path$key";
      'SideIndicator' = $side;
      'ReferenceValue' = $refValue;
      'DifferenceValue' = $difValue;
    }
  }

  # Recursively compares two hashtables.
  function core-compare( [string]$path, [Hashtable]$ref, [Hashtable]$dif ) {
    # Hold on to keys from the other object that are not in the reference.
    $nonrefKeys = New-Object 'System.Collections.Generic.HashSet[string]'
    $dif.Keys | foreach { [void]$nonrefKeys.Add( $_ ) }

    # Test each key in the reference with that in the other object.
    foreach( $key in $ref.Keys ) {
      [void]$nonrefKeys.Remove( $key )
      $refValue = $ref.$key
      $difValue = $dif.$key

      if( -not $dif.ContainsKey( $key ) ) {
        result '<='
      }
      elseif( $refValue -is [hashtable] -and $difValue -is [hashtable] ) {
        core-compare "$path$key." $refValue $difValue
      }
      elseif( $refValue -ne $difValue ) {
        result '<>'
      }
      elseif( $IncludeEqual ) {
        result '=='
      }
    }

    # Show all keys in the other object not in the reference.
    $refValue = $null
    foreach( $key in $nonrefKeys ) {
      $difValue = $dif.$key
      result '=>'
    }
  }

  core-compare '' $ReferenceObject $DifferenceObject
}

function Are-TemplatesDifferent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $oldtemplate,
        [Parameter(Mandatory)]
        $newTemplate
    )
    #id - wont change
    #name - wont change
    #actiontype - wont change
    #version - will be incremented, shouldn't be checked

    #description
    if ($oldtemplate.Description -ne $newTemplate.Description) { 
        return $true 
    }
    #Properties['Octopus.Action.Script.Syntax']
    if ($oldtemplate.Properties['Octopus.Action.Script.Syntax'] -ne $newTemplate.Properties['Octopus.Action.Script.Syntax']) { 
        return $true
    }
    #Properties['Octopus.Action.Script.ScriptBody']
    if ($oldtemplate.Properties['Octopus.Action.Script.ScriptBody'] -ne $newTemplate.Properties['Octopus.Action.Script.ScriptBody']) { 
        return $true 
    }
    #Parameters - check we have the same number of them, with the same names
    if (($oldTemplate.Parameters.Name -join ',') -ne ($newTemplate.Parameters.Name -join ',')) {
        return $true
    }

    #loop through the params, and compare each hastable (recursively)
    foreach($oldParam in $oldtemplate.Parameters)
    {
        $newParam =  ($newTemplate.Parameters | where { $_.Name -eq $oldParam.Name })
        $result = Compare-Hashtable -ReferenceObject $oldParam -DifferenceObject $newParam
        if ($result) { 
            return $true 
        }
    }

    return $false
}

function Run-Tests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $inputFile
    )
    $testFile = $inputFile.Replace(".ps1", ".Tests.ps1")
    $testResultsFile = $inputFile.Replace(".ps1", ".TestResults.xml")

    if (-not (Test-Path -LiteralPath $testFile -PathType Leaf)) {
        throw "Step Template test file  '$testFile' does not exist."
    }
            
    $item = Get-Item -LiteralPath $testFile
    if ($item -isnot [System.IO.FileInfo]) {
        throw "Step Template test file '$testFile' is not a file."
    }

    $testResult = Invoke-Pester -Script $testFile -PassThru -OutputFile $testResultsFile -OutputFormat NUnitXml

    if ($testResult.FailedCount -gt 0) {
        throw "$($testResult.FailedCount) tests failed for step template '$inputFile'"
    }
    $testResultsFile = $inputFile.Replace(".ps1", ".generic.TestResults.xml")
    if ($inputFile -match ".*\.scriptmodule\.ps1")
    {
        $testResult = Invoke-Pester -Script @{ Path = "$PSScriptRoot\scriptmodule-generic-tests.ps1"; Parameters = @{ Sut = $inputFile } } -PassThru -OutputFile $testResultsFile -OutputFormat NUnitXml
    }
    else
    {
        $testResult = Invoke-Pester -Script @{ Path = "$PSScriptRoot\step-template-generic-tests.ps1"; Parameters = @{ Sut = $inputFile } } -PassThru -OutputFile $testResultsFile -OutputFormat NUnitXml
    }
    

    if ($testResult.FailedCount -gt 0) {
        throw "$($testResult.FailedCount) tests failed for step template '$inputFile'"
    }
}


function Upload-ScriptModule {
[CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $inputFile,
        [Parameter(Mandatory)]
        [string] $octopusURI,
        [Parameter(Mandatory)]
        [string] $apikey
    )

$header = @{ "X-Octopus-ApiKey" = $apikey }

#Module Name and Powershell Script
$ModuleName = Get-VariableFromScriptFile -Path $InputFile -VariableName ScriptModuleName
$ModuleScript = Get-ScriptBody -inputFile $inputFile


#Getting if module already exists, and if it doesnt, create it
$Modules = Invoke-WebRequest $octopusURI/api/LibraryVariableSets -Method GET -Headers $header | select -ExpandProperty content | ConvertFrom-Json
$ScriptModule = $Modules.Items | ?{$_.name -eq $ModuleName}

If($ScriptModule -eq $null){
    
    $SMBody = [PSCustomObject]@{
        ContentType = "ScriptModule"
        Name = $ModuleName
    } | ConvertTo-Json

    $Scriptmodule = Invoke-WebRequest $octopusURI/api/LibraryVariableSets -Method POST -Body $SMBody -Headers $header | select -ExpandProperty content | ConvertFrom-Json    
}

#Getting the library variable set asociated with the module
$Variables = Invoke-WebRequest $octopusURI/$($Scriptmodule.Links.Variables) -Headers $header | select -ExpandProperty content | ConvertFrom-Json

#Creating/updating the variable that holds the Powershell script
If($Variables.Variables.Count -eq 0)
{
    $Variable = [PSCustomObject]@{   
        Name = "Octopus.Script.Module[$Modulename]"    
        Value = $ModuleScript #Powershell script goes here
    }

    $Variables.Variables += $Variable

    $VSBody = $Variables | ConvertTo-Json -Depth 3
}
else{    
    $Variables.Variables[0].value = $ModuleScript #Updating powershell script
    $VSBody = $Variables | ConvertTo-Json -Depth 3    
}

#Updating the library variable set
Invoke-WebRequest $octopusURI/$($Scriptmodule.Links.Variables) -Headers $header -Body $VSBody -Method PUT | select -ExpandProperty content | ConvertFrom-Json

}



function Upload-StepTemplateIfChanged {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $inputFile,
        [Parameter(Mandatory)]
        [string] $octopusURI,
        [Parameter(Mandatory)]
        [string] $apikey
    )
    $templateName = Get-VariableFromScriptFile -Path $InputFile -VariableName StepTemplateName
    $oldTemplate = Download-StepTemplate -octopusURI $octopusURI -apikey $apikey -templateName $templateName
    $outputFile = $inputFile.Replace('.ps1', '.json')

    try
    {
        if ($oldTemplate -ne $null) {
            Write-host "Template '$($oldtemplate.Id)' already exists on Octopus Deploy server (at version $($oldTemplate.Version))"
            $newTemplate = Clone-Template $oldTemplate $inputFile
            $json = Convert-ToJson -newTemplate $newTemplate
            $json | Set-Content -Path $outputFile

            if (Are-TemplatesDifferent $oldtemplate $newTemplate) {
                write-host "Template has changed"
                write-host "Uploading template"
                $response = Invoke-WebRequest -Uri "$octopusURI/api/actiontemplates/$($newTemplate.Id)" -method PUT -body $json -Headers @{"X-Octopus-ApiKey"=$apikey} -UseBasicParsing
                $updatedTemplate = ($response.content | ConvertFrom-Json)
                write-host "Template '$($oldtemplate.Id)' updated to version $($updatedTemplate.version)"
            } 
            else {
                write-host "Template has not changed - skipping upload"
            }
        }
        else {
            write-host "Template was not found on Octopus Deploy server"

            $newTemplate = Create-Template -InputFile $inputFile
            $json = Convert-ToJson -newTemplate $newTemplate
            $json | Set-Content -Path $outputFile

            write-host "Uploading template"
            $response = Invoke-WebRequest -Uri "$octopusURI/api/actiontemplates" -method POST -body $json -Headers @{"X-Octopus-ApiKey"=$apikey} -UseBasicParsing    
        
            $updatedTemplate = ($response.content | ConvertFrom-Json)
            write-host "Template uploaded with id '$($updatedTemplate.id)'"
        }
    }
    catch [Microsoft.PowerShell.Commands.WriteErrorException]
    {
        Write-Output $_
        exit 1
    }
}

############################

try {
    Remove-Item "*.TestResults.xml" -recurse

    $overallResult = $true
    foreach ($inputFile in (Get-ChildItem "$PSScriptRoot\StepTemplates" -filter "*.steptemplate.ps1"))
    {
        try
        {
            Write-Host "PROCESSING STEP TEMPLATES"
            Write-Host "================================="
            Write-Host "Processing $inputFile"

            Run-Tests $inputFile.FullName
            if (Test-Path Env:\TEAMCITY_VERSION) {
                #only upload if we are running under teamcity
                Upload-StepTemplateIfChanged -inputFile $inputFile.FullName -octopusURI $ENV:OctopusURI -apikey $ENV:OctopusApikey
                #Upload-StepTemplateIfChanged -inputFile $inputFile.FullName -octopusURI $ENV:TestOctopusURI -apikey $ENV:TestOctopusApikey
            }

        }
        catch
        {
            $overallResult = $false
            Write-Error -ErrorRecord $_
        }
    }

    foreach ($inputfile in (Get-ChildItem "$PSScriptRoot\ScriptModules" -filter "*.scriptmodule.ps1"))
    {
        try
        {
            Write-Host "PROCESSING SCRIPT MODULES"
            Write-Host "================================="
            Write-Host "Processing $inputFile"

            Run-Tests $inputFile.FullName
            if (Test-Path Env:\TEAMCITY_VERSION) {
                #only upload if we are running under teamcity
                Upload-ScriptModule -inputFile $inputFile.FullName -octopusURI $ENV:OctopusURI -apikey $ENV:OctopusApikey
            }
        }
        catch
        {
            Write-Error -ErrorRecord $_
        }
    }

    if ($overallResult) {
        exit 0
    }
    else {
        exit 1
    }
}
catch [System.Exception] {
    Write-Error $_
    exit 1
}