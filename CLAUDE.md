# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SmartLCT-Fix is a troubleshooting toolkit for fixing Novastar LED wall controller communication issues on Windows 10/11.

**ROOT CAUSE FOUND:** SmartLCT's bundled MarsServerProvider fails to create the IPC window on Windows 11, causing "server register: false" errors. The fix is to swap in NovaLCT's working MarsServerProvider.

## Key Technical Details

**Hardware:**
- Device: Novastar VX400 (and similar controllers: VX600, VX1000, VX16S, MCTRL series)
- USB Chip: STMicroelectronics STM32
- VID: 0483, PID: 5720

**Driver situation:**
- Novastar ships libusb-win32 v1.2.6.0 (from 2013)
- Driver itself works fine with libusbK or WinUSB on Windows 11
- The REAL problem is SmartLCT's broken MarsServerProvider

**Software stack:**
- SmartLCT → MarsServerProvider → LibUsbDotNet → libusb driver → USB device
- MarsServerProvider uses IPC: shared memory "LedInfo" + hidden window `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5`
- SmartLCT's Mars fails to create the GUID window → "server register: false"
- NovaLCT's Mars creates the window correctly → works!

**Symptoms (before fix):**
- SmartLCT shows "The communication services are not working properly"
- Mars Service Provider shows `server register: false` in logs
- The GUID window `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5` is missing

## Scripts

All scripts require Administrator privileges. PowerShell scripts use `#Requires -RunAsAdministrator`.

| Script | Purpose |
|--------|---------|
| `Diagnose-NovastarDriver.ps1` | Detect driver issues (6 checks) |
| `Fix-NovastarDriver.ps1` | Attempt automated fix (limited success) |
| `Full-Reinstall.ps1` | Clean reinstall with SFC/DISM repairs |
| `Nuclear-Uninstall.ps1` | Complete removal (7 steps) |
| `Check-Installation.ps1` | Check what's installed |
| `Get-LibusbDrivers.ps1` | List libusb drivers in driver store |
| `Run-*.bat` | Batch launchers for PowerShell scripts |

```powershell
# Run a script (as Administrator)
.\scripts\Diagnose-NovastarDriver.ps1
```

## The Actual Fix (SOLUTION FOUND!)

**The Mars Swap - Steal NovaLCT's working MarsServerProvider:**

```powershell
# 1. Install NovaLCT first (provides working Mars files)
#    Installer: C:\Users\david\Desktop\NovaLCT V5.8.1.exe

# 2. Run the swap script
.\scripts\Swap-Mars.ps1

# 3. Launch SmartLCT - should now show "Service is connected"

# To restore original (if needed):
.\scripts\Swap-Mars.ps1 -Restore
```

**What the script does:**
1. Kills SmartLCT and MarsServerProvider
2. Backs up SmartLCT's Mars to `C:\Users\david\Desktop\SmartLCT_Mars_Backup`
3. Copies NovaLCT's Mars from `%APPDATA%\Nova Star\NovaLCT\Bin\MarsServerProvider`
4. SmartLCT now uses NovaLCT's working Mars!

**Part 2: Fix the USB Driver (if device not detected)**

**DO NOT USE ZADIG** - use Device Manager instead:
1. Open Device Manager
2. Find the NovaStar device (might show under libusbK or with yellow warning)
3. Right-click → Update driver → Browse my computer → Let me pick from list
4. Select **"Nova ProHD"** under **"libusb-win32 devices"**
5. VX400 now detected in SmartLCT!

## Common Commands

```powershell
# RUN AS ADMIN - use this pattern for elevated commands
Start-Process 'program.exe' -Verb RunAs
Start-Process powershell -ArgumentList '-File script.ps1' -Verb RunAs

# Kill SmartLCT and Mars (ALWAYS do this before patching/debugging)
Stop-Process -Name 'SmartLCT','MarsServerProvider' -Force -ErrorAction SilentlyContinue

# Check device status
Get-PnpDevice -Class "libusb-win32 devices"

# Check Mars processes
Get-Process -Name "*Mars*"

# View SmartLCT log
Get-Content "C:\Program Files (x86)\Nova Star\SmartLCT\Bin\Log\SmartLCT.log" -Tail 50

# View Mars log
Get-Content "$env:APPDATA\NovaLCT 2012\MarsServerProvider\MarsServerLog.log" -Tail 50

# List libusb drivers in driver store
pnputil /enum-drivers | Select-String "libusb" -Context 5

# Remove a ghost device
pnputil /remove-device "USB\VID_0483&PID_5720\<instance-id>"

# Copy file to Program Files (requires admin)
Start-Process cmd -ArgumentList '/c copy /Y "source.dll" "C:\Program Files (x86)\...\dest.dll"' -Verb RunAs -Wait

# Launch dnSpy debugger as admin
Start-Process 'C:\Users\david\Desktop\dnSpy\dnSpy.exe' -Verb RunAs
```

## File Locations

- SmartLCT: `C:\Program Files (x86)\Nova Star\SmartLCT\`
- MarsServerProvider: `...\SmartLCT\Bin\MarsServerProvider\`
- SmartLCT logs: `...\SmartLCT\Bin\Log\`
- Mars logs: `%APPDATA%\NovaLCT 2012\MarsServerProvider\`
- Config: `%APPDATA%\SmartLCT\`

## Notes

- **NovaLCT must be installed** to provide the working MarsServerProvider files
- User prefers SmartLCT for simplicity, but needs NovaLCT's Mars backend
- The libusb-win32 driver is intentional, not a mistake - just outdated
- LibUsbDotNet supports multiple backends (libusb-win32, libusbK, WinUSB)
- **IPC mechanism**: Shared memory "LedInfo" + hidden window with GUID title
- See `todo.md` for full troubleshooting session history and findings

## Key Technical Discovery

SmartLCT and MarsServerProvider communicate via:
1. **Shared memory** named "LedInfo" (100MB) - works fine
2. **Hidden window** with title `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5` for WM_COPYDATA messages

SmartLCT's bundled Mars fails to call `LCTServerStub.Initalize()` which creates this window.
NovaLCT's Mars (V5.8.1) works correctly and creates the window.

Use `Find-MarsWindow.ps1` to check if the GUID window exists.
