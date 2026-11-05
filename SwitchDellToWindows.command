#!/bin/zsh
# Existing Mac Option+] Shortcut entrypoint. Run LG webOS first, then Dell USB KVM.
# Recovery: SwitchDellOnlyToWindows.command
set -euo pipefail
exec /bin/zsh "/Users/Shared/SwitchMonitorInput/SwitchBothToWindows.command" "$@"
