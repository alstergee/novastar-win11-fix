#Requires -RunAsAdministrator
# Remove libusb-win32 registry entries from Programs

$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$entries = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match "libusb-win32" }

if ($entries) {
    foreach ($entry in $entries) {
        Write-Host "Found: $($entry.DisplayName)" -ForegroundColor Yellow
        Write-Host "  Path: $($entry.PSPath)" -ForegroundColor Gray
        Write-Host "  Removing..." -ForegroundColor Cyan
        Remove-Item $entry.PSPath -Force -ErrorAction SilentlyContinue
        Write-Host "  Done." -ForegroundColor Green
    }
} else {
    Write-Host "No libusb-win32 entries found in registry." -ForegroundColor Green
}
