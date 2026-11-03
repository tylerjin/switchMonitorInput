#Requires AutoHotkey v2.0
#SingleInstance Force

; Dell U2723QE (monitor ID DEL4277) - VCP 0x60 input selection
; Ctrl+Alt+1: Mac on USB-C (27 / 0x1B)
; Ctrl+Alt+2: Windows on HDMI (17 / 0x11)
; The sent key mirrors the existing Synergy screen-switch shortcuts.

monitorId := "DEL4277"
controlMyMonitor := A_ScriptDir "\ControlMyMonitor.exe"

SwitchMonitorInput(inputValue, synergyKey) {
    global monitorId, controlMyMonitor
    if !FileExist(controlMyMonitor) {
        MsgBox "Missing ControlMyMonitor.exe: " controlMyMonitor
        return
    }

    command := '"' controlMyMonitor '" /SetValue "' monitorId '" 60 ' inputValue
    try {
        RunWait(command, A_ScriptDir, "Hide")
    } catch as err {
        MsgBox "Cannot change Dell U2723QE input.`n" err.Message
        return
    }

    ; Avoid recursively triggering this hotkey when forwarding to Synergy.
    SendEvent "^!{" synergyKey "}"
}

$^!1::SwitchMonitorInput(27, "1")
$^!2::SwitchMonitorInput(17, "2")
