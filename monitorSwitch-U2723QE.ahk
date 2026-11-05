#Requires AutoHotkey v2.0
#SingleInstance Force

; Dell U2723QE (monitor ID DEL4278) - VCP 0x60 input selection
; Windows Alt+[ : Mac on USB-C (27 / 0x1B)
; Mac Option+] : return to Windows using the macOS helper.
; sc01A is the physical [ key on a standard US keyboard.

monitorId := "DEL4278"
controlMyMonitor := A_ScriptDir "\ControlMyMonitor.exe"

SwitchMonitorInput(inputValue) {
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

}

!sc01A::SwitchMonitorInput(27)
