# SmartLCT & V-Can Fix for Windows 11

**Fixes SmartLCT and V-Can communication issues with Novastar VX400 (and similar controllers) on Windows 11.**

## The Problem

After Windows 11 updates, SmartLCT/V-Can stop communicating with your VX400:
- "The communication services are not working properly"
- "server register: false" in logs
- Device not detected

**Root cause:** SmartLCT and V-Can ship with a broken MarsServerProvider that fails to create the IPC window needed for communication.

## Quick Start

### Fresh Install (One-Stop Shop)
Double-click `Install-Everything.bat` - installs SmartLCT, V-Can, applies fix, and installs driver.

### Already Have SmartLCT/V-Can Installed?
- **SmartLCT**: Double-click `Deploy-Fix.bat`
- **V-Can**: Double-click `Deploy-VCan-Fix.bat`

### After Running Fix
If device still not detected:
1. Open Device Manager
2. Find NovaStar device → Update driver
3. Browse → Let me pick from list
4. Select **"Nova ProHD"** under **"libusb-win32 devices"**

## What's Included

```
NovastarFix/
├── Install-Everything.bat         # ONE-CLICK: Install + Fix everything
├── Install-Everything.ps1         # Full installer script
├── Deploy-Fix.bat                 # SmartLCT fix only
├── Deploy-SmartLCT-Fix.ps1
├── Deploy-VCan-Fix.bat            # V-Can fix only
├── Deploy-VCan-Fix.ps1
├── Installers/                    # Software installers
│   ├── SmartLCT V3.5.13 Setup.exe
│   └── V-Can V3.8.0 Setup.exe
├── MarsServerProvider_Fixed/      # Working Mars from NovaLCT V5.8.1
├── Driver_NovaProHD/              # USB driver files
│   ├── nova_prohd.inf
│   ├── Nova_ProHD.cat
│   ├── amd64/
│   └── x86/
├── scripts/                       # Diagnostic scripts
├── CLAUDE.md                      # Technical documentation
└── README.md                      # This file
```

## Technical Details

**The Fix:**
SmartLCT/V-Can's MarsServerProvider doesn't call `LCTServerStub.Initalize()`, so the hidden IPC window (GUID: `A7F89E4D-04F4-46a6-9754-A334B3E8FEE5`) is never created. NovaLCT V5.8.1's Mars works correctly, so we swap it in.

**Device Info:**
- VID: 0483 (STMicroelectronics)
- PID: 5720
- Chip: STM32
- Working driver: Nova ProHD (libusb-win32)

## Supported Devices

Tested with:
- Novastar VX400

Should work with other Novastar controllers using STM32 USB:
- VX600, VX1000, VX16S
- MCTRL series

## Troubleshooting

**Device not detected?**
- Use Device Manager to manually select "Nova ProHD" driver
- Try different USB port (no hub)
- Try different USB cable
- Unplug, wait 10 seconds, replug

**Multiple "NovaStar" entries in Device Manager?**
Ghost devices from different USB ports. Remove with:
```powershell
pnputil /remove-device "USB\VID_0483&PID_5720\<instance-id>"
```

## Why Not Just Use NovaLCT?

Yes, NovaLCT works. No, we don't want it. SmartLCT and V-Can are simpler for basic configuration. This fix lets you keep using them.

## Disclaimer

Modifies system drivers. Use at your own risk. Not affiliated with Novastar.

## License

MIT
