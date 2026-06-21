# Phase 121: Canonical Contract Source - Research

**Researched:** 2026-06-20
**Domain:** Elixir compile-time module attributes, Mix codegen tasks, cross-language JSON fixture generation, Kotlin/Swift native package surgery
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** The one correct current bridge protocol version is `1.1.0`. Stale `1.0.0` copies snap **up** to `1.1.0`.

**D-02:** Snapping manifest `bridge_protocol_version` to `1.1.0` is backward-safe and resolves a live latent denial. `BridgeChannel.swift:182` does exact-match `request.version == session.bridgeProtocolVersion`. Today Elixir sends `1.1.0` but the manifest reports `1.0.0` — so aligning the manifest makes both sides `1.1.0` and the exact-match passes. Native reads `bridge_protocol_version` from the manifest at runtime (not baked), so both sides move together. Phase 121 does NOT depend on Phase 124's `>=` change landing first.

**D-03:** Three version axes kept explicit, each single-sourced, moving independently:
- **Bridge protocol** → `1.1.0` (the only axis with an additive change)
- **Manifest schema** → stays `1.0.0` (no schema change)
- **Native runtime** → stays `1.0.0` (no binary change)

**D-04:** No new top-level module. `Crosswake.Bridge.Contract` remains the bridge-protocol authority (`@version` / `version()`). `Manifest.Types` drops its `@bridge_protocol_version "1.0.0"` literal and references `Crosswake.Bridge.Contract.version()` at **compile time**. Manifest-schema and native-runtime constants stay in `Manifest.Types` (manifest concerns, not bridge concerns). Outcome: three named constants, three homes, zero duplicates.

**D-05:** Elixir surfaces derive at compile time — `lib/crosswake/shell/fixtures.ex` and `Manifest.Types` reference the canonical constant directly; they are NOT codegen targets.

**D-06:** `mix crosswake.contract.gen` emits **only the non-Elixir surfaces**: iOS/Android `route_activation.json` fixtures, generated shell templates, docs snippet. Each generated file carries a DO-NOT-EDIT header. Task is hermetic and network-free.

**D-07:** `bridge_contract_vectors.json` is emitted by `mix crosswake.contract.gen` in Phase 121. Phase 123 consumes it, Phase 121 produces it.

**D-08:** Remove the silent `?: "1.0.0"` native-runtime fallback at `ActivationCoordinator.kt:594`.

### Claude's Discretion

- Exact home/name of any internal helper that reads the canonical constant for the gen task
- Precise on-disk path/name of any canonical artifact the gen task reads from (e.g., a `priv/` JSON)
- Exact DO-NOT-EDIT header wording
- Whether the gen task writes a single intermediate canonical JSON or reads the Elixir constants directly (as long as hermetic and Elixir constant remains the authority)

### Deferred Ideas (OUT OF SCOPE)

- Native `>=` floor reconciliation (`BridgeChannel.swift:182`, `BridgeChannel.kt:101`) — Phase 124
- Drift guards (ExUnit test, generate-and-diff CI, doctor check, aggregator registration) — Phase 122
- Wiring `bridge_contract_vectors.json` into Swift/Kotlin/Elixir test suites — Phase 123
- Public docs / compatibility guide / support-matrix / changelog — Phase 124
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CANON-01 | Single canonical Elixir source for bridge protocol version; `Contract`, `Manifest.Types`, and shell fixtures all derive from it | D-04 locked; compile-time module-attribute reference feasible (see §Circular Dependency Analysis) |
| CANON-02 | Each of the three version axes has exactly one named authoritative source, no second hand-maintained copy | D-03 locked; surgical edit inventory pinned with line numbers |
| CANON-03 | `mix crosswake.contract.gen` task renders canonical contract into all derived non-Elixir surfaces | Task shape fully specified; gen.shell pattern confirmed as the mirror |
| CANON-04 | `1.1.0` vs `1.0.0` divergence resolved to one correct current value without breaking 0.1.x adopters | D-01/D-02 locked; backward-safety confirmed; every downstream literal enumerated |
| CANON-05 | Silent Kotlin `?: "1.0.0"` fallback removed — native always reads manifest-provided value | Exact file+line pinned; removal approach specified |
</phase_requirements>

---

## Summary

Phase 121 is a surgical coherence fix: three Elixir module attributes, two native files, two JSON fixtures, and a test fixture all carry stale `1.0.0` where `1.1.0` is correct for the bridge protocol axis. The fix has five parts: (1) update the `@bridge_protocol_version` attribute in `Manifest.Types` to reference `Crosswake.Bridge.Contract.version()` at compile time; (2) update two hardcoded strings in `Shell.Fixtures.activation_request/1`; (3) ship a new `mix crosswake.contract.gen` task that writes the iOS/Android JSON fixtures, docs snippet, and `bridge_contract_vectors.json` from the canonical constant; (4) regenerate and commit those outputs with correct values; (5) remove the `?: "1.0.0"` Kotlin fallback.

The circular-dependency question is the key structural constraint: `Crosswake.Bridge.Contract` already `alias`es `Crosswake.Manifest.Types` (line 7 of contract.ex). Therefore `Manifest.Types` cannot `alias Crosswake.Bridge.Contract` — that would create a compile-order cycle. The correct approach (verified against Elixir compiler semantics) is for `Manifest.Types` to call `Crosswake.Bridge.Contract.version()` as a fully-qualified function call in the module-attribute assignment, which resolves at compile time without an `alias` declaration and without creating a cycle. The same approach applies in `Shell.Fixtures`.

The gen task reads `Crosswake.Bridge.Contract.version()` directly (Mechanism 3 from STACK.md), not via a `priv/contract/runtime_contract.json` intermediate file (Mechanism 2). This is the simpler choice for Phase 121 because: the D-04 decision locks `Bridge.Contract` as the Elixir authority; introducing a JSON intermediary would add a file that Phase 122's drift guard must track; and the `crosswake.gen.shell` precedent already calls `Application.spec(:crosswake, :vsn)` at task run time for the same purpose. The gen task calls `Mix.Task.run("app.start")` or passes `--no-start` to `Mix.Task.run("compile")` to ensure the `Bridge.Contract` module is loaded before introspection.

**Primary recommendation:** One compile-time function call in `Manifest.Types` (replacing `@bridge_protocol_version "1.0.0"` with a call to `Crosswake.Bridge.Contract.version()`), two hardcoded string replacements in `Shell.Fixtures`, one new Mix task (`crosswake.contract.gen`) that reads from the canonical constant and emits four artifacts, and one Kotlin line removal. The whole phase is surgical — no new modules, no new architecture, no new dependencies.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bridge protocol version authority | Elixir library (`Bridge.Contract`) | — | Module attribute is compile-time constant; all surfaces derive from it |
| Manifest version defaults | Elixir library (`Manifest.Types`) | — | These are manifest concerns; `@manifest_schema_version` and `@native_runtime_version` stay here; `@bridge_protocol_version` becomes a derived reference |
| Shell activation fixture content | Elixir library (`Shell.Fixtures`) | — | `activation_request/1` must reference the canonical constant, not a literal |
| Non-Elixir artifact generation | Mix task (`crosswake.contract.gen`) | — | Hermetic codegen pattern mirrors `crosswake.gen.shell`; no runtime server needed |
| Example host fixture files | Generated artifact (committed) | Git (source-controlled) | `route_activation.json` in iOS/Android example hosts are output, not maintained by hand |
| Native fallback removal | Kotlin source (`ActivationCoordinator.kt`) | — | One-line deletion; no replacement constant needed in Phase 121 |
| Conformance vector schema | Gen task output | `test/fixtures/` | `bridge_contract_vectors.json` is emitted by gen task; Phase 123 wires it into test suites |

---

## Standard Stack

### Core — No New Dependencies

Phase 121 adds no new Hex dependencies. All work uses built-in Elixir/Mix facilities.

| Tool | Version | Purpose | Source |
|------|---------|---------|--------|
| Elixir compiler | Already in `.tool-versions` | Compile-time module attribute resolution | [ASSUMED] — already installed |
| `Jason` | Already in `mix.exs` | JSON encoding for gen task output | [ASSUMED] — already in deps |
| `Mix.Task` | Elixir stdlib | Task infrastructure for `crosswake.contract.gen` | [ASSUMED] |

### Supporting — Existing Patterns to Mirror

| File | Pattern | Purpose |
|------|---------|---------|
| `lib/mix/tasks/crosswake.gen.shell.ex` | `fetch_version!/0` calls `Application.spec(:crosswake, :vsn)` at run time | Gen task reads live Elixir value, not a static file |
| `lib/crosswake/doctor/publish_readiness.ex` §`generator_coordinate_parity_check` | Reads live `Application.spec` value, checks it against template text | The `contract_version_parity` check in Phase 122 mirrors this shape |
| `lib/crosswake/compatibility/compatibility.ex:616` `compatible_version?/2` | `>=` floor negotiation already in Elixir | Phase 124 targets; awareness-only for Phase 121 |

**Installation:** None required.

---

## Package Legitimacy Audit

No new external packages are installed in Phase 121. Audit skipped — all changes use existing dependencies.

---

## Architecture Patterns

### System Architecture Diagram

```
Elixir compile time
┌─────────────────────────────────────────────────────┐
│  Bridge.Contract                                     │
│    @version "1.1.0"  ←──────── THE canonical source │
│    version/0 (line 106)                              │
└───────────┬─────────────────────────────────────────┘
            │ compile-time call (fully-qualified)
            ▼
┌───────────────────────────────────────────────────┐
│  Manifest.Types                                   │
│    @manifest_schema_version "1.0.0"  (unchanged)  │
│    @bridge_protocol_version  ←── Contract.version()│
│    @native_runtime_version "1.0.0"  (unchanged)   │
│    new_compatibility/1  (no change needed)         │
└──────────────┬────────────────────────────────────┘
               │  already called by
               ▼
┌──────────────────────────────────────────────────┐
│  Shell.Fixtures                                  │
│    activation_request/1                          │
│      bridge_protocol_version: "1.0.0"  ← CHANGE │
│      native_runtime_version:  "1.0.0"  (ok)     │
└──────────────────────────────────────────────────┘

Run time (mix crosswake.contract.gen)
┌──────────────────────────────────────────────────────┐
│  Mix.Tasks.Crosswake.Contract.Gen                    │
│    reads: Crosswake.Bridge.Contract.version()        │
│    writes:                                           │
│      examples/ios_shell_host/Fixtures/               │
│        route_activation.json  (bridge_protocol_version│
│          updated to 1.1.0; other fields preserved)   │
│      examples/android_shell_host/app/src/main/assets/│
│        route_activation.json  (same)                 │
│      test/fixtures/bridge_contract_vectors.json      │
│      docs/_contract_snippet.md  (or priv/docs/)      │
└──────────────────────────────────────────────────────┘

Native (one-line deletion)
┌──────────────────────────────────────────────────────┐
│  ActivationCoordinator.kt:594                        │
│    BEFORE: ?: "1.0.0"                               │
│    AFTER:  line removed (fail closed — no fallback)  │
└──────────────────────────────────────────────────────┘
```

### Recommended Project Structure (unchanged from current)

```
lib/
├── crosswake/
│   ├── bridge/
│   │   └── contract.ex          # THE authority — @version "1.1.0" (no change needed)
│   ├── manifest/
│   │   └── types.ex             # @bridge_protocol_version becomes Contract.version() call
│   └── shell/
│       └── fixtures.ex          # activation_request/1 updated
└── mix/
    └── tasks/
        └── crosswake.contract.gen.ex   # NEW — gen task
examples/
├── ios_shell_host/Fixtures/
│   └── route_activation.json    # REGENERATED — bridge_protocol_version → 1.1.0
└── android_shell_host/app/src/main/assets/
    └── route_activation.json    # REGENERATED — same
test/
└── fixtures/
    └── bridge_contract_vectors.json   # NEW — emitted by gen task
packages/
└── crosswake-shell-core-android/
    └── .../ActivationCoordinator.kt   # one-line deletion at line 594
```

### Pattern 1: Compile-Time Cross-Module Attribute Reference (D-04)

`Manifest.Types` already has NO `alias Crosswake.Bridge.Contract` and must not add one (cycle risk — `contract.ex` line 7 already aliases `Manifest.Types`). The safe pattern is a fully-qualified call used as a module-attribute value:

```elixir
# lib/crosswake/manifest/types.ex
# BEFORE (lines 651-653):
@manifest_schema_version "1.0.0"
@bridge_protocol_version "1.0.0"
@native_runtime_version "1.0.0"

# AFTER:
@manifest_schema_version "1.0.0"
@bridge_protocol_version Crosswake.Bridge.Contract.version()   # compile-time call, no alias
@native_runtime_version "1.0.0"
```

This works because Elixir evaluates module-attribute values at compile time. The fully-qualified module reference does not require an `alias` declaration. Elixir's compiler resolves the module and calls `version/0` during compilation of `types.ex`. No cycle exists because `contract.ex` only uses `Types` in function body code (the `to_map/1` calls at lines 185-187 and 202), not in module attributes — so there is no compile-order constraint in the direction that would create a deadlock.

**VERIFIED (code inspection):** `contract.ex` line 7: `alias Crosswake.Manifest.Types` — confirms the alias exists in `contract.ex` but NOT in `types.ex`, so the reference direction `types.ex → Contract.version()` is safe. [VERIFIED: codebase]

### Pattern 2: Shell.Fixtures Activation Request Reference

```elixir
# lib/crosswake/shell/fixtures.ex
# BEFORE (lines 82-83):
bridge_protocol_version: "1.0.0",
native_runtime_version: "1.0.0",

# AFTER:
bridge_protocol_version: Crosswake.Bridge.Contract.version(),
native_runtime_version: "1.0.0",
```

`Shell.Fixtures` imports `Manifest.Types` (alias at line 8) but does NOT import `Bridge.Contract`. Adding a fully-qualified call (no alias needed) is the correct approach to avoid bringing in the alias. Alternatively, adding `alias Crosswake.Bridge.Contract` to `fixtures.ex` is safe because `Shell.Fixtures` is not transitively aliased by `contract.ex`.

**VERIFIED (code inspection):** `fixtures.ex` lines 7-11 show existing aliases: `Manifest`, `Manifest.Types`, `Shell.Activation`, `Shell.Denial`, `SupportMatrix` — no `Bridge.Contract`. Adding the alias or using fully-qualified call is both safe. [VERIFIED: codebase]

### Pattern 3: `mix crosswake.contract.gen` Task Shape

Mirror `lib/mix/tasks/crosswake.gen.shell.ex`. Key structural points from that file:

- Uses `use Mix.Task` with `@impl Mix.Task`
- Calls `fetch_version!/0` → `Application.spec(:crosswake, :vsn) || Mix.Project.config()[:version]` to read a live runtime value
- Uses `ensure_file/2` helper for idempotent writes (reads first, skips if unchanged)
- No `DO-NOT-EDIT` header is used by `gen.shell` (it uses a host-ownership README instead)

For `crosswake.contract.gen`, a DO-NOT-EDIT header IS appropriate because these are generated artifacts, not host-owned scaffolds. Header convention: the first two lines of each generated file should be a comment declaring it generated and providing the regenerate command.

```elixir
# lib/mix/tasks/crosswake.contract.gen.ex
defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task

  @shortdoc "Regenerate non-Elixir contract artifacts from the canonical bridge protocol version"

  @moduledoc """
  Reads `Crosswake.Bridge.Contract.version()` and regenerates:
  - `examples/ios_shell_host/Fixtures/route_activation.json`
  - `examples/android_shell_host/app/src/main/assets/route_activation.json`
  - `test/fixtures/bridge_contract_vectors.json`
  - Docs snippet (location TBD in plan)

  Generated files carry a DO-NOT-EDIT header. CI verifies they are current with:
      mix crosswake.contract.gen && git diff --exit-code

  Run after any change to `Crosswake.Bridge.Contract` @version.
  """

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    bridge_vsn = Crosswake.Bridge.Contract.version()

    write_if_changed(ios_activation_path(), ios_activation_json(bridge_vsn))
    write_if_changed(android_activation_path(), android_activation_json(bridge_vsn))
    write_if_changed(vectors_path(), vectors_json(bridge_vsn))
    write_if_changed(docs_snippet_path(), docs_snippet(bridge_vsn))

    Mix.shell().info("crosswake.contract.gen complete (bridge=#{bridge_vsn})")
  end

  defp write_if_changed(path, content) do
    File.mkdir_p!(Path.dirname(path))
    case File.read(path) do
      {:ok, ^content} -> Mix.shell().info("unchanged: #{path}")
      _ ->
        File.write!(path, content)
        Mix.shell().info("wrote: #{path}")
    end
  end
  # ... path helpers and content builders below ...
end
```

**Key design decision for Phase 121:** The gen task reads `Crosswake.Bridge.Contract.version()` directly (not from a `priv/` JSON intermediate). Rationale: (a) D-04 locks `Bridge.Contract` as the Elixir authority; (b) a `priv/contract/runtime_contract.json` would add a new artifact that Phase 122's drift guard must track and Phase 121 is scope-fenced to producing artifacts, not creating new sources; (c) `gen.shell` already establishes the `Application.spec` pattern for reading live values at task runtime. The `Mix.Task.run("app.start")` call ensures the module is loaded — this is the established Mix task pattern and not a risk in the project root context.

### Pattern 4: Generated JSON Fixture Content

The existing `route_activation.json` fixtures (both iOS and Android) have identical structure. The gen task must preserve all fields and update only `bridge_protocol_version`. Current content (confirmed by file read):

```json
{
  "bridge_protocol_version": "1.0.0",   ← ONLY this field changes
  "capabilities": { "camera": "1.0.0" },
  "correlation_id": "ios-example-capture-1",   (android uses android-example-capture-1)
  "declared_pack_requirements": { "camera_capture_assets": "1.0.0" },
  "installed_packs": { "camera_capture_assets": "1.0.0" },
  "manifest_source": "bundled",
  "native_runtime_version": "1.0.0",     ← D-03: stays 1.0.0
  "origin": "https://example.crosswake.invalid",
  "route_id": "selective-native-claim-capture",
  "source": "cold_start",
  "url": "https://example.crosswake.invalid/native/claims/claim-1/capture"
}
```

The gen task must NOT use `Shell.Fixtures.export/1` to produce these files — that function generates a completely different activation fixture (for `"dashboard"` route, different correlation IDs, etc.). The example host fixtures for `route_activation.json` use the `"selective-native-claim-capture"` route and camera pack, which is specific to the example host. The gen task must reproduce the exact current content with only `bridge_protocol_version` updated to `1.1.0`.

**VERIFIED (file read):** iOS: `examples/ios_shell_host/Fixtures/route_activation.json` — 19 lines, `bridge_protocol_version: "1.0.0"`. Android: `examples/android_shell_host/app/src/main/assets/route_activation.json` — identical structure, `correlation_id: "android-example-capture-1"`. [VERIFIED: codebase]

### Pattern 5: `bridge_contract_vectors.json` Schema

This file is emitted by the gen task and consumed by Phase 123. Phase 121 defines its schema. Recommended location: `test/fixtures/bridge_contract_vectors.json` (within the Elixir test tree; native packages will reference it via relative path).

Schema (based on NATIVE-TESTING.md research, adapted to Phase 121 scope):

```json
{
  "_comment": "Canonical bridge contract vectors. Generated by mix crosswake.contract.gen. Phase 123 wires these into Swift/Kotlin/Elixir test suites.",
  "_regenerate": "mix crosswake.contract.gen",
  "protocol": "crosswake.bridge",
  "bridge_protocol_version": "1.1.0",
  "manifest_schema_version": "1.0.0",
  "native_runtime_version": "1.0.0",
  "commands": [
    "app.info.get",
    "haptics.impact",
    "permissions.status",
    "notifications.token.get",
    "share.invoke",
    "files.pick",
    "transfer.download",
    "transfer.export",
    "transfer.import",
    "transfer.upload.prepare"
  ],
  "denial_reasons": [
    "compatibility_mismatch",
    "inactive_route",
    "origin_denied",
    "undeclared_capability",
    "unavailable_capability",
    "pack_incompatible"
  ],
  "vectors": [
    {
      "id": "bridge_version_mismatch_deny",
      "description": "Request with stale bridge_protocol_version is denied with compatibility_mismatch",
      "request_overrides": { "version": "1.0.0" },
      "expected_status": "deny",
      "expected_denial_reason": "compatibility_mismatch"
    },
    {
      "id": "bridge_wrong_route_deny",
      "description": "Request scoped to wrong route is denied with inactive_route",
      "request_overrides": { "route_id": "ghost-route", "active_route_id": "ghost-route" },
      "expected_status": "deny",
      "expected_denial_reason": "inactive_route"
    },
    {
      "id": "bridge_wrong_origin_deny",
      "description": "Request from non-allowlisted origin is denied with origin_denied",
      "request_overrides": { "origin": "https://evil.example.com" },
      "expected_status": "deny",
      "expected_denial_reason": "origin_denied"
    },
    {
      "id": "bridge_unknown_command_deny",
      "description": "Request with unknown command is denied with undeclared_capability",
      "request_overrides": { "command": "xss.inject", "capability": "xss.inject" },
      "expected_status": "deny",
      "expected_denial_reason": "undeclared_capability"
    }
  ]
}
```

The `vectors` array in Phase 121 is a minimal seed — enough to define the format. Phase 123 extends it. The `bridge_protocol_version`, `manifest_schema_version`, `native_runtime_version`, `protocol`, and `commands` fields are derived from `Crosswake.Bridge.Contract` at gen time (not hand-authored).

### Anti-Patterns to Avoid

- **Aliasing `Bridge.Contract` in `Manifest.Types`:** Creates a compile-order cycle because `contract.ex` already aliases `Types`. Use fully-qualified call instead.
- **Using `Shell.Fixtures.export/1` to generate example host fixtures:** That function generates `"dashboard"` route fixtures, not the `"selective-native-claim-capture"` fixtures the example hosts use. The gen task must reproduce the example-host-specific content.
- **Regenerating all six fixture files from `Fixtures.export/1`:** The `manifest.json`, `denial.json`, etc. are NOT targets for Phase 121 — only `route_activation.json` contains `bridge_protocol_version`. Leave the other fixture files alone.
- **Generating ContractVersions.swift / ContractVersions.kt:** The STACK.md research (Mechanism 2 recommendation) suggests generated Swift/Kotlin constants. However, D-05 and D-06 together confirm this is not needed for Phase 121 — native code reads from the JSON manifest at runtime (confirmed in `ActivationCoordinator.swift` and `ActivationCoordinator.kt`), so updating the JSON fixtures is sufficient. ContractVersions.kt/swift generation is ARCHITECTURE.md research for Phase 122 drift guards, not Phase 121 scope.
- **Updating the build/ copies:** `examples/ios_shell_host/build/` and `examples/android_shell_host/app/build/` are build artifacts — do not update them. The gen task writes to source paths only.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Idempotent file writes in Mix task | A bespoke `File.write!` that always overwrites | `write_if_changed/2` pattern from `gen.shell.ex` | Avoids spurious `git diff` churn when content is unchanged |
| JSON serialization with consistent key ordering | Manual string concatenation | `Jason.encode!/2` with sorted keys or deterministic struct serialization | Prevents non-determinism in CI diff check |
| Task startup for module availability | `Code.ensure_loaded?/1` polling | `Mix.Task.run("app.start")` | Standard Mix task idiom; already used by other gen tasks in this repo |

**Key insight:** The `gen.shell` task already demonstrates the exact hermetic, version-reading, file-writing pattern needed. `crosswake.contract.gen` is a narrower sibling of the same shape, not a novel architecture.

---

## Common Pitfalls

### Pitfall 1: Circular Compile-Time Alias

**What goes wrong:** Adding `alias Crosswake.Bridge.Contract` at the top of `manifest/types.ex` or `shell/fixtures.ex` while `contract.ex` already `alias`es `Manifest.Types` creates a compile-order cycle: Elixir cannot compile `contract.ex` without `types.ex` being compiled, and cannot compile `types.ex` without `contract.ex` being compiled.

**Why it happens:** The natural instinct is to add `alias Bridge.Contract` so you can write `Contract.version()` instead of the fully-qualified form. But `contract.ex:7` already has `alias Crosswake.Manifest.Types`.

**How to avoid:** Use the fully-qualified call `Crosswake.Bridge.Contract.version()` in the module attribute assignment — no `alias` needed. Elixir resolves fully-qualified calls at compile time without requiring a declared alias.

**Warning signs:** `(CompileError)` during `mix compile` mentioning a circular dependency between `Crosswake.Manifest.Types` and `Crosswake.Bridge.Contract`.

### Pitfall 2: Wrong Target Files for the Gen Task

**What goes wrong:** The gen task writes to `build/` paths or to the `Fixtures.export/1` file list (which includes `crosswake_manifest.json`, `route_denial.json`, etc.) instead of only the two `route_activation.json` example-host fixture files.

**Why it happens:** `Shell.Fixtures.export/1` returns a map of all fixture paths, and it's tempting to use that map as the target list. But: (a) `Fixtures.export/1` generates `"dashboard"` route fixtures, not the example-host `"selective-native-claim-capture"` fixtures; (b) the `build/` copies are not source files.

**How to avoid:** The gen task hardcodes exactly two target paths for `route_activation.json`:
- `examples/ios_shell_host/Fixtures/route_activation.json`
- `examples/android_shell_host/app/src/main/assets/route_activation.json`

And reads the current content of each file to preserve all fields except `bridge_protocol_version`. [VERIFIED: codebase — file content confirmed]

### Pitfall 3: Updating `native_runtime_version` in `route_activation.json`

**What goes wrong:** Since `native_runtime_version: "1.0.0"` appears alongside `bridge_protocol_version: "1.0.0"` in the fixture, a developer might update both to `1.1.0`.

**Why it happens:** D-03 is clear but easy to misread during implementation: only the bridge protocol axis changes; the native runtime axis stays at `1.0.0`.

**How to avoid:** The gen task explicitly sets `bridge_protocol_version` to `Crosswake.Bridge.Contract.version()` (`1.1.0`) and sets `native_runtime_version` to the `native_runtime_version` constant from `Manifest.Types` or hard-codes `"1.0.0"` for Phase 121. The plan must call this out explicitly.

### Pitfall 4: Hardcoded Test Assertions Become Stale

**What goes wrong:** Several test files hardcode `"1.0.0"` for `bridge_protocol_version`:
- `test/mix/tasks/crosswake_doctor_test.exs:144` — asserts `bridge_protocol_version == "1.0.0"`
- `test/crosswake/doctor/doctor_test.exs:96,214` — same
- `test/crosswake/compatibility/compatibility_test.exs:22,47,70,119,144` — hardcoded `"1.0.0"` in compatibility structs

After Phase 121 changes `@bridge_protocol_version` in `Manifest.Types` to derive from `Contract.version()` (`1.1.0`), these test assertions will fail.

**How to avoid:** The plan must include an explicit task to update these test literals. The correct fix is to replace `"1.0.0"` literals with `Crosswake.Bridge.Contract.version()` or `Crosswake.Manifest.Types.new_compatibility().bridge_protocol_version` depending on what each test is actually asserting.

**Enumerated locations (complete list confirmed by grep):**
- `test/mix/tasks/crosswake_doctor_test.exs:143-145` (3 assertions)
- `test/crosswake/doctor/doctor_test.exs:95-97,213-215` (6 assertions)
- `test/crosswake/compatibility/compatibility_test.exs:21-22,46-48,69-71,118-120,143-145` (15 assertions)
- `test/fixtures/proof/phase52_operator_inspection.json:1828` — this is a committed proof fixture; update only if the proof is re-generated

### Pitfall 5: Forgetting the `crosswake_manifest.json` Example Host Fixtures

**What goes wrong:** `grep -rn '"bridge_protocol_version"'` hits `examples/ios_shell_host/Fixtures/crosswake_manifest.json:350` and `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json:350` with `"1.0.0"` — these are compatibility block entries in the manifest fixture, NOT in `route_activation.json`. Phase 121's gen task scope is `route_activation.json` only.

**Why it happens:** The grep reveals multiple hits in `crosswake_manifest.json`. These are inside the `compatibility` section of the manifest fixture, generated by `Shell.Fixtures.manifest_json()` → `Types.new_compatibility()`. After Phase 121's `Manifest.Types` fix, if `mix crosswake.gen.shell` is re-run, the manifest fixtures will also regenerate with the correct version. But that is not Phase 121's responsibility.

**How to avoid:** Phase 121 gen task scope: `route_activation.json` only. The plan must document that `crosswake_manifest.json` example host fixtures are out of scope for Phase 121 (they regenerate naturally when Phase 122's drift guard runs, or when `mix crosswake.gen.shell` is next run by an adopter).

### Pitfall 6: `ActivationCoordinator.kt:594` — Removing the Line vs. Changing the Fallback

**What goes wrong:** After removing `?: "1.0.0"`, the call to `.getString("native_runtime_version")` on a null JSON object would throw a `NullPointerException` or return null, and the assignment would be `null` — which is different from failing closed with an error.

**Why it happens:** The full context at line 594:
```kotlin
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version") ?: "1.0.0"
```
`compatibilityJson` is `root.optJSONObject("compatibility")` — can return null. If null, `?.getString(...)` returns null, and `?: "1.0.0"` was the guard. Removing the `?: "1.0.0"` means `nativeRuntimeVersion` becomes a nullable `String?`.

**How to avoid:** The plan must specify the correct removal approach. D-08 says "fail closed if absent." The correct implementation depends on how `nativeRuntimeVersion` is used downstream. Read `ActivationCoordinator.kt` to determine if the variable can be nullable. If it is typed `String` (non-nullable), changing `getString` to `optString` and removing the fallback causes a compile error — the fix would be to use `?: error("native_runtime_version absent in manifest")` to throw rather than default. The plan task must specify the exact replacement.

**Warning signs:** Kotlin compiler error `"smart cast to 'String' is impossible"` or `"null cannot be a value of a non-null type String"` after removing the fallback.

---

## Code Examples

### Compile-Time Cross-Module Attribute Reference

```elixir
# Source: codebase inspection — this is the pattern used at types.ex:651-653
# BEFORE:
@manifest_schema_version "1.0.0"
@bridge_protocol_version "1.0.0"
@native_runtime_version "1.0.0"

# AFTER:
@manifest_schema_version "1.0.0"
@bridge_protocol_version Crosswake.Bridge.Contract.version()
@native_runtime_version "1.0.0"
```

No `alias` needed. No circular dependency because:
- `contract.ex:7` has `alias Crosswake.Manifest.Types` (one direction)
- `types.ex` does NOT alias `Crosswake.Bridge.Contract` (the other direction is clean)
- Elixir evaluates fully-qualified module attribute values by compiling the referenced module first; since `contract.ex` does not call `Types` in module attributes (only in function bodies), the dependency graph is acyclic [ASSUMED: Elixir compile semantics — standard behavior, well-documented]

### Shell.Fixtures Activation Request Fix

```elixir
# Source: lib/crosswake/shell/fixtures.ex lines 76-89 (confirmed by code read)
# BEFORE (lines 82-83):
bridge_protocol_version: "1.0.0",
native_runtime_version: "1.0.0",

# AFTER:
bridge_protocol_version: Crosswake.Bridge.Contract.version(),
native_runtime_version: "1.0.0",
```

### Gen Task Write Helper (mirroring gen.shell pattern)

```elixir
# Source: lib/mix/tasks/crosswake.gen.shell.ex lines 261-269 (ensure_file pattern)
# The gen task uses write_if_changed (enhanced pattern) for generated artifacts:
defp write_if_changed(path, content) do
  File.mkdir_p!(Path.dirname(path))
  case File.read(path) do
    {:ok, ^content} ->
      Mix.shell().info("unchanged: #{path}")
    _ ->
      File.write!(path, content)
      Mix.shell().info("wrote: #{path}")
  end
end
```

### Kotlin Fallback Removal (ActivationCoordinator.kt:594)

```kotlin
// Source: packages/crosswake-shell-core-android/.../ActivationCoordinator.kt:594
// BEFORE:
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version") ?: "1.0.0"

// AFTER (fail-closed — one option):
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version")
    ?: error("crosswake_manifest.json is missing native_runtime_version in compatibility block")

// OR (if typed as String? downstream):
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version")
```

The plan must specify which form based on how `nativeRuntimeVersion` is typed downstream in `ActivationCoordinator.kt`. Reading the full context around line 594-630 is required to determine the correct null-handling approach.

---

## Downstream Literal Inventory (CANON-04 Compliance)

Every file that currently hardcodes `"bridge_protocol_version"` with the value `"1.0.0"` and must move to `1.1.0` in Phase 121:

**Source files (Elixir) — changed by compile-time reference:**
| File | Line(s) | Current Value | Phase 121 Action |
|------|---------|---------------|-----------------|
| `lib/crosswake/manifest/types.ex` | 652 | `"1.0.0"` | Replace with `Crosswake.Bridge.Contract.version()` call |
| `lib/crosswake/shell/fixtures.ex` | 82 | `"1.0.0"` | Replace with `Crosswake.Bridge.Contract.version()` call |

**Test files — updated to use canonical value:**
| File | Line(s) | Current Value | Phase 121 Action |
|------|---------|---------------|-----------------|
| `test/mix/tasks/crosswake_doctor_test.exs` | 144 | `"1.0.0"` | Update assertion to `Crosswake.Bridge.Contract.version()` |
| `test/crosswake/doctor/doctor_test.exs` | 96, 214 | `"1.0.0"` | Update assertion |
| `test/crosswake/compatibility/compatibility_test.exs` | 22, 47, 70, 119, 144 | `"1.0.0"` | Update compatibility struct initializations |

**Generated artifacts — updated by gen task:**
| File | Field | Current Value | Phase 121 Action |
|------|-------|---------------|-----------------|
| `examples/ios_shell_host/Fixtures/route_activation.json` | `bridge_protocol_version` | `"1.0.0"` | Regenerate via gen task → `"1.1.0"` |
| `examples/android_shell_host/app/src/main/assets/route_activation.json` | `bridge_protocol_version` | `"1.0.0"` | Regenerate via gen task → `"1.1.0"` |
| `test/fixtures/bridge_contract_vectors.json` | `bridge_protocol_version` | (new file) | Emit by gen task with `"1.1.0"` |

**Out-of-scope for Phase 121 (these will align in later phases or naturally):**
| File | Note |
|------|------|
| `examples/ios_shell_host/Fixtures/crosswake_manifest.json:350` | Manifest fixture; regenerates when `gen.shell` is next run or Phase 122 |
| `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json:350` | Same |
| `test/fixtures/proof/phase52_operator_inspection.json:1828` | Archived proof fixture; do NOT update |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt:627` | This reads the field name as a key string `"bridge_protocol_version"` — correct; not a version literal |

**VERIFIED (grep -rn '"bridge_protocol_version"' lib/ test/ packages/ examples/):** Full enumeration confirmed. [VERIFIED: codebase]

---

## Mirror Precedents (Awareness-Only, Not Edit Targets in Phase 121)

### `generator_coordinate_parity_check` in `publish_readiness.ex`

Location: `lib/crosswake/doctor/publish_readiness.ex:536-577`. Shape: reads `Application.spec(:crosswake, :vsn)` (a live value), compares against template text, emits a `result_check/1` struct with `category: :generator_coordinate_parity`, `proof_class: :merge_blocking`, and a `hint` field naming the fix command.

Phase 122 adds `contract_version_parity_check` as a sibling with the same shape. Phase 121 must not add this check itself (out of scope per CONTEXT.md deferred section). However, the plan should note that the `contract.ex` edits must produce a `version()` function that Phase 122's check can call.

### `compatible_version?/2` in `compatibility.ex:616`

Shape: `Version.compare(normalized_available, normalized_required) != :lt` — i.e., `available >= required`. This is the Elixir `>=` floor that Phase 124 will bring to native. Phase 121 does not touch this function. Awareness: the `1.1.0` fix makes both Elixir and native sides consistent so that even the current exact-match behavior produces a pass (both sides say `1.1.0`). [VERIFIED: codebase]

---

## Runtime State Inventory

This phase is a coherence/refactor phase — relevant category audit:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | No database or datastore stores `bridge_protocol_version` as a runtime key | None |
| Live service config | No external service config embeds this version string | None |
| OS-registered state | No OS-level registrations reference `bridge_protocol_version` | None |
| Secrets/env vars | No secret keys reference `bridge_protocol_version` | None |
| Build artifacts | `examples/ios_shell_host/build/` and `examples/android_shell_host/app/build/` contain stale `1.0.0` copies | These are build artifacts — `.gitignore`d or not committed as source; no action required in Phase 121 |

**Committed build artifacts confirmed out-of-scope:** The grep results include `build/` paths. These ARE in git (no `.gitignore` for them), so they show up in `grep`. However, CONTEXT.md explicitly states: "the `build/` copies are build artifacts, ignore." The plan must not include any action for these paths.

---

## Validation Architecture

Nyquist validation is ENABLED (`workflow.nyquist_validation` key absent in `.planning/config.json` → treat as enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/contract/ test/crosswake/compatibility/compatibility_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CANON-01 | `Manifest.Types.new_compatibility().bridge_protocol_version == Crosswake.Bridge.Contract.version()` | unit | `mix test test/crosswake/compatibility/compatibility_test.exs` | ✅ (needs assertion update) |
| CANON-02 | Each axis has exactly one source — grep returns single value | smoke | `grep -rn '"bridge_protocol_version"' lib/ \| grep -v "#" \| sort -u \| wc -l` returns 0 hardcoded literals | Manual / CI |
| CANON-03 | `mix crosswake.contract.gen` runs without error; `git diff --exit-code` on generated files passes | integration | `mix crosswake.contract.gen && git diff --exit-code examples/ios_shell_host/Fixtures/route_activation.json examples/android_shell_host/app/src/main/assets/route_activation.json test/fixtures/bridge_contract_vectors.json` | ❌ Wave 0 — gen task does not exist yet |
| CANON-04 | Doctor report emits `bridge_protocol_version == "1.1.0"` | unit | `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs` | ✅ (needs assertion update 1.0.0→1.1.0) |
| CANON-05 | `ActivationCoordinator.kt:594` does not contain `?: "1.0.0"` | smoke | `grep -n '?: "1.0.0"' packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt` — must return empty | Manual / CI |

### Wave 0 Gaps

- [ ] `lib/mix/tasks/crosswake.contract.gen.ex` — does not exist; Wave 0 creates it
- [ ] `test/fixtures/bridge_contract_vectors.json` — emitted by gen task; Wave 0 creates the task, Wave 1 runs it and commits the output

*(All existing test files exist — they require assertion updates, not new file creation)*

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/compatibility/compatibility_test.exs` (fastest signal for the attribute change)
- **Per wave merge:** `mix test` (full suite)
- **Phase gate:** Full suite green + `mix crosswake.contract.gen && git diff --exit-code` clean before `/gsd-verify-work`

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir + Mix | All tasks | ✓ | `.tool-versions` | — |
| Jason (Hex dep) | Gen task JSON encoding | ✓ | Already in deps | — |
| `mix test` | Validation | ✓ | — | — |
| Kotlin compiler | ActivationCoordinator.kt change verification | ✗ on CI Linux | — | Inspect-only; Android JVM tests are advisory (established pattern) |

**Missing dependencies with no fallback:** None that block Phase 121.

**Missing dependencies with fallback:** Kotlin compiler (not available on Ubuntu CI). Kotlin change is a one-line deletion verifiable by grep; the Android package JUnit tests run separately (Phase 123 wires them into CI).

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | Indirectly | Bridge denial logic is preserved exactly; no access control logic changes |
| V5 Input Validation | No | Version comparison is a string comparison, not user input |
| V6 Cryptography | No | — |

**Known Threat Pattern:** The `?: "1.0.0"` Kotlin fallback is a silent version assumption. Removing it ensures native shells fail closed when the manifest compatibility block is malformed or absent — this is a correctness improvement, not a security regression. The bridge denial path (`compatibility_mismatch`) already exists and is not changed. [ASSUMED: ASVS applicability assessment]

---

## Open Questions

1. **`ActivationCoordinator.kt:594` downstream type of `nativeRuntimeVersion`**
   - What we know: Line 594 assigns `val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version") ?: "1.0.0"`. The variable is used at line 627: `bridgeProtocolVersion = json.getString("bridge_protocol_version")` (different field, same function).
   - What's unclear: Whether `nativeRuntimeVersion` is passed to a constructor or function that requires `String` (non-nullable) or `String?` (nullable). The plan executor must read lines 595-630 to determine the exact replacement.
   - Recommendation: Plan task must include "read lines 594-630 of ActivationCoordinator.kt and choose between `?: error(...)` (fail-closed exception) or nullable typing" as a pre-condition step.

2. **DO-NOT-EDIT header convention for generated files**
   - What we know: `gen.shell` uses a host-ownership README, not a per-file header. The generated JSON fixtures don't have headers today.
   - What's unclear: Whether JSON files should carry a `_generated_by` key or whether a parallel `_GENERATED.md` in the Fixtures directory is the better convention.
   - Recommendation: Use a `_generated_by` key at the top of each generated JSON (e.g., `"_generated_by": "mix crosswake.contract.gen"`). For the `bridge_contract_vectors.json`, use `_comment` and `_regenerate` keys as specified in the schema above. JSON doesn't have comments, so convention keys are the clean approach.

3. **Gen task idempotency with non-deterministic fields**
   - What we know: The existing `route_activation.json` files do not contain timestamps or random values.
   - What's unclear: Whether any future expansion of the gen task outputs (docs snippet, vectors) might introduce non-determinism.
   - Recommendation: The gen task must sort all map keys before JSON encoding (Jason encodes maps in insertion order by default in Elixir; use `Jason.encode!(map, pretty: true)` and confirm key order is stable, or manually sort keys before encoding).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Elixir compile-time module attribute assignment using fully-qualified `Crosswake.Bridge.Contract.version()` in `types.ex` resolves without a cycle, because `contract.ex` uses `Types` only in function bodies | §Pattern 1, §Pitfall 1 | Compile error; fix would require extracting version to a separate module or using `Application.get_env` pattern |
| A2 | `Mix.Task.run("app.start")` in the gen task loads `Crosswake.Bridge.Contract` module in the project root context | §Pattern 3 | Task fails on `UndefinedFunctionError`; fallback is `Mix.Task.run("compile")` then direct module call |
| A3 | The `native_runtime_version` on line 594 of `ActivationCoordinator.kt` needs only a null-check change (not a deeper refactor) for D-08 | §Pitfall 6, §Open Questions | Larger Kotlin refactor needed; blocker for CANON-05 |
| A4 | ASVS V4 (Access Control) is the only indirectly applicable ASVS category | §Security Domain | If bridge denial is considered a security boundary, V2/V3 may apply — but these are not changed in Phase 121 |

**If this table is empty for any entry:** All other claims in this research were verified directly against the codebase.

---

## Sources

### Primary (HIGH confidence — verified against codebase)

- `lib/crosswake/bridge/contract.ex` — full file read; confirmed `@version "1.1.0"` at line 10, `version/0` at line 106, `alias Crosswake.Manifest.Types` at line 7. [VERIFIED: codebase]
- `lib/crosswake/manifest/types.ex:651-653` — confirmed `@manifest_schema_version "1.0.0"`, `@bridge_protocol_version "1.0.0"`, `@native_runtime_version "1.0.0"`. [VERIFIED: codebase]
- `lib/crosswake/shell/fixtures.ex:82-83` — confirmed `bridge_protocol_version: "1.0.0"`, `native_runtime_version: "1.0.0"` in `activation_request/1`. [VERIFIED: codebase]
- `packages/crosswake-shell-core-android/.../ActivationCoordinator.kt:594` — confirmed `?: "1.0.0"` fallback. [VERIFIED: codebase]
- `packages/crosswake-shell-core-ios/.../BridgeChannel.swift:182` — confirmed `request.version == session.bridgeProtocolVersion` exact-match guard. [VERIFIED: codebase]
- `examples/ios_shell_host/Fixtures/route_activation.json` — confirmed content; `bridge_protocol_version: "1.0.0"`. [VERIFIED: codebase]
- `examples/android_shell_host/app/src/main/assets/route_activation.json` — confirmed content; `bridge_protocol_version: "1.0.0"`. [VERIFIED: codebase]
- `lib/mix/tasks/crosswake.gen.shell.ex` — full structural review; `fetch_version!/0` at line 199, `write_fixture_files` at line 229, `ensure_file` at line 261. [VERIFIED: codebase]
- `lib/crosswake/doctor/publish_readiness.ex:536-577` — `generator_coordinate_parity_check` shape confirmed. [VERIFIED: codebase]
- `lib/crosswake/compatibility/compatibility.ex:616-627` — `compatible_version?/2` confirmed as `>= floor` semantics. [VERIFIED: codebase]
- `grep -rn '"bridge_protocol_version"'` — complete enumeration of all hits across lib/, test/, packages/, examples/. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- `.planning/research/STACK.md` — Mechanism 2 vs. 3 analysis; gen task shape recommendations [CITED: .planning/research/STACK.md]
- `.planning/research/ARCHITECTURE.md` — failure message contract, guard topology, generate-and-diff discipline [CITED: .planning/research/ARCHITECTURE.md]
- `.planning/research/NATIVE-TESTING.md` — `bridge_contract_vectors.json` schema, seam inventory [CITED: .planning/research/NATIVE-TESTING.md]
- `.planning/research/PITFALLS.md` — Pitfall 1.1 (drift), Pitfall 1.3 (circular dep), Pitfall 3.5 (fabricated proof) [CITED: .planning/research/PITFALLS.md]

---

## Metadata

**Confidence breakdown:**
- Surgical edit targets: HIGH — every line number confirmed by code read
- Gen task shape: HIGH — mirrors existing `gen.shell` pattern, confirmed by code read
- Circular dependency safety: HIGH — confirmed by alias direction in both files; one assumption noted
- Kotlin fallback removal: MEDIUM — confirmed line, downstream type requires plan-time investigation
- `bridge_contract_vectors.json` schema: MEDIUM — format derived from NATIVE-TESTING.md research; exact field list is discretion

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 (stable codebase; 30-day validity)
