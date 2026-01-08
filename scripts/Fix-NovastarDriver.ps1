#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Fixes Novastar VX400/SmartLCT driver binding issues on Windows 10/11
.DESCRIPTION
    Removes incorrect libusb-win32 driver binding and installs/binds the
    correct Silicon Labs CP210x driver for Novastar devices.
.PARAMETER Force
    Skip confirmation prompts
.PARAMETER DownloadDriver
    Download fresh CP210x driver from Silicon Labs
.NOTES
    Author: SmartLCT-Fix Project
    Requires: Administrator privileges
    WARNING: This script modifies system drivers. Use at your own risk.
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DownloadDriver
)

$ErrorActionPreference = "Stop"

# URLs and paths
$CP210xDriverURL = "https://www.silabs.com/documents/public/software/CP210x_Universal_Windows_Driver.zip"
$TempDir = "$env:TEMP\NovastarFix"
$LogFile = "$TempDir\fix-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
    Write-Host $Message -ForegroundColor $Color
}

function Test-AdminPrivileges {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================
# STARTUP
# ============================================
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Novastar SmartLCT Driver Fix       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n"

# Create temp directory
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

Write-Log "Fix script started"
Write-Log "Log file: $LogFile"

# Check admin
if (-not (Test-AdminPrivileges)) {
    Write-Log "ERROR: This script requires Administrator privileges!" "Red"
    Write-Log "Right-click PowerShell and select 'Run as Administrator'" "Yellow"
    exit 1
}

# ============================================
# STEP 1: Detect problem devices
# ============================================
Write-Log "`n[STEP 1/5] Detecting problem devices..." "Yellow"

$problemDevices = @()

# Check libusb-win32 devices
$libusbDevices = Get-PnpDevice -Class "libusb-win32 devices" -ErrorAction SilentlyContinue
$libusbNovastar = $libusbDevices | Where-Object { $_.FriendlyName -match "NovaStar|Novastar|NOVASTAR" }

if ($libusbNovastar) {
    foreach ($dev in $libusbNovastar) {
        Write-Log "  Found: $($dev.FriendlyName) [libusb-win32]" "Red"
        $problemDevices += $dev
    }
}

# Also check for any USB device with Novastar name that's NOT a COM port
$allNovastar = Get-PnpDevice | Where-Object {
    $_.FriendlyName -match "NovaStar|Novastar|NOVASTAR" -and
    $_.Class -ne "Ports"
}
foreach ($dev in $allNovastar) {
    if ($dev -notin $problemDevices) {
        Write-Log "  Found: $($dev.FriendlyName) [$($dev.Class)]" "Yellow"
        $problemDevices += $dev
    }
}

if ($problemDevices.Count -eq 0) {
    Write-Log "  No problem devices found!" "Green"
    Write-Log "  Either the issue is already fixed, or the device is not connected." "White"

    # Check if there's already a working COM port
    $workingPorts = Get-PnpDevice -Class "Ports" -ErrorAction SilentlyContinue |
                    Where-Object { $_.FriendlyName -match "CP210x|Silicon Labs" }
    if ($workingPorts) {
        Write-Log "`n  Working COM port(s) detected:" "Green"
        foreach ($port in $workingPorts) {
            Write-Log "    $($port.FriendlyName)" "Green"
        }
    }
    exit 0
}

Write-Log "`n  Found $($problemDevices.Count) device(s) to fix" "Cyan"

# ============================================
# STEP 2: Confirmation
# ============================================
if (-not $Force) {
    Write-Host "`n"
    Write-Host "WARNING: This script will:" -ForegroundColor Yellow
    Write-Host "  1. Uninstall the libusb-win32 driver for Novastar device(s)" -ForegroundColor White
    Write-Host "  2. Remove the device from the system" -ForegroundColor White
    Write-Host "  3. Attempt to reinstall with correct CP210x driver" -ForegroundColor White
    Write-Host "`n"

    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -notmatch "^[Yy]") {
        Write-Log "Operation cancelled by user" "Yellow"
        exit 0
    }
}

# ============================================
# STEP 3: Download CP210x driver (optional)
# ============================================
if ($DownloadDriver) {
    Write-Log "`n[STEP 2/5] Downloading CP210x driver from Silicon Labs..." "Yellow"

    $driverZip = "$TempDir\CP210x_Driver.zip"
    $driverDir = "$TempDir\CP210x_Driver"

    try {
        Write-Log "  Downloading from: $CP210xDriverURL" "Gray"
        Invoke-WebRequest -Uri $CP210xDriverURL -OutFile $driverZip -UseBasicParsing
        Write-Log "  Download complete" "Green"

        Write-Log "  Extracting..." "Gray"
        Expand-Archive -Path $driverZip -DestinationPath $driverDir -Force
        Write-Log "  Extraction complete: $driverDir" "Green"

    } catch {
        Write-Log "  WARNING: Could not download driver: $_" "Yellow"
        Write-Log "  Will rely on Windows to find the correct driver" "Yellow"
    }
} else {
    Write-Log "`n[STEP 2/5] Skipping driver download (use -DownloadDriver to fetch fresh driver)" "Gray"
}

# ============================================
# STEP 4: Remove problem driver binding
# ============================================
Write-Log "`n[STEP 3/5] Removing incorrect driver bindings..." "Yellow"

foreach ($device in $problemDevices) {
    Write-Log "  Processing: $($device.FriendlyName)" "Cyan"
    Write-Log "    InstanceId: $($device.InstanceId)" "Gray"

    try {
        # Get the driver INF file
        $driverInf = Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName "DEVPKEY_Device_DriverInfPath" -ErrorAction SilentlyContinue

        # Remove the device
        Write-Log "    Removing device..." "Gray"
        $result = pnputil /remove-device "$($device.InstanceId)" 2>&1
        Write-Log "    $result" "Gray"

        # If we found the INF, try to delete it from driver store
        if ($driverInf.Data -and $driverInf.Data -match "oem\d+\.inf") {
            Write-Log "    Attempting to remove driver package: $($driverInf.Data)" "Gray"
            $deleteResult = pnputil /delete-driver $driverInf.Data /force 2>&1
            Write-Log "    $deleteResult" "Gray"
        }

        Write-Log "    Device removed successfully" "Green"

    } catch {
        Write-Log "    ERROR: $_" "Red"
        Write-Log "    Continuing with next device..." "Yellow"
    }
}

# ============================================
# STEP 5: Remove libusb-win32 drivers from store
# ============================================
Write-Log "`n[STEP 4/5] Cleaning libusb drivers from driver store..." "Yellow"

try {
    $driverList = pnputil /enum-drivers 2>&1
    $driverListText = $driverList -join "`n"

    # Find all libusb OEM inf files
    $libusbInfs = [regex]::Matches($driverListText, "(oem\d+\.inf)[\s\S]*?Original Name:\s+libusb", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

    if ($libusbInfs.Count -gt 0) {
        foreach ($match in $libusbInfs) {
            $infName = $match.Groups[1].Value
            Write-Log "  Removing libusb driver: $infName" "Gray"
            $deleteResult = pnputil /delete-driver $infName /force 2>&1
            Write-Log "    $deleteResult" "Gray"
        }
    } else {
        Write-Log "  No standalone libusb drivers found in driver store" "Green"
    }
} catch {
    Write-Log "  WARNING: Error cleaning driver store: $_" "Yellow"
}

# ============================================
# STEP 6: Trigger device re-detection
# ============================================
Write-Log "`n[STEP 5/5] Triggering hardware re-detection..." "Yellow"

Write-Log "  Scanning for hardware changes..." "Gray"
$scanResult = pnputil /scan-devices 2>&1
Write-Log "  $scanResult" "Gray"

# Wait a moment for Windows to detect
Write-Log "  Waiting for Windows to detect device..." "Gray"
Start-Sleep -Seconds 5

# Check if it worked
$newComPorts = Get-PnpDevice -Class "Ports" -ErrorAction SilentlyContinue |
               Where-Object { $_.FriendlyName -match "CP210x|Silicon Labs" -and $_.Status -eq "OK" }

$remainingProblems = Get-PnpDevice -Class "libusb-win32 devices" -ErrorAction SilentlyContinue |
                     Where-Object { $_.FriendlyName -match "NovaStar|Novastar|NOVASTAR" }

# ============================================
# RESULTS
# ============================================
Write-Host "`n"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "              RESULTS                   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($newComPorts -and -not $remainingProblems) {
    Write-Log "`n[SUCCESS] Driver fix applied successfully!" "Green"
    Write-Log "`nNew COM port(s) detected:" "Green"
    foreach ($port in $newComPorts) {
        Write-Log "  $($port.FriendlyName)" "Green"
    }
    Write-Log "`nNext steps:" "Cyan"
    Write-Log "  1. Restart Mars Service Provider (or reboot)" "White"
    Write-Log "  2. Launch SmartLCT" "White"
    Write-Log "  3. Try connecting to your VX400" "White"

} elseif ($remainingProblems) {
    Write-Log "`n[PARTIAL] Some devices still have wrong driver" "Yellow"
    Write-Log "Try:" "Yellow"
    Write-Log "  1. Unplug the VX400 USB cable" "White"
    Write-Log "  2. Reboot the computer" "White"
    Write-Log "  3. Plug the VX400 back in" "White"
    Write-Log "  4. Run this script again" "White"

} else {
    Write-Log "`n[UNKNOWN] Could not verify fix" "Yellow"
    Write-Log "The device may need to be reconnected." "White"
    Write-Log "Try:" "Yellow"
    Write-Log "  1. Unplug the VX400 USB cable" "White"
    Write-Log "  2. Wait 10 seconds" "White"
    Write-Log "  3. Plug it back in" "White"
    Write-Log "  4. Check Device Manager for COM ports" "White"
}

# ============================================
# SERVICE RESTART
# ============================================
Write-Log "`nAttempting to restart Novastar services..." "Yellow"

$services = Get-Service -Name "*Mars*", "*Novastar*", "*NovaStar*" -ErrorAction SilentlyContinue | Select-Object -Unique

foreach ($svc in $services) {
    try {
        Write-Log "  Restarting: $($svc.DisplayName)" "Gray"
        Restart-Service -Name $svc.Name -Force -ErrorAction Stop
        Write-Log "    Restarted successfully" "Green"
    } catch {
        Write-Log "    Could not restart: $_" "Yellow"
    }
}

Write-Log "`nLog saved to: $LogFile" "Gray"
Write-Host "`n========================================`n" -ForegroundColor Cyan
