# Get the driver files for the NovaStar device
$device = Get-PnpDevice | Where-Object {
    $_.InstanceId -match "VID_0483.*PID_5720" -and $_.Status -eq "OK"
} | Select-Object -First 1

if (-not $device) {
    Write-Host "NovaStar device not found or not working!" -ForegroundColor Red
    exit 1
}

Write-Host "Found device: $($device.FriendlyName)" -ForegroundColor Green
Write-Host "Instance ID: $($device.InstanceId)" -ForegroundColor Cyan
Write-Host "Class: $($device.Class)" -ForegroundColor Cyan

# Get driver info
$driverInfo = Get-PnpDeviceProperty -InstanceId $device.InstanceId | Where-Object {
    $_.KeyName -match "Driver|INF"
}

Write-Host "`n=== Driver Properties ===" -ForegroundColor Yellow
foreach ($prop in $driverInfo) {
    Write-Host "$($prop.KeyName): $($prop.Data)"
}

# Get the INF path
$infName = (Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName "DEVPKEY_Device_DriverInfPath").Data
$infSection = (Get-PnpDeviceProperty -InstanceId $device.InstanceId -KeyName "DEVPKEY_Device_DriverInfSection").Data

Write-Host "`n=== Driver INF ===" -ForegroundColor Yellow
Write-Host "INF File: $infName"
Write-Host "INF Section: $infSection"

# Find the INF in the driver store
$driverStore = "C:\Windows\System32\DriverStore\FileRepository"
$infPath = Get-ChildItem $driverStore -Recurse -Filter $infName -ErrorAction SilentlyContinue | Select-Object -First 1

if ($infPath) {
    Write-Host "`nFound INF at: $($infPath.FullName)" -ForegroundColor Green
    $driverFolder = $infPath.DirectoryName
    Write-Host "Driver folder: $driverFolder" -ForegroundColor Cyan

    Write-Host "`n=== Driver Files ===" -ForegroundColor Yellow
    Get-ChildItem $driverFolder | ForEach-Object {
        Write-Host "  $($_.Name) ($($_.Length) bytes)"
    }

    # Output the path for copying
    Write-Host "`nDRIVER_PATH=$driverFolder" -ForegroundColor Magenta
} else {
    Write-Host "Could not find INF in driver store" -ForegroundColor Red
}
