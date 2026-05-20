# Phase 04: Honest Offline Contract - Pattern Map

**Mapped:** 2026-05-16
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/policy/schema.ex` | config | validate | `lib/crosswake/policy/schema.ex` | exact |
| `lib/crosswake/policy/route.ex` | model | normalize | `lib/crosswake/policy/route.ex` | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact |
| `lib/crosswake/manifest/builder.ex` | service | transform | `lib/crosswake/manifest/builder.ex` | exact |
| `lib/crosswake/offline/contracts.ex` | model | transform | `lib/crosswake/manifest/types.ex` | role-match |
| `lib/crosswake/offline/journal.ex` | model | request-response | `lib/crosswake/bridge/contract.ex` | role-match |
| `lib/crosswake/offline/replay.ex` | service | request-response | `lib/crosswake/shell/activation.ex` | role-match |
| `lib/crosswake/offline/status.ex` | model | transform | `lib/crosswake/shell/denial.ex` | role-match |
| `lib/crosswake/doctor/doctor.ex` | service | request-response | `lib/crosswake/doctor/doctor.ex` | exact |
| `lib/crosswake/doctor/formatter.ex` | formatter | transform | `lib/crosswake/doctor/formatter.ex` | exact |
| `lib/crosswake/doctor/json_formatter.ex` | formatter | transform | `lib/crosswake/doctor/json_formatter.ex` | exact |
| `guides/offline.md` | docs | file-I/O | `guides/native_shell.md` | role-match |
| `test/crosswake/offline/*` | test | request-response | `test/crosswake/bridge/*` | role-match |
| `test/mix/tasks/crosswake_doctor_test.exs` | test | request-response | `test/mix/tasks/crosswake_doctor_test.exs` | exact |

## Pattern Assignments

### `lib/crosswake/policy/schema.ex` (config, validate)

**Analog:** `lib/crosswake/policy/schema.ex`

Use the existing NimbleOptions pattern: tight enums or custom validators, additive fields, and small explicit type specs. Phase 4 should add contract references or identifiers here rather than exploding the `offline` enum into many semantic submodes.

### `lib/crosswake/policy/route.ex` (model, normalize)

**Analog:** `lib/crosswake/policy/route.ex`

The route model is already a normalized `%Route{}` built from `Defaults.route() |> Keyword.merge(options) |> Schema.validate()`. Additive Phase 4 fields should be normalized here and stay route-local.

### `lib/crosswake/manifest/types.ex` (model, transform)

**Analog:** `lib/crosswake/manifest/types.ex`

This is the strongest exact pattern in the repo:

- nested modules
- `@enforce_keys`
- typed `defstruct`
- `new_*` constructors
- one `to_map/1` boundary

Any offline contract types should follow this exactly.

### `lib/crosswake/manifest/builder.ex` (service, transform)

**Analog:** `lib/crosswake/manifest/builder.ex`

Builder logic currently stays simple: derive top-level capability registry, map routes with normalized fields, and assemble one canonical typed root. Phase 4 additions should preserve this shape by compiling offline contract references and payloads into route entries rather than inventing a second builder pipeline.

### `lib/crosswake/offline/contracts.ex` (model, transform)

**Analog:** `lib/crosswake/manifest/types.ex`

Recommended shape:

- `CacheContract`
- `IslandContract`
- `ReplayContract`
- `TelemetryContract`

Keep them as typed structs with small explicit constructors. This fits the repo’s contract-first style and avoids slipping into service-heavy logic before the public contract is stable.

### `lib/crosswake/offline/journal.ex` (model, request-response)

**Analog:** `lib/crosswake/bridge/contract.ex`

`Crosswake.Bridge.Contract` already models versioned request/reply envelopes with correlation ids and typed `to_map/1` output. Journal entries and replay requests or results should use the same explicit-envelope posture:

- immutable fields
- explicit ids
- explicit statuses
- machine-readable `to_map/1`

### `lib/crosswake/offline/replay.ex` (service, request-response)

**Analog:** `lib/crosswake/shell/activation.ex`

`Crosswake.Shell.Activation` is a good service-level analog because it turns a typed request into a typed allow/deny decision. Replay should do the same:

- input: typed replay request
- output: typed replay outcome
- no hidden side effects in the contract layer

### `lib/crosswake/offline/status.ex` (model, transform)

**Analog:** `lib/crosswake/shell/denial.ex`

Route-local offline states should behave like a stable product vocabulary, similar to denial reasons:

- small enum-like reason/status set
- optional hint and details
- user-facing stability
- machine-readable structure

### `lib/crosswake/doctor/doctor.ex` (service, request-response)

**Analog:** `lib/crosswake/doctor/doctor.ex`

Doctor already follows the right pattern:

- compile truth
- inspect artifact posture
- emit structured findings
- aggregate product status

Phase 4 should extend the current report structure with `offline` posture rather than bolting on a separate diagnostics entrypoint.

### `lib/crosswake/doctor/formatter.ex` and `json_formatter.ex` (formatter, transform)

**Analog:** exact

Both formatters already render stable summary sections before findings. Add one offline posture section with:

- cached-route support summary
- island-contract support summary
- replay/telemetry support summary
- structured lists for offline states or missing checks

### `guides/offline.md` (docs, file-I/O)

**Analog:** `guides/native_shell.md`

Follow the existing Crosswake guide posture:

- explicit boundaries
- public non-goals
- proof-oriented support language
- calm adopter-facing phrasing

The offline guide should explain one study/session exemplar plus one cached neighboring route, not generic offline strategy for all app classes.

### `test` surfaces

**Policy tests:** mirror `test/crosswake/policy/schema_test.exs` and `test/crosswake/policy/route_test.exs`

**Manifest tests:** mirror `test/crosswake/manifest/manifest_test.exs`

**Doctor tests:** mirror `test/crosswake/doctor/doctor_test.exs` and `test/mix/tasks/crosswake_doctor_test.exs`

**Offline tests:** new `test/crosswake/offline/*` should mirror the bridge/shell pattern of asserting typed requests, typed outcomes, and stable map rendering.

## Key Practical Guidance For The Planner

1. Put Phase 4 public truth into route and manifest contracts first.
2. Keep new offline modules typed and serializable before adding operational logic.
3. Reuse `doctor` as the primary operator/developer surface.
4. Reuse guides as contract documentation, not as speculative architecture essays.
5. Keep the study/session exemplar wired through fixtures and tests so support claims stay narrow.

## Anti-Patterns To Avoid

- Adding a second offline config file outside route policy.
- Encoding every offline behavior directly into the `offline` enum.
- Making replay semantics implicit through `sync` strings alone.
- Emitting verbose low-level telemetry without stable route-level outcome vocabulary.
- Writing broad “Crosswake solves offline” guidance instead of route-class-specific support truth.

## Confirmation

Wrote the Phase 4 pattern map with route, manifest, offline-contract, doctor, docs, and test analogs.

Files analyzed:
- `.planning/phases/04-honest-offline-contract/04-CONTEXT.md`
- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/policy/route.ex`
- `lib/crosswake/manifest/types.ex`
- `lib/crosswake/manifest/builder.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/check.ex`
- `lib/crosswake/doctor/formatter.ex`
- `lib/crosswake/doctor/json_formatter.ex`
- `lib/crosswake/bridge/contract.ex`
- `lib/crosswake/shell/activation.ex`
- `test/crosswake/manifest/manifest_test.exs`
- `test/crosswake/doctor/doctor_test.exs`
- `test/support/router_fixtures.ex`
