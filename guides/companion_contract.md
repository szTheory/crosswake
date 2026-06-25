# Companion Contract

> **Reference** — This guide enumerates the stable public surface
> that companion packages may depend on. For implementing a companion,
> see [Companion Integrations](companions.md). For declaring compatibility
> ranges, see [Companion Compatibility Contract](compatibility.md#companion-compatibility-contract).

## Contract Surface

The following five modules are the public companion contract surface,
semver-stable under `crosswake` >= 0.1.0.

| Module | Role | What companion code does with it | Stability tier |
|---|---|---|---|
| `Crosswake.Companion` | Behaviour | Declare `@behaviour Crosswake.Companion` and implement all 6 callbacks | Public stable |
| `Crosswake.Companion.State` | Return type | Return from `report_state/0` | Public stable |
| `Crosswake.Compatibility.Finding` | Return type | Return `{:deny, %Finding{}}` from `route_gated?/2` | Public stable |
| `Crosswake.Compatibility.Target` | Input type | Receive as argument in `route_gated?/2` and `kill_switch_active?/1` | Public stable |
| `Crosswake.Manifest.Types.RouteEntry` | Input type | Receive as argument in `route_gated?/2` | Public stable |

## Stability Tiers

- **Public stable** — semver-protected under `crosswake` >= 0.1.0. No breaking changes to struct fields, types, or callbacks without a major version bump.
- **Private** — `@moduledoc false`. Not part of any public API. May change without notice.

## What Is Not Contract

Any module carrying `@moduledoc false` is internal to Crosswake core and
must not be aliased or pattern-matched in companion code. Specifically:

- `Crosswake.Shell.Denial` — core-owned envelope. Companions return
  `{:deny, Finding.t()}` from `route_gated?/2`; core translates findings
  into `Denial` structs internally. **Companions must never construct or
  reference `Denial` directly**, including `Denial.reasons/0` — that
  function is for core operators, not companion authors. Emit your own
  denial-code strings via `Finding.t()`.
- All other `Crosswake.Manifest.Types.*` nested modules (`Root`, `Host`,
  `Crosswake.Manifest.Types.Compatibility`, `Capability`, etc.) — internal.
- Eval machinery: `Crosswake.Compatibility` (the parent module), its
  internal functions and private helpers.

## Declaring Compatibility

Companion packages declare the `crosswake` version range they are compatible
with. See [Companion Compatibility Contract](compatibility.md#companion-compatibility-contract)
for the required format.

## Telemetry Events

Crosswake emits the following static companion span event names that
companion implementations may observe (source of truth: `Crosswake.Companion`
moduledoc):

- `[:crosswake, :companion, :validate_dependency, :start | :stop | :exception]`
- `[:crosswake, :companion, :route_gate, :start | :stop | :exception]`
- `[:crosswake, :companion, :kill_switch, :start | :stop | :exception]`

All events carry `%{companion_id: atom(), route_id: binary() | nil}` metadata.
