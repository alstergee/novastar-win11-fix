# Get NovaStar device info
Write-Host "Looking for NovaStar devices..." -ForegroundColor Cyan

# Check libusb-win32 devices class
$libusbDevices = Get-PnpDevice -Class "libusb-win32 devices" -ErrorAction SilentlyContinue
if ($libusbDevices) {
    Write-Host "`n=== libusb-win32 devices ===" -ForegroundColor Yellow
    foreach ($dev in $libusbDevices) {
        Write-Host "Name: $($dev.FriendlyName)" -ForegroundColor White
        Write-Host "Status: $($dev.Status)" -ForegroundColor White
        Write-Host "InstanceId: $($dev.InstanceId)" -ForegroundColor Gray

        # Get driver info
        $driverInfo = Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName "DEVPKEY_Device_DriverInfPath" -ErrorAction SilentlyContinue
        if ($driverInfo.Data) {
            Write-Host "Driver INF: $($driverInfo.Data)" -ForegroundColor Cyan
        }

        $driverVersion = Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName "DEVPKEY_Device_DriverVersion" -ErrorAction SilentlyContinue
        if ($driverVersion.Data) {
            Write-Host "Driver Version: $($driverVersion.Data)" -ForegroundColor Cyan
        }
        Write-Host ""
    }
}

# Check for any Nova-named devices
$novaDevices = Get-PnpDevice | Where-Object { $_.FriendlyName -match "Nova" }
if ($novaDevices) {
    Write-Host "`n=== All Nova* devices ===" -ForegroundColor Yellow
    foreach ($dev in $novaDevices) {
        Write-Host "Name: $($dev.FriendlyName)" -ForegroundColor White
        Write-Host "Class: $($dev.Class)" -ForegroundColor White
        Write-Host "Status: $($dev.Status)" -ForegroundColor White
        Write-Host "InstanceId: $($dev.InstanceId)" -ForegroundColor Gray
        Write-Host ""
    }
}

# Check USB device with VID 0483
$stmDevices = Get-PnpDevice | Where-Object { $_.InstanceId -match "USB\\VID_0483" }
if ($stmDevices) {
    Write-Host "`n=== STM32 USB devices (VID 0483) ===" -ForegroundColor Yellow
    foreach ($dev in $stmDevices) {
        Write-Host "Name: $($dev.FriendlyName)" -ForegroundColor White
        Write-Host "Class: $($dev.Class)" -ForegroundColor White
        Write-Host "Status: $($dev.Status)" -ForegroundColor White
        Write-Host "InstanceId: $($dev.InstanceId)" -ForegroundColor Gray
        Write-Host ""
    }
}

if (-not $libusbDevices -and -not $novaDevices -and -not $stmDevices) {
    Write-Host "No NovaStar or STM32 devices found!" -ForegroundColor Red
}
