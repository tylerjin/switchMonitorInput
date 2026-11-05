#!/bin/zsh
# Mac -> Windows. LG main display via paired webOS, Dell vertical via built-in KVM.
set -euo pipefail
ROOT="/Users/Shared/SwitchMonitorInput"
CONFIG="$ROOT/DualMonitor.local.env"
[[ -r "$CONFIG" ]] || { print -u2 "Missing $CONFIG"; exit 2; }
source "$CONFIG"
[[ "$LG_WIN_HDMI" == [1-4] ]] || { print -u2 "Invalid LG_WIN_HDMI"; exit 3; }
[[ -n "$LG_TV_IP" ]] || { print -u2 "Missing LG_TV_IP"; exit 3; }
CLIENT="$ROOT/.venv/bin/bscpylgtvcommand"
KEYFILE="$ROOT/.lg-webos-key.sqlite"
[[ -x "$CLIENT" ]] || { print -u2 "WebOS CLI missing"; exit 4; }
if [[ "$#" -gt 0 && "$1" == "--dry-run" ]]; then
  print "READY: LG -> HDMI_$LG_WIN_HDMI; Dell -> DisplayPort 15"
  exit 0
fi
# Fail closed. If pairing fails, do not transfer the keyboard to Windows.
"$CLIENT" --log ERROR -p "$KEYFILE" "$LG_TV_IP" set_input "HDMI_$LG_WIN_HDMI"
/bin/zsh "$ROOT/SwitchDellToWindows.command"
