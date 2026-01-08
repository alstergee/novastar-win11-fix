# Check Windows Event Log for errors
Write-Host "=== Recent Application Errors ===" -ForegroundColor Yellow
Get-WinEvent -LogName Application -MaxEvents 50 -ErrorAction SilentlyContinue |
    Where-Object { $_.LevelDisplayName -eq "Error" -or $_.LevelDisplayName -eq "Warning" } |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-30) } |
    Select-Object TimeCreated, ProviderName, Message |
    Format-List

Write-Host "`n=== .NET Runtime Errors ===" -ForegroundColor Yellow
Get-WinEvent -LogName Application -MaxEvents 50 -ErrorAction SilentlyContinue |
    Where-Object { $_.ProviderName -match "\.NET|CLR|Application Error" } |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-30) } |
    Select-Object TimeCreated, ProviderName, Message |
    Format-List
