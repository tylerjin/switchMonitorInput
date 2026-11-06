## Wake diagnosis: 2026-11-06 (Dell KVM / LG OLED)

**Reported:** when both computers' screens are dark, a key press seems to wake an inconsistent host, while LG sometimes does not light up.

**Measured, not inferred:**
- Windows AC screen timeout ~10 minutes, OS S3 sleep timeout disabled; keyboard/mouse HID wake capability present; no recent Windows Power-Troubleshooter event found. The two machines being "screen off" is not proof that they were system-sleeping.
- Mac AC `pmset sleep=0` (no automatic system sleep), `displaysleep=60`; macOS logs several display-off/on events, including built-in keyboard/trackpad activity. The Mac can be active when its display is dark.
- LGTV Companion v5.7.0 was additionally configured with `BlankWhenIdle=true` and `BlankWhenIdleDelay=5`: *Windows idle could blank the shared LG panel even while the Mac was using it.* Backed up `C:\ProgramData\LGTV Companion\config.json` to `config.pre-dual-wake-fix-20261106.json` and changed **only** `BlankWhenIdle=false`. Restarted `LGTVsvc`; readback: false, auto HDMI select still false, service running, TV still on HDMI 4.
- Current LG webOS `get_power_state` returned `Active`; thus the field problem of a fully powered-off TV was not reproduced. Windows `LGTVcli.exe -screenon Device1` returned `Active` and HDMI remained 4. On the Mac, calling `turn_screen_on` while already active correctly returns error "-102: current sub state must be screen off"; do not insert an unconditional call into the existing working hotkey.
- HDMI-CEC/SIMPLINK remains **off**, deliberately preventing wake-driven source steals. The downside is no HDMI-based TV power sync. LGTV Companion can power on LG by network from Windows, but Mac does not have a console-user wake watcher installed; auto-on from a Mac wake is not established.

**Dell KVM OSD must be checked by the user:** Input Source > Auto Select and Auto Select for USB-C, Personalize > Fast Wakeup, Other USB Charging. The state is not reliably exposed by the current DDC/CI tooling. Auto Select may transfer keyboard focus when a video source sleeps/wakes; the desired behavior is *keep the last explicit hotkey-selected host*, not switch to any newly signaled host. Try USB-C Auto Select=No and general Auto Select=Off (with a reversible wake test). Consider Fast Wakeup=On and Other USB Charging=On in Standby to maintain USB readiness; higher standby power. Do not change the existing USB upstream-to-video port mapping.

**Follow-up physical tests:** (1) While Windows owns KVM, let both video outputs darken, press shared keyboard: Windows should become active; Dell must not auto-switch to USB-C. (2) While Mac owns KVM repeat: Mac should become active; Dell must not auto-switch to DP. (3) Check whether LG is actually in webOS standby or just panel-black on failure; if truly off and Mac owns KVM, add owner-aware *power-only* wake automation for Mac, never HDMI auto-source switching. (4) Confirm Alt+[ / Option+] dual-display switching still works.

OLED care: disabling Windows' cross-host five-minute forced blank does not bypass OS/TV protection; however, Mac currently waits 60 minutes to sleep its display. Recommend configuring a shorter macOS display-off interval (e.g. 10-15 minutes) if appropriate.

This task's **configuration correction is verified; physical dual-host sleep/wake behavior remains unverified.** Do not claim it fully fixed until the OSD and user wake tests have passed.

---

## 2026-11-05: fixed actual hotkey wiring and added LG input readback

**Current active hotkeys:** Windows **Alt+[** and macOS **Option+]** both now invoke dual-display orchestration; the prior hotkey entry scripts had only called the Dell KVM, which explained why LG did not switch.

- Windows: `monitorSwitch-U2723QE.ahk` invokes `SwitchBothToMac.ps1`. The latter sends LG to HDMI 1, verifies the foreground app is `com.webos.app.hdmi1` on two successive polls, then sends Dell VCP 27 (USB-C).
- macOS: existing `SwitchDellToWindows.command` shortcut path now invokes `SwitchBothToWindows.command`. This verifies LG HDMI 4 on two successive polls, then calls `SwitchDellOnlyToWindows.command` (Dell VCP 15).
- Both sides report LG failures rather than claiming success. Windows logs `SwitchBothToMac.log` in the repo folder; Mac logs `/Users/Shared/SwitchMonitorInput/SwitchBothToWindows.log`.
- **Backout:** the original Dell-only commands remain available separately as `monitorSwitch-DellOnly.ahk` and `SwitchDellOnlyToWindows.command`.
- Windows LGTV Companion 5.7.0 and Mac unsigned-manifest webOS client both passed read-only control/authorization tests. **An actual full physical round trip triggered by the updated hotkeys is still pending user validation**.
- The older "staged only / no hotkey binding" notes below describe the previous state; they no longer describe the currently deployed entrypoints.

---

## Confirmed LG input mapping and webOS 26 compatibility (2026-11-05)

- LG main TV: **Windows HDMI 4**, **Mac HDMI 1**.
- Dell vertical U2723QE: **Windows DisplayPort (VCP 15)**, **Mac USB-C (VCP 27)**.
- Windows LGTV Companion was upgraded from **5.0.5 to 5.7.0**. A non-switching foreground-app query now succeeds; the TV reported `com.webos.app.hdmi4`.
- macOS `lg_webos_compat.py` removes a blacklisted signed manifest from the existing `bscpylgtv` CLI without modifying its installed package. The read-only `--pair-test` succeeded with `com.webos.app.hdmi4`.
- The machine-local Windows config `DualMonitor.local.json` has `LgMacHdmi=1`; the macOS config `DualMonitor.local.env` records `LG_MAC_HDMI=1`, `LG_WIN_HDMI=4`. Do not commit local IPs or key databases.
- Windows `SwitchBothToMac.ps1 -DryRun` reports LG HDMI 1, Dell USB-C 27. Mac `SwitchBothToWindows.command --dry-run` reports LG HDMI 4, Dell DP 15.
- **Physical two-display switching has not been validated. The existing Win Alt+[ and Mac Option+] hotkeys still control Dell only.** After a reversible physical test, wire them to `SwitchBothToMac.ps1` and `SwitchBothToWindows.command`, preserving the LG-first, Dell-second fail-closed order.

---

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
