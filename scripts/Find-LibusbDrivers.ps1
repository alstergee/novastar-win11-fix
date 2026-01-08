# Find all libusb/novastar related drivers in driver store
$output = pnputil /enum-drivers
$text = $output -join "`n"

# Split into driver blocks
$blocks = $text -split "(?=Published Name:)"

foreach ($block in $blocks) {
    if ($block -match "libusb|novastar|nova star|libusbk|winusb" -and $block -match "oem\d+\.inf") {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host $block -ForegroundColor Yellow
    }
}
