<#

.SYNOPSIS
    Serializes an object into a string containing PowerShell code that can be used to re-create the object.

.EXAMPLE

$myValue = @{ "myKey1" = "myValue1"; "myKey2" = @( "myItem1", "myItem2") };
$mySource = ConvertTo-PSSource -InputObject $myValue;
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
        [object] $InputObject,

        [Parameter(Mandatory=$false)]
        [int] $IndentLevel = 0

    )

    function ConvertTo-PSString
    {
        param( [string] $InputObject )
        $InputObject = $InputObject.Replace("``", "````");
        $InputObject = $InputObject.Replace("`"", "```"");
        $InputObject = $InputObject.Replace("`$", "```$");
        $InputObject = $InputObject.Replace("`r", "``r");
        $InputObject = $InputObject.Replace("`n", "``n");
        $InputObject = $InputObject.Replace("`t", "``t");
        return "`"$InputObject`"";
    }

    $indent = " " * 4;
    $baseIndent = $indent * $IndentLevel;

    switch( $true )
    {

        { $InputObject -eq $null } {
            return "`$null";
        }

        { $InputObject -is [bool] } {
	    if( [bool] $InputObject )
	    {
                return "`$true";
	    }
	    else
	    {
                return "`$false";
	    }
        }

        { $InputObject -is [string] } {
            return (ConvertTo-PSString -InputObject $InputObject);
        }

        { $InputObject -is [hashtable] } {
            $source = new-object System.Text.StringBuilder;
            $keys = @( $InputObject.Keys | sort-object );
            if( $keys.Length -eq 0 )
            {
                [void] $source.Append("@{}");
            }
            else
            {
                $source = new-object System.Text.StringBuilder;
                [void] $source.Append("@{");
                [void] $source.AppendLine();
                foreach( $key in $keys )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSSource -InputObject $key));
                    [void] $source.Append(" = ");
                    [void] $source.Append((ConvertTo-PSSource -InputObject $InputObject[$key] -IndentLevel ($IndentLevel + 1)));
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append("}");
            }
            return $source.ToString();
        }

        { $InputObject -is [PSCustomObject] } {
            $source = new-object System.Text.StringBuilder;
            $properties = @( $InputObject.psobject.Properties.GetEnumerator() );
            if( $properties.Length -eq 0 )
            {
                [void] $source.Append("new-object PSCustomObject");
            }
            else
            {
                [void] $source.AppendLine("new-object PSCustomObject -Property ([ordered] @{");
                foreach( $property in $InputObject.psobject.Properties )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSSource -InputObject $property.Name));
                    [void] $source.Append(" = ");
                    [void] $source.Append((ConvertTo-PSSource -InputObject $property.Value -IndentLevel ($IndentLevel + 1)));
                    [void] $source.AppendLine();
                }
                [void] $source.Append($baseIndent);
                [void] $source.Append("})");
            }
            return $source.ToString();
        }

        { $InputObject.GetType().IsArray } {
            $source = new-object System.Text.StringBuilder;
            if( $InputObject.Length -eq 0 )
            {
                [void] $source.Append("@()");
            }
            else
            {
                [void] $source.Append("@(");
                [void] $source.AppendLine();
                for( $index = 0; $index -lt $InputObject.Length; $index++ )
                {
                    [void] $source.Append($baseIndent);
                    [void] $source.Append($indent);
                    [void] $source.Append((ConvertTo-PSSource -InputObject $InputObject[$index] -IndentLevel ($IndentLevel + 1)));
                    if( $index -lt ($InputObject.Length - 1) )
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
            return $InputObject.ToString();
        }

    }

}