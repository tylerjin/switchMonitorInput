#Requires AutoHotkey v2.0
#SingleInstance Force

; Dell U2723QE + LG OLED dual-screen switch to Mac
; Alt+[ invokes LG HDMI1 readback verification before Dell USB-C27 KVM switch.
; Saved Dell-only fallback: monitorSwitch-DellOnly.ahk
!sc01A::SwitchBothToMac()

SwitchBothToMac() {
    script := A_ScriptDir "\SwitchBothToMac.ps1"
    if !FileExist(script) {
        MsgBox "Missing dual-display script: " script
        return
    }
    command := '"' A_WinDir '\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "' script '"'
    try {
        code := RunWait(command, A_ScriptDir, "Hide")
        if (code != 0) {
            MsgBox "LG dual-display switch failed (exit " code ").`nDell KVM was not switched.`nSee: " A_ScriptDir "\SwitchBothToMac.log"
        }
    } catch as err {
        MsgBox "Cannot start dual-display switch: " err.Message
    }
}
