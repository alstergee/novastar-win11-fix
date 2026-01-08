# Find Nova installers on desktop
Write-Host "=== Installers on Desktop ===" -ForegroundColor Cyan
Get-ChildItem "C:\Users\david\Desktop" -File | Where-Object {
    $_.Extension -match "\.exe|\.msi"
} | Where-Object {
    $_.Name -match "SmartLCT|V-Can|VCan|Nova|Setup"
} | ForEach-Object {
    Write-Host "$($_.Name) - $([math]::Round($_.Length/1MB, 2)) MB"
    Write-Host "  Path: $($_.FullName)"
}

# Also list all exe files just in case
Write-Host "`n=== All .exe files on Desktop ===" -ForegroundColor Yellow
Get-ChildItem "C:\Users\david\Desktop" -File -Filter "*.exe" | ForEach-Object {
    Write-Host "$($_.Name) - $([math]::Round($_.Length/1MB, 2)) MB"
}
