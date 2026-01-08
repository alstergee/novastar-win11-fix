#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Diagnoses Novastar VX400/SmartLCT driver issues on Windows 10/11
.DESCRIPTION
    Checks for common driver binding issues where the Novastar device
    gets bound to libusb-win32 instead of Silicon Labs CP210x driver.
.NOTES
    Author: SmartLCT-Fix Project
    Requires: Administrator privileges
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Novastar SmartLCT Driver Diagnostic  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n"

# Known identifiers
$SiliconLabsVID = "10C4"
$CommonNovastarPIDs = @("EA60", "EA61", "EA70")  # CP210x variants

$issues = @()
$findings = @()

# ============================================
# CHECK 1: Look for Novastar under libusb-win32
# ============================================
Write-Host "[1/6] Checking for libusb-win32 bound devices..." -ForegroundColor Yellow

$libusbDevices = Get-PnpDevice -Class "libusb-win32 devices" -ErrorAction SilentlyContinue
$libusbNovastar = $libusbDevices | Where-Object { $_.FriendlyName -match "NovaStar|Novastar|NOVASTAR" }

if ($libusbNovastar) {
    Write-Host "  [!] PROBLEM FOUND: Novastar device bound to libusb-win32!" -ForegroundColor Red
    foreach ($dev in $libusbNovastar) {
        Write-Host "      Device: $($dev.FriendlyName)" -ForegroundColor Red
        Write-Host "      Status: $($dev.Status)" -ForegroundColor Red
        Write-Host "      InstanceId: $($dev.InstanceId)" -ForegroundColor Gray
        $issues += @{
            Type = "WrongDriver"
            Device = $dev.FriendlyName
            InstanceId = $dev.InstanceId
            Driver = "libusb-win32"
        }
    }
} else {
    Write-Host "  [OK] No Novastar devices bound to libusb-win32" -ForegroundColor Green
}

# ============================================
# CHECK 2: Look for Silicon Labs CP210x COM ports
# ============================================
Write-Host "`n[2/6] Checking for Silicon Labs CP210x COM ports..." -ForegroundColor Yellow

$comPorts = Get-PnpDevice -Class "Ports" -ErrorAction SilentlyContinue
$cp210xPorts = $comPorts | Where-Object { $_.FriendlyName -match "CP210x|Silicon Labs" }

if ($cp210xPorts) {
    Write-Host "  [OK] Found CP210x COM port(s):" -ForegroundColor Green
    foreach ($port in $cp210xPorts) {
        Write-Host "      $($port.FriendlyName) - Status: $($port.Status)" -ForegroundColor Green
        $findings += @{
            Type = "CP210xFound"
            Device = $port.FriendlyName
            Status = $port.Status
        }
    }
} else {
    Write-Host "  [!] No Silicon Labs CP210x COM ports found" -ForegroundColor Yellow
    $findings += @{
        Type = "NoCP210x"
        Message = "No CP210x COM ports detected"
    }
}

# ============================================
# CHECK 3: Check for USB devices with Silicon Labs VID
# ============================================
Write-Host "`n[3/6] Scanning USB devices for Silicon Labs hardware (VID:$SiliconLabsVID)..." -ForegroundColor Yellow

$usbDevices = Get-PnpDevice | Where-Object { $_.InstanceId -match "USB\\VID_$SiliconLabsVID" }

if ($usbDevices) {
    Write-Host "  Found Silicon Labs USB device(s):" -ForegroundColor Cyan
    foreach ($usb in $usbDevices) {
        $driverInfo = Get-PnpDeviceProperty -InstanceId $usb.InstanceId -KeyName "DEVPKEY_Device_DriverInfPath" -ErrorAction SilentlyContinue
        $driverName = if ($driverInfo.Data) { $driverInfo.Data } else { "Unknown" }

        Write-Host "      Device: $($usb.FriendlyName)" -ForegroundColor Cyan
        Write-Host "      Class: $($usb.Class)" -ForegroundColor Gray
        Write-Host "      Driver INF: $driverName" -ForegroundColor Gray
        Write-Host "      InstanceId: $($usb.InstanceId)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "  [!] No Silicon Labs USB devices detected" -ForegroundColor Yellow
    Write-Host "      Is the VX400 connected and powered on?" -ForegroundColor Yellow
}

# ============================================
# CHECK 4: Check for any Novastar-named devices anywhere
# ============================================
Write-Host "[4/6] Searching for any Novastar-named devices..." -ForegroundColor Yellow

$allNovastar = Get-PnpDevice | Where-Object { $_.FriendlyName -match "NovaStar|Novastar|NOVASTAR" }

if ($allNovastar) {
    Write-Host "  Found Novastar device(s):" -ForegroundColor Cyan
    foreach ($dev in $allNovastar) {
        Write-Host "      Name: $($dev.FriendlyName)" -ForegroundColor Cyan
        Write-Host "      Class: $($dev.Class)" -ForegroundColor Gray
        Write-Host "      Status: $($dev.Status)" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "  [!] No Novastar-named devices found in system" -ForegroundColor Yellow
}

# ============================================
# CHECK 5: Check Mars Service Provider service
# ============================================
Write-Host "[5/6] Checking Mars Service Provider..." -ForegroundColor Yellow

$marsService = Get-Service -Name "*Mars*" -ErrorAction SilentlyContinue
$novastarServices = Get-Service -Name "*Novastar*", "*NovaStar*" -ErrorAction SilentlyContinue

$allServices = @()
if ($marsService) { $allServices += $marsService }
if ($novastarServices) { $allServices += $novastarServices }
$allServices = $allServices | Select-Object -Unique

if ($allServices) {
    foreach ($svc in $allServices) {
        $statusColor = if ($svc.Status -eq "Running") { "Green" } else { "Red" }
        Write-Host "  Service: $($svc.DisplayName)" -ForegroundColor Cyan
        Write-Host "      Status: $($svc.Status)" -ForegroundColor $statusColor
        Write-Host "      StartType: $($svc.StartType)" -ForegroundColor Gray

        if ($svc.Status -ne "Running") {
            $issues += @{
                Type = "ServiceNotRunning"
                Service = $svc.Name
                DisplayName = $svc.DisplayName
            }
        }
    }
} else {
    Write-Host "  [!] No Mars/Novastar services found" -ForegroundColor Yellow
    Write-Host "      SmartLCT may not be installed properly" -ForegroundColor Yellow
}

# ============================================
# CHECK 6: Check installed drivers in driver store
# ============================================
Write-Host "`n[6/6] Checking driver store for relevant drivers..." -ForegroundColor Yellow

$driverList = pnputil /enum-drivers 2>$null
$libusbDrivers = $driverList | Select-String -Pattern "libusb" -Context 0,5
$cp210xDrivers = $driverList | Select-String -Pattern "silabs|cp210|silicon" -Context 0,5

if ($libusbDrivers) {
    Write-Host "  Found libusb driver(s) in driver store:" -ForegroundColor Yellow
    # Extract OEM inf names
    $matches = [regex]::Matches(($driverList -join "`n"), "Published Name:\s+(oem\d+\.inf)[\s\S]*?Class Name:\s+libusb", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($match in $matches) {
        Write-Host "      $($match.Groups[1].Value)" -ForegroundColor Yellow
    }
}

if ($cp210xDrivers) {
    Write-Host "  Found Silicon Labs/CP210x driver(s) in driver store:" -ForegroundColor Green
}

# ============================================
# SUMMARY
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "            DIAGNOSIS SUMMARY           " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($issues.Count -gt 0) {
    Write-Host "`n[!] ISSUES DETECTED:" -ForegroundColor Red

    foreach ($issue in $issues) {
        switch ($issue.Type) {
            "WrongDriver" {
                Write-Host "`n  PROBLEM: Device bound to wrong driver" -ForegroundColor Red
                Write-Host "    Device: $($issue.Device)" -ForegroundColor White
                Write-Host "    Current Driver: $($issue.Driver) (WRONG)" -ForegroundColor Red
                Write-Host "    Should be: Silicon Labs CP210x" -ForegroundColor Green
                Write-Host "    Instance: $($issue.InstanceId)" -ForegroundColor Gray
            }
            "ServiceNotRunning" {
                Write-Host "`n  PROBLEM: Service not running" -ForegroundColor Red
                Write-Host "    Service: $($issue.DisplayName)" -ForegroundColor White
            }
        }
    }

    Write-Host "`n[RECOMMENDED ACTION]" -ForegroundColor Yellow
    Write-Host "  Run: .\Fix-NovastarDriver.ps1" -ForegroundColor Cyan
    Write-Host "  This will attempt to fix the driver binding automatically.`n" -ForegroundColor White

} else {
    Write-Host "`n[OK] No obvious driver issues detected" -ForegroundColor Green

    if (-not $cp210xPorts -and -not $allNovastar) {
        Write-Host "`n[?] However, no Novastar device was found at all." -ForegroundColor Yellow
        Write-Host "    - Is the VX400 connected via USB?" -ForegroundColor White
        Write-Host "    - Is it powered on?" -ForegroundColor White
        Write-Host "    - Try a different USB port (not through a hub)" -ForegroundColor White
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Return structured results for scripting
return @{
    Issues = $issues
    Findings = $findings
    HasProblems = ($issues.Count -gt 0)
}
