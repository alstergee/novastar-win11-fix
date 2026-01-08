# Check Mars logs
$roaming = [Environment]::GetFolderPath("ApplicationData")

Write-Host "=== Nova folders in AppData ===" -ForegroundColor Yellow
Get-ChildItem $roaming -Directory | Where-Object { $_.Name -match "Nova|Mars|LCT|Smart" } | ForEach-Object {
    Write-Host $_.FullName -ForegroundColor Cyan
}

$marsLogDir = Join-Path $roaming "NovaLCT 2012\MarsServerProvider"
Write-Host "`n=== Mars log directory ===" -ForegroundColor Yellow
if (Test-Path $marsLogDir) {
    Get-ChildItem $marsLogDir -Recurse | ForEach-Object {
        Write-Host $_.FullName
    }

    $logFile = Join-Path $marsLogDir "MarsServerLog.log"
    if (Test-Path $logFile) {
        Write-Host "`n=== Last 30 lines of Mars log ===" -ForegroundColor Yellow
        Get-Content $logFile -Tail 30
    }
} else {
    Write-Host "Directory does not exist: $marsLogDir" -ForegroundColor Red
}

# Check SmartLCT log
$smartLogDir = Join-Path $roaming "SmartLCT"
Write-Host "`n=== SmartLCT AppData directory ===" -ForegroundColor Yellow
if (Test-Path $smartLogDir) {
    Get-ChildItem $smartLogDir -Recurse | ForEach-Object {
        Write-Host $_.FullName
    }
} else {
    Write-Host "Directory does not exist: $smartLogDir" -ForegroundColor Red
}
