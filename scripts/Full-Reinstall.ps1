#Requires -RunAsAdministrator
# Full SmartLCT Reinstall Script

$ErrorActionPreference = "Continue"

Write-Host "`n=== SmartLCT Full Reinstall ===" -ForegroundColor Cyan

# Step 1: Kill processes
Write-Host "`n[1/6] Killing Novastar processes..." -ForegroundColor Yellow
Get-Process -Name "*Mars*" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "*SmartLCT*" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "*Nova*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Write-Host "Done." -ForegroundColor Green

# Step 2: Run uninstaller
Write-Host "`n[2/6] Running SmartLCT uninstaller..." -ForegroundColor Yellow
$uninstaller = "C:\Program Files (x86)\Nova Star\SmartLCT\unins000.exe"
if (Test-Path $uninstaller) {
    Write-Host "Starting uninstaller - PLEASE COMPLETE THE UNINSTALL WIZARD" -ForegroundColor Magenta
    Start-Process -FilePath $uninstaller -Wait
    Write-Host "Uninstaller finished." -ForegroundColor Green
} else {
    Write-Host "Uninstaller not found at $uninstaller" -ForegroundColor Red
}

# Step 3: Clean up leftover folders
Write-Host "`n[3/6] Cleaning up leftover folders..." -ForegroundColor Yellow
$foldersToDelete = @(
    "C:\Program Files (x86)\Nova Star\SmartLCT",
    "$env:APPDATA\SmartLCT",
    "$env:LOCALAPPDATA\SmartLCT",
    "$env:APPDATA\Nova Star\SmartLCT"
)
foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        Write-Host "  Removing: $folder" -ForegroundColor Gray
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "Done." -ForegroundColor Green

# Step 4: Run SFC and DISM
Write-Host "`n[4/6] Running system repairs (this takes a while)..." -ForegroundColor Yellow
Write-Host "  Running DISM..." -ForegroundColor Gray
DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-Null
Write-Host "  Running SFC..." -ForegroundColor Gray
sfc /scannow 2>&1 | Out-Null
Write-Host "Done." -ForegroundColor Green

# Step 5: Prompt for reinstall
Write-Host "`n[5/6] Ready for reinstall" -ForegroundColor Yellow
Write-Host "Please reinstall SmartLCT now." -ForegroundColor Magenta
Write-Host "Download from: https://www.ledincloud.com/novastar-smartlct-resource-center/" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter after you've reinstalled SmartLCT"

# Step 6: Test
Write-Host "`n[6/6] Testing SmartLCT..." -ForegroundColor Yellow
$smartlct = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\SmartLCT.exe"
if (Test-Path $smartlct) {
    Write-Host "Starting SmartLCT..." -ForegroundColor Cyan
    Start-Process -FilePath $smartlct -Verb RunAs
} else {
    Write-Host "SmartLCT not found at expected location." -ForegroundColor Red
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Write-Host "`nIf SmartLCT still doesn't work, proceed to the manual Zadig step." -ForegroundColor Yellow
