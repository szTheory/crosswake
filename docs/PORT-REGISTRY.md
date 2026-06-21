# Port Registry

This file is the port allocation convention for the maintainer's OSS library demos.
It is a reusable pattern: other repos in the same portfolio can adopt the same
reserved block and allocation rule to avoid demo-port collisions when running
multiple libs concurrently.

## Reserved Block

Ports **4700 through 4799** are reserved for the maintainer's OSS library demos.

Each lib gets exactly one port in this block. The committed `PORT=` value in the
lib's `.env` is the real collision guard — two libs are collision-safe as long as
their committed `PORT=` values differ, regardless of any container naming scheme.

## Excluded Ports

These ports are off-limits for demo allocation because they collide with common
dev tools or well-known services:

| Port | Conflict |
|------|----------|
| 3000 | React / Next.js default |
| 4000 | Phoenix framework default |
| 4002 | Old crosswake demo default (retired; do not re-use) |
| 5000 | macOS AirPlay Receiver |
| 5173 | Vite dev server default |
| 8080 | Generic HTTP proxy / alt-HTTP default |
| 49152+ | IANA ephemeral range (OS-assigned; never bind a service here) |

## Allocation Rule

1. Pick the next free port in the **4700–4799** block (scan the table below).
2. One port per lib — the port stays fixed for the life of the lib's demo.
3. Commit `PORT=<your-port>` and `COMPOSE_PROJECT_NAME=<your-lib>` in the lib's
   `examples/<host>/.env`.
4. Add a row to the registry table below.

### COMPOSE_PROJECT_NAME caveat

`COMPOSE_PROJECT_NAME` namespaces container **names**, network names, and volume
names — it does **NOT** affect host port bindings. Two concurrent `docker compose`
stacks with different `COMPOSE_PROJECT_NAME` values can still collide on host
ports if they both bind the same port number.

The committed `PORT=` value is the real collision guard. Always pick a unique port
before setting `COMPOSE_PROJECT_NAME`.

### Android emulator note

The Android emulator runs inside a virtualized network. The emulator reaches the
**host machine** at `10.0.2.2` (not `localhost` or `127.0.0.1`). When documenting
backend URLs for Android, always use `10.0.2.2:<port>` in place of
`localhost:<port>`.

## Port Registry Table

| Library | Port | COMPOSE_PROJECT_NAME | Host Path |
|---------|------|----------------------|-----------|
| crosswake | 4700 | crosswake | examples/phoenix_host |

To claim the next port: pick `4701` (next free), add a row above, follow the
allocation rule, and open a PR. The registry row is the allocation record.
