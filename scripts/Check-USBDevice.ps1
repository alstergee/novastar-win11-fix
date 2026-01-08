# Check USB device status
Write-Host "=== USB Devices (Nova/STM related) ===" -ForegroundColor Yellow

$devices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -match "Nova|STM|5720" -or $_.InstanceId -match "0483|5720"
}

foreach ($device in $devices) {
    Write-Host "`nFriendlyName: $($device.FriendlyName)" -ForegroundColor Cyan
    Write-Host "Status: $($device.Status)"
    Write-Host "Class: $($device.Class)"
    Write-Host "InstanceId: $($device.InstanceId)"
}

if (-not $devices) {
    Write-Host "No Nova/STM USB devices found!" -ForegroundColor Red
}

Write-Host "`n=== All libusb devices ===" -ForegroundColor Yellow
$libusb = Get-PnpDevice | Where-Object { $_.Class -match "libusb|libusbK|USBDevice" }
foreach ($dev in $libusb) {
    Write-Host "$($dev.Status): $($dev.FriendlyName)" -ForegroundColor Cyan
}
