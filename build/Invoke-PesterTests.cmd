@echo off

set psscript=C:\asos\src\github\mikeclayton\OctopusStepTemplateCi\build\Invoke-PesterTests.ps1

pushd C:\asos\src\tfs\kingsway\ASOS\BRB\OctopusDeployStepTemplates\Release\src

powershell -NoProfile -NonInteractive -File "%psscript%"

popd
