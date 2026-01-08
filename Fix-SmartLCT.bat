@echo off
:: ============================================
:: SmartLCT Fix for Windows 11
:: ============================================
:: Fixes the broken MarsServerProvider that prevents
:: SmartLCT from communicating with your VX400.

echo.
echo  SmartLCT Fix for Windows 11
echo  ===========================
echo.
echo  This will fix SmartLCT communication issues.
echo  You'll see a UAC prompt - click Yes to allow.
echo.
pause

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Fix-SmartLCT.ps1\"' -Verb RunAs"
