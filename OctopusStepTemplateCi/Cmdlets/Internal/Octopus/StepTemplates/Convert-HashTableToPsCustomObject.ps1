<#
.NAME
    Convert-HashTableToPsCustomObject

.SYNOPSIS
    Converts a hash table to a PsCustomObject
#>
function Convert-HashTableToPsCustomObject { 
     param ( 
        $InputObject
     )     
     foreach ($Hashtable in $InputObject) { 
         if ($Hashtable.GetType().Name -eq 'hashtable') { 
             $output = New-Object -TypeName PsObject; 
             Add-Member -InputObject $output -MemberType ScriptMethod -Name AddNote -Value {  
                 Add-Member -InputObject $this -MemberType NoteProperty -Name $args[0] -Value $args[1]; 
             }; 
             $Hashtable.Keys | Sort-Object | % {  
                 $output.AddNote($_, $Hashtable.$_);  
             } 
             $output; 
         } else { 
             Write-Error "Object is not a hashtable"; 
         } 
     } 
}