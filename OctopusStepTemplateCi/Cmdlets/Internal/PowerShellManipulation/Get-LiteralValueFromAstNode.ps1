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

    It also side-steps an issue with ScriptBlock.Invoke() where it unrolls the return value
    if it's an array containing a single item. For example {@(100)}.Invoke() evaluates to
    an array with one item, which then gets unrolled to just return the item itself, i.e. 100.

    By comparison, Get-LiteralValueFromAstNode preserves the original script block structure
    and will return @(100) if the script block is {@(100)} or 100 if the script block is {100}.

.EXAMPLE
    $node  = { @( 100 ) }.Ast.EndBlock.Statements[0].PipelineElements[0];
    $value = Get-LiteralValueFromAstNode -Node $node;

.EXAMPLE
    $node  = { 100 }.Ast.EndBlock.Statements[0].PipelineElements[0];
    $value = Get-LiteralValueFromAstNode -Node $node;
    
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

        { $Node -is [System.Management.Automation.Language.StringConstantExpressionAst] } {

            # represents a string constant with no variable references or no sub-expressions.
            # e.g. "my string"
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.stringconstantexpressionast?view=powershellsdk-1.1.0

            return $node.Value;

        }

        { $Node -is [System.Management.Automation.Language.ConstantExpressionAst] } {

            # represents a constant value - e.g. 100
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.constantexpressionast?view=powershellsdk-1.1.0

            return $Node.Value;

        }

        { $Node -is [System.Management.Automation.Language.ExpandableStringExpressionAst] } {

            # represents a string which contains variable references (e.g. "my $true string", "my $var string") or sub-expressions (e.g. "my $(10 * 2) string"),
            # where the values need to be expanded in order to compute the literal string value
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.expandablestringexpressionast?view=powershellsdk-1.1.0

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

            # represents a reference to a variable that needs to be resolved in order to evaluate its value
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.variableexpressionast?view=powershellsdk-1.1.0

            # only evaluate built-in literal values, not user defined variables
            # or built-in variables that can have different values on different systems.
            if( -not $Node.IsConstantVariable )
            {
                throw new-object System.InvalidOperationException("Only variable that reference constant values can be evaluated (e.g. `$true, `$false, `$null).");
            }

            switch( $Node.VariablePath.UserPath )
            {
                "null"  { return $null; }
                "true"  { return $true; }
                "false" { return $false; }
                default {
                    throw new-object System.InvalidOperationException("Variable '`$$($Node.VariablePath.UserPath)' not supported.");
                }
            }

        }

        { $Node -is [System.Management.Automation.Language.BinaryExpressionAst] } {

            # represents an operator that requires two parameters (e.g. { 2 + 2 } or  { "my" + "string" } );
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.binaryexpressionast?view=powershellsdk-1.1.0

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

            # represents the first expression in a pipeleine
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.commandexpressionast?view=powershellsdk-1.1.0

            $value = Get-LiteralValueFromAstNode -Node $Node.Expression;

            return @(, $value);

        }

        { $Node -is [System.Management.Automation.Language.ArrayExpressionAst] } {

            # represents an array expression - e.g. { @( 1, 2, 3 ) }, as opposed to
	    # an array literal - e.g. { 1, 2, 3 }
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.arrayexpressionast?view=powershellsdk-1.1.0

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

            # represents an array literal - e.g. { 1, 2, 3 }
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.arrayliteralast?view=powershellsdk-1.1.0

            $results = @();
            if( $null -ne $Node.Elements )
            {
                foreach( $expressionAst in $Node.Elements )
                {
                    $results += Get-LiteralValueFromAstNode -Node $expressionAst;
                }
            }

            return @(, $results);

        }

        { $Node -is [System.Management.Automation.Language.HashtableAst] } {

            # represents a hashtable literal - e.g. { @{ "key" = "value" } }
            # see https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.language.hashtableast?view=powershellsdk-1.1.0

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
