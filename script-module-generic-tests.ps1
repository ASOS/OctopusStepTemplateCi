#requires -version 3

# ------------------------------------------------
# Octopus Deploy Script Module Generic Tests
# ------------------------------------------------
#
# Ver    Who                             When        What
# 1.00   Leslie Lintott                  03-09-15    Initial Version
# 1.01   Matt Richardson (DevOpsGuys)    24-11-15    Add validation to ensure a script module description is supplied
#
# ------------------------------------------------

param ([string] $sut)


Describe 'Script Module parameters' {
 	Context "Script Module contains metadata parameters" {
        $filename = Split-Path -Leaf $sut

		It "Script Module '$filename' should contain metadata variable `$ScriptModuleName" {
			{ Get-VariableFromScriptFile $sut "ScriptModuleName" } | Should Not Throw
		}

        It "Script Module '$filename' should contain metadata variable `$ScriptModuleDescription" {
			{ Get-VariableFromScriptFile $sut "ScriptModuleDescription" } | Should Not Throw
		}
    }
}