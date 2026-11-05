#!/bin/zsh
# Mac -> Windows. LG main display via webOS, Dell portrait via built-in USB KVM.
set -euo pipefail
ROOT="/Users/Shared/SwitchMonitorInput"
CONFIG="$ROOT/DualMonitor.local.env"
[[ -r "$CONFIG" ]] || { print -u2 "Missing $CONFIG"; exit 2; }
source "$CONFIG"
[[ "$LG_WIN_HDMI" == [1-4] ]] || { print -u2 "Invalid LG_WIN_HDMI"; exit 3; }
[[ -n "$LG_TV_IP" ]] || { print -u2 "Missing LG_TV_IP"; exit 3; }
PYTHON="$ROOT/.venv/bin/python"
COMPAT="$ROOT/lg_webos_compat.py"
KEYFILE="$ROOT/.lg-webos-key.sqlite"
[[ -x "$PYTHON" && -r "$COMPAT" ]] || { print -u2 "WebOS compatibility client missing"; exit 4; }
if [[ "$#" -gt 0 && "$1" == "--dry-run" ]]; then
  print "READY: LG -> HDMI_$LG_WIN_HDMI; Dell -> DisplayPort 15"
  exit 0
fi
if [[ "$#" -gt 0 && "$1" == "--pair-test" ]]; then
  "$PYTHON" "$COMPAT" --log ERROR -p "$KEYFILE" "$LG_TV_IP" get_current_app
  exit 0
fi
# Fail closed: only transfer keyboard after LG switch succeeds.
"$PYTHON" "$COMPAT" --log ERROR -p "$KEYFILE" "$LG_TV_IP" set_input "HDMI_$LG_WIN_HDMI"
/bin/zsh "$ROOT/SwitchDellOnlyToWindows.command"
