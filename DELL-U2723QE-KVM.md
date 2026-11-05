## 2026-11-05: LG 42-inch main screen + Dell U2723QE portrait screen

**Status: staging only; existing working hotkeys remain active.** Do not claim two-display switching is operational until the pairing/HDMI prerequisites below are verified.

- Windows shortcut remains **Alt+[**; Mac shortcut remains **Option+]**.
- Windows uses **LG HDMI 4** (found in its existing LGTV Companion Device1 profile) and **Dell DisplayPort 15** (measured via VCP 0x60).
- Mac uses Dell **USB-C 27** and a separate, currently unknown HDMI socket on the LG TV.
- Windows now detects the Dell as **DEL4278**, not the older DEL4277. The Windows helper has been updated.
- Network discovery and display EDID identify this LG as **OLED42C2PCA (C2 42-inch; LG TV SSCR2)**, not the C4 designation initially assumed.
- LG is accessible via webOS locally, but Windows LGTV Companion reports **Invalid pairing key**; the Mac webOS client reports **Unable to pair**. Physical TV authorization must be repaired.
- Dell's own hardware USB KVM continues to manage keyboard/mouse; no Synergy or external KVM tool is needed.

Staged scripts, **not bound to hotkeys yet**:

- Windows: \`SwitchBothToMac.ps1\` reads local \`DualMonitor.local.json\` (\`LgWindowsHdmi=4\`, \`LgMacHdmi=0\` pending confirmation). It changes LG input first with the existing \`LGTVcli.exe\`, then changes the Dell USB KVM by DDC/CI.
- Mac: \`SwitchBothToWindows.command\` reads local \`DualMonitor.local.env\`, calls an isolated bscpylgtv 0.5.5 CLI to switch LG to HDMI 4, then invokes \`SwitchDellToWindows.command\` to set Dell DP 15.
- Both staged helpers intentionally stop **before moving the Dell USB KVM** if the LG operation fails. The Windows helper also refuses to run when the Mac HDMI port is unknown.
- TV pairing key databases and machine-local IP/HDMI configuration are **not committed to Git**.

Complete the transition only after confirming which LG HDMI socket is connected to the Mac and accepting the on-TV pairing prompts, then do a full physical cross-host switch and return test. The old one-monitor shortcuts should remain in use meanwhile. If the display becomes inaccessible, use the LG remote to choose the correct HDMI source and the Dell physical joystick to choose DP or USB-C.

---

# Dell U2723QE hardware KVM: Windows DP ↔ Mac USB-C

## Why the Windows-only hotkey cannot return from Mac

With the keyboard/mouse receiver plugged into the Dell monitor's USB downstream hub, the built-in KVM directs keyboard input to the selected USB upstream computer. After switching to Mac, Windows can no longer detect Windows-side hotkeys. This is expected hardware behavior, not an AutoHotkey failure.

## Wiring and input values

- Windows: DisplayPort video, plus a separate upstream USB cable to the monitor for keyboard/mouse.
- Mac: USB-C video + upstream USB connection.
- Dell U2723QE VCP 0x60: DisplayPort = 15, USB-C = 27 (read back and verified).
- In the Dell OSD KVM / USB settings, map DP to the physical upstream port used by Windows. USB-C must map to the Mac's USB-C upstream path.
- Do **not** connect USB storage to the switched monitor hub during KVM testing.

## Windows → Mac

Run the existing `monitorSwitch-U2723QE.ahk` under AutoHotkey v2.

- **Alt+[** (Windows): Dell USB-C / Mac (legacy Dell-only hotkey, pending full dual-screen setup).
- The legacy Ctrl+Alt+1 / Ctrl+Alt+2 bindings are removed.

## Mac → Windows

Requires `m1ddc`, already installed under `/opt/homebrew/bin/m1ddc`.

Run `SwitchDellToWindows.command` from macOS while Dell USB-C is selected:

```zsh
/bin/zsh /Users/Shared/SwitchMonitorInput/SwitchDellToWindows.command
```

The script refuses to switch if it cannot find exactly one Dell U2723QE. It controls the monitor by the model detected in the live display list, not by an unstable display number or a private serial.

To bind a native global macOS hotkey:

1. Open **Shortcuts** on the Mac and create a new shortcut called **Return to Windows**.
2. Add **Run Shell Script**, with the command above.
3. Open **Shortcut Details**, choose **Add Keyboard Shortcut**, and press **Option+]** (if not reserved on your Mac).
4. Test **while Mac owns the keyboard and the Dell input is USB-C**. On success the Dell should switch to Windows HDMI and the keyboard should follow if the Dell USB KVM input mappings are correct.

Apple documentation: https://support.apple.com/zh-cn/guide/shortcuts-mac/-apd163eb9f95/mac

**Alternative:** Dell Display and Peripheral Manager for macOS supports hardware KVM hotkeys on compatible Dell models. This avoids the script but requires installing/configuring the application in the console user's account.

## Verification status (2026-11-03)

- Windows Dell DDC switch HDMI 17 → USB-C 27 → HDMI 17: **passed, readback confirmed**.
- Windows AHK v2 syntax, live user-session process and logon task: **passed**.
- Mac script shell syntax and model selection logic: **passed**.
- Mac live DDC return-to-Windows and macOS keyboard shortcut: **not yet verified** (remote management account cannot access Mac GUI session).

## Recovery

Use Dell's physical joystick / On-Screen Display (OSD) **Input Source → HDMI** if the software return shortcut fails. The physical monitor controls do not depend on which computer currently owns the keyboard.
