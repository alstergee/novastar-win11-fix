@echo off
:: Novastar SmartLCT Driver Diagnostic Launcher
:: Requires Administrator privileges

echo.
echo ==========================================
echo  Novastar SmartLCT Driver Diagnostic
echo ==========================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] This script requires Administrator privileges.
    echo     Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: Run the diagnostic
powershell -ExecutionPolicy Bypass -File "%~dp0Diagnose-NovastarDriver.ps1"

echo.
pause
