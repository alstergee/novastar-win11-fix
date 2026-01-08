# Check MarsServerProvider dependencies
$marsPath = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider"

Write-Host "=== Loading MarsServerProvider Assembly ===" -ForegroundColor Yellow
try {
    $asm = [System.Reflection.Assembly]::LoadFile("$marsPath\MarsServerProvider.exe")
    Write-Host "Loaded successfully" -ForegroundColor Green

    Write-Host "`n=== Referenced Assemblies ===" -ForegroundColor Yellow
    $asm.GetReferencedAssemblies() | ForEach-Object {
        $name = $_.Name
        $version = $_.Version

        # Check if it exists
        $dllPath = "$marsPath\$name.dll"
        if (Test-Path $dllPath) {
            Write-Host "[OK] $name v$version" -ForegroundColor Green
        } else {
            # Check GAC
            $gacPath = "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\$name"
            if (Test-Path $gacPath) {
                Write-Host "[GAC] $name v$version" -ForegroundColor Cyan
            } else {
                Write-Host "[MISSING?] $name v$version" -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "`n=== LibUsbDotNet Info ===" -ForegroundColor Yellow
try {
    $libusb = [System.Reflection.Assembly]::LoadFile("$marsPath\LibUsbDotNet.dll")
    Write-Host "LibUsbDotNet loaded" -ForegroundColor Green
    Write-Host "Version: $($libusb.GetName().Version)" -ForegroundColor Cyan
} catch {
    Write-Host "Error loading LibUsbDotNet: $_" -ForegroundColor Red
}
