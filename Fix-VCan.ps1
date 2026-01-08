#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fixes V-Can communication issues on Windows 11

.DESCRIPTION
    V-Can's MarsServerProvider is broken on Windows 11 - it fails to create
    the IPC window needed for communication, causing "server register: false".

    This script replaces it with a working version from NovaLCT V5.8.1 and
    optionally installs the Nova ProHD USB driver.

.PARAMETER Restore
    Restores the original MarsServerProvider from backup

.PARAMETER SkipDriver
    Skip USB driver installation

.EXAMPLE
    .\Fix-VCan.ps1

.EXAMPLE
    .\Fix-VCan.ps1 -Restore
#>
param(
    [switch]$Restore,
    [switch]$SkipDriver
)

$ErrorActionPreference = "Stop"

# ============================================
# Configuration
# ============================================
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixedMars = Join-Path $scriptDir "MarsServerProvider_Fixed"
$driverDir = Join-Path $scriptDir "Driver_NovaProHD"
$vcanMars = "C:\Program Files (x86)\Nova Star\V-Can\Bin\MarsServerProvider"
$backupDir = Join-Path $scriptDir "Backups\VCan_MarsServerProvider"

# ============================================
# Header
# ============================================
Write-Host ""
Write-Host "  V-Can Fix for Windows 11" -ForegroundColor Cyan
Write-Host "  ========================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# Validation
# ============================================
if (-not (Test-Path $vcanMars)) {
    Write-Host "ERROR: V-Can not found." -ForegroundColor Red
    Write-Host "Expected: $vcanMars" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Install V-Can first, then run this script." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $fixedMars)) {
    Write-Host "ERROR: MarsServerProvider_Fixed folder not found." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================
# Stop running processes
# ============================================
Write-Host "Stopping V-Can processes..." -ForegroundColor Yellow
@("V-Can", "VCan", "MarsServerProvider", "NovaLCT") | ForEach-Object {
    Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# ============================================
# Restore mode
# ============================================
if ($Restore) {
    Write-Host ""
    Write-Host "RESTORE MODE" -ForegroundColor Yellow
    Write-Host ""

    if (-not (Test-Path $backupDir)) {
        Write-Host "ERROR: No backup found at $backupDir" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host "Restoring original MarsServerProvider..." -ForegroundColor Cyan
    Remove-Item "$vcanMars\*" -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item -Path "$backupDir\*" -Destination $vcanMars -Recurse -Force

    Write-Host ""
    Write-Host "Restored successfully!" -ForegroundColor Green
    Read-Host "Press Enter to exit"
    exit 0
}

# ============================================
# Apply fix
# ============================================
Write-Host ""

# Backup original (if not already backed up)
if (-not (Test-Path $backupDir)) {
    Write-Host "Backing up original MarsServerProvider..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Copy-Item -Path "$vcanMars\*" -Destination $backupDir -Recurse -Force
}

# Replace with fixed version
Write-Host "Installing fixed MarsServerProvider..." -ForegroundColor Cyan
Copy-Item -Path "$fixedMars\*" -Destination $vcanMars -Recurse -Force
Write-Host "  Done!" -ForegroundColor Green

# Install driver
if (-not $SkipDriver) {
    Write-Host ""
    Write-Host "Installing USB driver..." -ForegroundColor Cyan
    $infFile = Join-Path $driverDir "nova_prohd.inf"

    if (Test-Path $infFile) {
        $null = pnputil /add-driver $infFile /install 2>&1
        Write-Host "  Done!" -ForegroundColor Green
    } else {
        Write-Host "  Driver files not found, skipping." -ForegroundColor Yellow
    }
}

# ============================================
# Done
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Fix applied successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Connect VX400 via USB"
Write-Host "  2. Launch V-Can"
Write-Host "  3. Should detect device automatically"
Write-Host ""
Write-Host "If device not detected:" -ForegroundColor Yellow
Write-Host "  Device Manager -> NovaStar -> Update driver"
Write-Host "  -> Let me pick -> Select 'Nova ProHD'"
Write-Host ""
Read-Host "Press Enter to exit"
