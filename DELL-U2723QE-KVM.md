# Dell U2723QE hardware KVM: Windows HDMI ↔ Mac USB-C

## Why the Windows-only hotkey cannot return from Mac

With the keyboard/mouse receiver plugged into the Dell monitor's USB downstream hub, the built-in KVM directs keyboard input to the selected USB upstream computer. After switching to Mac, Windows can no longer detect Windows-side hotkeys. This is expected hardware behavior, not an AutoHotkey failure.

## Wiring and input values

- Windows: HDMI video, plus a separate upstream USB cable to the monitor for keyboard/mouse.
- Mac: USB-C video + upstream USB connection.
- Dell U2723QE VCP 0x60: HDMI = 17, USB-C = 27 (verified on this monitor).
- In the Dell OSD KVM / USB settings, map HDMI to the physical upstream port used by Windows. USB-C must map to the Mac's USB-C upstream path.
- Do **not** connect USB storage to the switched monitor hub during KVM testing.

## Windows → Mac

Run the existing `monitorSwitch-U2723QE.ahk` under AutoHotkey v2.

- **Alt+[** (Windows): Dell USB-C / Mac.
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
