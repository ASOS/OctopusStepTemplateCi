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
    Get-LiteralValueFromAstNode

.SYNOPSIS
    Gets the literal value represented by a PowerShell Ast node.

.DESCRIPTION
    Gets the literal value represented by a PowerShell Ast node.

    This is safer than calling Invoke() on a script block as it won't execute any
    instruction statements (e.g. write-host, remove-item, format-volume) while evaluating.

    It also side-steps an issue with ScriptBlock.Invoke which converts an array containing
    one item into the same output as the unrolled item. For example {100}.Invoke() returns
    an object of type [System.Collections.ObjectModel.Collection[[System.Management.Automation.PSObject]]
    containing one item with a value of 100, but {@(100)}.Invoke() also returns exactly
    the same result. There's no way of knowing whether a return value of 100 from Invoke()
    was declared inside the script block as a free-standing value or as an array with a
    single item. By contrast, Get-LiteralValueFromAstNode will return an array containing
    a single item if that's what the Ast specifically represents.
    
#>
function Get-LiteralValueFromAstNode
{

    param
    (

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Language.Ast]
        $Node

    )

    switch( $true )
    {

        { $Node -is [System.Management.Automation.Language.ConstantExpressionAst] } {
            # bool, int32
            return $Node.Value;
        }

        { $Node -is [System.Management.Automation.Language.StringConstantExpressionAst] } {
            return $node.Value;
        }

        { $Node -is [System.Management.Automation.Language.ExpandableStringExpressionAst] } {
            # reverse the nested expressions so we can substitute them without tracking start positions
            $nestedExpressions = @($Node.NestedExpressions);
            [array]::Reverse($nestedExpressions);
	    # substitute the values
            # e.g. "[$null|$true|$false]" -> "[|True|False]";
	    $result = $Node.Value;
	    foreach( $nestedExpression in $nestedExpressions )
            {
                # work out the range to substitute
                $relativeStart = $nestedExpression.Extent.StartOffset - $Node.Extent.StartOffset - 1;
                $relativeEnd = $nestedExpression.Extent.EndOffset - $Node.Extent.StartOffset - 1;
                $head = $result.Substring(0, $relativeStart);
                $tail = $result.Substring($relativeEnd);
                # work out the value to substitute
                $nestedValue = Get-LiteralValueFromAstNode -Node $nestedExpression;
                if( $nestedValue -ne $null )
                {
                    $nestedValue = $nestedValue.ToString();
                }
                # perform the substitution
                $result = $head + $nestedValue + $tail;
            }
            return $result;
        }

        { $Node -is [System.Management.Automation.Language.VariableExpressionAst] } {
            # only evaluate built-in literal values, not user defined variables
	    # or built-in variables that can have different values on different systems.
            switch( $Node.VariablePath.UserPath )
            {
                "null"  { return $null; }
                "true"  { return $true; }
                "false" { return $false; }
                default {
                    throw new-object System.InvalidOperationException("Variable values not supported.");
                }
            }
        }

        { $Node -is [System.Management.Automation.Language.BinaryExpressionAst] } {
            switch( $Node.Operator )
            {
                "Plus" {
                    $leftValue  = Get-LiteralValueFromAstNode -Node $Node.Left;
                    $rightValue = Get-LiteralValueFromAstNode -Node $Node.Right;
                    $result     = $leftValue + $rightValue;
                    return @(, $result);
                }
                default {
                    throw new-object System.InvalidOperationException("Operator not supported.");
                }
            }
        }

        { $Node -is [System.Management.Automation.Language.CommandExpressionAst] } {
	    $value = Get-LiteralValueFromAstNode -Node $Node.Expression;
	    return @(, $value);
	}

        { $Node -is [System.Management.Automation.Language.ArrayExpressionAst] } {
            if( $Node.StaticType -ne [System.Object[]] )
	    {
                # we don't handle arrays of other types of objects yet (e.g. [System.String[]])
                throw new-object System.InvalidOperationException("Array element type not supported.");
	    }
            # if a comma is (accidentally?) missed out between elements that are separated by
            # line-breaks, the powershell parser will create a separate sub-expression statement
            # for each group of items that *are* comma separated.
            #
            # e.g.
            #
            # $x = @(
            #     10 # <-- look no comma!
            #     20
            # )
            #
            # in this case, there are multiple statements and we need to aggregate the items
            $results = @();
            foreach( $statementAst in $Node.SubExpression.Statements )
            {
                if( ($statementAst -isnot [System.Management.Automation.Language.PipelineAst]) -or
                    ($statementAst.PipelineElements.Count -ne 1) -or
                    ($statementAst.PipelineElements[0] -isnot [System.Management.Automation.Language.CommandExpressionAst]) )
                {
                    throw new-object System.InvalidOperationException("Array expression does not represent a literal array.");
                }
                $itemListExpression = $statementAst.PipelineElements[0].Expression;
                $results += Get-LiteralValueFromAstNode -Node $itemListExpression;
            }
            return @(, $results);
        }

        { $Node -is [System.Management.Automation.Language.ArrayLiteralAst] } {
            $results = @();
            foreach( $expressionAst in $Node.Elements )
            {
                $results += Get-LiteralValueFromAstNode -Node $expressionAst;
            }
            return @(, $results);
        }

        { $Node -is [System.Management.Automation.Language.HashtableAst] } {
            $result = @{};
	    foreach( $kvp in $Node.KeyValuePairs )
            {
               # convert the key
               $key = Get-LiteralValueFromAstNode -Node $kvp.Item1;
               # convert the value
	       if( ($kvp.Item2 -isnot [System.Management.Automation.Language.PipelineAst]) -or
                   ($kvp.Item2.PipelineElements.Count -ne 1 ) )
               {
                   throw new-object System.InvalidOperationException("Hashtable expression could not be processed.");
               }	       
               $value = Get-LiteralValueFromAstNode -Node $kvp.Item2.PipelineElements[0];
               # append to the result set
	       $result.Add($key, $value);
            }
            return @(, $result);
        }

        default {
            throw new-object System.InvalidOperationException("Ast nodes of type '$($Node.GetType().FullName)' are not supported.");
        }

    }

}
