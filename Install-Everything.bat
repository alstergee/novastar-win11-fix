@echo off
:: Novastar Complete Installer + Fix
:: One-stop shop for SmartLCT, V-Can, and Windows 11 fixes

echo.
echo  ==========================================
echo   Novastar Complete Install + Fix
echo   Windows 11 Edition
echo  ==========================================
echo.
echo  This will:
echo    1. Install SmartLCT V3.5.13
echo    2. Install V-Can V3.8.0
echo    3. Fix the broken MarsServerProvider
echo    4. Install the USB driver
echo.
echo  You will need to click "Yes" on the UAC prompt.
echo.
pause

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Install-Everything.ps1\"' -Verb RunAs"
