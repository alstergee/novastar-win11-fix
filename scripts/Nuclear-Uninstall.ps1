#Requires -RunAsAdministrator
# NUCLEAR UNINSTALL - Remove ALL Novastar software and drivers

$ErrorActionPreference = "Continue"

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Red
Write-Host "  NUCLEAR NOVASTAR UNINSTALL" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "`n"

# Step 1: Kill all processes
Write-Host "[1/7] Killing all Novastar processes..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.ProcessName -match 'Mars|SmartLCT|Nova|VCAN|VCan' } | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "Done." -ForegroundColor Green

# Step 2: Find and list all Novastar programs
Write-Host "`n[2/7] Finding Novastar programs..." -ForegroundColor Yellow
$programs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'Nova|SmartLCT|Mars|VCAN|VCan|libusb' }

if ($programs) {
    Write-Host "Found programs to uninstall:" -ForegroundColor Cyan
    foreach ($prog in $programs) {
        Write-Host "  - $($prog.DisplayName)" -ForegroundColor White
    }
} else {
    Write-Host "No Novastar programs found in registry." -ForegroundColor Yellow
}

# Step 3: Run uninstallers
Write-Host "`n[3/7] Running uninstallers..." -ForegroundColor Yellow

# SmartLCT uninstaller
$smartlctUninstall = "C:\Program Files (x86)\Nova Star\SmartLCT\unins000.exe"
if (Test-Path $smartlctUninstall) {
    Write-Host "  Uninstalling SmartLCT..." -ForegroundColor Cyan
    Start-Process -FilePath $smartlctUninstall -ArgumentList '/VERYSILENT','/NORESTART' -Wait -ErrorAction SilentlyContinue
    Write-Host "  Done." -ForegroundColor Green
}

# NovaLCT uninstaller - check common locations
$novalctPaths = @(
    "C:\Program Files (x86)\Nova Star\NovaLCT\unins000.exe",
    "C:\Program Files\Nova Star\NovaLCT\unins000.exe",
    "$env:APPDATA\Nova Star\NovaLCT\unins000.exe"
)
foreach ($path in $novalctPaths) {
    if (Test-Path $path) {
        Write-Host "  Uninstalling NovaLCT from $path..." -ForegroundColor Cyan
        Start-Process -FilePath $path -ArgumentList '/VERYSILENT','/NORESTART' -Wait -ErrorAction SilentlyContinue
        Write-Host "  Done." -ForegroundColor Green
    }
}

# V-Can uninstaller
$vcanPaths = @(
    "C:\Program Files (x86)\Nova Star\V-Can\unins000.exe",
    "C:\Program Files\Nova Star\V-Can\unins000.exe"
)
foreach ($path in $vcanPaths) {
    if (Test-Path $path) {
        Write-Host "  Uninstalling V-Can from $path..." -ForegroundColor Cyan
        Start-Process -FilePath $path -ArgumentList '/VERYSILENT','/NORESTART' -Wait -ErrorAction SilentlyContinue
        Write-Host "  Done." -ForegroundColor Green
    }
}

# Step 4: Remove libusb driver packages from Programs
Write-Host "`n[4/7] Looking for libusb driver packages..." -ForegroundColor Yellow
$libusbProgs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -match 'libusb|libusbK' }

if ($libusbProgs) {
    foreach ($prog in $libusbProgs) {
        Write-Host "  Found: $($prog.DisplayName)" -ForegroundColor Cyan
        if ($prog.UninstallString) {
            Write-Host "  Uninstall command: $($prog.UninstallString)" -ForegroundColor Gray
        }
    }
    Write-Host "  NOTE: You may need to manually uninstall these from Control Panel" -ForegroundColor Yellow
}

# Step 5: Nuke drivers from driver store
Write-Host "`n[5/7] Removing drivers from driver store..." -ForegroundColor Yellow
$drivers = pnputil /enum-drivers 2>$null
$driverText = $drivers -join "`n"

# Find all libusb and novastar related OEM inf files
$oemMatches = [regex]::Matches($driverText, "(oem\d+\.inf)[\s\S]*?(?:libusb|novastar|nova)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$oemFiles = @()
foreach ($match in $oemMatches) {
    $oemFiles += $match.Groups[1].Value
}
$oemFiles = $oemFiles | Select-Object -Unique

if ($oemFiles.Count -gt 0) {
    foreach ($oem in $oemFiles) {
        Write-Host "  Removing driver: $oem" -ForegroundColor Cyan
        $result = pnputil /delete-driver $oem /force 2>&1
        Write-Host "    $result" -ForegroundColor Gray
    }
} else {
    Write-Host "  No Novastar/libusb drivers found in driver store." -ForegroundColor Yellow
}

# Also try to remove any device still showing
Write-Host "`n  Removing any lingering devices..." -ForegroundColor Yellow
$devices = Get-PnpDevice | Where-Object { $_.FriendlyName -match 'NovaStar|Novastar|libusb' }
foreach ($dev in $devices) {
    Write-Host "  Removing device: $($dev.FriendlyName)" -ForegroundColor Cyan
    pnputil /remove-device "$($dev.InstanceId)" 2>&1 | Out-Null
}

# Step 6: Delete leftover folders
Write-Host "`n[6/7] Deleting leftover folders..." -ForegroundColor Yellow
$foldersToNuke = @(
    "C:\Program Files (x86)\Nova Star",
    "C:\Program Files\Nova Star",
    "$env:APPDATA\Nova Star",
    "$env:APPDATA\SmartLCT",
    "$env:APPDATA\NovaLCT",
    "$env:APPDATA\NovaLCT 2012",
    "$env:LOCALAPPDATA\Nova Star",
    "$env:LOCALAPPDATA\SmartLCT",
    "$env:LOCALAPPDATA\NovaLCT",
    "$env:USERPROFILE\usb_driver"  # Zadig leftover
)

foreach ($folder in $foldersToNuke) {
    if (Test-Path $folder) {
        Write-Host "  Deleting: $folder" -ForegroundColor Cyan
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "Done." -ForegroundColor Green

# Step 7: Summary
Write-Host "`n========================================" -ForegroundColor Red
Write-Host "  NUCLEAR UNINSTALL COMPLETE" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "`nRemaining manual steps:" -ForegroundColor Yellow
Write-Host "  1. Check Control Panel > Programs for any remaining Novastar/libusb items" -ForegroundColor White
Write-Host "  2. Run Revo Uninstaller to clean registry leftovers" -ForegroundColor White
Write-Host "  3. UNPLUG the VX400" -ForegroundColor White
Write-Host "  4. REBOOT the computer" -ForegroundColor White
Write-Host "  5. Plug VX400 back in" -ForegroundColor White
Write-Host "  6. Fresh install SmartLCT" -ForegroundColor White
Write-Host "`n"
