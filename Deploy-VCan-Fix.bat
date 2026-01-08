@echo off
:: V-Can Mars Fix Launcher
:: This batch file runs the PowerShell deployment script as Administrator

echo.
echo  V-Can Mars Fix for Windows 11
echo  =============================
echo.
echo  This will fix V-Can communication issues on Windows 11.
echo  You may see a UAC prompt - click Yes to allow.
echo.
pause

powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File \"%~dp0Deploy-VCan-Fix.ps1\"' -Verb RunAs"
