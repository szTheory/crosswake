# Phase 121: Canonical Contract Source - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Collapse bridge-protocol-version drift to one Elixir authority, generate all derived non-Elixir surfaces via `mix crosswake.contract.gen`, resolve the `1.1.0` vs `1.0.0` divergence to the one correct current value, and remove the silent Kotlin `?: "1.0.0"` native-runtime fallback so native fails closed.

Covers requirements **CANON-01 through CANON-05**. This is coherence work — no new bridge commands, no envelope restructuring, no IDL/protobuf redesign, no breaking the published `crosswake 0.1.x` adopter contract.

**Not in this phase:** native `>=` floor reconciliation (Phase 124 / COMPAT-01), drift guards / generate-and-diff CI / doctor parity check (Phase 122), wiring vectors into Swift/Kotlin test suites (Phase 123), public docs/guide/support-matrix updates (Phase 124). Phase 121 *produces* the canonical artifacts and gen task; later phases guard and consume them.

</domain>

<decisions>
## Implementation Decisions

### Version value resolution (CANON-04)
- **D-01:** The one correct current bridge protocol version is **`1.1.0`**. The stale `1.0.0` copies in `Manifest.Types` and JSON fixtures are snapped **up** to `1.1.0` — not the reverse. Rationale: the `1.1.0` bump (commit `4ccc646`, "bump @version to 1.1.0 … additive-minor, no breaking change") was a real additive Threadline change (`thread_id` added to all four envelope structs). `Crosswake.Bridge.Contract` is already authoritative at `1.1.0`; the manifest/fixture `1.0.0` literals are simply stale and were never updated. Rolling Contract back to `1.0.0` would be a false version statement and is rejected.
- **D-02:** Snapping the manifest `bridge_protocol_version` to `1.1.0` is **backward-safe for existing 0.1.x adopters** and resolves a *live latent denial*. Native does exact match `request.version == session.bridgeProtocolVersion` (`BridgeChannel.swift:182`). Today Elixir already sends `1.1.0` while the manifest reports `1.0.0` → exact-match would deny. Aligning the manifest to `1.1.0` makes both sides `1.1.0` → pass. Native shells read `bridge_protocol_version` from the manifest at runtime (not baked into the binary), so both sides move together. **Therefore Phase 121 does NOT depend on Phase 124's `>=` change landing first** to be safe.

### Per-axis values (CANON-02)
- **D-03:** The three version axes are kept explicit, each single-sourced, and they move **independently**:
  - **Bridge protocol** → `1.1.0` (the only axis with an additive change).
  - **Manifest schema** → stays `1.0.0` (no schema change).
  - **Native runtime** → stays `1.0.0` (no binary change).
  - They are NOT locked together; only the axis that actually changed moves.

### Canonical module shape (CANON-01)
- **D-04:** No new top-level module. `Crosswake.Bridge.Contract` remains the **bridge-protocol authority** (`@version` / `version()`). `Crosswake.Manifest.Types` drops its `@bridge_protocol_version` literal and references `Crosswake.Bridge.Contract.version()` at **compile time** (no second hand-maintained literal). The manifest-schema and native-runtime axes keep their own single named constants in `Manifest.Types` (they are manifest concerns, not bridge concerns). Outcome: three named constants, three homes, zero duplicates. `grep -rn '"bridge_protocol_version"'` resolves to a single value everywhere.

### Gen artifact boundary (CANON-03)
- **D-05:** **Elixir surfaces derive at compile time** — `lib/crosswake/shell/fixtures.ex` and `Manifest.Types` reference the canonical constant directly; they are NOT codegen targets and cannot drift.
- **D-06:** `mix crosswake.contract.gen` emits **only the non-Elixir surfaces**: the iOS/Android `route_activation.json` fixtures, generated shell templates, and the docs snippet. Each generated file carries a DO-NOT-EDIT header. The task is hermetic and network-free. (The generate-and-diff CI guard that enforces freshness is Phase 122, not here — but the task and committed outputs must exist now.)
- **D-07:** `bridge_contract_vectors.json` **is emitted by `mix crosswake.contract.gen` in Phase 121** (user decision: "Emit vectors now"). The canonical JSON + gen task both exist and are part of the canonical artifact set from the start. **Phase 123 owns wiring it into the Swift/Kotlin/Elixir test suites** — Phase 121 produces it, Phase 123 consumes it.

### Kotlin fallback removal (CANON-05)
- **D-08:** Remove the silent `?: "1.0.0"` native-runtime fallback at `ActivationCoordinator.kt:594` so native always reads the manifest-provided value and **fails closed** if absent. (Locked by research; not a gray area — listed here for completeness so the planner does not skip it.)

### Claude's Discretion
- Exact home/name of any internal helper that reads the canonical constant for the gen task, the precise on-disk path/name of the canonical artifact the gen task reads from (e.g. a `priv/` JSON), and the exact DO-NOT-EDIT header wording are planner/researcher discretion, provided D-01..D-08 hold.
- Whether the gen task writes a single intermediate canonical JSON or reads the Elixir constants directly is discretion, as long as the output is hermetic and the Elixir constant remains the authority.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone planning
- `.planning/ROADMAP.md` — Phase 121 goal, success criteria 1–5, and milestone phase ordering (canonical → guards → native-proof → compat/docs → publish-last).
- `.planning/REQUIREMENTS.md` — CANON-01..05 definitions, anti-scope table, phase-ordering non-negotiable note.
- `.planning/research/SUMMARY.md` — convergent design (Elixir authority + gen + diff; resolve the version value; kill Kotlin fallback). §"Convergent Recommendation" item 1.
- `.planning/research/PITFALLS.md` — drift-guard failure-message contract, vacuous/fabricated-proof anti-patterns (informs gen + later guards).
- `.planning/research/ARCHITECTURE.md`, `.planning/research/STACK.md`, `.planning/research/NATIVE-TESTING.md` — codegen-and-diff discipline precedents, three-axis model, native test seam inventory.

### Code to change (Elixir authority)
- `lib/crosswake/bridge/contract.ex` §`@version "1.1.0"` (line 10), `version/0` (line 105) — the canonical bridge-protocol authority.
- `lib/crosswake/manifest/types.ex` §lines 651–653 (`@manifest_schema_version`, `@bridge_protocol_version`, `@native_runtime_version`) — drop the bridge-protocol literal; reference `Contract.version()` at compile time; keep schema + native-runtime constants.
- `lib/crosswake/shell/fixtures.ex` §lines ~82–83 — replace hardcoded `1.0.0` with compile-time reference to the canonical constant.

### Code to change (native / generated surfaces)
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt:594` — remove `?: "1.0.0"` fallback; fail closed.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:182` — exact-match comparison (`request.version == session.bridgeProtocolVersion`); NOT changed here (Phase 124 owns `>=`), but understand it to verify D-02 backward-safety.
- `examples/ios_shell_host/Fixtures/route_activation.json`, `examples/android_shell_host/app/src/main/assets/route_activation.json` — JSON fixtures that become gen targets (the `build/` copies are build artifacts, ignore).

### Existing patterns to mirror
- `lib/mix/tasks/crosswake.gen.shell.ex` — closest existing generator task; mirror its structure for `crosswake.contract.gen`.
- `lib/crosswake/doctor/publish_readiness.ex` §`generator_coordinate_parity` — sibling parity-check precedent (Phase 122 adds `contract_version_parity` here; informs the canonical-source shape now).
- `lib/crosswake/compatibility/compatibility.ex:616` `compatible_version?/2` — the existing `>=` floor negotiation Elixir already uses (the semantics native will adopt in Phase 124).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Bridge.Contract.version/0` — already the de-facto authority at `1.1.0`; becomes THE single source other surfaces reference.
- `lib/mix/tasks/crosswake.gen.shell.ex` and the `crosswake.gen.*` task family — established hermetic generator pattern to mirror for `crosswake.contract.gen`.
- `generator_coordinate_parity` check in `publish_readiness.ex` — the parity-check idiom to reuse for the canonical-source story.

### Established Patterns
- **Generate-and-commit-and-diff discipline** already exists in the repo (brand tokens, generator coordinates) — `mix crosswake.contract.gen` is "zero new mental model," not a new pipeline.
- **Three explicit version axes** (`manifest_schema` / `bridge_protocol` / `native_runtime`) are already modeled in `Manifest.Types`; this phase de-duplicates their sources, it does not introduce the axis model.

### Integration Points
- `Manifest.Types` → compile-time reference to `Bridge.Contract.version()` (new coupling, Elixir-internal).
- `mix crosswake.contract.gen` → writes iOS/Android `route_activation.json`, shell templates, docs snippet, and `bridge_contract_vectors.json` (new task).
- The live native exact-match denial (`BridgeChannel.swift:182`) is *resolved as a side effect* of aligning the manifest to `1.1.0` — verify in planning that no checked-in example or proof lane was relying on the `1.0.0` mismatch.

</code_context>

<specifics>
## Specific Ideas

- The `1.1.0` value is anchored to a real commit (`4ccc646`, Threadline `thread_id` additive-minor change) — treat `1.1.0` as the factual current protocol version, not an arbitrary pick.
- Backward-safety argument is concrete: native reads `bridge_protocol_version` from the manifest at runtime (not baked), so aligning the manifest moves both sides of the exact-match together.

</specifics>

<deferred>
## Deferred Ideas

- **Native `>=` min-version-floor reconciliation** (`BridgeChannel.swift:182`, `BridgeChannel.kt:101` exact-match → floor) — Phase 124 / COMPAT-01. Phase 121's value alignment makes exact-match harmless in the meantime.
- **Drift guards** (single-reader ExUnit test, generate-and-diff CI, `contract_version_parity` doctor check, aggregator/branch-protection registration) — Phase 122.
- **Wiring `bridge_contract_vectors.json` into Swift/Kotlin/Elixir test suites** + the six native behaviors — Phase 123.
- **Public docs / compatibility guide / support-matrix / changelog upgrade-impact labels** — Phase 124.

None of these are scope creep into 121 — they are the explicitly-ordered later phases.

</deferred>

---

*Phase: 121-canonical-contract-source*
*Context gathered: 2026-06-20*
