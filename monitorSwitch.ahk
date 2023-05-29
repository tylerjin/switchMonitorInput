; Used to change the monitor source
; Requires ControlMyMonitor from https://www.nirsoft.net/utils/control_my_monitor.html
; Ctrl(^), Alt(!), Shift(+) 和 Win(#)
; 15 DP, 16 USBC, 17 HDMI1,18 HDMI2
setMonitorInputSource(monitor, inputSelectCode, source)
{
  cmd := "ControlMyMonitor.exe /SetValue " . monitor . " " . inputSelectCode . " " . source
  Run cmd
}

; Map monitor switch to same keys as synergy keyboard switch
$^!1::
{
  setMonitorInputSource("\\.\DISPLAY1\Monitor0", 60, 15)
  Send '^!{1}'
}

$^!2::
{
  setMonitorInputSource("\\.\DISPLAY1\Monitor0", 60, 17)
  Send '^!{2}'
}