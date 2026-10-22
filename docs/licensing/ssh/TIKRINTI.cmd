@echo off
setlocal
set "ARCHIVE=%~1"
if not defined ARCHIVE set "ARCHIVE=%~dp0Grandiniu_LD_pilnas_paketas_licencija_EN_LT_2026-10-22.zip"
if not exist "%ARCHIVE%" (
  echo Archive not found. Pass its full path as the first argument.
  exit /b 2
)
ssh-keygen -Y verify -f "%~dp0allowed_signers" -I grandiniu-ld-release-20261022-v11 -n grandiniu-ld-release -s "%~dp0Grandiniu_LD_pilnas_paketas_licencija_EN_LT_2026-10-22.zip.sig" < "%ARCHIVE%"
exit /b %ERRORLEVEL%
