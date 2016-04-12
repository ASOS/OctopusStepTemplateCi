#requires -Version 3.0

param ([string] $sut)


Describe 'Script Module parameters' {
 	Context "Script Module contains metadata parameters" {

		It "Script Module should contain `$ScriptModuleName" {
			{ Get-VariableFromScriptFile $sut "ScriptModuleName" } | Should Not Throw
		}
    }
}