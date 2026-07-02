<p align="center">
  <img src="assets/icon-256.png" width="120" alt="zwave-js-ui" />
</p>

# zwave-js-ui

Z-Wave JS UI is a full-featured Z-Wave control panel and MQTT gateway.

A first-party [orca](https://github.com/argyle-labs/orca) plugin (service-backend).

This repo is **self-contained** — the steps below run zwave-js-ui **by hand, without orca**. orca automates exactly this (same image, ports, and data) through one generic surface.

---

## Run it without orca

### Docker Compose

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

### Other runtimes

**Podman** — the compose above works with `podman compose up -d`, or run it directly:

```sh
podman run -d --name zwave-js-ui --restart unless-stopped \
    -p 8091:8091/tcp \
    -p 3000:3000/tcp \
    -v ./store:/usr/src/app/store \
    zwavejs/zwave-js-ui:latest
```

**LXC** — on a container-capable LXC (e.g. a Proxmox LXC with nesting enabled) run the same image via Docker/Podman as above, or install zwave-js-ui from upstream directly on the guest: <https://github.com/zwave-js/zwave-js-ui>.

**VM** — install zwave-js-ui from upstream (<https://github.com/zwave-js/zwave-js-ui>) or run the same container image inside the VM; expose port `8091`.

**Unraid** — add via *Community Applications*, or *Docker → Add Container* with image `zwavejs/zwave-js-ui:latest`, port `8091`, and the volume paths above.

### Dependencies

Requires a Z-Wave controller (USB stick) passed through to the container; MQTT is optional.

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
