# Swap Mars - Copy NovaLCT's working MarsServerProvider to SmartLCT
param(
    [switch]$Restore  # Use this to restore from backup
)

$novaLctMars = Join-Path $env:APPDATA "Nova Star\NovaLCT\Bin\MarsServerProvider"
$smartLctMars = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backup = Join-Path (Split-Path -Parent $scriptDir) "MarsServerProvider_Backup"

# Kill processes first
Write-Host "Killing processes..." -ForegroundColor Yellow
Stop-Process -Name "SmartLCT","MarsServerProvider","NovaLCT","NovaMonitorManager" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

if ($Restore) {
    Write-Host "=== Restoring SmartLCT Mars from backup ===" -ForegroundColor Yellow
    if (Test-Path $backup) {
        # Need admin to write to Program Files
        $cmd = "xcopy `"$backup\*`" `"$smartLctMars`" /E /Y /Q"
        Start-Process cmd -ArgumentList "/c $cmd" -Verb RunAs -Wait
        Write-Host "Restored!" -ForegroundColor Green
    } else {
        Write-Host "No backup found at $backup" -ForegroundColor Red
    }
} else {
    Write-Host "=== Swapping Mars ===" -ForegroundColor Yellow

    # Backup SmartLCT Mars first
    if (-not (Test-Path $backup)) {
        Write-Host "Backing up SmartLCT Mars to $backup" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        Copy-Item -Path "$smartLctMars\*" -Destination $backup -Recurse -Force
    } else {
        Write-Host "Backup already exists, skipping backup" -ForegroundColor Cyan
    }

    # Copy NovaLCT Mars to SmartLCT location
    Write-Host "Copying NovaLCT Mars to SmartLCT location..." -ForegroundColor Cyan
    $cmd = "xcopy `"$novaLctMars\*`" `"$smartLctMars`" /E /Y /Q"
    Start-Process cmd -ArgumentList "/c $cmd" -Verb RunAs -Wait

    Write-Host "Done! Now try launching SmartLCT." -ForegroundColor Green
}
