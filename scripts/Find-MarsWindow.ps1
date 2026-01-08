# Find Mars message window

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WinApi {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
}
"@

$marsGuid = "A7F89E4D-04F4-46a6-9754-A334B3E8FEE5"

Write-Host "=== Searching for Mars Window ===" -ForegroundColor Yellow
Write-Host "Looking for window with name: $marsGuid"

# Try FindWindow first
$hwnd = [WinApi]::FindWindow($null, $marsGuid)
if ($hwnd -ne [IntPtr]::Zero) {
    Write-Host "FOUND via FindWindow: $hwnd" -ForegroundColor Green
} else {
    Write-Host "Not found via FindWindow" -ForegroundColor Yellow
}

# Enumerate all windows
Write-Host "`n=== All windows containing 'Nova', 'Mars', 'LCT', or the GUID ===" -ForegroundColor Yellow
$windows = @()

$callback = [WinApi+EnumWindowsProc]{
    param($hwnd, $lParam)
    $length = [WinApi]::GetWindowTextLength($hwnd)
    if ($length -gt 0) {
        $sb = New-Object System.Text.StringBuilder($length + 1)
        [WinApi]::GetWindowText($hwnd, $sb, $sb.Capacity) | Out-Null
        $title = $sb.ToString()
        if ($title -match "Nova|Mars|LCT|A7F89E4D|SmartLCT|Server") {
            $pid = 0
            [WinApi]::GetWindowThreadProcessId($hwnd, [ref]$pid) | Out-Null
            Write-Host "  HWND: $hwnd | PID: $pid | Title: $title" -ForegroundColor Cyan
        }
    }
    return $true
}

[WinApi]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null

# Check Mars process
Write-Host "`n=== Mars Process Check ===" -ForegroundColor Yellow
$mars = Get-Process -Name "MarsServerProvider" -ErrorAction SilentlyContinue
if ($mars) {
    Write-Host "Mars PID: $($mars.Id)"
    Write-Host "Mars MainWindowHandle: $($mars.MainWindowHandle)"
    Write-Host "Mars MainWindowTitle: '$($mars.MainWindowTitle)'"
} else {
    Write-Host "Mars not running" -ForegroundColor Red
}
