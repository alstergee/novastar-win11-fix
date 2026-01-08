# Search for Nova installers in common locations
$searchPaths = @(
    [Environment]::GetFolderPath("Desktop"),
    [Environment]::GetFolderPath("UserProfile") + "\Downloads",
    [Environment]::GetFolderPath("MyDocuments"),
    [Environment]::GetFolderPath("UserProfile")
)

Write-Host "=== Searching for Nova Installers ===" -ForegroundColor Cyan

foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $found = Get-ChildItem $path -File -Recurse -Depth 2 -ErrorAction SilentlyContinue | Where-Object {
            $_.Extension -eq ".exe" -and $_.Name -match "SmartLCT|NovaLCT|V-Can|VCan|Nova.*Setup"
        }
        foreach ($f in $found) {
            Write-Host "$($f.Name)" -ForegroundColor Green
            Write-Host "  Size: $([math]::Round($f.Length/1MB, 2)) MB"
            Write-Host "  Path: $($f.FullName)"
        }
    }
}
