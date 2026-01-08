# Get Nova device instance ID
$devices = Get-PnpDevice | Where-Object { $_.FriendlyName -match 'Nova' -or $_.InstanceId -match 'VID_0483' }
foreach ($dev in $devices) {
    Write-Host "Name: $($dev.FriendlyName)" -ForegroundColor Yellow
    Write-Host "Class: $($dev.Class)"
    Write-Host "Status: $($dev.Status)"
    Write-Host "InstanceId: $($dev.InstanceId)" -ForegroundColor Cyan
    Write-Host ""
}
