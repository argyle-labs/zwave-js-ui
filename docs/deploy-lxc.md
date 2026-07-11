# Z-Wave JS UI on a Proxmox LXC (native, USB controller passthrough)

A standalone deployment: Z-Wave JS UI running **natively** inside a **Debian
LXC** on Proxmox, driving a USB Z-Wave controller and exposing both a web UI and
the Z-Wave JS websocket server for Home Assistant. Nothing here needs orca.

> Placeholders: `<proxmox-host>` = your Proxmox node, `<ip>` = a LAN address,
> `<pool>` = your ZFS/backup pool, `<mqtt-host>` = your Mosquitto broker. Pick
> the CT ID with `pvesh get /cluster/nextid` (shown as `<CTID>`).

- **Ports**: 8091 (web UI), 3000 (Z-Wave JS websocket server for the HA integration)
- **Type**: Proxmox LXC — Debian minimal
- **Footprint**: 2 cores / 512 MB RAM / 4 GB disk
- **Hardware**: a USB Z-Wave controller (Aeotec Z-Stick, Zooz ZST10/ZST39, etc.)
  attached to `<proxmox-host>` and passed through

---

## Step 1 — Identify the controller on the host

```bash
ls -l /dev/serial/by-id/          # find the controller's stable path
dmesg | grep -i ttyACM            # it usually enumerates as /dev/ttyACM0
```

Prefer the `/dev/serial/by-id/...` path — it's stable across reboots, unlike a
bare `ttyACM0`.

## Step 2 — Create the LXC + pass the device through

```bash
pveam available | grep debian-12
pct create "$(pvesh get /cluster/nextid)" \
  local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname zwave-js-ui \
  --storage local-lvm \
  --rootfs local-lvm:4 \
  --cores 2 --memory 512 --swap 512 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --onboot 1
```

Stop the CT and add the passthrough lines to `/etc/pve/lxc/<CTID>.conf` on
`<proxmox-host>` (full sample in
[`lxc/zwave-js-ui.conf.example`](../lxc/zwave-js-ui.conf.example)):

```ini
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.cgroup2.devices.allow: c 166:* rwm
lxc.mount.entry: /dev/ttyACM0 dev/ttyACM0 none bind,optional,create=file
```

For a stable path, bind the by-id symlink instead, e.g.:
`lxc.mount.entry: /dev/serial/by-id/<id> dev/ttyACM0 none bind,optional,create=file`.

## Step 3 — Install Z-Wave JS UI

```bash
pct start <CTID>
pct enter <CTID>

ls -l /dev/ttyACM0                # the controller must appear
# install via the community-scripts installer or the upstream release tarball
```

## Step 4 — Configure

Open **http://<ip>:8091**:

- **Settings → Z-Wave**: serial port `/dev/ttyACM0`; paste your controller's
  security keys (S0/S2) — back these up, they can't be recovered.
- **Settings → MQTT** (optional): `mqtt://<mqtt-host>:1883`.
- **Settings → Home Assistant**: enable the WS server on port **3000**, then
  point the HA Z-Wave JS integration at `ws://<ip>:3000`.

## Step 5 — Persistence + backups

The store lives on a bind mount (`mp1: /var/lib/zwave-store`). The critical file
is the network + security-key store — back it up to `/mnt/backups`:

```bash
tar czf /mnt/backups/zwave_$(date +%Y%m%d).tar.gz -C /var/lib/zwave-store .
```

Losing the security keys means re-pairing every device, so keep these backups.

## Troubleshooting

**`/dev/ttyACM0` missing in the CT** — on the host: `grep -i mount
/etc/pve/lxc/<CTID>.conf`; confirm the device exists (`ls -l /dev/ttyACM0` or the
by-id path). The `optional` flag silently skips a missing device.

**Controller busy / won't open** — only one process may hold the port; ensure no
other Z-Wave stack (old zwavejs2mqtt, HA add-on) has it open.

**HA can't connect** — verify the WS server is listening: `ss -tlnp | grep 3000`.
