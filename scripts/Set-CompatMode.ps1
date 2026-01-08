#Requires -RunAsAdministrator
# Set Windows 7 compatibility mode for SmartLCT and Mars

$exePaths = @(
    "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\SmartLCT.exe",
    "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider\MarsServerProvider.exe"
)

foreach ($exe in $exePaths) {
    Write-Host "Setting compatibility for: $exe" -ForegroundColor Yellow

    # Registry path for compatibility settings
    $regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

    # Create the key if it doesn't exist
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Set Windows 7 compatibility mode + Run as Admin
    Set-ItemProperty -Path $regPath -Name $exe -Value "~ WIN7RTM RUNASADMIN" -Type String
    Write-Host "Done" -ForegroundColor Green
}

Write-Host "`nCompatibility mode set. Now kill and relaunch SmartLCT." -ForegroundColor Cyan
