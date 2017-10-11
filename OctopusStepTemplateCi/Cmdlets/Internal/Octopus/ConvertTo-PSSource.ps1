<#

.SYNOPSIS
    Serializes an object into a string containing PowerShell code that can be used to re-create the object.

.EXAMPLE

$myValue = @{ "myKey1" = "myValue1"; "myKey2" = @( "myItem1", "myItem2") };
$mySource = ConvertTo-PSSource -Value $myValue;
Write-DebugText $mySource;

"@{
    myKey1 = "myValue1"
    myKey2 = @(
        "myItem1",
    "myItem2"
    )
}"

#>
function ConvertTo-PSSource
{

    param
    (

        [Parameter(Mandatory=$false)]
        [object] $Value,

        [Parameter(Mandatory=$false)]
        [int] $IndentLevel = 0

    )

    function ConvertTo-PSString
    {
        param( [string] $Value )
        $Value = $Value.Replace("`"", "```"");
        $Value = $Value.Replace("`$", "```$");
        return "`"$Value`"";
    }

    $indent = " " * 4;
    $baseIndent = $indent * $IndentLevel;

    switch( $true )
    {

        { $Value -eq $null } {
            return "`$null";
        }

        { $Value -is [string] } {
            return (ConvertTo-PSString -Value $Value.ToString());
        }

        { $Value -is [hashtable] } {
            $source = new-object System.Text.StringBuilder;
            if( $Value.Keys.Count -eq 0 )
            {
                [void] $source.Append("@{}");
            }
            else
            {
                $source = new-object System.Text.StringBuilder;
                [void] $source.Append("@{");
                [void] $source.AppendLine();
                foreach( $key in ($Value.Keys | sort-object) )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSString -Value $key));
                    [void] $source.Append(" = ");
                    [void] $source.Append((ConvertTo-PSSource -Value $Value[$key] -IndentLevel ($IndentLevel + 1)));
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append("}");
            }
            return $source.ToString();
        }

        { $Value -is [PSCustomObject] } {
            $source = new-object System.Text.StringBuilder;
            $properties = @($Value.psobject.Properties.GetEnumerator());
            if( $properties.Length -eq 0 )
            {
                [void] $source.Append("new-object PSCustomObject");
            }
            else
            {
                [void] $source.AppendLine("new-object PSCustomObject -Property ([ordered] @{");
                foreach( $property in $Value.psobject.Properties )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSString -Value $property.Name));
                    [void] $source.Append(" = ");
                    [void] $source.Append((ConvertTo-PSSource -Value $property.Value -IndentLevel ($IndentLevel + 1)));
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append("})");
            }
            return $source.ToString();
        }

        { $Value.GetType().IsArray } {
            $source = new-object System.Text.StringBuilder;
            if( $Value.Length -eq 0 )
            {
                [void] $source.Append("@()");
            }
            else
            {
                [void] $source.Append("@(");
                [void] $source.AppendLine();
                for( $index = 0; $index -lt $Value.Length; $index++ )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSSource -Value $Value[$index] -IndentLevel ($IndentLevel + 1)));
                    if( $index -lt ($Value.Length - 1) )
                    {
                        [void] $source.Append(",");
                    }
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append(")");
            }
            return $source.ToString();
        }

        default {
            return $Value.ToString();
        }

    }

}