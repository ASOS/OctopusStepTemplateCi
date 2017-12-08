@echo off

rem generic script to execute a powershell *.ps1 file with the same base name as this *.cmd

set powershell64=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe
set powershellnative=%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe

rem if we're being called from a 32-bit process we still want to invoke the 64-bit powershell exe
if EXIST "%powershellnative%" (
    set powershell64=%powershellnative%
)

set currentdir=%~dp0
set currentdirwithoutbackslash=%currentdir:~0,-1%
set currentfilewithoutextension=%~n0

set psscript=%currentdirwithoutbackslash%\%currentfilewithoutextension%.ps1

echo calling %currentfilewithoutextension%.ps1
powershell -NoProfile -NonInteractive -File "%psscript%" %*
echo returned from %currentfilewithoutextension%.ps1

echo errorlevel = %ERRORLEVEL%
exit /b %ERRORLEVEL%
