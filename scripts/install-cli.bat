@echo off
REM oortcodex-cli one-click installer (cmd entry -> delegates to install-cli.ps1)
REM Keep this file ASCII-only: cmd parses it with the legacy codepage, non-ASCII text would garble.
REM Chinese output is produced by install-cli.mjs (started through install-cli.ps1).

setlocal
chcp 65001 >nul
set "SCRIPT_DIR=%~dp0"
set "PS1_SCRIPT=%SCRIPT_DIR%install-cli.ps1"

if not exist "%PS1_SCRIPT%" (
    echo [oortcodex] ERROR: core script not found: %PS1_SCRIPT%
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_SCRIPT%" %*
set "EXIT_CODE=%ERRORLEVEL%"

endlocal & exit /b %EXIT_CODE%
