@echo off
:: Novastar SmartLCT Driver Fix Launcher
:: Requires Administrator privileges
:: WARNING: This modifies system drivers!

echo.
echo ==========================================
echo  Novastar SmartLCT Driver Fix
echo ==========================================
echo.
echo WARNING: This script will modify system drivers.
echo Make sure your VX400 is connected before continuing.
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

:: Run the fix
powershell -ExecutionPolicy Bypass -File "%~dp0Fix-NovastarDriver.ps1"

echo.
pause
