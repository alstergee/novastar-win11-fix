# Analyze Nova.LCT.Message.Server for registration logic (32-bit)
$marsPath = "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider"

Write-Host "=== Nova.LCT.Message.Server ===" -ForegroundColor Yellow
try {
    $serverAsm = [System.Reflection.Assembly]::LoadFile("$marsPath\Nova.LCT.Message.Server.dll")
    $serverTypes = $serverAsm.GetTypes()

    foreach ($type in $serverTypes) {
        Write-Host "`n$($type.FullName)" -ForegroundColor Green

        # Get all methods
        $methods = $type.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::DeclaredOnly)
        foreach ($method in $methods) {
            $params = ($method.GetParameters() | ForEach-Object { $_.ParameterType.Name }) -join ', '
            Write-Host "  $($method.Name)($params)" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "`n=== Nova.Process.ShareMemory ===" -ForegroundColor Yellow
try {
    $shareAsm = [System.Reflection.Assembly]::LoadFile("$marsPath\Nova.Process.ShareMemory.dll")
    $shareTypes = $shareAsm.GetTypes()

    foreach ($type in $shareTypes) {
        Write-Host "`n$($type.FullName)" -ForegroundColor Green

        $methods = $type.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::DeclaredOnly)
        foreach ($method in $methods) {
            $params = ($method.GetParameters() | ForEach-Object { $_.ParameterType.Name }) -join ', '
            Write-Host "  $($method.Name)($params): $($method.ReturnType.Name)" -ForegroundColor Cyan
        }

        $fields = $type.GetFields([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static)
        foreach ($field in $fields) {
            Write-Host "  [F] $($field.Name): $($field.FieldType.Name)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
