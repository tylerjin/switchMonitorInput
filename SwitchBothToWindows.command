#!/bin/zsh
# Return LG to Windows HDMI 4 first; then Dell USB KVM to Windows DP 15.
set -euo pipefail
ROOT="/Users/Shared/SwitchMonitorInput"
source "$ROOT/DualMonitor.local.env"
[[ "$LG_WIN_HDMI" == [1-4] && "$LG_MAC_HDMI" == [1-4] ]] || exit 2
PYTHON="$ROOT/.venv/bin/python"
COMPAT="$ROOT/lg_webos_compat.py"
KEYFILE="$ROOT/.lg-webos-key.sqlite"
LOG="$ROOT/SwitchBothToWindows.log"
lg() { "$PYTHON" "$COMPAT" --log ERROR -p "$KEYFILE" "$LG_TV_IP" "$@"; }
record() { print -r -- "$(date '+%F %T') $*" >> "$LOG"; }
if [[ "${1:-}" == "--dry-run" ]]; then
  print "READY: LG -> HDMI_$LG_WIN_HDMI; Dell -> DisplayPort 15"
  exit 0
fi
if [[ "${1:-}" == "--pair-test" || "${1:-}" == "--check-only" ]]; then
  lg get_current_app
  exit 0
fi
target="com.webos.app.hdmi$LG_WIN_HDMI"
before="$(lg get_current_app)"
record "BEGIN current=$before target=$target"
if [[ "$before" != "$target" ]]; then
  lg set_input "HDMI_$LG_WIN_HDMI" >> "$LOG" 2>&1 || {
    record "LG_COMMAND_FAILED; Dell not switched"
    exit 3
  }
fi
matched=0
for i in {1..10}; do
  sleep 0.5
  current="$(lg get_current_app)" || {
    record "LG_READBACK_FAILED; Dell not switched"
    exit 4
  }
  record "READBACK[$i]=$current"
  if [[ "$current" == "$target" ]]; then
    (( matched+=1 ))
  else
    matched=0
  fi
  if (( matched >= 2 )); then break; fi
done
if (( matched < 2 )); then
  record "LG_NOT_CONFIRMED; restoring HDMI_$LG_MAC_HDMI"
  lg set_input "HDMI_$LG_MAC_HDMI" >> "$LOG" 2>&1 || true
  print -u2 "LG input not confirmed; Dell KVM unchanged"
  exit 5
fi
if ! /bin/zsh "$ROOT/SwitchDellOnlyToWindows.command" >> "$LOG" 2>&1; then
  record "DELL_FAILED; restoring HDMI_$LG_MAC_HDMI"
  lg set_input "HDMI_$LG_MAC_HDMI" >> "$LOG" 2>&1 || true
  exit 6
fi
record "OK LG=HDMI_$LG_WIN_HDMI Dell=DP15"
