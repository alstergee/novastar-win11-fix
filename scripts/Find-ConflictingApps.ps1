# Find potentially conflicting apps
$badApps = @(
    'killer', 'nahimic', 'sonic', 'steelseries', 'razer', 'corsair',
    'icue', 'synapse', 'ghub', 'engine', 'armory', 'aura', 'rgb',
    'msi', 'dragon', 'mystic'
)

$pattern = $badApps -join '|'

Write-Host "=== Potentially Conflicting Processes ===" -ForegroundColor Yellow
$found = Get-Process | Where-Object { $_.ProcessName -match $pattern }
if ($found) {
    $found | Format-Table ProcessName, Id, Path -AutoSize
} else {
    Write-Host "None found" -ForegroundColor Green
}

Write-Host "`n=== All Running Processes (for manual review) ===" -ForegroundColor Yellow
Get-Process | Where-Object { $_.MainWindowTitle -ne '' } | Sort-Object ProcessName | Format-Table ProcessName, MainWindowTitle -AutoSize
