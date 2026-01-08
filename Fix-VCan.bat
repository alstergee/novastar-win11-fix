@echo off
:: ============================================
:: V-Can Fix for Windows 11
:: ============================================
:: Fixes the broken MarsServerProvider that prevents
:: V-Can from communicating with your VX400.

echo.
echo  V-Can Fix for Windows 11
echo  ========================
echo.
echo  This will fix V-Can communication issues.
echo  You'll see a UAC prompt - click Yes to allow.
echo.
pause

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Fix-VCan.ps1\"' -Verb RunAs"
