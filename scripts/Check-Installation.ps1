# Quick installation check
Write-Host "=== Checking NovaStar Installation ===" -ForegroundColor Cyan

# Check Program Files
Write-Host "`n[Program Files]" -ForegroundColor Yellow
$paths = @(
    "C:\Program Files\NovaStar",
    "C:\Program Files (x86)\NovaStar",
    "C:\Program Files\SmartLCT",
    "C:\Program Files (x86)\SmartLCT",
    "C:\Program Files\NovaLCT",
    "C:\Program Files (x86)\NovaLCT"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "  FOUND: $p" -ForegroundColor Green
        Get-ChildItem $p -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor Gray }
    }
}

# Check services
Write-Host "`n[Services]" -ForegroundColor Yellow
$services = Get-Service | Where-Object { $_.DisplayName -like "*Mars*" -or $_.DisplayName -like "*Nova*" -or $_.Name -like "*Mars*" }
if ($services) {
    foreach ($s in $services) {
        Write-Host "  $($s.DisplayName) [$($s.Status)]" -ForegroundColor Green
    }
} else {
    Write-Host "  No NovaStar/Mars services found" -ForegroundColor Red
}

# Check installed programs
Write-Host "`n[Installed Programs]" -ForegroundColor Yellow
$uninstall = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
$novaProgs = $uninstall | Where-Object { $_.DisplayName -like "*Nova*" -or $_.DisplayName -like "*SmartLCT*" -or $_.DisplayName -like "*Mars*" }
if ($novaProgs) {
    foreach ($prog in $novaProgs) {
        Write-Host "  $($prog.DisplayName) v$($prog.DisplayVersion)" -ForegroundColor Green
        if ($prog.InstallLocation) { Write-Host "    Location: $($prog.InstallLocation)" -ForegroundColor Gray }
    }
} else {
    Write-Host "  No NovaStar programs found in registry" -ForegroundColor Red
}

# Check running processes
Write-Host "`n[Running Processes]" -ForegroundColor Yellow
$procs = Get-Process | Where-Object { $_.ProcessName -like "*Nova*" -or $_.ProcessName -like "*Mars*" -or $_.ProcessName -like "*SmartLCT*" }
if ($procs) {
    foreach ($proc in $procs) {
        Write-Host "  $($proc.ProcessName) [PID: $($proc.Id)]" -ForegroundColor Green
    }
} else {
    Write-Host "  No NovaStar processes running" -ForegroundColor Yellow
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
