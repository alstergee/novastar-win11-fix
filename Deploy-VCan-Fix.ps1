#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploys the V-Can Mars fix for Windows 11

.DESCRIPTION
    V-Can's bundled MarsServerProvider is broken on Windows 11 (same as SmartLCT).
    This script replaces MarsServerProvider with a working version from NovaLCT V5.8.1

.PARAMETER Restore
    Restores the original V-Can MarsServerProvider from backup

.EXAMPLE
    .\Deploy-VCan-Fix.ps1

.EXAMPLE
    .\Deploy-VCan-Fix.ps1 -Restore
#>
param(
    [switch]$Restore
)

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixedMars = Join-Path $scriptDir "MarsServerProvider_Fixed"
$vcanMars = "C:\Program Files (x86)\Nova Star\V-Can\Bin\MarsServerProvider"
$backupDir = Join-Path $scriptDir "VCan_MarsServerProvider_Backup"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  V-Can Mars Fix for Windows 11" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if V-Can is installed
if (-not (Test-Path $vcanMars)) {
    Write-Host "ERROR: V-Can not found at expected location:" -ForegroundColor Red
    Write-Host "  $vcanMars" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install V-Can first, then run this script." -ForegroundColor Yellow
    exit 1
}

# Check if fixed Mars files exist
if (-not (Test-Path $fixedMars)) {
    Write-Host "ERROR: Fixed MarsServerProvider files not found at:" -ForegroundColor Red
    Write-Host "  $fixedMars" -ForegroundColor Red
    exit 1
}

# Kill running processes
Write-Host "Stopping V-Can and MarsServerProvider..." -ForegroundColor Yellow
$processes = @("V-Can", "VCan", "MarsServerProvider", "SmartLCT", "NovaLCT", "NovaMonitorManager")
foreach ($proc in $processes) {
    Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

if ($Restore) {
    # Restore from backup
    Write-Host ""
    Write-Host "=== RESTORE MODE ===" -ForegroundColor Yellow

    if (-not (Test-Path $backupDir)) {
        Write-Host "ERROR: No backup found at:" -ForegroundColor Red
        Write-Host "  $backupDir" -ForegroundColor Red
        exit 1
    }

    Write-Host "Restoring original MarsServerProvider from backup..." -ForegroundColor Cyan

    # Remove current files
    Get-ChildItem $vcanMars -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    # Copy backup
    Copy-Item -Path "$backupDir\*" -Destination $vcanMars -Recurse -Force

    Write-Host ""
    Write-Host "SUCCESS! Original MarsServerProvider restored." -ForegroundColor Green

} else {
    # Deploy fix
    Write-Host ""
    Write-Host "=== DEPLOY MODE ===" -ForegroundColor Yellow

    # Create backup if it doesn't exist
    if (-not (Test-Path $backupDir)) {
        Write-Host "Creating backup of original MarsServerProvider..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Copy-Item -Path "$vcanMars\*" -Destination $backupDir -Recurse -Force
        Write-Host "  Backed up to: $backupDir" -ForegroundColor Gray
    } else {
        Write-Host "Backup already exists, skipping..." -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "=== Deploying fixed MarsServerProvider ===" -ForegroundColor Cyan

    # Copy fixed files (overwrite existing)
    Copy-Item -Path "$fixedMars\*" -Destination $vcanMars -Recurse -Force
    Write-Host "  MarsServerProvider replaced successfully!" -ForegroundColor Green

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  SUCCESS! V-Can fix deployed." -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Launch V-Can - it should now connect to Mars service" -ForegroundColor White
    Write-Host ""
    Write-Host "2. If device NOT detected, the Nova ProHD driver" -ForegroundColor White
    Write-Host "   should already be installed from SmartLCT fix." -ForegroundColor White
    Write-Host ""
    Write-Host "NOTE: The driver fix from SmartLCT deployment" -ForegroundColor Gray
    Write-Host "      applies system-wide and works for V-Can too." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
