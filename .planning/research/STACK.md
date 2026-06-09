# Technology Stack: v7.0 Threadline Audit Capstone

**Project:** Crosswake (v7.0 Threadline Audit Capstone)
**Researched:** 2026-06-09 · **Confidence:** HIGH (codebase-grounded)

## Headline: this milestone adds NO new runtime dependencies

Threadline is a capability built from primitives already present in the stack. The honest, house-style
move is to add a feature, not a dependency graph.

| Need | Use | Already present? | New dep? |
|---|---|---|---|
| Server thread-id generation | `Ecto.UUID.generate/0` | Yes (Phoenix/Ecto) | No |
| iOS thread-id generation | `UUID().uuidString` | Swift stdlib | No |
| Android thread-id generation | `UUID.randomUUID().toString()` | Kotlin/Java stdlib | No |
| Boundary instrumentation | `:telemetry.span/3` + `:telemetry.execute/3` | Yes (already used in route_gate, Sigra, Chimeway) | No |
| Console correlation | `Logger.metadata/1` | Yes (stdlib; lib currently unused — first metadata touchpoint) | No |
| Plug interception | `Plug.Conn` | Yes (Phoenix) | No |
| LiveView WS context | `Phoenix.LiveView.get_connect_params/1` + `on_mount` | Yes | No |
| Ledger persistence | host-side `Ecto` + generated schema/migration | Host app owns Ecto (Crosswake does not declare it) | No (host dep) |
| Ledger PK | `:binary_id` | Yes (matches v6.0 demo decision) | No |
| Opaque actor ref | `:crypto.mac(:hmac, :sha256, …)` | OTP stdlib (pattern already in `Chimeway.Redaction`) | No |
| Row hash (advisory) | `:crypto.hash(:sha256, …)` | OTP stdlib | No |

## Explicitly NOT added (and why)

- **`opentelemetry` / `opentelemetry_phoenix`** — Threadline is a thin correlation layer, not a tracer.
  Taking an OTel dep would force an observability lifecycle on every adopter and overclaim scope. Instead:
  document **coexistence** — a host already running OTel sees `thread_id` in Logger/telemetry metadata and
  can map it to a span attribute with a one-line `telemetry.attach/4`. Zero coupling.
- **`phoenix_live_dashboard` (in core)** — the operator timeline UI is deferred to a future, separately-
  packaged `crosswake_dashboard`. Prior art (Oban → `oban_web`) confirms interactive operator UIs belong in
  their own package, not the core lib, so the dep is never forced on CI-only adopters.
- **`uniq` / any ULID or UUIDv7 library** — propagation IDs only need uniqueness, not time-sortability.
  `:binary_id` covers the ledger PK; UUIDv4 covers propagation. No new dep earns its keep here.
- **`paper_trail` / `ex_audit` / `carbonite`** — these audit *row mutations*, not cross-boundary *business
  events*, and they couple to the host Repo. Threadline scaffolds a host-owned event ledger instead.

## Stack interaction notes

- The Plug is the library's **first** entry into the host Plug pipeline. Today the installer only patches
  `import Crosswake.Router` (`lib/crosswake/install/patcher.ex`); a new marker-driven plug-injection mode is
  needed (or documented manual `plug Crosswake.Plug.Threadline`). Keep it additive and idempotent.
- Telemetry namespace continues the existing convention: `[:crosswake, :threadline, …]`.
- The ledger is opt-in: no Ecto means Threadline still works in ephemeral (telemetry/log) mode.
