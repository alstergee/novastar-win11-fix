# Export the Nova ProHD driver files
$exportDir = "C:\Users\david\Desktop\Alex\Driver_NovaProHD"

# Find the device
$device = Get-PnpDevice | Where-Object {
    $_.InstanceId -match "VID_0483.*PID_5720" -and $_.Status -eq "OK"
} | Select-Object -First 1

if (-not $device) {
    Write-Host "NovaStar device not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found: $($device.FriendlyName)" -ForegroundColor Green

# Use pnputil to export the driver
$infName = (Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName "DEVPKEY_Device_DriverInfPath").Data
Write-Host "INF: $infName"

# Export using pnputil
Write-Host "`nExporting driver to $exportDir..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $exportDir -Force | Out-Null

# Find all INF files that match libusb/Nova
$infDir = "C:\Windows\INF"
$tempExport = "C:\Users\david\Desktop\Alex\temp_driver_export"
New-Item -ItemType Directory -Path $tempExport -Force | Out-Null

# Export from pnputil
$result = pnputil /export-driver $infName $tempExport 2>&1
Write-Host $result

if (Test-Path "$tempExport\*") {
    Move-Item "$tempExport\*" $exportDir -Force
    Write-Host "`nDriver exported to: $exportDir" -ForegroundColor Green
    Get-ChildItem $exportDir
} else {
    Write-Host "Export failed, trying alternate method..." -ForegroundColor Yellow

    # Try to find the driver in DriverStore
    $driverStore = "C:\Windows\System32\DriverStore\FileRepository"

    # Search for libusb-win32 folders
    Get-ChildItem $driverStore -Directory | Where-Object {
        $_.Name -match "libusb" -or $_.Name -match "nova"
    } | ForEach-Object {
        Write-Host "Found: $($_.FullName)" -ForegroundColor Cyan
        Copy-Item -Path "$($_.FullName)\*" -Destination $exportDir -Recurse -Force
    }
}

Remove-Item $tempExport -Force -Recurse -ErrorAction SilentlyContinue

Write-Host "`n=== Exported Files ===" -ForegroundColor Yellow
Get-ChildItem $exportDir -Recurse | ForEach-Object {
    Write-Host "  $($_.FullName)"
}
