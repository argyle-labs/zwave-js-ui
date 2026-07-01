<p align="center">
  <img src="assets/icon-256.png" width="120" alt="zwave-js-ui" />
</p>

# zwave-js-ui

Z-Wave JS UI is a full-featured Z-Wave control panel and MQTT gateway.

A first-party [orca](https://github.com/argyle-labs/orca) plugin (service-backend).

This repo is **self-contained** — the steps below run zwave-js-ui **by hand, without orca**. orca automates exactly this (same image, ports, and data) through one generic surface.

---

## Run it without orca

### Docker / Podman

```yaml
# compose.yml
services:
  zwave-js-ui:
    image: zwavejs/zwave-js-ui:latest
    container_name: zwave-js-ui
    restart: unless-stopped
    ports:
      - "8091:8091/tcp"   # web UI
      - "3000:3000/tcp"   # Z-Wave JS websocket
    volumes:
      - ./store:/usr/src/app/store   # (also map your Z-Wave USB stick via devices:)
```

```sh
docker compose up -d
```

Podman: the same file with `podman-compose up -d`.

### Ports & data

| | |
|---|---|
| Default port | `8091` |
| Upstream | <https://github.com/zwave-js/zwave-js-ui> |
| Operator notes | [zwave-js-ui.md](docs/zwave-js-ui.md) |


### Backup & restore

Back up the config/data volume(s) above — that's the whole service state (stop the container first for a clean copy). Restore by putting them back and starting it.

> With orca this is **`service.backup` / `service.restore`** — location-agnostic (docker / podman / lxc / vm), one command regardless of where zwave-js-ui runs. No per-service backup script.

## With orca

orca drives this plugin through the single generic `service.*` surface — no per-plugin tools:

```sh
orca service.deploy zwave-js-ui      # render + launch on any supported runtime
orca service.status zwave-js-ui      # health + rich diagnostics (typed payload)
orca service.backup zwave-js-ui      # location-agnostic backup (tar; PBS on Proxmox)
orca service.configure zwave-js-ui   # apply config via the upstream API
```

## Layout

- `src/` — the plugin (pure Rust): the `ServiceBackend` descriptor + `configure` / `status`.
- `docs/` — standalone operator notes.
- [CAPABILITIES.md](CAPABILITIES.md) — the service-backend contract checklist.
- `assets/` — plugin icon.
