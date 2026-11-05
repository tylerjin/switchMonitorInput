#!/bin/zsh
# Dell U2723QE: return the monitor and its built-in USB KVM to Windows DisplayPort.
# Install a macOS Shortcut/Quick Action to run this script on a hotkey.
set -euo pipefail

DDC="/opt/homebrew/bin/m1ddc"
if [[ ! -x "$DDC" ]]; then
  print -u2 "m1ddc not installed: $DDC"
  exit 2
fi

# Verify the monitor model; never switch another connected monitor by mistake.
displays="$("$DDC" display list 2>&1)" || {
  print -u2 "Cannot enumerate monitors: $displays"
  exit 3
}
matches="$(print -r -- "$displays" | /usr/bin/grep -E '^\[[0-9]+\][[:space:]]+DELL U2723QE[[:space:]]*\(' || true)"
if [[ -z "$matches" ]]; then
  print -u2 "Dell U2723QE not detected. Make sure its USB-C input is active."
  print -u2 "$displays"
  exit 4
fi
if [[ "$(print -r -- "$matches" | /usr/bin/wc -l | /usr/bin/tr -d ' ')" != "1" ]]; then
  print -u2 "More than one U2723QE detected; refusing ambiguous switch."
  exit 5
fi

display_number="$(print -r -- "$matches" | /usr/bin/sed -E 's/^\[([0-9]+)\].*/\1/')"
"$DDC" display "$display_number" set input 15
print "Requested Dell U2723QE -> Windows DisplayPort (VCP 0x60 = 15)"
