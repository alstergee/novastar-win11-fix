# Analyze MarsServerProvider assembly
$marsPath = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider"

Add-Type -AssemblyName System.Reflection

Write-Host "=== Loading Assembly ===" -ForegroundColor Yellow
$asm = [System.Reflection.Assembly]::LoadFile("$marsPath\MarsServerProvider.exe")

Write-Host "`n=== All Types ===" -ForegroundColor Yellow
$types = $asm.GetTypes()
$types | ForEach-Object { Write-Host $_.FullName }

Write-Host "`n=== Looking for 'register' or 'server' related methods ===" -ForegroundColor Yellow
foreach ($type in $types) {
    $methods = $type.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static)
    foreach ($method in $methods) {
        if ($method.Name -match 'register|server|init|start|connect') {
            Write-Host "$($type.FullName).$($method.Name)" -ForegroundColor Cyan
        }
    }
}

Write-Host "`n=== Looking for ShareMemory usage ===" -ForegroundColor Yellow
$shareMemAsm = [System.Reflection.Assembly]::LoadFile("$marsPath\Nova.Process.ShareMemory.dll")
$shareMemTypes = $shareMemAsm.GetTypes()
$shareMemTypes | ForEach-Object {
    Write-Host $_.FullName -ForegroundColor Green
    $_.GetMethods() | ForEach-Object { Write-Host "  - $($_.Name)" }
}
