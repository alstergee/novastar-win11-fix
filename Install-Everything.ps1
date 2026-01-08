#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Complete Novastar software installation and fix for Windows 11

.DESCRIPTION
    This script:
    1. Installs SmartLCT (if not already installed)
    2. Installs V-Can (if not already installed)
    3. Replaces broken MarsServerProvider with working version from NovaLCT V5.8.1
    4. Installs the Nova ProHD USB driver

.PARAMETER SkipSmartLCT
    Skip SmartLCT installation

.PARAMETER SkipVCan
    Skip V-Can installation

.PARAMETER SkipDriver
    Skip driver installation

.EXAMPLE
    .\Install-Everything.ps1

.EXAMPLE
    .\Install-Everything.ps1 -SkipVCan
#>
param(
    [switch]$SkipSmartLCT,
    [switch]$SkipVCan,
    [switch]$SkipDriver
)

$ErrorActionPreference = "Stop"

# Paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installersDir = Join-Path $scriptDir "Installers"
$fixedMars = Join-Path $scriptDir "MarsServerProvider_Fixed"
$driverDir = Join-Path $scriptDir "Driver_NovaProHD"

$smartLctInstaller = Join-Path $installersDir "SmartLCT V3.5.13 Setup.exe"
$vcanInstaller = Join-Path $installersDir "V-Can V3.8.0 Setup.exe"

$smartLctPath = "C:\Program Files (x86)\Nova Star\SmartLCT"
$vcanPath = "C:\Program Files (x86)\Nova Star\V-Can"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Novastar Complete Install + Fix" -ForegroundColor Cyan
Write-Host "  Windows 11 Edition" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Kill any running Nova processes
Write-Host "Stopping any running Novastar processes..." -ForegroundColor Yellow
$processes = @("SmartLCT", "V-Can", "VCan", "MarsServerProvider", "NovaLCT", "NovaMonitorManager")
foreach ($proc in $processes) {
    Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# ============================================
# STEP 1: Install SmartLCT
# ============================================
if (-not $SkipSmartLCT) {
    Write-Host ""
    Write-Host "=== Step 1: SmartLCT Installation ===" -ForegroundColor Cyan

    if (Test-Path "$smartLctPath\Bin\SmartLCT.exe") {
        Write-Host "  SmartLCT already installed, skipping..." -ForegroundColor Gray
    } elseif (Test-Path $smartLctInstaller) {
        Write-Host "  Installing SmartLCT V3.5.13..." -ForegroundColor White
        Write-Host "  (This may take a minute, please wait...)" -ForegroundColor Gray

        # Try silent install first, fall back to normal if it fails
        $proc = Start-Process -FilePath $smartLctInstaller -ArgumentList "/S" -Wait -PassThru

        if ($proc.ExitCode -ne 0) {
            Write-Host "  Silent install failed, trying normal install..." -ForegroundColor Yellow
            Write-Host "  Please complete the installer manually." -ForegroundColor Yellow
            Start-Process -FilePath $smartLctInstaller -Wait
        }

        if (Test-Path "$smartLctPath\Bin\SmartLCT.exe") {
            Write-Host "  SmartLCT installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: SmartLCT may not have installed correctly." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  WARNING: SmartLCT installer not found at:" -ForegroundColor Yellow
        Write-Host "  $smartLctInstaller" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "=== Step 1: SmartLCT Installation (SKIPPED) ===" -ForegroundColor Gray
}

# ============================================
# STEP 2: Install V-Can
# ============================================
if (-not $SkipVCan) {
    Write-Host ""
    Write-Host "=== Step 2: V-Can Installation ===" -ForegroundColor Cyan

    if (Test-Path "$vcanPath\Bin\V-Can.exe") {
        Write-Host "  V-Can already installed, skipping..." -ForegroundColor Gray
    } elseif (Test-Path $vcanInstaller) {
        Write-Host "  Installing V-Can V3.8.0..." -ForegroundColor White
        Write-Host "  (This may take a minute, please wait...)" -ForegroundColor Gray

        # Try silent install
        $proc = Start-Process -FilePath $vcanInstaller -ArgumentList "/S" -Wait -PassThru

        if ($proc.ExitCode -ne 0) {
            Write-Host "  Silent install failed, trying normal install..." -ForegroundColor Yellow
            Write-Host "  Please complete the installer manually." -ForegroundColor Yellow
            Start-Process -FilePath $vcanInstaller -Wait
        }

        if (Test-Path "$vcanPath\Bin\V-Can.exe") {
            Write-Host "  V-Can installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: V-Can may not have installed correctly." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  WARNING: V-Can installer not found at:" -ForegroundColor Yellow
        Write-Host "  $vcanInstaller" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "=== Step 2: V-Can Installation (SKIPPED) ===" -ForegroundColor Gray
}

# Kill processes again before patching
Write-Host ""
Write-Host "Stopping processes before applying fix..." -ForegroundColor Yellow
foreach ($proc in $processes) {
    Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# ============================================
# STEP 3: Apply Mars Fix
# ============================================
Write-Host ""
Write-Host "=== Step 3: Applying MarsServerProvider Fix ===" -ForegroundColor Cyan

if (-not (Test-Path $fixedMars)) {
    Write-Host "  ERROR: Fixed MarsServerProvider not found at:" -ForegroundColor Red
    Write-Host "  $fixedMars" -ForegroundColor Red
} else {
    # Fix SmartLCT
    $smartLctMars = "$smartLctPath\Bin\MarsServerProvider"
    if (Test-Path $smartLctMars) {
        Write-Host "  Patching SmartLCT MarsServerProvider..." -ForegroundColor White
        Copy-Item -Path "$fixedMars\*" -Destination $smartLctMars -Recurse -Force
        Write-Host "    SmartLCT patched!" -ForegroundColor Green
    } else {
        Write-Host "  SmartLCT not found, skipping patch..." -ForegroundColor Gray
    }

    # Fix V-Can
    $vcanMars = "$vcanPath\Bin\MarsServerProvider"
    if (Test-Path $vcanMars) {
        Write-Host "  Patching V-Can MarsServerProvider..." -ForegroundColor White
        Copy-Item -Path "$fixedMars\*" -Destination $vcanMars -Recurse -Force
        Write-Host "    V-Can patched!" -ForegroundColor Green
    } else {
        Write-Host "  V-Can not found, skipping patch..." -ForegroundColor Gray
    }
}

# ============================================
# STEP 4: Install Driver
# ============================================
if (-not $SkipDriver) {
    Write-Host ""
    Write-Host "=== Step 4: Installing Nova ProHD Driver ===" -ForegroundColor Cyan

    $infFile = Join-Path $driverDir "nova_prohd.inf"
    if (Test-Path $infFile) {
        Write-Host "  Adding driver to driver store..." -ForegroundColor White
        $result = pnputil /add-driver $infFile /install 2>&1

        if ($LASTEXITCODE -eq 0 -or $result -match "successfully") {
            Write-Host "  Driver added to store!" -ForegroundColor Green
        } else {
            Write-Host "  Driver may already be installed." -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "  NOTE: If device is not detected after install:" -ForegroundColor Yellow
        Write-Host "  1. Open Device Manager" -ForegroundColor White
        Write-Host "  2. Find the NovaStar device" -ForegroundColor White
        Write-Host "  3. Update driver -> Browse -> Let me pick" -ForegroundColor White
        Write-Host "  4. Select 'Nova ProHD' under 'libusb-win32 devices'" -ForegroundColor White
    } else {
        Write-Host "  WARNING: Driver INF not found at:" -ForegroundColor Yellow
        Write-Host "  $infFile" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "=== Step 4: Driver Installation (SKIPPED) ===" -ForegroundColor Gray
}

# ============================================
# DONE
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now:" -ForegroundColor Yellow
Write-Host "  1. Connect your VX400 via USB" -ForegroundColor White
Write-Host "  2. Launch SmartLCT or V-Can" -ForegroundColor White
Write-Host "  3. Device should be detected automatically" -ForegroundColor White
Write-Host ""
Write-Host "If device is NOT detected, manually select" -ForegroundColor Gray
Write-Host "'Nova ProHD' driver in Device Manager." -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
