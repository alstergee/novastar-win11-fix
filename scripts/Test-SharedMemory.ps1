# Test shared memory creation/access like Mars does

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class SharedMemTest {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr CreateFileMapping(
        IntPtr hFile,
        IntPtr lpFileMappingAttributes,
        uint flProtect,
        uint dwMaximumSizeHigh,
        uint dwMaximumSizeLow,
        string lpName);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr OpenFileMapping(
        uint dwDesiredAccess,
        bool bInheritHandle,
        string lpName);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr MapViewOfFile(
        IntPtr hFileMappingObject,
        uint dwDesiredAccess,
        uint dwFileOffsetHigh,
        uint dwFileOffsetLow,
        uint dwNumberOfBytesToMap);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll")]
    public static extern int GetLastError();
}
"@

$PAGE_READWRITE = 0x04
$FILE_MAP_ALL_ACCESS = 0x06
$INVALID_HANDLE_VALUE = [IntPtr]::new(-1)

Write-Host "=== Testing Shared Memory 'LedInfo' ===" -ForegroundColor Yellow

# Try to open existing
$handle = [SharedMemTest]::OpenFileMapping($FILE_MAP_ALL_ACCESS, $false, "LedInfo")
$error = [SharedMemTest]::GetLastError()

if ($handle -ne [IntPtr]::Zero) {
    Write-Host "SUCCESS: Opened existing 'LedInfo' shared memory" -ForegroundColor Green
    Write-Host "Handle: $handle"
    [SharedMemTest]::CloseHandle($handle)
} else {
    Write-Host "Could not open existing 'LedInfo' (error $error) - trying to create..." -ForegroundColor Yellow

    # Try to create
    $size = 104857600 + 130  # Same as Mars code
    $handle = [SharedMemTest]::CreateFileMapping($INVALID_HANDLE_VALUE, [IntPtr]::Zero, $PAGE_READWRITE, 0, $size, "LedInfo")
    $error = [SharedMemTest]::GetLastError()

    if ($handle -ne [IntPtr]::Zero) {
        Write-Host "SUCCESS: Created 'LedInfo' shared memory" -ForegroundColor Green
        Write-Host "Handle: $handle"

        # Try to map
        $view = [SharedMemTest]::MapViewOfFile($handle, $FILE_MAP_ALL_ACCESS, 0, 0, $size)
        if ($view -ne [IntPtr]::Zero) {
            Write-Host "SUCCESS: Mapped view of shared memory" -ForegroundColor Green
        } else {
            Write-Host "FAILED: Could not map view (error $([SharedMemTest]::GetLastError()))" -ForegroundColor Red
        }

        [SharedMemTest]::CloseHandle($handle)
    } else {
        Write-Host "FAILED: Could not create shared memory (error $error)" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing Semaphores ===" -ForegroundColor Yellow
try {
    $sem = [System.Threading.Semaphore]::OpenExisting("WriteShareMemory")
    Write-Host "SUCCESS: Opened 'WriteShareMemory' semaphore" -ForegroundColor Green
    $sem.Close()
} catch {
    Write-Host "Could not open 'WriteShareMemory' - not created by Mars yet" -ForegroundColor Yellow
}
