# Novastar VX400 + SmartLCT Troubleshooting Tracker

## Current Status
**Problem:** SmartLCT cannot communicate with VX400 after Windows 11 updates
**Goal:** Get SmartLCT working again (NOT switching to NovaLCT)
**Current Phase:** ✅ FULLY WORKING!

---

## ✅ SOLUTION FOUND (2026-01-07)

### THE COMPLETE FIX (Two Parts)

#### Part 1: Fix the IPC - Swap MarsServerProvider from NovaLCT

**SmartLCT's MarsServerProvider is broken on Windows 11. NovaLCT's version works!**

```powershell
# Run the swap script (backs up original first)
.\scripts\Swap-Mars.ps1

# To restore original SmartLCT Mars:
.\scripts\Swap-Mars.ps1 -Restore
```

**What this does:**
1. Backs up SmartLCT's MarsServerProvider to `C:\Users\david\Desktop\SmartLCT_Mars_Backup`
2. Copies NovaLCT's working MarsServerProvider from `%APPDATA%\Nova Star\NovaLCT\Bin\MarsServerProvider`
3. SmartLCT now shows "Service is connected" ✓

#### Part 2: Fix the Driver - Use Device Manager (NOT Zadig!)

**After the Mars swap, if device isn't detected:**

1. Open **Device Manager**
2. Find the NovaStar device (might be under "libusbK devices" or with a yellow warning)
3. Right-click → **Update driver**
4. Choose **"Browse my computer for drivers"**
5. Choose **"Let me pick from a list of available drivers"**
6. Select **"Nova ProHD"** under **libusb-win32 devices**
7. Click Next → device now detected in SmartLCT!

**Requirements:**
- NovaLCT must be installed first (provides the working Mars files)
- The Nova ProHD driver should already be in the driver store from NovaLCT installation

---

## ROOT CAUSE ANALYSIS

**Mars's hidden IPC window was NOT being created by SmartLCT's Mars!**

SmartLCT looks for window: `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5`
- SmartLCT's Mars: Window **MISSING** → "server register: false"
- NovaLCT's Mars: Window **CREATED** → "server register: true" ✓

### IPC Mechanism (from decompiled Nova.LCT.Message.Server.dll):
1. Shared memory named "LedInfo" (100MB) - **WORKS FINE** ✓
2. Hidden window with GUID title for WM_COPYDATA messaging - **BROKEN in SmartLCT Mars** ✗
3. Uses `ChangeWindowMessageFilter` for UIPI bypass

### Why SmartLCT's Mars fails:
- The `Initalize()` method in `LCTServerStub` is never called
- Debugging showed breakpoints in `Initalize()` were never hit
- Mars runs but silently fails before IPC setup
- NovaLCT's newer MarsServerProvider (V5.8.1) doesn't have this bug

---

## EVERYTHING WE'VE TRIED (Breadcrumb Trail)

### Session: 2026-01-07

#### Phase 1: Initial Diagnosis
- [x] Checked Device Manager
- [x] Found device under "libusb-win32 devices" as "NovaStar"
- [x] Identified VID: 0483, PID: 5720 (STMicroelectronics STM32 chip)
- [x] Confirmed libusb-win32 is INTENTIONALLY used by Novastar (not wrong driver)
- [x] Found driver version 1.2.6.0 from 2013 (ancient!)
- [x] Found MarsServerProvider fails with `server register: false`

#### Phase 2: Driver Experiments with Zadig
- [x] Tried libusbK v3.1.0.0 via Zadig - **FAILED** (IPC issue, not driver)
- [x] Tried fresh libusb-win32 v1.4.0.0 via Zadig - **FAILED** (IPC issue, not driver)
- [ ] WinUSB via Zadig - **TESTING** (after IPC fix)

#### Phase 3: Software Reinstalls
- [x] Reinstalled SmartLCT V3.5.13 - **FAILED**
- [x] Installed SmartLCT V3.5.3 over existing - **FAILED**
- [x] Cancelled driver installer during SmartLCT install - **FAILED**

#### Phase 4: Deep Debugging
- [x] Decompiled Nova.LCT.Message.Server.dll with dnSpy
- [x] Found IPC mechanism uses GUID window + shared memory
- [x] Created Find-MarsWindow.ps1 to detect GUID window
- [x] Confirmed GUID window missing when SmartLCT Mars runs
- [x] Tried debugging with dnSpy - `Initalize()` never called
- [x] Created MarsShim.cs to fake the GUID window - didn't fully work

#### Phase 5: The Switcheroo (SUCCESS!)
- [x] Installed NovaLCT V5.8.1
- [x] Confirmed NovaLCT's Mars CREATES the GUID window ✓
- [x] Created Swap-Mars.ps1 script
- [x] Swapped NovaLCT's MarsServerProvider into SmartLCT
- [x] **SmartLCT now shows "Service is connected"** ✓

#### Phase 6: USB Driver (SUCCESS!)
- [x] Tried WinUSB via Zadig - **FAILED**
- [x] Used Device Manager → Update driver → Browse → Pick from list
- [x] Selected **Nova ProHD** under **libusb-win32 devices**
- [x] **VX400 NOW DETECTED IN SMARTLCT!** ✓

---

## NEXT STEPS

**IT'S WORKING!** No more steps needed.

### If you need to redo the fix after reinstalling SmartLCT:
1. Make sure NovaLCT is installed
2. Run `.\scripts\Swap-Mars.ps1`
3. If device not detected, use Device Manager to select "Nova ProHD" driver

---

## KEY FINDINGS

| Finding | Details |
|---------|---------|
| Device | USB VID 0483 PID 5720 (STM32 chip) |
| Working Driver | **Nova ProHD** under libusb-win32 devices (NOT Zadig!) |
| **ROOT CAUSE** | SmartLCT's Mars fails to create IPC window on Win11 |
| **IPC FIX** | Swap Mars from NovaLCT V5.8.1 |
| **DRIVER FIX** | Device Manager → Nova ProHD driver |
| IPC Window GUID | `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5` |
| Before Fix | `server register: false`, device not detected |
| **After Fix** | `Service is connected`, VX400 detected! ✓ |

---

## WHAT WE LEARNED

1. **SmartLCT's bundled MarsServerProvider is broken** on Windows 11
2. **NovaLCT's MarsServerProvider works** - it creates the required GUID window
3. **The IPC mechanism** uses both shared memory AND a hidden window for WM_COPYDATA
4. **Zadig is NOT the answer** - use Device Manager to select Nova ProHD driver instead
5. **Installation order matters** - install NovaLCT first, provides working Mars + correct driver
6. **Two fixes needed**: Mars swap (for IPC) + Nova ProHD driver (for USB detection)

---

## Download Links

- SmartLCT V3.2.1 (OLD): https://www.colorlitled.com/novastar-smartlct-download/
- SmartLCT V3.2.1 (Chauvet): https://chauvetvideo.com/downloads-beta/
- Zadig (driver tool): https://zadig.akeo.ie/

---

## Scripts Created

| Script | Purpose |
|--------|---------|
| `Swap-Mars.ps1` | **THE FIX** - Swap NovaLCT's Mars into SmartLCT |
| `Find-MarsWindow.ps1` | Check if GUID IPC window exists |
| `Test-SharedMemory.ps1` | Test "LedInfo" shared memory |
| `Check-USBDevice.ps1` | Check USB device status |
| `Check-MarsLog.ps1` | Check Mars log files |
| `Check-EventLog.ps1` | Check Windows Event Log for errors |
| `MarsShim.cs` | Experimental - fake Mars IPC window |
| `Diagnose-NovastarDriver.ps1` | Check driver status |
| `Fix-NovastarDriver.ps1` | Attempt automated fix |
| `Nuclear-Uninstall.ps1` | Complete removal |
| `Run-AsAdmin.ps1` | Helper for elevated commands |

---

## Log Files Location

- SmartLCT: `C:\Program Files (x86)\Nova Star\SmartLCT\Bin\Log\SmartLCT.log`
- Mars: `%APPDATA%\NovaLCT 2012\MarsServerProvider\MarsServerLog.log`
- Zadig: `C:\Users\david\Desktop\Zadig.log`
