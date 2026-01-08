# Check USB device and Mars status
Write-Host "=== Mars Status ===" -ForegroundColor Cyan
$mars = Get-Process -Name MarsServerProvider -ErrorAction SilentlyContinue
if ($mars) {
    Write-Host "Running: $($mars.Path)" -ForegroundColor Green
} else {
    Write-Host "NOT RUNNING" -ForegroundColor Red
}

Write-Host "`n=== USB Device (VID_0483 PID_5720) ===" -ForegroundColor Cyan
$devices = Get-PnpDevice | Where-Object { $_.InstanceId -match "VID_0483.*PID_5720" }
foreach ($dev in $devices) {
    Write-Host "Status: $($dev.Status)" -ForegroundColor $(if ($dev.Status -eq "OK") { "Green" } else { "Red" })
    Write-Host "Name: $($dev.FriendlyName)"
    Write-Host "Class: $($dev.Class)"
    Write-Host "InstanceId: $($dev.InstanceId)"

    # Get driver info
    $driverInf = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName "DEVPKEY_Device_DriverInfPath" -ErrorAction SilentlyContinue).Data
    $driverDesc = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName "DEVPKEY_Device_DriverDesc" -ErrorAction SilentlyContinue).Data
    Write-Host "Driver: $driverDesc"
    Write-Host "INF: $driverInf"
}

if (-not $devices) {
    Write-Host "NO DEVICE FOUND!" -ForegroundColor Red
    Write-Host "Check if VX400 is plugged in and powered on."
}

Write-Host "`n=== IPC Window Check ===" -ForegroundColor Cyan
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@

$guid = "A7F89E4D-04F4-46a6-9754-A334B3E8FEE5"
$hwnd = [WinAPI]::FindWindow([NullString]::Value, $guid)
if ($hwnd -ne [IntPtr]::Zero) {
    Write-Host "GUID Window: FOUND (handle: $hwnd)" -ForegroundColor Green
} else {
    Write-Host "GUID Window: NOT FOUND" -ForegroundColor Red
}
