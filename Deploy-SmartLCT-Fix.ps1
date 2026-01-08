#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deploys the SmartLCT Mars fix for Windows 11

.DESCRIPTION
    SmartLCT's bundled MarsServerProvider is broken on Windows 11.
    This script:
    1. Replaces MarsServerProvider with a working version from NovaLCT V5.8.1
    2. Installs the Nova ProHD USB driver for device detection

.PARAMETER Restore
    Restores the original SmartLCT MarsServerProvider from backup

.PARAMETER SkipDriver
    Skip the driver installation step

.EXAMPLE
    .\Deploy-SmartLCT-Fix.ps1

.EXAMPLE
    .\Deploy-SmartLCT-Fix.ps1 -Restore

.EXAMPLE
    .\Deploy-SmartLCT-Fix.ps1 -SkipDriver
#>
param(
    [switch]$Restore,
    [switch]$SkipDriver
)

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixedMars = Join-Path $scriptDir "MarsServerProvider_Fixed"
$driverDir = Join-Path $scriptDir "Driver_NovaProHD"
$smartLctMars = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider"
$backupDir = Join-Path $scriptDir "MarsServerProvider_Backup"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SmartLCT Mars Fix for Windows 11" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if SmartLCT is installed
if (-not (Test-Path $smartLctMars)) {
    Write-Host "ERROR: SmartLCT not found at expected location:" -ForegroundColor Red
    Write-Host "  $smartLctMars" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install SmartLCT first, then run this script." -ForegroundColor Yellow
    exit 1
}

# Check if fixed Mars files exist
if (-not (Test-Path $fixedMars)) {
    Write-Host "ERROR: Fixed MarsServerProvider files not found at:" -ForegroundColor Red
    Write-Host "  $fixedMars" -ForegroundColor Red
    exit 1
}

# Kill running processes
Write-Host "Stopping SmartLCT and MarsServerProvider..." -ForegroundColor Yellow
$processes = @("SmartLCT", "MarsServerProvider", "NovaLCT", "NovaMonitorManager")
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
    Get-ChildItem $smartLctMars -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

    # Copy backup
    Copy-Item -Path "$backupDir\*" -Destination $smartLctMars -Recurse -Force

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
        Copy-Item -Path "$smartLctMars\*" -Destination $backupDir -Recurse -Force
        Write-Host "  Backed up to: $backupDir" -ForegroundColor Gray
    } else {
        Write-Host "Backup already exists, skipping..." -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "=== Step 1: Deploying fixed MarsServerProvider ===" -ForegroundColor Cyan

    # Copy fixed files (overwrite existing)
    Copy-Item -Path "$fixedMars\*" -Destination $smartLctMars -Recurse -Force
    Write-Host "  MarsServerProvider replaced successfully!" -ForegroundColor Green

    # Install driver
    if (-not $SkipDriver) {
        Write-Host ""
        Write-Host "=== Step 2: Installing Nova ProHD USB Driver ===" -ForegroundColor Cyan

        if (Test-Path $driverDir) {
            $infFile = Join-Path $driverDir "nova_prohd.inf"
            if (Test-Path $infFile) {
                Write-Host "  Adding driver to driver store..." -ForegroundColor Gray
                $result = pnputil /add-driver $infFile /install 2>&1
                if ($LASTEXITCODE -eq 0 -or $result -match "successfully") {
                    Write-Host "  Driver installed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "  Driver may already be installed or requires device to be connected." -ForegroundColor Yellow
                    Write-Host "  Output: $result" -ForegroundColor Gray
                }
            } else {
                Write-Host "  WARNING: Driver INF not found at $infFile" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  WARNING: Driver folder not found at $driverDir" -ForegroundColor Yellow
            Write-Host "  You may need to manually install the Nova ProHD driver." -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "Skipping driver installation (use -SkipDriver:$false to install)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  SUCCESS! SmartLCT fix deployed." -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Plug in the VX400 (if not already connected)" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Launch SmartLCT - it should show 'Service is connected'" -ForegroundColor White
    Write-Host "   and detect the VX400 automatically." -ForegroundColor White
    Write-Host ""
    Write-Host "3. If device NOT detected, open Device Manager:" -ForegroundColor White
    Write-Host "   - Find NovaStar device -> Update driver" -ForegroundColor Gray
    Write-Host "   - Browse my computer -> Let me pick from list" -ForegroundColor Gray
    Write-Host "   - Select 'Nova ProHD' under 'libusb-win32 devices'" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
