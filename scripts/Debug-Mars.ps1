# Debug Mars communication
Write-Host "=== Mars Process ===" -ForegroundColor Yellow
$mars = Get-Process -Name "MarsServerProvider" -ErrorAction SilentlyContinue
if ($mars) {
    Write-Host "PID: $($mars.Id)"
    Write-Host "Started: $($mars.StartTime)"
    Write-Host "Memory: $([math]::Round($mars.WorkingSet64/1MB, 2)) MB"

    Write-Host "`n=== TCP Connections ===" -ForegroundColor Yellow
    Get-NetTCPConnection -OwningProcess $mars.Id -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, RemoteAddress, RemotePort, State

    Write-Host "`n=== UDP Endpoints ===" -ForegroundColor Yellow
    Get-NetUDPEndpoint -OwningProcess $mars.Id -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
} else {
    Write-Host "Mars not running" -ForegroundColor Red
}

Write-Host "`n=== SmartLCT Process ===" -ForegroundColor Yellow
$smartlct = Get-Process -Name "SmartLCT" -ErrorAction SilentlyContinue
if ($smartlct) {
    Write-Host "PID: $($smartlct.Id)"

    Write-Host "`n=== TCP Connections ===" -ForegroundColor Yellow
    Get-NetTCPConnection -OwningProcess $smartlct.Id -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, RemoteAddress, RemotePort, State

    Write-Host "`n=== UDP Endpoints ===" -ForegroundColor Yellow
    Get-NetUDPEndpoint -OwningProcess $smartlct.Id -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
} else {
    Write-Host "SmartLCT not running" -ForegroundColor Red
}

Write-Host "`n=== Shared Memory / Named Pipes ===" -ForegroundColor Yellow
# Check for named pipes that might be used for IPC
Get-ChildItem "\\.\pipe\" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "Nova|Mars|Smart" } | Select-Object Name
