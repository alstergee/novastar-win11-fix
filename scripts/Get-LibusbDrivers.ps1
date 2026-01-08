# Find libusb drivers
$output = pnputil /enum-drivers
$output | Select-String -Pattern "libusb" -Context 5,5
