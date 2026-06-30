#!/usr/bin/env bash
# Creates and configures a zwave-js-ui LXC on Proxmox VE. Run on the host as root.
set -euo pipefail
VMID="${1:?Usage: $0 <vmid> [options]}"
# TODO: pct create / config / install zwave-js-ui. Mirror jellyfin/lxc/provision.sh.
echo "[provision] zwave-js-ui LXC $VMID — not yet implemented"
