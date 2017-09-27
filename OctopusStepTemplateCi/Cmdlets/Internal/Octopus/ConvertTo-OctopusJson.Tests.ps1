$ErrorActionPreference = "Stop";
Set-StrictMode -Version "Latest";

Describe "ConvertTo-OctopusDeploy" {

    It "when InputObject is null" {
        $input    = $null;
        $expected = "null";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty string" {
        $input    = [string]::Empty;
        $expected = "`"`"";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a simple string" {
        $input    = "my simple string";
        $expected = "`"my simple string`"";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string with apostrophes" {
        $input    = "my string with 'apostrophes'";
        $expected = "`"my string with 'apostrophes'`"";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string with special characters" {
        $input    = "my \ `"string`" with `r`n special `t characters";
        $expected = "`"my \\ \`"string\`" with \r\n special \t characters`"";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string with whitespace between curly brackets" {
        $input    = "{    }";
        $expected = "`"{    }`"";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a string resembling the json escape sequence for an apostrophe" {
        $input    = "\u0027";
        $expected = "`"\\u0027`"";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a positive integer" {
        $input    = 100;
        $expected = "100";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a negative integer" {
        $input    = -100;
        $expected = "-100";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty array" {
        $input    = @();
        $expected = "[]";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a populated array" {
        $input    = @( $null, 100, "my string" );
        $expected = "[`r`n  null,`r`n  100,`r`n  `"my string`"`r`n]";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty hash table" {
        $input    = @{};
        $expected = "{}";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an empty PSCustomObject" {
	$input    = new-object PSCustomObject;
        $expected = "{}";
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is a populated PSCustomObject" {
	$input    = [PSCustomObject] [ordered] @{
            "myNull"     = $null
            "myInt"      = 100
            "myString"   = "text"
	    "myArray"    = @( $null, 200, "string", [PSCustomObject] [ordered] @{ "nestedProperty" = "nestedValue" } )
	    "myPsObject" = [PSCustomObject] [ordered] @{ "childProperty" = "childValue" }
	};
        $expected = @"
{
  "myNull": null,
  "myInt": 100,
  "myString": "text",
  "myArray": [
    null,
    200,
    "string",
    {
      "nestedProperty": "nestedValue"
    }
  ],
  "myPsObject": {
    "childProperty": "childValue"
  }
}
"@
        ConvertTo-OctopusJson -InputObject $input `
            | Should Be $expected;
    }

    It "when InputObject is an unhandled type" {
        { ConvertTo-OctopusJson -InputObject ([System.Guid]::NewGuid()) } `
            | Should Throw "Unhandled input object type 'System.Guid'.";
    }

}