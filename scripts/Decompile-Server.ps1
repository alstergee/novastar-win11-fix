# Analyze Nova.LCT.Message.Server for registration logic
$marsPath = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider"

Write-Host "=== Nova.LCT.Message.Server ===" -ForegroundColor Yellow
$serverAsm = [System.Reflection.Assembly]::LoadFile("$marsPath\Nova.LCT.Message.Server.dll")
$serverTypes = $serverAsm.GetTypes()

foreach ($type in $serverTypes) {
    Write-Host "`n$($type.FullName)" -ForegroundColor Green

    # Get all methods
    $methods = $type.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::DeclaredOnly)
    foreach ($method in $methods) {
        Write-Host "  $($method.Name)($($method.GetParameters() | ForEach-Object { $_.ParameterType.Name } | Join-String -Separator ', '))" -ForegroundColor Cyan
    }

    # Get fields
    $fields = $type.GetFields([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static)
    foreach ($field in $fields) {
        if ($field.Name -match 'register|server|memory|share') {
            Write-Host "  [Field] $($field.Name): $($field.FieldType.Name)" -ForegroundColor Yellow
        }
    }
}
