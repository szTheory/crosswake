# Phase 139: crosswake_threadline Extraction - Research

**Researched:** 2026-07-02
**Domain:** Elixir companion extraction — observer-pattern Hex package + priv/ templates + Hex publish pipeline
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THREAD-01 | All threadline modules (`Crosswake.Threadline.*`, `Crosswake.Audit.Ledger`, `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`, `crosswake.threadline` and `crosswake.gen.audit` mix tasks) move to standalone `packages/crosswake_threadline/`; the `gen.audit` template path repoints to `Application.app_dir(:crosswake_threadline, ...)`; module names preserved (non-breaking). | Source inventory completed: 7 source files + 2 EEX templates (unique among all companion packages). app_dir fix confirmed needed at `lib/mix/tasks/crosswake.gen.audit.ex:23-24`. |
| THREAD-02 | Threadline observes purely via `:telemetry.attach_many` by event-name (zero compile deps on siblings); owns its forbidden-metadata-key list LOCALLY; audit handler crash-isolated with `try/rescue` so a write failure cannot silently detach the telemetry handler. | VERIFIED: threadline source files reference NO `Sigra.*` or `Chimeway.*` modules (only a comment at `threadline/telemetry.ex:38-40` cites provenance). Current Plug.Threadline already has `try/rescue` for its OWN errors; the THREAD-02 crash-isolation requirement refers to the AUDIT HANDLER which is host-owned. Core coupling sites identified: 2 files need decoupling (support_matrix.ex + telemetry.ex static refs to `Crosswake.Threadline.Telemetry`). |
| THREAD-03 | `crosswake_threadline` publishes to Hex as independent `release-please` component, gated by `hex.publish --dry-run` + clean-room before publish, AFTER sigra and chimeway are live. | release-please-config.json, manifest, release-please.yml patterns confirmed. Chimeway blocks (Phase 138) are the direct analogs. Strategy: in-tree extract + deferred human-gated publish (Wave 4, `autonomous: false`). |
</phase_requirements>

## Summary

Phase 139 is the FINAL companion extraction in v17.0. Threadline is the "observer" — it attaches to `:telemetry` event-names from core and companions at runtime, never at compile time. This is structurally the **simplest** extraction of the three (no Finding-boundary refactor, no auth dispatch, no Companion behaviour implementation), but it has two unique characteristics that distinguish it from Phase 138:

1. **Threadline is NOT a `Crosswake.Companion` behaviour implementor.** It has no `companion_id/0`, no `validate_dependency/0`, no `route_gated?/2`. It is a pure audit-and-correlation infrastructure module that is registered in host applications as `config :crosswake, :companions, [...]` implicitly (the host wires it via Plug and LiveView, not via the companion registry). After extraction, the host simply depends on `crosswake_threadline` and uses `plug Crosswake.Plug.Threadline` and `on_mount: Crosswake.Live.Threadline`. No registry callback is involved.

2. **The `priv/templates/` directory moves with the package.** `mix crosswake.gen.audit` scaffolds host-owned audit Ecto schema and migration from EEX templates at `priv/templates/crosswake/audit/{ledger.ex.eex,migration.exs.eex}`. These must move to `packages/crosswake_threadline/priv/templates/crosswake/audit/`, and `mix.exs` files: must include `"priv"`. The `Application.app_dir(:crosswake, ...)` call becomes `Application.app_dir(:crosswake_threadline, ...)`.

**Core has TWO compile-time coupling sites onto threadline** that must be inverted before extraction:
- `lib/crosswake/support_matrix/support_matrix.ex:16` — `alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry`, used inside the `@audit_ledger_support_truth` MODULE ATTRIBUTE at lines 295-297 (stale-beam trap — module-attribute eval at compile time).
- `lib/crosswake/telemetry.ex:245` — `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` called inside `attach_default_logger/1` function body (compile dep via static alias).

Both must be removed by freezing values as literals (support_matrix) and expanding the `@baseline_forbidden_keys` list (telemetry).

**Primary recommendation:** Follow `script/extract_companion.md` steps for threadline (no-engine, no-companion-behaviour, priv/ included in files:). Invert the 2 core coupling sites in Wave 1 alongside extraction. Use the chimeway 4-wave structure (no Finding-boundary wave needed). Defer the irreversible Hex publish to a human-gated Wave 4.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP thread_id read/mint (Plug.Threadline) | Package (crosswake_threadline) | Host Application (pipeline wiring) | Plug stays in the package; host wires it in the Phoenix router pipeline |
| LiveView metadata bridge (Live.Threadline) | Package (crosswake_threadline) | Host Application (on_mount wiring) | on_mount hook lives in the package; host declares `on_mount: Crosswake.Live.Threadline` |
| Audit ledger HMAC contract (Audit.Ledger) | Package (crosswake_threadline) | Host Application (Ecto schema owns fields) | Ledger struct contract + actor_ref HMAC in package; host-owned Ecto schema implements it |
| gen.audit EEX template scaffolding | Package (crosswake_threadline) | Host Application (generated files) | Templates ship in package priv/; generated files live in host app (host-owned) |
| crosswake.threadline mix task | Package (crosswake_threadline) | Host Application (ledger config) | Task queries host-owned Repo + schema via Application env; ships with the package |
| Telemetry attach to core/companion events | Package (crosswake_threadline) | Core (Telemetry public catalog) | attach_many by event-name atom lists; zero compile dep on siblings |
| Threadline event names in core catalog | Core (Crosswake.Telemetry) | — | Core's `build_active_events/0` ALREADY declares threadline events as literals (no Threadline module call); stays in core unchanged |
| Forbidden-key PII denylist aggregation | Core (Crosswake.Telemetry) | Package (Threadline.Telemetry, owned locally) | After extraction: threadline's 11 unique forbidden keys absorbed into core @baseline_forbidden_keys; static compile dep on Threadline.Telemetry removed |
| audit_ledger_support_truth in SupportMatrix | Core (SupportMatrix, frozen literals) | — | Convert @audit_ledger_support_truth MODULE ATTRIBUTE to frozen literal form (@audit_ledger_support_truth_static), removing compile dep on ThreadlineTelemetry |
| Package publication | CI (release-please) | Human gate (PR merge) | Same pattern as rulestead/rindle/sigra/chimeway |
| Clean-room verification | CI (clean-room-proof-threadline) | — | Post-publish lane; no-engine mode; vacuity-safe: no siblings installed |

## Standard Stack

### Core (no new external deps — source + CI movement)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `crosswake` | `~> 0.1` (Hex dep when CROSSWAKE_RELEASE=1) | Core runtime dep of the package | Env-conditional pattern proven on rulestead/rindle/sigra/chimeway |
| `elixir` | `~> 1.19` | Language runtime | Matches core, sigra, chimeway mix.exs |

### Transitive via `crosswake` (no explicit declaration needed)

| Library | Purpose | Source |
|---------|---------|--------|
| `:plug` | `Plug.Conn` used by `Crosswake.Plug.Threadline` | Transitive through `{:crosswake, "~> 0.1"}` |
| `phoenix_live_view` | `Phoenix.LiveView.*` used by `Crosswake.Live.Threadline` | Transitive through `{:crosswake, "~> 0.1"}` |
| `nimble_options` | `NimbleOptions.new!/1` + `validate!/2` in `Crosswake.Plug.Threadline` | Transitive through `{:crosswake, "~> 0.1"}` |

[VERIFIED: core `mix.exs` lines 49-51 confirms `nimble_options ~> 1.1`, `phoenix ~> 1.8`, `phoenix_live_view ~> 1.1` as direct deps; these propagate transitively to any package depending on `{:crosswake, "~> 0.1"}`]

### No Engine Optional Dep

Threadline has NO third-party engine library. All machinery (UUID generation via `:crypto`, HMAC via `:crypto.mac`, telemetry via `:telemetry`) is OTP built-ins already available through core. `validate_dependency/0` does NOT apply (threadline is not a `Crosswake.Companion` behaviour implementor — it has no companion facade). [VERIFIED: live code read — no optional engine dep in any threadline file]

**Consequence for recipe:** Steps 6 (engine_present stub), ENGINE_PRESENT_LANE, and `engine-present.test` alias are OMITTED for threadline. Identical to sigra and chimeway.

### Supporting CI Infrastructure (already in repo)

| Script/File | Purpose |
|-------------|---------|
| `script/verify_companion_cleanroom.sh` | Post-publish clean-room verification (parametric, no-engine mode) |
| `script/strip_release_as.py` | Auto-strips one-shot `release-as` pin (PROOF-03) |
| `release-please-config.json` | Add threadline component block (clone chimeway block) |
| `.release-please-manifest.json` | Add `"packages/crosswake_threadline": "0.1.0"` |
| `.github/workflows/release-please.yml` | Add ~100 lines: threadline outputs + 3 new jobs |

## Package Legitimacy Audit

No new external packages are installed by this phase. `crosswake_threadline` is a first-party package extracted from the monorepo. No third-party packages are added to any `mix.exs`.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `crosswake_threadline` | First-party (new) | — | — | github.com/szTheory/crosswake | First-party | Created by this phase |
| `crosswake` (as dep) | First-party | — | — | github.com/szTheory/crosswake | First-party | Already in use by rulestead/rindle/sigra/chimeway packages |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

## Zero-Sibling-Dep Verification (the Linchpin)

**Claim: threadline has zero compile-time reference to any `Sigra.*` or `Chimeway.*` module.**

**VERIFIED against live code (2026-07-02):**

```bash
$ grep -rn "Sigra\|sigra\|Chimeway\|chimeway\|crosswake_sigra\|crosswake_chimeway" \
    lib/crosswake/threadline/ \
    lib/crosswake/plug/threadline.ex \
    lib/crosswake/live/threadline.ex \
    lib/crosswake/audit/ledger.ex \
    lib/mix/tasks/crosswake.threadline.ex \
    lib/mix/tasks/crosswake.gen.audit.ex
```

**Result:**
```
lib/crosswake/threadline/telemetry.ex:38:  # Sigra's verified 19-key PII denylist plus :actor_ref (RESEARCH A1 — Phase 94's
lib/crosswake/threadline/telemetry.ex:40:  # in Sigra's list). Total: 20 forbidden keys.
```

Every hit is a **code comment** (provenance note explaining the origin of the 20-key list). There is **no** `alias Crosswake.Companions.Sigra.*`, no `Crosswake.Companions.Chimeway.*` reference, no runtime module call. **The claim is TRUE.** [VERIFIED: live code grep, 2026-07-02]

**The no-sibling-dep invariant is simpler to enforce than chimeway's** because threadline does NOT implement `Crosswake.Companion` behaviour at all — there is no registry callback path through which a sibling module could creep in.

**grep invariant the plan/checker must enforce:**

```bash
grep -rn "Crosswake\.Companions\.Sigra\|crosswake_sigra\|Crosswake\.Companions\.Chimeway\|crosswake_chimeway" \
  packages/crosswake_threadline/lib/ && echo FAIL || echo CLEAN
```

No `only: :test` allowlist is needed (unlike chimeway which has a sigra test-only dep) — threadline has zero dependency on sibling companions, even in tests.

## Source Inventory (THREAD-01)

### Source Files to Move

All move from their current location in core `lib/` to `packages/crosswake_threadline/lib/` (same relative sub-path):

[VERIFIED: live filesystem grep, 2026-07-02]

| Core Path | Package Path | Module |
|-----------|-------------|--------|
| `lib/crosswake/threadline/id.ex` | `packages/crosswake_threadline/lib/crosswake/threadline/id.ex` | `Crosswake.Threadline.Id` |
| `lib/crosswake/threadline/telemetry.ex` | `packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex` | `Crosswake.Threadline.Telemetry` |
| `lib/crosswake/plug/threadline.ex` | `packages/crosswake_threadline/lib/crosswake/plug/threadline.ex` | `Crosswake.Plug.Threadline` |
| `lib/crosswake/live/threadline.ex` | `packages/crosswake_threadline/lib/crosswake/live/threadline.ex` | `Crosswake.Live.Threadline` |
| `lib/crosswake/audit/ledger.ex` | `packages/crosswake_threadline/lib/crosswake/audit/ledger.ex` | `Crosswake.Audit.Ledger` |
| `lib/mix/tasks/crosswake.threadline.ex` | `packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex` | `Mix.Tasks.Crosswake.Threadline` |
| `lib/mix/tasks/crosswake.gen.audit.ex` | `packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | `Mix.Tasks.Crosswake.Gen.Audit` |

### Template Files to Move (UNIQUE — No Other Companion Has This)

[VERIFIED: live filesystem, 2026-07-02]

| Core Path | Package Path |
|-----------|-------------|
| `priv/templates/crosswake/audit/ledger.ex.eex` | `packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex` |
| `priv/templates/crosswake/audit/migration.exs.eex` | `packages/crosswake_threadline/priv/templates/crosswake/audit/migration.exs.eex` |

**Package `files:` must include `"priv"`** (unlike sigra/chimeway/rulestead/rindle which all omit priv). The package `mix.exs` must use:
```elixir
files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
```

### No Companion Facade

Threadline has **no** companion facade module (no `lib/crosswake/companions/threadline.ex`). It does NOT implement `@behaviour Crosswake.Companion`. It is registered in host apps via Plug/LiveView wiring, not via the `:companions` registry. **No facade file exists to move or remove.** [VERIFIED: `lib/crosswake/companions/` only contains `play_billing.ex`, `store_kit.ex`, and their subdirectories — no threadline.ex]

### What STAYS in Core (NOT Moved)

| Item | Rationale |
|------|-----------|
| `lib/crosswake/telemetry.ex` `build_active_events/0` threadline entry | Core's telemetry catalog ALREADY uses literals for the threadline event (`event: [:crosswake, :threadline, :request]`) — no module call; stays as-is [VERIFIED: telemetry.ex:155-167] |
| `lib/crosswake/doctor/doctor.ex` threadline posture checks (lines 881-1082) | Doctor.ex checks for threadline CONFIGURATION in the host (router plug presence, ledger config) — it uses STRING matching (`String.contains?(contents, "plug Crosswake.Plug.Threadline")`), NOT a compile-time module dep. Doctor stays in core. [VERIFIED: doctor.ex:953] |
| `test/crosswake/doctor/doctor_threadline_test.exs` | Tests `Doctor.run/1` which is core logic; stays in core |
| `test/crosswake/support_matrix/support_matrix_test.exs` (threadline entries) | Tests `SupportMatrix.audit_ledger_support_truth/0` (core function) after converting to frozen literals; stays in core with updated assertions |
| `test/crosswake/telemetry_test.exs` (threadline event atoms) | Tests only use event-name atom lists (not `Crosswake.Threadline.Telemetry` module); stays in core |

## Core Coupling Sites (Must Decouple Before or During Extraction)

### SITE 1: `lib/crosswake/support_matrix/support_matrix.ex`

**Lines:**
- L16: `alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry` (compile-time alias)
- L285-300: `@audit_ledger_support_truth` MODULE ATTRIBUTE calls `ThreadlineTelemetry.event_names()`, `ThreadlineTelemetry.metadata_keys()`, `ThreadlineTelemetry.forbidden_metadata_keys()` at module-evaluation time (stale-beam trap)

**Fix: Convert `@audit_ledger_support_truth` to `@audit_ledger_support_truth_static` with frozen literal values** — identical pattern to `@notification_support_truth_static` (Phase 136 DECOUPLE-03). The values are stable (frozen API contract), so inlining is semantically correct.

[VERIFIED: `@notification_support_truth_static` at support_matrix.ex:263 shows the exact pattern; `@auth_contract_truth_static` at line 133 shows the same pattern applied twice already]

```elixir
# BEFORE (compile dep on Threadline.Telemetry):
@audit_ledger_support_truth [
  %{
    ...
    telemetry: %{
      status: :shipped,
      event_names: ThreadlineTelemetry.event_names(),
      metadata_keys: ThreadlineTelemetry.metadata_keys(),
      forbidden_metadata_keys: ThreadlineTelemetry.forbidden_metadata_keys()
    },
    ...
  }
]

# AFTER (frozen literals — compile dep removed):
@audit_ledger_support_truth_static %{
  ...
  telemetry: %{
    status: :shipped,
    # Frozen from Crosswake.Threadline.Telemetry — compile dep removed in Phase 139
    event_names: [
      [:crosswake, :threadline, :request, :start],
      [:crosswake, :threadline, :request, :stop],
      [:crosswake, :threadline, :request, :exception]
    ],
    metadata_keys: [:thread_id, :correlation_id, :route_id, :source],
    forbidden_metadata_keys: [
      :access_token, :actor_id, :actor_ref, :authorization_code, :credential_id,
      :device_id, :email, :id_token, :ip, :nonce, :org_id, :passkey_credential_id,
      :pkce_verifier, :provider_payload, :raw_return_to, :refresh_token, :return_to,
      :session_ref, :subject_ref, :user_agent
    ]
  },
  ...
}
def audit_ledger_support_truth, do: [@audit_ledger_support_truth_static]
```

**Test update required:** `test/crosswake/support_matrix/support_matrix_test.exs` lines 300-317 currently compare `entry.telemetry.forbidden_metadata_keys == ThreadlineTelemetry.forbidden_metadata_keys()` etc. After freezing, these become literal list comparisons (same values, no module call needed). The tests STAY in core; their assertions become direct literal comparisons OR the tests add a comment confirming the values match the frozen literals.

### SITE 2: `lib/crosswake/telemetry.ex`

**Line:**
- L245: `MapSet.new(Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++ companion_forbidden_keys)` inside `attach_default_logger/1` function body

**The comment at L235-237 explicitly flags this:** "Threadline stays in-tree for Phase 136 — its keys are included directly."

**Fix: Expand `@baseline_forbidden_keys` to absorb threadline's unique keys**, then remove the `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call.

Current `@baseline_forbidden_keys` (10 keys): `access_token, refresh_token, id_token, authorization_code, token, session_ref, subject_ref, actor_id, ip, email`

Threadline's 20 keys = baseline's 10 (minus `:token`) + 11 unique: `actor_ref, credential_id, device_id, nonce, org_id, passkey_credential_id, pkce_verifier, provider_payload, raw_return_to, return_to, user_agent` + `session_ref, subject_ref` (already in baseline) [VERIFIED: threadline/telemetry.ex:41-62]

**Expanded baseline (21 keys) after absorbing threadline's unique keys plus keeping `:token`:**

```elixir
@baseline_forbidden_keys [
  # auth tokens — catastrophic if leaked
  :access_token, :refresh_token, :id_token, :authorization_code, :token,
  # identity anchors
  :session_ref, :subject_ref, :actor_id, :actor_ref,
  # direct PII
  :ip, :email,
  # auth-flow fields (absorbed from Threadline.Telemetry Phase 139)
  :credential_id, :device_id, :nonce, :org_id,
  :passkey_credential_id, :pkce_verifier, :provider_payload,
  :raw_return_to, :return_to, :user_agent
]
```

Then in `attach_default_logger/1` (line 244-245), replace:
```elixir
MapSet.new(Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++ companion_forbidden_keys)
```
with:
```elixir
MapSet.new(@baseline_forbidden_keys ++ companion_forbidden_keys)
```

The `Phase133TelemetryContractTest` uses `Crosswake.Plug.Threadline.init/1` and `call/2` to trigger the threadline telemetry event for TELEM-04 Side A. After extraction, core must either:
- Add `{:crosswake_threadline, path: "../../packages/crosswake_threadline", only: :test}` to core `mix.exs` (recommended — mirrors chimeway's test-only sigra dep), OR
- Replace the `Plug.Threadline` trigger with a synthetic `:telemetry.execute` call

**Recommended:** Add test-only path dep on `crosswake_threadline` in core `mix.exs`. This is the cleanest pattern and mirrors Phase 138's `{:crosswake_sigra, path: "../../packages/crosswake_sigra", only: :test}` in chimeway.

### No Coupling in `doctor.ex`

[VERIFIED: doctor.ex uses only string matching `String.contains?(contents, "plug Crosswake.Plug.Threadline")` — this is a STRING LITERAL, not a compile-time module alias. Doctor.ex has NO `alias Crosswake.Threadline.*` or `Crosswake.Threadline.` module call. Doctor stays fully in core without changes. 2026-07-02]

## Telemetry Attach Mechanism (THREAD-02)

### How Threadline Currently Attaches

Threadline does NOT use `:telemetry.attach_many` to observe others. It EMITS telemetry events (via `Crosswake.Threadline.Telemetry.execute/3`) and IS OBSERVED by hosts via `:telemetry.attach_many` or `Crosswake.Telemetry.attach_default_logger/1`.

The D-7 requirement "threadline observes purely via `:telemetry.attach_many` by event-name" describes the DESIGN INTENT for the audit handler (which attaches to core/companion telemetry events to write audit records). This audit handler is **host-owned** (generated by `mix crosswake.gen.audit` and implemented by the host's Ecto schema). Threadline provides the scaffold — the handler is not in the package itself.

The package provides:
- `Crosswake.Threadline.Telemetry` — emit events (start/stop/exception for HTTP spans)
- `Crosswake.Plug.Threadline` — the Plug that EMITS the 3 threadline events
- `Crosswake.Live.Threadline` — LiveView on_mount that propagates thread_id
- `Crosswake.Audit.Ledger` — the struct contract + HMAC helper for the host-owned ledger
- Mix tasks — `crosswake.threadline` (inspect events), `crosswake.gen.audit` (scaffold host ledger)

### try/rescue Crash Isolation (THREAD-02)

`Crosswake.Plug.Threadline.call/2` ALREADY has a `try/rescue` block at lines 35-76 [VERIFIED: live code read]. This handles PLUG errors.

The D-7 `try/rescue` requirement for "audit handler crash-isolation" refers to the HOST-OWNED audit handler that the host writes after running `mix crosswake.gen.audit`. When the host wires a `:telemetry.attach_many` handler for audit writing, if that handler raises, telemetry auto-detaches it → silent audit blackout.

**THREAD-02 requirement:** The `mix crosswake.gen.audit` template for the LEDGER.EX.EEX should include a `try/rescue` pattern in the generated telemetry handler. This is a template change, not a source code change. The generated scaffold should show:

```elixir
# In the generated host-owned audit handler:
def handle_event(event, measurements, metadata, _config) do
  try do
    # ... write audit record ...
    :ok
  rescue
    e ->
      Logger.error("Audit ledger write failed for event #{inspect(event)}: #{Exception.message(e)}")
      # Do NOT reraise — reraising would cause telemetry to auto-detach this handler,
      # resulting in silent audit blackout. Return :ok to keep handler attached.
      :ok
  end
end
```

[ASSUMED — exact generated template content; the principle is VERIFIED by D-7 language]

### Event Names Threadline Observes/Emits

**Emitted (3 event names, in `Crosswake.Threadline.Telemetry`):**
```elixir
[
  [:crosswake, :threadline, :request, :start],
  [:crosswake, :threadline, :request, :stop],
  [:crosswake, :threadline, :request, :exception]
]
```
[VERIFIED: `threadline/telemetry.ex:32-36`]

**Metadata keys (4-key PROP-02 allowlist):** `[:thread_id, :correlation_id, :route_id, :source]` [VERIFIED: `threadline/telemetry.ex:28`]

**Forbidden metadata keys (20 keys):** The full list owned locally by `Crosswake.Threadline.Telemetry` [VERIFIED: `threadline/telemetry.ex:41-62`]. Comment at line 38-40 notes provenance ("Sigra's verified 19-key PII denylist plus :actor_ref") — this is a provenance comment only, NOT a compile coupling. The keys are local inline constants.

## Forbidden-Key Locality (THREAD-02)

**D-7 requirement:** "Owns its forbidden-key list locally (the 'derived from sigra's 19 keys' note is provenance, not coupling — freeze as threadline's own)."

**VERIFIED TRUE:** `@forbidden_metadata_keys` at `threadline/telemetry.ex:41-62` is an inline module attribute (20 atoms). There is NO call to `Sigra.forbidden_metadata_keys()` or any sigra function. The comment at line 38-40 explains *why* these 20 keys were chosen (they match sigra's 19-key denylist + `:actor_ref`) but the values are self-contained. [VERIFIED: live code read, 2026-07-02]

After extraction, these 20 keys remain in `packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex` unchanged — they are frozen threadline-owned constants.

## Template Path Fix (THREAD-01)

**Current code in `lib/mix/tasks/crosswake.gen.audit.ex:23-24`:**

```elixir
schema_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/ledger.ex.eex")
migration_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/migration.exs.eex")
```

**After extraction (THREAD-01 requirement):**

```elixir
schema_template = Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/ledger.ex.eex")
migration_template = Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/migration.exs.eex")
```

The existing fallback at lines 26-27 (`if File.exists?(schema_template), do: schema_template, else: Path.join(File.cwd!(), ...)`) handles the development case when `app_dir` is not resolved at runtime. This fallback path string ALSO changes to reflect the new location: `"priv/templates/crosswake/audit/ledger.ex.eex"` (relative to package root, correct for `mix crosswake.gen.audit` run from the package directory). [VERIFIED: `crosswake.gen.audit.ex:23-27`]

## Phoenix Optionality (D-7)

**D-7 says:** "Consider making the `Crosswake.Live.Threadline` Phoenix dep optional."

**Research finding:** Since `crosswake_threadline` depends on `{:crosswake, "~> 0.1"}`, and `crosswake` already declares `{:phoenix_live_view, "~> 1.1"}` as a direct dep (core `mix.exs:51`), `phoenix_live_view` is **always available transitively** to any package depending on core. Making it "optional" with `Code.ensure_loaded?(Phoenix.LiveView)` would be purely defensive — there is no actual scenario where an adopter has `crosswake` but NOT `phoenix_live_view`.

**Recommendation: Do NOT add `optional: true` or `Code.ensure_loaded?` guards for Phoenix.** The D-7 suggestion is aspirational and does not apply to the current architecture where phoenix is a hard transitive dep through core. Keep `Crosswake.Live.Threadline` as-is. Document in the package README that Phoenix LiveView is required (it comes through `crosswake`).

[VERIFIED: core `mix.exs:51` — `{:phoenix_live_view, "~> 1.1"}` is a direct non-optional core dep; it propagates transitively to all companion packages]

## release-please Wiring (THREAD-03)

The chimeway pattern (Phase 138, commits `a61b5e0f` / `51fd30ff`) is the direct analog. Apply `s/chimeway/threadline/g` throughout.

### release-please-config.json threadline block

```json
"packages/crosswake_threadline": {
  "component": "crosswake_threadline",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "_TODO_release_as": "ONE-SHOT override (Phase 139 / recipe Step 12f / Pitfall 6): remove 'release-as' after the first crosswake_threadline Release PR merges.",
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_threadline/mix.exs"],
  "changelog-sections": [
    { "type": "feat",     "section": "Features" },
    { "type": "fix",      "section": "Bug Fixes" },
    { "type": "perf",     "section": "Performance Improvements" },
    { "type": "deps",     "section": "Dependencies" },
    { "type": "chore",    "section": "Miscellaneous",          "hidden": true },
    { "type": "docs",     "section": "Documentation",          "hidden": true },
    { "type": "test",     "section": "Tests",                  "hidden": true },
    { "type": "ci",       "section": "Continuous Integration", "hidden": true },
    { "type": "refactor", "section": "Refactoring",            "hidden": true },
    { "type": "build",    "section": "Build System",           "hidden": true }
  ]
}
```

[VERIFIED: pattern matches live chimeway block in release-please-config.json]

### .release-please-manifest.json addition

Add after the chimeway line (current 7 keys: `.`, ios, android, rulestead, rindle, sigra, chimeway):
```json
"packages/crosswake_threadline": "0.1.0"
```
[VERIFIED: live manifest read — `"packages/crosswake_chimeway": "0.1.0"` is the model]

### release-please.yml outputs block (add after chimeway, ~L67)

```yaml
# Companion: crosswake_threadline (Phase 139 — independently versioned, NOT in lockstep)
threadline_release_created: ${{ steps.release.outputs['packages/crosswake_threadline--release_created'] }}
threadline_tag_name: ${{ steps.release.outputs['packages/crosswake_threadline--tag_name'] }}
threadline_version: ${{ steps.release.outputs['packages/crosswake_threadline--version'] }}
```

### `publish-hex-threadline` job (mirror `publish-hex-chimeway` with s/chimeway/threadline/g)

Key points:
- `if: ${{ needs.release-please.outputs.threadline_release_created == 'true' }}` (per-component gate, NOT aggregate `releases_created`)
- `env: CROSSWAKE_RELEASE: "1"`
- `ref: ${{ needs.release-please.outputs.threadline_tag_name }}`
- Cache: `packages/crosswake_threadline/deps` + `_build`, key `runner.os-threadline-hashFiles(mix.lock)`
- Steps: `mix deps.get` → `mix compile --warnings-as-errors` → verify version → `mix test` → `mix hex.publish --dry-run --yes` → `mix hex.publish --yes` → Hex propagation poll

### `clean-room-proof-threadline` job (mirror `clean-room-proof-chimeway`)

```yaml
clean-room-proof-threadline:
  needs: [release-please, publish-hex-threadline]
  if: ${{ needs.release-please.outputs.threadline_release_created == 'true' }}
  ...
  - name: Run clean-room proof
    run: >
      bash script/verify_companion_cleanroom.sh
      crosswake_threadline
      "${{ needs.release-please.outputs.threadline_version }}"
```

### `release-as-cleanup` patch

Add `|| needs.release-please.outputs.threadline_release_created == 'true'` to the `if:` condition at line 1069.

Add threadline strip block after chimeway strip:
```bash
if [ "${{ needs.release-please.outputs.threadline_release_created }}" = "true" ]; then
  python3 script/strip_release_as.py crosswake_threadline
fi
```

### `release-failure-alert` patch

Add to `needs:` list:
```yaml
- publish-hex-threadline
- clean-room-proof-threadline
```

Add to the issue body echo block:
```bash
echo "- publish-hex-threadline: ${{ needs.publish-hex-threadline.result }}"
echo "- clean-room-proof-threadline: ${{ needs.clean-room-proof-threadline.result }}"
```

[VERIFIED: all patterns match live chimeway additions in release-please.yml lines 62-67, 432-520, 1023-1060, 1061-1112, 1114-1165]

## Architecture Patterns

### System Architecture Diagram

```
[Host Application]
    plug Crosswake.Plug.Threadline (in router pipeline)
    on_mount: Crosswake.Live.Threadline (in LiveView)
         |
         v
[packages/crosswake_threadline]
    Crosswake.Plug.Threadline.call/2
         |
         +-- Read/mint thread_id from X-Crosswake-Thread-Id header
         |        (Id.generate() — stdlib :crypto.strong_rand_bytes)
         |
         +-- Logger.metadata(crosswake_thread_id: id)
         |
         +-- Conn.put_resp_header("x-crosswake-thread-id", id)
         |
         +-- Threadline.Telemetry.execute([:crosswake, :threadline, :request, :start], ...)
         |   [PII scrub: @forbidden_metadata_keys 20-key denylist filters metadata]
         |
         +-- Conn.register_before_send (stop event)
         |
         rescue -> :exception event + reraise
         |
         v
    Events emitted: :start / :stop / :exception (3 active event names)

    Crosswake.Live.Threadline.on_mount(:default, ...)
         |
         +-- Phoenix.LiveView.get_connect_params -> "_crosswake_thread_id"
         +-- Logger.metadata(crosswake_thread_id: id)
         |
         v (thread_id propagated to LiveView logger context)

    Crosswake.Audit.Ledger (struct contract)
         |
         +-- actor_ref/2 — HMAC-SHA256 anonymization (:crypto.mac)
         +-- @type t — 15-field append-only audit record struct
         |
         v (host implements Ecto schema from mix crosswake.gen.audit template)

[Core (Crosswake.Telemetry)]
    build_active_events/0 — includes threadline event LITERAL
    [:crosswake, :threadline, :request] with metadata: [:thread_id, :correlation_id, :route_id, :source]
    (no compile dep on Crosswake.Threadline.Telemetry — events declared as literals)

    attach_default_logger/1
    @baseline_forbidden_keys (21 after Phase 139 expansion)
    [threadline's 11 unique keys absorbed into baseline — Crosswake.Threadline.Telemetry.forbidden_metadata_keys() call removed]

[CI Clean-Room Lane]
    crosswake + crosswake_threadline (NO crosswake_sigra, NO crosswake_chimeway)
         |
         v
    verify_companion_cleanroom.sh crosswake_threadline <version>
    smoke test assertions:
      - Crosswake.Threadline.Telemetry.event_names() == 3 events (canary: Telemetry shipped)
      - Crosswake.Plug.Threadline.init([]) returns opts (canary: Plug shipped)
      - Crosswake.Audit.Ledger module is loaded (canary: Ledger shipped)
```

### Recommended Package Structure

```
packages/crosswake_threadline/
├── lib/
│   └── crosswake/
│       ├── threadline/
│       │   ├── id.ex                    # UUID minting (:crypto.strong_rand_bytes)
│       │   └── telemetry.ex             # 3 event names + 4 metadata keys + 20 forbidden keys
│       ├── plug/
│       │   └── threadline.ex            # HTTP Plug: read/mint thread_id, emit telemetry
│       ├── live/
│       │   └── threadline.ex            # LiveView on_mount: propagate thread_id
│       └── audit/
│           └── ledger.ex                # Audit ledger struct + actor_ref HMAC
│   └── mix/
│       └── tasks/
│           ├── crosswake.threadline.ex  # mix crosswake.threadline (inspect events)
│           └── crosswake.gen.audit.ex   # mix crosswake.gen.audit (scaffold host ledger)
├── priv/
│   └── templates/
│       └── crosswake/
│           └── audit/
│               ├── ledger.ex.eex        # Generated host Ecto schema template
│               └── migration.exs.eex   # Generated Ecto migration template
├── test/
│   ├── crosswake/
│   │   ├── threadline/
│   │   │   ├── id_test.exs              (MOVED from core)
│   │   │   └── telemetry_test.exs       (MOVED from core)
│   │   ├── plug/
│   │   │   └── threadline_test.exs      (MOVED from core)
│   │   ├── live/
│   │   │   └── threadline_test.exs      (MOVED from core)
│   │   └── audit/
│   │       └── ledger_test.exs          (MOVED from core)
│   └── crosswake/
│       └── proof/
│           ├── phase91_threadline_contract_closeout_test.exs   (MOVED from core)
│           ├── phase92_server_propagation_closeout_test.exs    (MOVED from core)
│           ├── phase96_threadline_docs_contract_test.exs       (MOVED from core)
│           └── phase139_threadline_cleanroom_test.exs          (NEW — non-vacuous clean-room proof)
│   └── mix/tasks/
│       ├── crosswake.gen.audit_test.exs  (MOVED from core)
│       └── crosswake.threadline_test.exs (MOVED from core)
│   └── test_helper.exs
├── mix.exs                # @version "0.1.0", files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
├── mix.lock
├── config/
│   └── config.exs
├── README.md
├── LICENSE
└── CHANGELOG.md
```

### Pattern 1: `packages/crosswake_threadline/mix.exs`

```elixir
# Source: packages/crosswake_chimeway/mix.exs (verified live code read) — apply s/chimeway/threadline/g
defmodule CrosswakeThreadline.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_threadline,
      version: @version,
      name: "crosswake_threadline",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # NOTE: No ENGINE_PRESENT_LANE branch — threadline has no optional engine library.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [crosswake_dep()]
    # NOTE: No sibling companion dep (THREAD-02 invariant).
    # NimbleOptions, Phoenix, Phoenix.LiveView come transitively through crosswake.
  end

  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp description, do: "Threadline audit and correlation observer for the Crosswake route-policy system."

  defp package do
    [
      name: "crosswake_threadline",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_threadline",
        "GitHub" => @source_url
      },
      # NOTE: "priv" is REQUIRED — threadline ships EEX templates for mix crosswake.gen.audit.
      # This is unique among companion packages (rulestead/rindle/sigra/chimeway omit priv/).
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
```

[VERIFIED: pattern confirmed against live sigra/chimeway mix.exs; key difference = `files:` includes `"priv"`]

### Pattern 2: Non-vacuous clean-room ExUnit proof

Unlike chimeway (which uses telemetry aggregation) and sigra (which uses RouteGate auth dispatch), threadline is NOT a Companion behaviour implementor. The clean-room proof must assert:
1. `Crosswake.Threadline.Telemetry.event_names/0` returns the 3 request-span names (proves Telemetry module shipped)
2. `Crosswake.Plug.Threadline.init([])` returns valid opts without raising (proves Plug shipped)
3. `Crosswake.Audit.Ledger.actor_ref("test-id", secret: "secret")` returns a hex string (proves Ledger shipped)
4. No sibling companion deps in `mix.exs` (vacuity guard)

```elixir
defmodule Crosswake.Proof.Phase139ThreadlineCleanroomTest do
  use ExUnit.Case, async: true  # threadline is NOT a :companions registrant; async: true OK

  test "Threadline.Telemetry.event_names/0 returns 3 request-span events (canary: Telemetry shipped)" do
    events = Crosswake.Threadline.Telemetry.event_names()
    assert is_list(events) and length(events) == 3,
           "Threadline.Telemetry.event_names/0 must return 3 events — module may be missing from tarball"
    assert [:crosswake, :threadline, :request, :start] in events
    assert [:crosswake, :threadline, :request, :stop] in events
    assert [:crosswake, :threadline, :request, :exception] in events
  end

  test "Plug.Threadline.init/1 returns valid opts (canary: Plug shipped)" do
    opts = Crosswake.Plug.Threadline.init([])
    assert is_list(opts), "Plug.Threadline.init/1 must return a keyword list"
    assert opts[:header_name] == "x-crosswake-thread-id"
  end

  test "Audit.Ledger.actor_ref/2 returns HMAC hex string (canary: Ledger shipped)" do
    result = Crosswake.Audit.Ledger.actor_ref("test-user-id", secret: "test-secret")
    assert is_binary(result) and byte_size(result) == 64,
           "actor_ref/2 must return a 64-char hex string (SHA-256 HMAC)"
  end

  test "clean-room: no sibling companion deps (THREAD-02 vacuity guard)" do
    deps = Mix.Project.config()[:deps]
    dep_names = Enum.map(deps, fn {name, _} -> name; {name, _, _} -> name end)
    refute :crosswake_sigra in dep_names, "crosswake_threadline must NOT depend on crosswake_sigra"
    refute :crosswake_chimeway in dep_names, "crosswake_threadline must NOT depend on crosswake_chimeway"
  end
end
```

### Pattern 3: `verify_companion_cleanroom.sh` threadline canary

Add a threadline-specific `elif` branch to the canary block (following the chimeway pattern at lines ~307-320):

```bash
$(if [ "$PACKAGE" = "crosswake_threadline" ]; then cat <<'CANARYEOF'

  # threadline-specific: not a Companion behaviour implementor — no enabled?/1, validate_dependency/0
  # The canary proves all three core modules shipped in the tarball without sibling companions.
  test "Threadline.Telemetry.event_names/0 returns 3 request-span events (canary: Telemetry shipped)" do
    events = Crosswake.Threadline.Telemetry.event_names()
    assert is_list(events) and length(events) == 3,
           "Threadline.Telemetry.event_names/0 should return 3 events — Telemetry module may be missing from tarball"
  end

  test "Plug.Threadline.init/1 is callable (canary: Plug shipped)" do
    opts = Crosswake.Plug.Threadline.init([])
    assert opts[:header_name] == "x-crosswake-thread-id"
  end
CANARYEOF
fi)
```

**Critical:** The standard `refute ${COMPANION_MODULE_SUFFIX}.enabled?(%{})` and `validate_dependency/0` assertions in the no-engine smoke test MUST BE SKIPPED for threadline — threadline does NOT implement `Crosswake.Companion` behaviour. Add an `if [ "$PACKAGE" = "crosswake_threadline" ]` guard to suppress the companion-specific assertions.

### Pattern 4: `mix.exs` `companions.test` alias update

Add threadline lines after chimeway (core `mix.exs` lines 73-74):
```elixir
"cmd --cd packages/crosswake_threadline mix deps.get",
"cmd --cd packages/crosswake_threadline mix test"
```

Also update the comment at line 58 to mention `crosswake_threadline`.

### Anti-Patterns to Avoid

- **Using `assert/refute Threadline.enabled?(%{})` in the clean-room smoke test:** Threadline does NOT implement `Crosswake.Companion` — `enabled?/1` does NOT exist. The smoke script's companion-behaviour assertions must be skipped for threadline.
- **Omitting `"priv"` from the package `files:` list:** The EEX templates are the package's primary generator artifact. Without `"priv"` in `files:`, `mix hex.build` will not include the templates and `Application.app_dir(:crosswake_threadline, "priv/...")` will fail at runtime.
- **Leaving `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call in `telemetry.ex:245`:** After extraction, this static reference will cause core compile failure. The fix (expand @baseline_forbidden_keys) is Wave 1 work, atomic with extraction.
- **Leaving `@audit_ledger_support_truth` module attribute calling `ThreadlineTelemetry.*()` in `support_matrix.ex`:** Same compile-failure risk. Convert to `@audit_ledger_support_truth_static` with frozen literals in Wave 1.
- **Adding `crosswake_threadline` to `companion_guard.ex @extracted_companion_names`:** The guard checks for `Crosswake.Companions.*` prefixes (sigra/chimeway modules). Threadline modules are under `Crosswake.Threadline.*`, `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`, `Crosswake.Audit.Ledger` — these are NOT in the companion namespace. The planner should verify whether to add these paths to companion_guard or leave it as-is (the guard only bans `Crosswake.Companions.*` prefixes — threadline doesn't fit that pattern).
- **Blocking test split on phase133:** phase133 uses `Crosswake.Plug.Threadline` to TRIGGER the TELEM-04 Side A proof. Add `{:crosswake_threadline, path: "../../packages/crosswake_threadline", only: :test}` to core `mix.exs` to keep phase133 in core without splitting.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `release-as` cleanup after first publish | Manual edit + PR | `script/strip_release_as.py` (auto, PROOF-03) | Already parametric; add threadline to `release-as-cleanup` job `if:` condition only |
| Clean-room verification | Custom CI steps | `script/verify_companion_cleanroom.sh` (parametric, no-engine mode + threadline canary patch) | Handles poll + throwaway host + doctor; threadline invocation: `bash script/verify_companion_cleanroom.sh crosswake_threadline 0.1.0` |
| Template EEX path resolution fallback | Custom path logic | Existing fallback at `crosswake.gen.audit.ex:26-27` (already written) | The `if File.exists?(schema_template), do: ..., else: File.cwd!()` fallback already handles dev mode |
| Inlining threadline forbidden keys | Custom aggregation mechanism | Expand `@baseline_forbidden_keys` in `telemetry.ex` | Simplest; removes the static dep with no behavior change (all 20 keys end up in the set) |
| Thread-safety in clean-room ExUnit test | `async: false` | `async: true` (threadline has no Application env mutation) | Threadline is NOT a `:companions` registrant; no `put_env` needed; unlike chimeway/sigra, threadline tests can run `async: true` |

## Runtime State Inventory

> Threadline extraction is a source-move + CI-registration operation, not a rename/rebrand.
> Runtime state inventory for rename triggers does not apply.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — threadline thread_id state lives in host Logger.metadata (process-local); audit records live in host Ecto schema (host-owned, not in crosswake package) | None |
| Live service config | None — threadline is registered via Phoenix router plug + LiveView on_mount; after extraction, host switches dep from core to `crosswake_threadline` package | None (host config update is adopter-side; host imports from the same module path) |
| OS-registered state | None | None |
| Secrets/env vars | `HEX_API_KEY` CI secret (already present for sigra/chimeway) | None — same key reused |
| Build artifacts | `lib/crosswake/threadline/`, `lib/crosswake/plug/threadline.ex`, `lib/crosswake/live/threadline.ex`, `lib/crosswake/audit/ledger.ex`, `lib/mix/tasks/crosswake.*.ex`, `priv/templates/crosswake/audit/` — in-tree files removed from core | Removing from core, adding to package |

## Common Pitfalls

### Pitfall 1: Clean-room smoke test using companion-behaviour assertions (enabled?/validate_dependency)
**What goes wrong:** `verify_companion_cleanroom.sh` no-engine smoke test asserts `validate_dependency() == :ok` and `enabled?(%{})` — but threadline does NOT implement `Crosswake.Companion` behaviour. These functions do not exist on any threadline module. The clean-room CI job will fail with `UndefinedFunctionError`.
**Why it happens:** The script was written for companions (rulestead/rindle/sigra/chimeway). Threadline is the first non-companion extraction.
**How to avoid:** Add `if [ "$PACKAGE" = "crosswake_threadline" ]` guard to SKIP the companion-behaviour assertions block and substitute the threadline-specific canary (Telemetry.event_names/0 == 3, Plug.Threadline.init([]) returns opts).
**Warning signs:** `clean-room-proof-threadline` fails with `UndefinedFunctionError` on `validate_dependency/0` or `enabled?/1`.

### Pitfall 2: Forgetting `"priv"` in the package `files:` allowlist
**What goes wrong:** `mix hex.build` excludes `priv/` from the tarball. `Application.app_dir(:crosswake_threadline, "priv/templates/...")` returns a path to a non-existent directory at runtime. `mix crosswake.gen.audit` falls back to `File.cwd!()` (the fallback at lines 26-27) — which works locally but not after Hex publish (the package is in `_build`, not the working directory).
**Why it happens:** Every other companion package uses `files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)` (no priv). Planner copies that verbatim.
**How to avoid:** Explicitly add `"priv"` to threadline's `files:` list. Verify with `mix hex.build --unpack` that `priv/templates/crosswake/audit/` appears in the tarball.
**Warning signs:** `Application.app_dir(:crosswake_threadline, "priv/...")` returns a path that `File.exists?/1` returns false for; the fallback to `File.cwd!()` path also fails (not in the package `lib/` at Hex runtime).

### Pitfall 3: Leaving core compile-time Threadline references (causes compile failure after move)
**What goes wrong:** If `lib/crosswake/support_matrix/support_matrix.ex:16` still has `alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry` and `lib/crosswake/telemetry.ex:245` still calls `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` after the threadline source files move to the package, core `mix compile` fails with `module not found: Crosswake.Threadline.Telemetry`.
**Why it happens:** These were intentionally left as "Threadline stays in-tree for Phase 136" (telemetry.ex:235-237 comment). They must be fixed atomically with extraction.
**How to avoid:** Include the 2 decoupling changes in Wave 1 of Phase 139, in the SAME commit as the source move. The test gate (Wave 1 artifact: `mix compile --warnings-as-errors` from repo root) catches this immediately.
**Warning signs:** Core `mix compile` fails with `(CompileError) module not found: Crosswake.Threadline.Telemetry`.

### Pitfall 4: `release-as` one-shot footgun (same as sigra/chimeway)
**What goes wrong:** `release-as: "0.1.0"` permanently overrides subsequent releases if not stripped.
**Why it happens:** release-please treats `release-as` as a permanent override.
**How to avoid:** Wire `threadline_release_created` to the `release-as-cleanup` job's `if:` condition. The `release-as-cleanup` job will auto-strip it (PROOF-03).

### Pitfall 5: Vacuous clean-room proof (no sibling deps to assert absence of)
**What goes wrong:** The threadline clean-room ExUnit test asserts `refute :crosswake_sigra in dep_names` — but if the test runs inside a CI environment where `crosswake_sigra` IS available (e.g., from a different matrix lane), the test passes vacuously.
**Why it happens:** The clean-room lane installs only `crosswake + crosswake_threadline` but the ExUnit assertion checks `Mix.Project.config()[:deps]` which only reflects the package's own mix.exs, not the full resolution tree. This means the assertion is ALWAYS correct (threadline's mix.exs will never list sigra/chimeway).
**How to avoid:** The vacuity guard is structural (the mix.exs dep list check is correct). The CI-level vacuity guard is enforced by the clean-room lane NOT installing sigra/chimeway.

### Pitfall 6: phase133 TELEM-04 test breaks after Plug.Threadline moves
**What goes wrong:** `test/crosswake/proof/phase133_telemetry_contract_test.exs` calls `Crosswake.Plug.Threadline.init([])` and `call/2` to trigger the threadline telemetry event. After extraction, `Crosswake.Plug.Threadline` is no longer compiled into core, so phase133 fails with `module not found`.
**Why it happens:** phase133 is a CORE test proving CORE's telemetry catalog (TELEM-04). It uses Plug.Threadline as a trigger.
**How to avoid:** Add `{:crosswake_threadline, path: "../../packages/crosswake_threadline", only: :test}` to CORE's `mix.exs` deps. This gives the core test suite access to the package without shipping a production dep. Same pattern as chimeway added sigra as a test-only dep.
**Warning signs:** Core `mix test` fails with `(UndefinedFunctionError) function Crosswake.Plug.Threadline.init/1 is undefined`.

## Code Examples

### gen.audit.ex — after app_dir fix

```elixir
# Source: lib/mix/tasks/crosswake.gen.audit.ex:23-27 (BEFORE fix)
schema_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/ledger.ex.eex")
migration_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/migration.exs.eex")

# AFTER fix (THREAD-01):
schema_template = Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/ledger.ex.eex")
migration_template = Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/migration.exs.eex")
```

### support_matrix.ex — @audit_ledger_support_truth_static conversion

```elixir
# BEFORE (compile dep, in @audit_ledger_support_truth MODULE ATTRIBUTE):
alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry  # ← REMOVE
@audit_ledger_support_truth [                                    # ← RENAME to _static + freeze
  %{
    telemetry: %{
      event_names: ThreadlineTelemetry.event_names(),           # ← freeze as literal
      metadata_keys: ThreadlineTelemetry.metadata_keys(),       # ← freeze as literal
      forbidden_metadata_keys: ThreadlineTelemetry.forbidden_metadata_keys()  # ← freeze as literal
    },
    ...
  }
]

# AFTER (frozen literals, no compile dep):
# Remove: alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
@audit_ledger_support_truth_static %{
  telemetry: %{
    status: :shipped,
    # Frozen from Crosswake.Threadline.Telemetry — compile dep removed Phase 139.
    event_names: [
      [:crosswake, :threadline, :request, :start],
      [:crosswake, :threadline, :request, :stop],
      [:crosswake, :threadline, :request, :exception]
    ],
    metadata_keys: [:thread_id, :correlation_id, :route_id, :source],
    forbidden_metadata_keys: [
      :access_token, :actor_id, :actor_ref, :authorization_code, :credential_id,
      :device_id, :email, :id_token, :ip, :nonce, :org_id, :passkey_credential_id,
      :pkce_verifier, :provider_payload, :raw_return_to, :refresh_token, :return_to,
      :session_ref, :subject_ref, :user_agent
    ]
  },
  ...
}
def audit_ledger_support_truth, do: [@audit_ledger_support_truth_static]
```

### telemetry.ex — @baseline_forbidden_keys expansion

```elixir
# BEFORE (10 keys):
@baseline_forbidden_keys [
  :access_token, :refresh_token, :id_token, :authorization_code, :token,
  :session_ref, :subject_ref, :actor_id, :ip, :email
]
# ...line 245:
MapSet.new(Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++ companion_forbidden_keys)

# AFTER (21 keys — absorbs threadline's unique 11 keys; removes static Threadline.Telemetry dep):
@baseline_forbidden_keys [
  # auth tokens (core baseline)
  :access_token, :refresh_token, :id_token, :authorization_code, :token,
  # identity anchors (core baseline)
  :session_ref, :subject_ref, :actor_id,
  # direct PII (core baseline)
  :ip, :email,
  # auth-flow and identity fields (absorbed from Threadline.Telemetry — Phase 139)
  :actor_ref, :credential_id, :device_id, :nonce, :org_id,
  :passkey_credential_id, :pkce_verifier, :provider_payload,
  :raw_return_to, :return_to, :user_agent
]
# Remove the comment "Threadline stays in-tree for Phase 136 — its keys are included directly."
# ...line 244-245 becomes:
MapSet.new(@baseline_forbidden_keys ++ companion_forbidden_keys)
```

### Test split: support_matrix_test.exs (after frozen literals)

```elixir
# BEFORE (calls Crosswake.Threadline.Telemetry module):
test "entry telemetry.forbidden_metadata_keys matches Crosswake.Threadline.Telemetry" do
  alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  assert entry.telemetry.forbidden_metadata_keys == ThreadlineTelemetry.forbidden_metadata_keys()
end

# AFTER (literal comparison — stays in CORE; no module dep):
test "entry telemetry.forbidden_metadata_keys is the frozen 20-key threadline denylist (Phase 139)" do
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  # Values frozen from Crosswake.Threadline.Telemetry in Phase 139 extraction.
  assert :actor_ref in entry.telemetry.forbidden_metadata_keys
  assert :access_token in entry.telemetry.forbidden_metadata_keys
  assert length(entry.telemetry.forbidden_metadata_keys) == 20
end
```

## Test Split Table (THREAD-01)

[VERIFIED: test file inventory, 2026-07-02]

| File | Classification | Lane |
|------|---------------|------|
| `test/crosswake/threadline/id_test.exs` | Threadline-internal | MOVE → package |
| `test/crosswake/threadline/telemetry_test.exs` | Threadline-internal | MOVE → package |
| `test/crosswake/plug/threadline_test.exs` | Threadline-internal | MOVE → package |
| `test/crosswake/live/threadline_test.exs` | Threadline-internal | MOVE → package |
| `test/crosswake/audit/ledger_test.exs` | Threadline-internal | MOVE → package |
| `test/mix/tasks/crosswake.gen.audit_test.exs` | Threadline-internal | MOVE → package |
| `test/mix/tasks/crosswake.threadline_test.exs` | Threadline-internal | MOVE → package |
| `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | References `Crosswake.Threadline.Telemetry` directly | MOVE → package |
| `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | References `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`, `Crosswake.Threadline.Telemetry` | MOVE → package |
| `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | References `Crosswake.Plug.Threadline`, `Crosswake.Threadline.Telemetry` | MOVE → package |
| `test/crosswake/doctor/doctor_threadline_test.exs` | Tests `Doctor.run/1` (core) — doctor checks for threadline config | STAY in core |
| `test/crosswake/proof/phase133_telemetry_contract_test.exs` | Tests CORE `Crosswake.Telemetry` catalog; uses `Plug.Threadline` as event trigger | STAY in core, add test-only path dep `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` |
| `test/crosswake/support_matrix/support_matrix_test.exs` (threadline entries lines 259-329) | Tests `SupportMatrix.audit_ledger_support_truth/0` (core function) — update assertions to use frozen literals | STAY in core (update assertions) |
| `test/crosswake/telemetry_test.exs` (threadline atom refs) | Uses only threadline event-name atom lists, not module | STAY in core |

## Recommended Wave Structure (4 Waves — Mirror Phase 138)

### Wave 1: Extraction + Core Decoupling (atomic)
- Scaffold `packages/crosswake_threadline/` (mix.exs with `priv` in files:, config.exs, README, CHANGELOG, LICENSE, test_helper.exs)
- Move all 7 source files + 2 EEX templates (preserving namespace — non-breaking)
- Fix `Application.app_dir(:crosswake → :crosswake_threadline)` in gen.audit.ex
- Convert `@audit_ledger_support_truth` → `@audit_ledger_support_truth_static` (remove ThreadlineTelemetry alias from support_matrix.ex)
- Expand `@baseline_forbidden_keys` in telemetry.ex + remove `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call
- Add `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` to CORE `mix.exs` (fixes phase133)
- Add crosswake_threadline path dep to `examples/phoenix_host/mix.exs`
- Move test files (all MOVE classifications from Test Split Table)
- Update support_matrix_test.exs frozen-literal assertions
- Remove `Crosswake.Threadline.Telemetry` from core `mix.exs` ExDoc docs grouping
- **Gate: `mix compile --warnings-as-errors` (repo root) + `cd packages/crosswake_threadline && mix test`**

### Wave 2: Telemetry Handler Hardening + Clean-Room Proof
- Add `try/rescue` pattern to gen.audit EEX template (the generated audit handler)
- Write `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs`
- Verify `Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0` count == 20 (canary)
- Verify `Plug.Threadline.init([])` API contract in package tests
- Add `StubThreadlineAbsentCompanion` ONLY IF doctor.ex needs one for threadline-absent stub testing (check: does doctor_threadline_test need a stub companion or does it use `Application.get_env(:crosswake, :audit_ledger, nil)` directly? If stub not needed, skip this)
- **Gate: `cd packages/crosswake_threadline && mix test` + core suite `mix test --exclude requires_example_host`**

### Wave 3: release-please + Clean-Room CI + Compat Matrix
- `script/verify_companion_cleanroom.sh` — add threadline-specific canary; suppress companion-behaviour assertions for threadline
- `release-please-config.json` — add threadline component block (clone chimeway, `release-as: "0.1.0"`)
- `.release-please-manifest.json` — add `"packages/crosswake_threadline": "0.1.0"`
- `.github/workflows/release-please.yml` — add outputs + `publish-hex-threadline` + `clean-room-proof-threadline` + cleanup/alert patches
- `mix.exs` `companions.test` alias — add threadline lines
- `guides/companion_compatibility.md` — add threadline row
- **Gate: CI green on all new jobs + clean-room proof job visible in YAML diff**

### Wave 4: Human-Gated Deferred Publish (autonomous: false)
- Pre-publish gates: path-dep dress rehearsal (Waves 1-3 already green) + `hex.publish --dry-run` + clean-room lane (no sigra, no chimeway)
- HUMAN go/no-go: merge threadline Release PR (irreversible Hex publish fires)
- Auto: post-publish clean-room from Hex, release-as cleanup PR
- HUMAN: merge cleanup PR
- **This wave is `autonomous: false` — mirrors Phase 138 Wave 4 exactly**

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Threadline compiled into core, `@audit_ledger_support_truth` calling `ThreadlineTelemetry.*()` at compile time | Standalone `crosswake_threadline` Hex package; `@audit_ledger_support_truth_static` with frozen literal values | Phase 139 | Core compiles without threadline present |
| `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` called in `attach_default_logger/1` (static ref) | Expanded `@baseline_forbidden_keys` (21 keys); companion forbidden keys via registry; no Threadline module call | Phase 139 | Core telemetry fully decoupled from threadline |
| `mix crosswake.gen.audit` resolves templates via `Application.app_dir(:crosswake, ...)` | `Application.app_dir(:crosswake_threadline, ...)` | Phase 139 | Templates correctly resolved from crosswake_threadline package |

**No deprecated patterns introduced:** Threadline extraction requires NO Finding-boundary refactor (sigra-specific), NO auth dispatch decoupling (chimeway has none either), and NO Companion behaviour implementation (threadline was never a companion). The 4-wave structure is the minimum necessary.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The audit handler `try/rescue` pattern (THREAD-02) applies to the HOST-OWNED generated handler, not to existing threadline source files | THREAD-02 / Architecture Patterns | If THREAD-02 requires a try/rescue in threadline source itself (not the generated template), a different code change is needed |
| A2 | `StubThreadlineAbsentCompanion` is NOT needed — doctor_threadline_test.exs uses `Application.get_env(:crosswake, :audit_ledger)` directly, not a stub companion | Test Split Table | If doctor tests need a stub companion representing "threadline absent", planner must add `StubThreadlineAbsentCompanion` beside the existing absent stubs |
| A3 | phase92 (`phase92_server_propagation_closeout_test.exs`) can move entirely to the threadline package test suite without losing any CORE proof coverage | Test Split Table | If phase92 also tests core capabilities beyond threadline, a partial split is needed |
| A4 | `verify_companion_cleanroom.sh` does not have other threadline-specific assertions beyond the new canary | Architecture Patterns — Pitfall 1 | Planner should read the script before patching to ensure no pre-existing threadline assertions conflict |
| A5 | The expanded `@baseline_forbidden_keys` (21 keys) does not break any existing test that asserts `baseline_forbidden_metadata_keys/0 == exact list of 10` | telemetry.ex decoupling | If a test freezes the baseline list as 10 keys, adding 11 more will fail that test. Planner must search for `baseline_forbidden_metadata_keys` assertions before expanding |

## Open Questions

1. **Does `doctor_threadline_test.exs` need a `StubThreadlineAbsentCompanion`?**
   - What we know: doctor_threadline_test.exs tests Doctor.run/1 with threadline posture checks (plug missing, ledger not configured). These checks read `Application.get_env(:crosswake, :audit_ledger)` and inspect host files — no companion registry needed.
   - What's unclear: Whether any doctor_threadline test puts a stub companion in the `:companions` env to simulate "threadline package absent".
   - Recommendation: Planner reads doctor_threadline_test.exs line by line before deciding.

2. **Does `Crosswake.Telemetry.forbidden_metadata_keys/0` exist as a public API?**
   - What we know: The chimeway clean-room proof (138-PATTERNS.md) assumes `Crosswake.Telemetry.forbidden_metadata_keys/0` is callable. Phase 139's cleanroom test does NOT use this (threadline is not a `:companions` registrant).
   - What's unclear: Whether expanding the baseline changes any public API contract tests.
   - Recommendation: Planner greps for `forbidden_metadata_keys` assertions in telemetry_test.exs and phase133 before expanding the baseline.

3. **Should `companion_guard.ex` be extended to ban `Crosswake.Threadline.*` static refs in core?**
   - What we know: `@extracted_companion_names` currently covers `Crosswake.Companions.{Rulestead,Rindle,Sigra,Chimeway}`. Threadline uses non-companion namespaces.
   - What's unclear: Whether to add threadline paths to companion_guard or rely on compile failures as the guard.
   - Recommendation: Since threadline paths do not follow the `Crosswake.Companions.*` prefix pattern, companion_guard cannot easily cover them. The two explicit decoupling changes (support_matrix + telemetry) are the structural guards. A grep CI step can enforce no-Threadline refs in core after extraction.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All build steps | ✓ | 1.19+ (per .tool-versions) | — |
| Hex CLI | `hex.publish` | ✓ | In CI via erlef/setup-beam | — |
| `HEX_API_KEY` secret | `hex.publish` | Expected ✓ | CI secret (used by rulestead/rindle/sigra/chimeway) | — |
| `RELEASE_PLEASE_TOKEN` secret | Release PR + cleanup PR CI trigger | Expected ✓ | CI secret (existing) | `github.token` (but won't chain-trigger CI on cleanup PR) |
| `packages/crosswake_sigra/` | NONE (threadline has no sibling dep) | ✓ | Path dep (local) | N/A |
| `packages/crosswake_chimeway/` | NONE (threadline has no sibling dep) | ✓ | Path dep (local) | N/A |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** `RELEASE_PLEASE_TOKEN` → can use `github.token` but cleanup PRs won't trigger CI automatically.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `packages/crosswake_threadline/test/test_helper.exs` (create in Wave 0) |
| Quick run command | `cd packages/crosswake_threadline && mix test` |
| Full suite command | `mix test --exclude requires_example_host && cd packages/crosswake_threadline && mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| THREAD-01 | All source modules compile in package context | compile | `cd packages/crosswake_threadline && mix compile --warnings-as-errors` | ❌ Wave 0 — package does not exist yet |
| THREAD-01 | Moved tests pass in package lane | unit | `cd packages/crosswake_threadline && mix test` | ❌ Wave 0 |
| THREAD-01 | No Crosswake.Threadline.* refs remain in core lib/ | structural | `grep -r "Crosswake\.Threadline\|Crosswake\.Plug\.Threadline\|Crosswake\.Live\.Threadline\|Crosswake\.Audit\.Ledger" lib/ && echo FAIL \|\| echo CLEAN` | Runs inline |
| THREAD-01 | app_dir(:crosswake_threadline) used in gen.audit.ex | structural | `grep "app_dir(:crosswake_threadline" packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | ❌ Wave 0 |
| THREAD-01 | priv/ templates included in Hex tarball | structural | `cd packages/crosswake_threadline && mix hex.build --unpack` then check for priv/templates/ | CI-only |
| THREAD-02 | No Sigra.*/Chimeway.* refs in threadline package | structural | `grep -rn "Crosswake\.Companions\.Sigra\|crosswake_sigra\|Crosswake\.Companions\.Chimeway\|crosswake_chimeway" packages/crosswake_threadline/lib/ && echo FAIL \|\| echo CLEAN` | Runs inline |
| THREAD-02 | crosswake_threadline mix.exs lists NO sibling companions | structural | `grep "crosswake_sigra\|crosswake_chimeway" packages/crosswake_threadline/mix.exs && echo FAIL \|\| echo CLEAN` | Runs inline |
| THREAD-02 | audit handler try/rescue pattern in gen.audit EEX template | structural | `grep "try\|rescue" packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex` | ❌ Wave 2 |
| THREAD-02 | Clean-room: Telemetry/Plug/Ledger modules ship in tarball | integration | `cd packages/crosswake_threadline && mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | ❌ Wave 2 |
| THREAD-03 | path-dep dress rehearsal passes mix test | integration | `CROSSWAKE_RELEASE=0 cd packages/crosswake_threadline && mix test` | ❌ Wave 0 |
| THREAD-03 | hex.publish --dry-run succeeds | CI | `CROSSWAKE_RELEASE=1 mix hex.publish --dry-run --yes` | CI-only |
| THREAD-03 | release-please component registered, NOT in linked-versions | structural | Verify release-please-config.json NOT in linked-versions group | Manual |
| THREAD-03 | clean-room lane installs NO sigra, NO chimeway | CI | CI lane invocation: `bash script/verify_companion_cleanroom.sh crosswake_threadline <version>` | CI-only |

### Backstop Tests

1. **Non-vacuous clean-room ExUnit proof** — `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs`
   - Asserts: `Telemetry.event_names/0 == 3`, `Plug.Threadline.init([])` OK, `Audit.Ledger.actor_ref/2` returns 64-char hex
   - Vacuity guard: `refute :crosswake_sigra in dep_names`, `refute :crosswake_chimeway in dep_names`

2. **No-sibling-dep structural guard** — inline grep
   - `grep -rn "Crosswake\.Companions\.Sigra\|crosswake_sigra\|Crosswake\.Companions\.Chimeway\|crosswake_chimeway" packages/crosswake_threadline/lib/ && echo FAIL || echo CLEAN`
   - Run as part of Wave 1 commit gate

3. **Core compile stays green after decoupling** — `mix compile --warnings-as-errors` from repo root
   - Proves support_matrix.ex and telemetry.ex decoupling succeeded
   - Run as Wave 1 commit gate

4. **Baseline forbidden keys count** — in `test/crosswake/telemetry_test.exs` (or new inline assertion)
   - After expanding `@baseline_forbidden_keys` from 10 to 21, any existing test asserting `length == 10` must be updated to 21

### Sampling Rate

- **Per task commit:** `cd packages/crosswake_threadline && mix test && mix compile --warnings-as-errors`
- **Per wave merge:** Full core suite + threadline lane: `mix test --exclude requires_example_host && cd packages/crosswake_threadline && mix test`
- **Phase gate:** Full suite green + clean-room proof green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `packages/crosswake_threadline/` directory skeleton (mix.exs, mix.lock, config/config.exs, README.md, CHANGELOG.md, LICENSE)
- [ ] `packages/crosswake_threadline/test/test_helper.exs` — `ExUnit.start(exclude: [:requires_example_host, :advisory_only])`
- [ ] `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` — non-vacuous clean-room ExUnit proof (Wave 2, but plan in Wave 0)
- [ ] Framework install: `cd packages/crosswake_threadline && mix deps.get` (after mix.exs is written)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No (threadline is audit/correlation; auth is sigra's domain) | — |
| V3 Session Management | No (threadline propagates thread_id, not session credentials) | — |
| V4 Access Control | No (threadline is an observer; it does not make access decisions) | — |
| V5 Input Validation | Yes | `Threadline.Telemetry.metadata/1` allowlist filters: only 4 keys pass, `safe_value?/1` bounds binary size to 128 chars |
| V6 Cryptography | Yes | `Audit.Ledger.actor_ref/2` uses `:crypto.mac(:hmac, :sha256)` — standard OTP, not hand-rolled |

### Known Threat Patterns for threadline extraction

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII leak via telemetry metadata (thread_id context) | Information Disclosure | `@forbidden_metadata_keys` 20-key denylist in `Threadline.Telemetry.metadata/1` — scrubs before emit |
| Audit handler raise → telemetry auto-detach → silent audit blackout | Repudiation | `try/rescue` in generated audit handler template (THREAD-02); log error, do NOT reraise |
| `actor_ref` HMAC secret not configured → `ArgumentError` at runtime | Denial of Service | `Audit.Ledger.actor_ref/2` raises explicitly: "Missing audit HMAC secret" — fails loud, not silent |
| Binary oversized value bypassing metadata filter | Tampering | `safe_value?/1` at `Threadline.Telemetry:150` bounds binaries to 128 chars [VERIFIED: live code] |
| `@baseline_forbidden_keys` expansion breaking existing contract tests | Tampering (unintended weakening via test failures) | Planner must audit `baseline_forbidden_metadata_keys/0` assertion counts before expanding |
| Release-as permanent override re-publishing stale version | Tampering (supply chain) | PROOF-03 auto-cleanup; `release-as-staleness-gate.yml` |

## Sources

### Primary (HIGH confidence)

- Live code reads: `lib/crosswake/threadline/id.ex`, `lib/crosswake/threadline/telemetry.ex`, `lib/crosswake/plug/threadline.ex`, `lib/crosswake/live/threadline.ex`, `lib/crosswake/audit/ledger.ex` — all threadline source files
- Live code reads: `lib/mix/tasks/crosswake.gen.audit.ex`, `lib/mix/tasks/crosswake.threadline.ex` — threadline mix tasks
- Live code grep: zero `Sigra.*` or `Chimeway.*` references in threadline source (THREAD-02 linchpin VERIFIED)
- Live code read: `lib/crosswake/support_matrix/support_matrix.ex:16,285-300` — `@audit_ledger_support_truth` module attribute compile dep (VERIFIED: stale-beam trap)
- Live code read: `lib/crosswake/telemetry.ex:235-245` — static `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call (VERIFIED)
- Live code read: `lib/crosswake/doctor/doctor.ex:881-1082` — string-based checks only, no compile dep (VERIFIED)
- Live code read: `lib/crosswake/companion_guard.ex` — `@extracted_companion_names` confirmed to NOT include threadline yet
- Live filesystem: `priv/templates/crosswake/audit/` — 2 EEX template files confirmed present
- Test file inventory: all 21 test files referencing Threadline/Ledger identified and classified
- `.planning/phases/138-crosswake-chimeway-extraction/138-RESEARCH.md` — companion extraction pattern template
- `.planning/phases/138-crosswake-chimeway-extraction/138-PATTERNS.md` — file classification and analog patterns
- `packages/crosswake_chimeway/mix.exs` — exact package structure template verified live
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml` — chimeway blocks read verbatim for threadline analog

### Secondary (MEDIUM confidence)

- `.planning/research/v17-companion-family-completion.md` — D-1..D-9 design spine; D-7 is threadline-specific authoritative decision record
- `.planning/ROADMAP.md` — Phase 139 success criteria (5 criteria confirmed, all traceable to research findings)

### Tertiary (LOW confidence)

- A1-A5 in Assumptions Log — inferred from pattern/precedent, not directly verified in this session

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; patterns directly read from live chimeway/sigra packages and CI files
- Zero-sibling-dep verification: HIGH — confirmed by live grep across all 7 threadline source files
- Core coupling sites: HIGH — both sites directly read from live source with exact line numbers
- Architecture: HIGH — all source files read; test files enumerated and classified; CI patterns verified
- priv/ template requirement: HIGH — live filesystem + mix.exs `files:` pattern gap confirmed
- wave structure: HIGH — mirrors Phase 138 exactly (4 waves, human-gated wave 4)
- Pitfalls: HIGH — verify_companion_cleanroom.sh assumption is VERIFIED (no enabled?/0 in threadline); priv/ gap is VERIFIED against live mix.exs

**Research date:** 2026-07-02
**Valid until:** 2026-08-01 (stable Elixir ecosystem; code drift is the main risk after Phase 138 wave 4 publishes chimeway)
