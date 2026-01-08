#Requires -RunAsAdministrator
# Kill conflicting apps

$killList = @(
    'SmartLCT', 'MarsServerProvider',
    'Nahimic3', 'NahimicService', 'NahimicSvc32', 'NahimicSvc64', 'NahimicAPO4Volume', 'nahimicNotifSys',
    'KillerAnalyticsService', 'KillerNetworkService', 'KillerProviderDataHelperService',
    'SteelSeriesEngine', 'SteelSeriesGG', 'SteelSeriesPrism'
)

foreach ($proc in $killList) {
    $p = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($p) {
        Write-Host "Killing $proc..." -ForegroundColor Yellow
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`nDone. Launching SmartLCT..." -ForegroundColor Green
Start-Sleep 2
Start-Process "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\SmartLCT.exe"
