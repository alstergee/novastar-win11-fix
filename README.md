# Novastar Windows 11 Fix

**Fixes SmartLCT and V-Can communication with Novastar VX400 on Windows 11.**

After Windows 11 updates, SmartLCT and V-Can stop detecting your LED controller. This repo contains a working fix.

---

## The Problem

You're running SmartLCT or V-Can on Windows 11 and suddenly your VX400 (or similar Novastar controller) isn't detected:

- SmartLCT shows **"The communication services are not working properly"**
- Mars Service Provider log shows **"server register: false"**
- Device appears in Device Manager but software can't see it
- Reinstalling doesn't help
- Different USB ports don't help
- You're losing your mind

## What We Tried (That Didn't Work)

During troubleshooting, we tried:

- **Zadig driver swap** (libusbK, WinUSB) - didn't fix the communication issue
- **Reinstalling SmartLCT** - installs the same broken files
- **Compatibility mode** - no effect
- **Running as admin** - no effect
- **Registry cleanup** - no effect
- **Different USB drivers** - red herring, not the real problem

## The Real Problem

After decompiling MarsServerProvider.exe with dnSpy, we discovered the actual root cause:

**SmartLCT and V-Can ship with a broken MarsServerProvider** that fails to initialize properly on Windows 11. Specifically, it doesn't call `LCTServerStub.Initalize()`, which means the IPC window (with GUID title `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5`) never gets created. Without this window, SmartLCT can't communicate with the Mars service.

The driver was a red herring. The real fix is replacing MarsServerProvider.

## The Solution

Replace the broken MarsServerProvider with a working version from **NovaLCT V5.8.1**, which properly creates the IPC window.

---

## Quick Fix (Automated)

### Already have SmartLCT or V-Can installed?

1. Download this repo
2. **For SmartLCT:** Double-click `Fix-SmartLCT.bat`
3. **For V-Can:** Double-click `Fix-VCan.bat`
4. Click "Yes" on the UAC prompt
5. Done! Launch your app.

### Fresh install?

1. Double-click `Install-Everything.bat`
2. Follow the prompts
3. Both apps installed and fixed automatically

---

## Manual Fix (DIY)

If you prefer to do it yourself:

### Step 1: Replace MarsServerProvider

1. Close SmartLCT/V-Can completely
2. Kill `MarsServerProvider.exe` in Task Manager if running
3. Navigate to your app's Mars folder:
   - **SmartLCT:** `C:\Program Files (x86)\Nova Star\SmartLCT\Bin\MarsServerProvider\`
   - **V-Can:** `C:\Program Files (x86)\Nova Star\V-Can\Bin\MarsServerProvider\`
4. Copy everything from `MarsServerProvider_Fixed\` into that folder (overwrite all)
5. Launch your app - should now show "Service is connected"

### Step 2: Fix USB Driver (if device still not detected)

1. Open **Device Manager**
2. Find the NovaStar device (might be under "libusb-win32 devices" or with a yellow warning)
3. Right-click → **Update driver**
4. Choose **"Browse my computer for drivers"**
5. Choose **"Let me pick from a list"**
6. Select **"Nova ProHD"** under **"libusb-win32 devices"**
7. Device should now be detected

---

## What's in This Repo

```
├── Fix-SmartLCT.bat          # One-click fix for SmartLCT
├── Fix-SmartLCT.ps1          # PowerShell script (called by .bat)
├── Fix-VCan.bat              # One-click fix for V-Can
├── Fix-VCan.ps1              # PowerShell script (called by .bat)
├── Install-Everything.bat    # Full installer + fix
├── Install-Everything.ps1    # PowerShell script (called by .bat)
├── MarsServerProvider_Fixed/ # Working Mars files from NovaLCT V5.8.1
├── Driver_NovaProHD/         # USB driver files
├── Installers/               # SmartLCT and V-Can installers
│   ├── SmartLCT V3.5.13 Setup.exe
│   └── V-Can V3.8.0 Setup.exe
└── README.md
```

---

## Supported Devices

Tested with:
- **Novastar VX400**

Should work with other Novastar controllers using the same STM32 USB interface:
- VX600, VX1000, VX16S
- MCTRL series
- Any device with VID `0483` / PID `5720`

---

## Technical Details

For the curious:

- **VID/PID:** 0483:5720 (STMicroelectronics STM32)
- **IPC Mechanism:** Shared memory "LedInfo" (100MB) + hidden window for WM_COPYDATA
- **Window GUID:** `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5`
- **Root cause:** `LCTServerStub.Initalize()` not called in SmartLCT/V-Can's Mars
- **Fix source:** NovaLCT V5.8.1's MarsServerProvider (which works correctly)

---

## FAQ

**Q: Why not just use NovaLCT?**

A: You can! NovaLCT works fine. But SmartLCT and V-Can are simpler for basic configuration. This fix lets you keep using the tools you prefer.

**Q: Will this break anything?**

A: The scripts create a backup before making changes. Run with `-Restore` to undo:
```powershell
.\Fix-SmartLCT.ps1 -Restore
.\Fix-VCan.ps1 -Restore
```

**Q: Do I need to run this after every Windows update?**

A: No, the fix is persistent. You only need to run it once (unless you reinstall SmartLCT/V-Can).

---

## Troubleshooting

**Still not detecting device?**
- Make sure you selected "Nova ProHD" driver in Device Manager
- Try a different USB port (directly on PC, not through a hub)
- Unplug device, wait 10 seconds, plug back in

**Multiple "NovaStar" entries in Device Manager?**
- These are ghost devices from different USB ports
- Right-click and uninstall the ones not currently in use

---

## License

MIT - Do whatever you want with this.

---

## Credits

Fix discovered through extensive debugging, decompilation, and stubbornness.
