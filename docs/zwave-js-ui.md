# Z-Wave JS UI

Z-Wave controller and MQTT bridge. Manages Z-Wave devices and publishes state to MQTT for Home Assistant.

---

## Instance

| Field | Value |
|---|---|
| LXC ID | 108 |
| Host | <host> (<ip>) |
| IP | <ip> (static DHCP lease) |
| OS | Debian 12 |
| CPU | 2 cores |
| RAM | 1 GB |
| Disk | 4 GB (local-lvm) |
| onboot | yes |
| USB passthrough | Z-Wave stick → `/dev/ttyACM0` |
| Web UI | http://<ip>:8091 |

---

## USB Passthrough

The Z-Wave USB stick is passed through from <host> to LXC 108. The device appears as `/dev/ttyACM0` inside the LXC.

In `/etc/pve/lxc/108.conf` on <host>:
```ini
lxc.cgroup2.devices.allow: c 166:* rwm
lxc.mount.entry: /dev/ttyACM0 dev/ttyACM0 none bind,optional,create=file
```

---

## Service Management

```bash
pct enter 108   # on <host>

systemctl status zwave-js-ui
systemctl restart zwave-js-ui
journalctl -u zwave-js-ui -f
```

---

## Configuration

Z-Wave JS UI is configured via its web UI at http://<ip>:8091.

Key settings:
- Serial port: `/dev/ttyACM0`
- MQTT broker: `mqtt://<ip>` (LXC 100)
- Home Assistant integration: via MQTT (not direct WebSocket — use MQTT mode for reliability)

---

## Persistent Storage

Z-Wave network configuration (node info, device names, security keys) stored at `/var/lib/zwave-store/` inside the LXC. This path is set via `STORE_DIR` in `/opt/.env`:

```
ZWAVEJS_EXTERNAL_CONFIG=/var/lib/zwave-store/.config-db
STORE_DIR=/var/lib/zwave-store
```

**This path is bind-mounted from <host>'s local filesystem** via `mp1` in `/etc/pve/lxc/108.conf`:
```
mp1: /var/lib/zwave-js-ui/zwave-js-ui,mp=/var/lib/zwave-store
```

The store lives at `/var/lib/zwave-store` (deliberately **outside** `/opt/zwave-js-ui`) so the community-scripts `update` flow — which does `rm -rf /opt/zwave-js-ui` — cannot follow the bind mount and wipe the host store. Previously the mount target was inside `/opt/zwave-js-ui/mnt/...`, and every run of `update` destroyed all config + security keys. **Do not put the store back inside `/opt/zwave-js-ui`.**

The store lives on <host> (not <host>) so ZwaveJS stays operational if the NAS goes down. It survives LXC rebuilds because data is outside the LXC rootfs.

## Backup

Three backup layers run nightly:
1. **Built-in app backup** — UI configured to write zips to `/mnt/backups` (→ `/mnt/<host>/backups/services/zwave` on <host>) at 1am, 7-day retention.
2. **backup-configs.sh** — directly tars the store dir at 2am, committed to git as `zwave-js-ui.tar.gz`.

PBS snapshots of LXC 108 also run daily via Proxmox.

**Security keys are in `settings.json` inside the store dir.** If keys are lost, all S2-paired devices must be re-paired. Always verify a recent backup exists before any LXC migration or restore.

## Restore After LXC Rebuild

```bash
# On <host> — before starting the new LXC
pct stop 108
# Ensure 108.conf contains both:
#   mp0: /mnt/<host>/backups/services/zwave,mp=/mnt/backups
#   mp1: /var/lib/zwave-js-ui/zwave-js-ui,mp=/var/lib/zwave-store
# AND /opt/.env in the LXC must set STORE_DIR=/var/lib/zwave-store
pct start 108
# Navigate to http://<ip>:8091 — config should be intact
# Verify: Settings → Z-Wave → serial port is /dev/ttyACM0
```

---

## Planned: Move to IoT VLAN

Z-Wave JS UI is planned to move to IoT VLAN (<subnet>). OPNsense will have a rule allowing LAN access on port 8091. See [home-assistant.md](home-assistant.md).

---

## Related

- [mqtt.md](mqtt.md)
- [home-assistant.md](home-assistant.md)
