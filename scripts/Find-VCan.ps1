# Find V-Can installation
Write-Host "=== Searching for V-Can ===" -ForegroundColor Cyan

# Check Program Files
$programPaths = @(
    "C:\Program Files (x86)",
    "C:\Program Files",
    "$env:APPDATA",
    "$env:LOCALAPPDATA"
)

foreach ($basePath in $programPaths) {
    Write-Host "`nSearching: $basePath" -ForegroundColor Yellow
    Get-ChildItem $basePath -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "nova|vcan|v-can|novastar"
    } | ForEach-Object {
        Write-Host "  Found: $($_.FullName)" -ForegroundColor Green

        # Check for MarsServerProvider subfolder
        $marsPath = Get-ChildItem $_.FullName -Recurse -Directory -Filter "MarsServerProvider" -ErrorAction SilentlyContinue
        if ($marsPath) {
            Write-Host "    -> MarsServerProvider at: $($marsPath.FullName)" -ForegroundColor Magenta
        }
    }
}

# Also search desktop for installers
Write-Host "`nSearching Desktop for installers..." -ForegroundColor Yellow
$desktop = [Environment]::GetFolderPath("Desktop")
Get-ChildItem $desktop -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match "vcan|v-can|nova"
} | ForEach-Object {
    Write-Host "  Found: $($_.FullName)" -ForegroundColor Cyan
}

# Check registry for installed programs
Write-Host "`nChecking Registry for V-Can..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($regPath in $regPaths) {
    Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match "vcan|v-can|nova"
    } | ForEach-Object {
        Write-Host "  Installed: $($_.DisplayName)" -ForegroundColor Green
        if ($_.InstallLocation) {
            Write-Host "    Location: $($_.InstallLocation)" -ForegroundColor Gray
        }
    }
}
