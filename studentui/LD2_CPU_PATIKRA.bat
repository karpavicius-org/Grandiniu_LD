@echo off
setlocal DisableDelayedExpansion
set "LD_SCILAB_CLI="
if defined SCILAB_BIN if exist "%SCILAB_BIN%" (
  for %%I in ("%SCILAB_BIN%") do if exist "%%~dpIScilex.exe" set "LD_SCILAB_CLI=%%~dpIScilex.exe"
)
if not defined LD_SCILAB_CLI (
  for /d %%D in ("%ProgramFiles%\scilab-2026.1.0" "%ProgramFiles%\scilab-*" "%LOCALAPPDATA%\Programs\scilab-*") do (
    if exist "%%~D\bin\Scilex.exe" set "LD_SCILAB_CLI=%%~D\bin\Scilex.exe"
  )
)
if not defined LD_SCILAB_CLI (
  echo ERROR: Scilab Scilex.exe nerastas.
  pause
  exit /b 1
)
set "LD2_LOG=%~dp0LD2_CPU_PATIKRA.log"
echo Atliekami visi 64 LD2 automatikos CPU bandymai...
"%LD_SCILAB_CLI%" -nb -f "%~dp0LD2\LD2_AUTO_SELFTEST.sce" > "%LD2_LOG%" 2>&1
findstr /C:"PASS: 64 complete callback workflows" "%LD2_LOG%" >nul
if errorlevel 1 (
  echo FAIL: LD2 patikra nepraejo. Klaida: %LD2_LOG%
  type "%LD2_LOG%"
  pause
  exit /b 1
)
echo PASS: LD2 automatikos 64 variantu testai. Zurnalas: %LD2_LOG%
pause
exit /b 0
