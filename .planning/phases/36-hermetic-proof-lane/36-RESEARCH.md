# Phase 36: Hermetic Proof Lane - Research

**Researched:** 2026-05-29
**Domain:** ExUnit hermetic proof test; Elixir entitlement projection; mock paywall corridor
**Confidence:** HIGH — all findings verified against actual shipped source files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Reach real projection code via `Code.require_file` the three pure example-host commerce modules at module scope (mirrors phase21/34 idiom). Required files (relative to `__DIR__`): `reconciliation_keys.ex`, `reconciliation_inbox.ex`, `entitlement_projection.ex`, and `mock_backend.ex`.
- **D-02 (SC#4 REINTERPRETATION):** "No Code.require_file on example-host paths" means no runtime/server paths (`*_live.ex`, `endpoint.ex`, `application.ex`, `router.ex`, `repo.ex`, `*_web.ex`). Loading the four pure commerce modules IS the hermetic idiom, NOT a violation.
- **D-03:** Self-scan guard reads `File.read!(__ENV__.file)` and asserts no runtime-path require_file substrings and no process-start/server tokens.
- **D-04:** All four `derived_state/1` outcomes asserted distinctly from inline-built snapshots.
- **D-05:** The `:pending` → `:granted` transition modeled via: (1) ingest_evidence/2 → status :awaiting_verification, (2) explicit derived_state on :awaiting_verification snapshot, (3) MockBackend.build_verified_snapshot/2 → project_snapshot/2 → derived_state == :granted.
- **D-06 (SC#3 REINTERPRETATION):** The mock-boundary fence asserts the three real truths: (1) authority_mutation_allowed_from_evidence?/1 returns false, (2) project_snapshot(nil, unverified) returns {:error, :unverified_reconciliation_outcome}, (3) verified-but-not-refreshed snapshot does NOT derive :granted.
- **D-07:** Phase34-prefixed inline helper modules (e.g. `Phase34PaywallCorridorSnapshots`) — NOT Code.require_file of the phase21 test file.
- **D-08:** `use ExUnit.Case, async: false`; no `@moduletag :requires_example_host` (untagged — merge-blocking).
- **D-09:** No CI changes expected; untagged file at `test/crosswake/proof/` is auto-discovered by `phase34-proof.yml` hermetic job glob.

### Claude's Discretion

- Exact inline evidence field values (`provider_reference`, `evidence_ref`, `captured_at`) — must be `provider: "mock"`, `source: :storefront`, produce `status: :awaiting_verification` from ingest_evidence/2.
- Concrete `group_id` (anchor to `@subscription_entry_id "sub_pro_monthly"`).
- Exact regex/substring set for the self-scan guard (D-03).
- Whether `:denied` snapshot uses `access.decision: :denied` or another non-granting lane combination.
- Test/describe block naming and assertion message wording.

### Deferred Ideas (OUT OF SCOPE)

- ROADMAP SC#3/SC#4 rewording (verifier task).
- `guides/commerce.md` walkthrough — Phase 37.
- StoreKit/Play Billing real adapters — v3.6.
- ExDoc zero-warnings cleanup (HEX-03).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Merge-blocking hermetic ExUnit proof drives full lane (mock purchase → ingest_evidence/2 → project_snapshot/2 → derived_state/1), no network or native SDK, all four states + :pending → :granted transition | Verified: all three called modules are pure functions reachable via Code.require_file; derived_state/1 precedence confirmed; ingest_evidence/2 and build_verified_snapshot/2 signatures confirmed |
| PROOF-03 | Proof asserts mock evidence can never directly grant entitlement authority — mock-boundary fence anchored on authority_mutation_allowed_from_evidence?/1 returning false | Verified: lib/reconciliation.ex:142 returns false unconditionally; project_snapshot/2 rejects unverified state with {:error, :unverified_reconciliation_outcome}; resolved_reconciliation? accepts only :projection_refreshed |
</phase_requirements>

---

## Summary

Phase 36 delivers a single ExUnit file: `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`. It is the merge-blocking hermetic proof for the v3.4 paywall corridor. All shipped code it asserts against (four example-host modules, one lib module) has been read and verified. The CONTEXT reinterpretations in D-02 and D-06 are factually correct against the shipped source — no alignment failures found.

The proof mirrors the established `phase34_mock_storefront_test.exs` idiom: `Code.require_file` four pure example-host commerce modules at module scope, `async: false`, untagged. The key new additions vs prior proof files are: (1) loading `mock_backend.ex` to call `build_verified_snapshot/2` directly, (2) driving `project_snapshot/2` and `derived_state/1` through the full pipeline, and (3) a D-03-style self-scan hermeticity guard (precedent: `phase23_commerce_support_proof_test.exs` and `phase33_commerce_corridor_routes_test.exs`).

The `phase34-proof.yml` CI job already globs `test/crosswake/proof/` with `mix test --exclude requires_example_host`. The new untagged file is auto-discovered. Zero CI changes are required.

**Primary recommendation:** One wave, one plan — the file has no blockers; all dependencies are shipped/locked and verified. The planner should specify the inline helper structures at the level of field-by-field values so the implementer cannot construct a vacuously-passing snapshot (the primary assertion risk).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Four-state coverage (SC#1) | Test — inline snapshot builders | — | derived_state/1 is pure; inline construction is the only tier |
| :pending → :granted transition (SC#2) | Test — ReconciliationInbox (example-host) + MockBackend | — | ingest_evidence/2 and build_verified_snapshot/2 are pure functions; no server tier involved |
| Mock-boundary fence (SC#3/PROOF-03) | Test — shipped lib (authority_mutation_allowed_from_evidence?/1) | Test — EntitlementProjection | lib function is in compilation path; no require_file needed |
| Hermeticity self-scan (SC#4) | Test — self-referential `File.read!(__ENV__.file)` guard | — | Structural enforcement: guard reads proof's own source |
| CI lane (SC#5) | CI — phase34-proof.yml merge-blocking job | — | `mix test --exclude requires_example_host` auto-discovers untagged file |

---

## Standard Stack

No external packages are installed. This phase uses only:

| Library | Source | Purpose |
|---------|--------|---------|
| ExUnit | Elixir stdlib | Test framework |
| `Crosswake.Commerce.Reconciliation` | `lib/crosswake/commerce/reconciliation.ex` | Fence anchor: `authority_mutation_allowed_from_evidence?/1` |
| `Crosswake.Commerce.Contracts` | `lib/crosswake/commerce/contracts.ex` | Struct construction for `ReconciliationEvidence`, `EntitlementSnapshot` |
| `CrosswakeExample.Commerce.ReconciliationKeys` | `examples/phoenix_host/...` via Code.require_file | Required by ReconciliationInbox at runtime |
| `CrosswakeExample.Commerce.ReconciliationInbox` | `examples/phoenix_host/...` via Code.require_file | `ingest_evidence/2` — the :pending origin |
| `CrosswakeExample.Commerce.EntitlementProjection` | `examples/phoenix_host/...` via Code.require_file | `project_snapshot/2`, `derived_state/1` |
| `CrosswakeExample.Commerce.MockBackend` | `examples/phoenix_host/...` via Code.require_file | `build_verified_snapshot/2` — the honest :granted source |

**No Package Legitimacy Audit required** — zero new dependencies are installed.

---

## Architecture Patterns

### System Architecture Diagram

```
[Inline Evidence builder]
    |
    v
ReconciliationInbox.ingest_evidence/2
    |  --> returns {:ok, %{status: :awaiting_verification, ...}}
    |
    v
[Inline pending snapshot builder]
EntitlementProjection.derived_state/1 --> assert :pending
    |
    v
MockBackend.build_verified_snapshot/2
    |  --> returns %EntitlementSnapshot{reconciliation.state: :projection_refreshed, ...}
    |
    v
EntitlementProjection.project_snapshot(nil, verified)
    |  --> {:ok, projected}
    |
    v
EntitlementProjection.derived_state/1 --> assert :granted

[Parallel fence branch]
Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1 --> assert false
EntitlementProjection.project_snapshot(nil, unverified) --> assert {:error, :unverified_reconciliation_outcome}
[verified-but-not-refreshed snapshot] --> derived_state/1 --> assert != :granted
```

### Recommended Project Structure

```
test/crosswake/proof/
└── phase34_paywall_corridor_proof_test.exs   # new — the single deliverable
```

All other files (four Code.require_file'd modules, CI workflow, lib modules) are SHIPPED/locked. Nothing else changes.

### Pattern: Code.require_file header (hermetic idiom)

Source: `test/crosswake/proof/phase34_mock_storefront_test.exs` lines 1-3. [VERIFIED: read file directly]

The new proof must require the modules in dependency order (ReconciliationKeys is required by ReconciliationInbox; EntitlementProjection is required by MockBackend at runtime but not at compile time):

```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
```

**Important difference from phase34_mock_storefront_test.exs:** That test required `reconciliation_keys.ex`, `reconciliation_inbox.ex`, `mock_storefront.ex`. The new proof drops `mock_storefront.ex` and adds `entitlement_projection.ex` + `mock_backend.ex`. Requiring `entitlement_projection.ex` before `mock_backend.ex` ensures the alias expansion in MockBackend resolves correctly at load time (though function calls are runtime dispatch in Elixir, loading order is still best practice). [VERIFIED: confirmed alias usage in mock_backend.ex line 38]

**Why NOT require mock_storefront.ex:** The new proof constructs evidence inline using the Contracts struct directly (with `provider: "mock"`, `source: :storefront`) rather than calling `MockStorefront.simulate_purchase/1`. This is a deliberate design choice per CONTEXT D-05.1 — the inline struct is the minimal provable input.

### Pattern: Module header and `async: false`

Source: `test/crosswake/proof/phase34_mock_storefront_test.exs` lines 5-26. [VERIFIED: read file directly]

```elixir
defmodule Crosswake.Proof.Phase34PaywallCorridorProofTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 34 paywall corridor.

  [hermeticity contract statement]

  Intentionally UNtagged (no @moduletag :requires_example_host) — hermetic via
  Code.require_file and pure function calls, so it runs in the merge-blocking lane
  under `mix test --exclude requires_example_host`.
  """

  use ExUnit.Case, async: false
  ...
end
```

### Pattern: phase21 snapshot builder helpers

Source: `test/crosswake/proof/phase21_reconciliation_example_test.exs` lines 180-229. [VERIFIED: read file directly]

The phase21 test defines these private helpers (reproduced inline as Phase34-prefixed in the new proof per D-07):

| Helper | Signature | Returns | Fields |
|--------|-----------|---------|--------|
| `snapshot/1` | `snapshot(overrides \\ %{})` | `%Contracts.EntitlementSnapshot{}` | group_id, authority, access, reconciliation, freshness, effective, evidence, as_of |
| `authority_lane/1` | `authority_lane(state)` | `%AuthorityLane{}` | state, reason: nil |
| `access_lane/1` | `access_lane(decision)` | `%AccessLane{}` | decision, reason: nil |
| `reconciliation_lane/2` | `reconciliation_lane(state, reference \\ "attempt_123")` | `%ReconciliationLane{}` | state, reference |
| `freshness_lane/1` | `freshness_lane(state)` | `%FreshnessLane{}` | state, checked_at: fixed ISO string, stale_after: nil |

No `evidence_lane/1` or `effective_lane/1` helpers exist — `EvidenceLane` and `EffectiveLane` are inlined directly in `snapshot/1`'s base map.

**Base defaults in `snapshot/1` (phase21):**
```
authority: authority_lane(:none)
access: access_lane(:denied)
reconciliation: reconciliation_lane(:projection_refreshed)
freshness: freshness_lane(:fresh)
effective: %EffectiveLane{effective_from: "2026-05-01T00:00:00Z", effective_until: nil}
evidence: %EvidenceLane{source: :webhook, reference: "evidence_123", observed_at: "2026-05-27T10:00:00Z"}
as_of: 100
```

Phase36 helpers should be prefixed `Phase34` to match CONTEXT D-07. Example: the private module name `Phase34PaywallCorridorSnapshots` (or simply private functions in the test module itself, matching the phase21 pattern of private functions, not a separate module — confirm with planner).

**NOTE:** Phase21 helpers are private functions directly in the test module, NOT in a separate inline module. CONTEXT D-07 mentions "inline fixture module" but the phase21 pattern is private functions. The planner should choose: private functions (cleaner, matches phase21) vs. a separate `defmodule Phase34PaywallCorridorSnapshots` (satisfies the "prefixed module name" collision-avoidance wording). Either works; private functions are the established precedent. [VERIFIED: phase21 uses `defp` at module level]

### Pattern: Self-scan hermeticity guard

Source: `test/crosswake/proof/phase23_commerce_support_proof_test.exs` lines 509-549 and `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs` lines 88-99. [VERIFIED: read both files directly]

**Phase23 approach (richer guard — escape-hatch patterns):**
```elixir
test "proof test stays hermetic" do
  source = File.read!(__ENV__.file) |> String.downcase()

  # Check for forbidden require_file lines
  require_call_lines =
    source
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(~r/^\s*code\.require_file\(/, &1))

  for line <- require_call_lines do
    assert String.contains?(line, "permitted_file.ex"),
           "proof test loads non-permitted file via Code.require_file: #{inspect(line)}"
  end

  # Check for network/process escape hatches
  escape_hatch_call_patterns = [
    ~r/system\.cmd\s*\(/,
    ~r/port\.open\s*\(/,
    ~r/:gen_tcp\.[a-z_]+\s*\(/,
    ~r/:httpc\.[a-z_]+\s*\(/,
    ~r/req\.get\s*\(/,
    ~r/tesla\.get\s*\(/
  ]
  for pattern <- escape_hatch_call_patterns do
    refute Regex.match?(pattern, source), "..."
  end
end
```

**Phase33 approach (simpler — token presence check):**
```elixir
test "proof stays hermetic" do
  source = File.read!(__ENV__.file) |> String.downcase()
  refute String.contains?(source, "crosswake" <> "example.router"), "..."
  refute Regex.match?(~r/code\.require_file\s*\(/, source), "..."
end
```

**For Phase36 (per D-03):** The guard reads `File.read!(__ENV__.file)` and asserts:
1. No `Code.require_file` line whose path contains a forbidden runtime substring (`_live`, `endpoint`, `application`, `router`, `repo`, `_web`). Only the four allowed pure commerce modules may be required.
2. No process-start/server tokens (`start_supervised`, `Phoenix.PubSub`, `GenServer.start`, `Endpoint`, `LiveViewTest`) appear in the proof body.
3. The file carries `async: false`.
4. The file is untagged (no `@moduletag :requires_example_host`).

The phase23 "filter require lines then assert each allowed" technique is the right model for assertion 1 — it produces a useful failure message naming the offending line.

**Key implementation note:** Forbidden token strings must be constructed with concatenation (e.g., `"phoenix" <> ".pubsub"`) to avoid the self-scan guard matching its OWN assertion body when scanning the file. Phase23 uses this technique for provider tokens (lines 35-40 of phase34_mock_storefront_test.exs). [VERIFIED: `"store" <> "kit"` pattern confirmed in phase34 test]

### Anti-Patterns to Avoid

- **Calling `verify_and_broadcast/2` in the proof:** This function calls `Phoenix.PubSub.broadcast/3` and `Logger.warning/1`. It would require a running PubSub process. The proof calls `build_verified_snapshot/2` ONLY, then drives `project_snapshot/2` and `derived_state/1` manually. [VERIFIED: verify_and_broadcast source confirmed in mock_backend.ex lines 56-88]
- **Code.require_file'ing the phase21 test file:** D-07 explicitly prohibits this. The helpers are reproduced inline.
- **Using `struct()` instead of `struct!()`:** The phase21 and MockBackend patterns use `struct!` which raises on missing enforce_keys — safer for test fixtures.
- **Vacuous assertions:** Building a snapshot that "should" be :stale but accidentally has `freshness.state: :fresh` passes derived_state/1 into the wrong branch silently. The planner must specify exact field values so the snapshot is uniquely routed.

---

## Verified Source Details

### 1. `Code.require_file` header form — phase34_mock_storefront_test.exs:1-26

[VERIFIED: read file directly]

Phase34_mock_storefront_test.exs requires:
- Line 1: `reconciliation_keys.ex`
- Line 2: `reconciliation_inbox.ex`
- Line 3: `mock_storefront.ex`

The new Phase36 proof differs by requiring `entitlement_projection.ex` and `mock_backend.ex` instead of `mock_storefront.ex`.

Phase21_reconciliation_example_test.exs (lines 1-3) requires: `reconciliation_keys.ex`, `reconciliation_inbox.ex`, `entitlement_projection.ex`. This is the CLOSEST precedent for the new proof — Phase36 adds `mock_backend.ex` on top.

**Note on phase21 tagging:** Phase21 test has `@moduletag :requires_example_host` (line 11) and is therefore EXCLUDED from the hermetic merge-blocking lane. It uses Code.require_file for pure modules but runs in the advisory lane only. Phase34 storefront test is UNTAGGED (confirmed: no moduletag in file). Phase36 new proof must be UNTAGGED like Phase34 storefront test. [VERIFIED: both files read directly]

### 2. phase21 snapshot builders — lines 180-229

[VERIFIED: read file directly]

Full helper signatures with return structures:

```elixir
# Line 180
defp snapshot(overrides \\ %{}) do
  base = %{
    group_id: "group_123",
    authority: authority_lane(:none),
    access: access_lane(:denied),
    reconciliation: reconciliation_lane(:projection_refreshed),
    freshness: freshness_lane(:fresh),
    effective: %Contracts.EntitlementSnapshot.EffectiveLane{
      effective_from: "2026-05-01T00:00:00Z",
      effective_until: nil
    },
    evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
      source: :webhook,
      reference: "evidence_123",
      observed_at: "2026-05-27T10:00:00Z"
    },
    as_of: 100
  }
  struct!(Contracts.EntitlementSnapshot, Map.merge(base, overrides))
end

# Line 202
defp authority_lane(state) do
  %Contracts.EntitlementSnapshot.AuthorityLane{state: state, reason: nil}
end

# Line 209
defp access_lane(decision) do
  %Contracts.EntitlementSnapshot.AccessLane{decision: decision, reason: nil}
end

# Line 216
defp reconciliation_lane(state, reference \\ "attempt_123") do
  %Contracts.EntitlementSnapshot.ReconciliationLane{state: state, reference: reference}
end

# Line 223
defp freshness_lane(state) do
  %Contracts.EntitlementSnapshot.FreshnessLane{
    state: state,
    checked_at: "2026-05-27T10:00:00Z",
    stale_after: nil
  }
end
```

**For the four states (from phase21 test lines 91-107):**
```elixir
# :stale
stale_snapshot = snapshot(%{freshness: freshness_lane(:stale)})

# :pending
pending_snapshot = snapshot(%{reconciliation: reconciliation_lane(:awaiting_verification)})
# NOTE: base freshness is :fresh, so stale doesn't override pending

# :denied
denied_snapshot = snapshot()
# Base defaults: freshness :fresh, reconciliation :projection_refreshed, access :denied
# -> granted_snapshot? returns false (access :denied) -> fallthrough to :denied

# :granted
granted_snapshot = snapshot(%{
  authority: authority_lane(:active),
  access: access_lane(:granted),
  reconciliation: reconciliation_lane(:projection_refreshed),
  freshness: freshness_lane(:fresh)
})
```

### 3. `derived_state/1` precedence — entitlement_projection.ex:39-53

[VERIFIED: read file directly, lines 39-53]

```elixir
def derived_state(%EntitlementSnapshot{} = snapshot) do
  cond do
    snapshot.freshness.state in [:stale, :unknown] -> :stale  # FIRST - wins over everything
    snapshot.reconciliation.state in @pending_reconciliation_states -> :pending
    granted_snapshot?(snapshot) -> :granted
    true -> :denied
  end
end
```

Module attributes (lines 11-13):
```elixir
@pending_reconciliation_states [:pending_purchase, :pending_restore, :awaiting_verification]
@grantable_authority_states [:active, :grace, :billing_retry, :canceled_scheduled_end]
@verified_reconciliation_states [:projection_refreshed, :verification_failed, :conflict, :stale_authority]
```

`granted_snapshot?` requirements (lines 55-59):
```elixir
defp granted_snapshot?(%EntitlementSnapshot{} = snapshot) do
  snapshot.freshness.state == :fresh and
    resolved_reconciliation?(snapshot.reconciliation.state) and
    snapshot.authority.state in @grantable_authority_states and
    snapshot.access.decision == :granted
end
```

`resolved_reconciliation?` (lines 62-63):
```elixir
defp resolved_reconciliation?(:projection_refreshed), do: true
defp resolved_reconciliation?(_state), do: false
```

**Confirmed D-04 anchors:**
- `:stale` — `freshness.state in [:stale, :unknown]` (wins over all other states)
- `:pending` — `freshness :fresh` + `reconciliation.state in [:pending_purchase, :pending_restore, :awaiting_verification]`
- `:granted` — `freshness :fresh` + `reconciliation :projection_refreshed` + `authority.state in [:active, :grace, :billing_retry, :canceled_scheduled_end]` + `access.decision :granted`
- `:denied` — `freshness :fresh` + NOT pending + NOT granted (any verified reconciliation state except :projection_refreshed, OR access :denied)

### 4. `ReconciliationInbox.ingest_evidence/2` — example-host

[VERIFIED: read reconciliation_inbox.ex directly, lines 14-37]

```elixir
@spec ingest_evidence(Contracts.ReconciliationEvidence.t(), keyword()) ::
        {:ok, map()} | {:error, term()}
def ingest_evidence(%Contracts.ReconciliationEvidence{} = evidence, opts \\ []) do
  with {:ok, source} <- normalize_source(evidence.source) do
    ...
    {:ok, %{
      source: source,
      event_key: event_key,
      subject_key: subject_key,
      status: evidence_status(evidence.event_kind),
      replay?: replay?,
      captured_at: evidence.captured_at,
      trace_metadata: ...
    }}
  end
end
```

`evidence_status/1` (lines 39-44):
```elixir
@success_like_event_kinds MapSet.new(["purchase", "restore", "renewal", "grace_period", "billing_retry"])

defp evidence_status(event_kind) do
  if MapSet.member?(@success_like_event_kinds, to_string(event_kind)) do
    :awaiting_verification
  else
    :verification_failed
  end
end
```

**For D-05.1:** `evidence` with `event_kind: "purchase"` (or `"restore"`) produces `status: :awaiting_verification`.

**Return shape is a plain MAP, not a struct.** Access as `result.status`, `result.replay?`, etc. (using dot notation on maps is valid in Elixir).

**Opts:** `correlation_id:`, `group_id:`, `seen_event_keys:` (list of strings).

For the corridor proof, `ingest_evidence/2` is called WITHOUT a `group_id` in D-05.1 (the corridor uses it for its own subject_key purposes but the proof just needs `status: :awaiting_verification`). The simple call form `ReconciliationInbox.ingest_evidence(evidence)` works.

### 5. `MockBackend.build_verified_snapshot/2` — examples/phoenix_host/.../mock_backend.ex

[VERIFIED: read file directly, lines 106-141]

```elixir
@subscription_entry_id "sub_pro_monthly"

@spec build_verified_snapshot(Contracts.ReconciliationEvidence.t(), String.t()) ::
        Contracts.EntitlementSnapshot.t()
def build_verified_snapshot(_evidence, group_id) do
  now_iso = DateTime.utc_now() |> DateTime.to_iso8601()

  struct!(Contracts.EntitlementSnapshot, %{
    group_id: group_id,
    authority: %Contracts.EntitlementSnapshot.AuthorityLane{state: :active, reason: nil},
    access: %Contracts.EntitlementSnapshot.AccessLane{decision: :granted, reason: nil},
    reconciliation: %Contracts.EntitlementSnapshot.ReconciliationLane{
      state: :projection_refreshed,
      reference: "mock_backend_ref_" <> @subscription_entry_id
    },
    freshness: %Contracts.EntitlementSnapshot.FreshnessLane{
      state: :fresh,
      checked_at: now_iso,
      stale_after: nil
    },
    effective: %Contracts.EntitlementSnapshot.EffectiveLane{
      effective_from: now_iso,
      effective_until: nil
    },
    evidence: %Contracts.EntitlementSnapshot.EvidenceLane{
      source: :storefront,
      reference: "mock_evt_" <> @subscription_entry_id <> "_purchase",
      observed_at: now_iso
    },
    as_of: System.system_time(:microsecond)
  })
end
```

**Key facts:**
- Signature is `build_verified_snapshot(evidence, group_id)` — `_evidence` is ignored. The `group_id` sets the snapshot's `group_id` field.
- Returns `%EntitlementSnapshot{}` directly (not `{:ok, snapshot}`).
- `as_of` uses `System.system_time(:microsecond)` — deterministic enough per call but not injected. No `captured_at`-style injection seam exists in `build_verified_snapshot/2`.
- The `verify_and_broadcast/2` function (lines 56-88) calls `Phoenix.PubSub.broadcast/3` and is NOT called in the proof (would require a running PubSub process).
- `@subscription_entry_id "sub_pro_monthly"` is the canonical `group_id` anchor. The proof should use `"sub_pro_monthly"` as `group_id` to match the MockStorefront/corridor constant.

### 6. `Crosswake.Commerce.Contracts` — enforced keys

[VERIFIED: read contracts.ex directly]

`%ReconciliationEvidence{}` @enforce_keys (line 152-159):
```
:source, :provider, :provider_reference, :event_kind, :evidence_ref, :captured_at
```
Optional fields: `:integrity_digest`, `:idempotency_ref`

`%EntitlementSnapshot{}` @enforce_keys (line 135):
```
:group_id, :authority, :access, :reconciliation, :freshness, :effective, :evidence, :as_of
```

Lane enforce_keys:
- `AuthorityLane`: `:state`
- `AccessLane`: `:decision`
- `ReconciliationLane`: `:state`
- `FreshnessLane`: `:state, :checked_at`
- `EffectiveLane`: `:effective_from`
- `EvidenceLane`: `:source, :reference`

**Inline evidence builder for D-05.1 (to pass ingest_evidence/2):**
```elixir
%Contracts.ReconciliationEvidence{
  source: :storefront,
  provider: "mock",
  provider_reference: "mock_txn_sub_pro_monthly",
  event_kind: "purchase",
  evidence_ref: "mock_evt_sub_pro_monthly_purchase",
  captured_at: "2026-05-29T00:00:00Z"   # fixed for determinism (Phase 34 D-08/D-09)
}
```

### 7. `authority_mutation_allowed_from_evidence?/1` — lib/crosswake/commerce/reconciliation.ex:141-142

[VERIFIED: read file directly]

```elixir
@spec authority_mutation_allowed_from_evidence?(Contracts.ReconciliationEvidence.t()) :: false
def authority_mutation_allowed_from_evidence?(%Contracts.ReconciliationEvidence{}), do: false
```

This function is in `lib/crosswake/commerce/reconciliation.ex`, which IS in the compilation path for `mix test` (elixirc_paths includes `lib/`). No `Code.require_file` needed. The proof calls it as `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?(evidence)`.

Note: There is ALSO an `ingest_evidence/2` in this lib module (line 114), but the proof uses the EXAMPLE-HOST `ReconciliationInbox.ingest_evidence/2` (the corridor's actual ingest path). The lib version has a different return type (`{:ok, %EvidenceResult{}}` struct vs the example-host's `{:ok, map()}`). Do not confuse them.

### 8. `.github/workflows/phase34-proof.yml` — CI verification

[VERIFIED: read file directly, lines 77-83]

The hermetic job step reads:
```yaml
- name: Run hermetic Phase 34+ paywall corridor proof lane
  # Broad hermetic run: excludes only requires_example_host-tagged tests
  # (integration tests that need a running server). The Phase 36 proof
  # file is untagged and uses Code.require_file to reach example-host
  # modules — so it is picked up automatically here without a per-file
  # path list. No provider SDK, no simulator, no device, no network.
  run: mix test --exclude requires_example_host
```

The workflow runs `mix test --exclude requires_example_host` — a glob across ALL test files, not an enumeration of specific files. The Phase36 proof file, being untagged, is automatically included. **D-09 confirmed: no CI changes needed.** [VERIFIED: workflow comment explicitly names Phase 36]

The workflow uses `--warnings-as-errors` at compile time (line 75: `mix compile --warnings-as-errors`) but NOT as a flag on `mix test` itself. The `--warnings-as-errors` constraint applies at compile time. Test-time compilation of Code.require_file'd files may produce warnings that would fail the job if warnings are elevated — the proof should ensure no compilation warnings from the required modules.

**Additional CI detail:** The hermetic job runs on `macos-15`, not ubuntu. Elixir 1.19.5 / OTP 27.3.

### 9. Self-scan guard mechanics — D-03 design

[VERIFIED: precedents read from phase23_commerce_support_proof_test.exs:509-549 and phase33_commerce_corridor_routes_test.exs:88-99]

Phase36 is the FIRST proof test to combine:
- Code.require_file of multiple example-host modules (like phase21/34)
- A self-scan guard (like phase23/33)

The guard design per D-03:

**Assertion 1 — No runtime-path require_file:**
```elixir
require_call_lines =
  source
  |> String.split("\n")
  |> Enum.filter(&Regex.match?(~r/^\s*code\.require_file\s*\(/, &1))

forbidden_runtime_substrings = ["_live", "endpoint", "application", "router", "repo", "_web"]

for line <- require_call_lines do
  for forbidden <- forbidden_runtime_substrings do
    refute String.contains?(line, forbidden),
           "proof requires runtime path containing #{inspect(forbidden)}: #{inspect(line)}"
  end
end
```

**Assertion 2 — No process-start/server tokens:**
Process-start tokens per D-03: `start_supervised`, `Phoenix.PubSub`, `GenServer.start`, `Endpoint`, `LiveViewTest`.

These must be checked as concatenated strings (e.g. `"start" <> "_supervised"`) to avoid the guard matching itself. The token check should apply to the function body lines, not the require_file header lines (or use Regex patterns that match call forms, not plain text).

**Assertion 3 — async: false present:**
```elixir
assert String.contains?(source, ~s(use ExUnit.Case, async: false)),
       "proof must use async: false"
```

**Assertion 4 — untagged (no @moduletag :requires_example_host):**
```elixir
refute String.contains?(source, "@module" <> "tag :requires_example_host"),
       "proof must be untagged — merge-blocking lane requires no @moduletag"
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verified entitlement snapshot | Custom struct builder from scratch | `MockBackend.build_verified_snapshot/2` | The shipped function produces the exact field values that pass `project_snapshot/2` and yield `:granted`; rolling your own may silently miss `as_of` or `reconciliation.reference` field values |
| `:pending` state derivation | Custom reconciliation state logic | `derived_state/1` on snapshot with `reconciliation.state: :awaiting_verification` | The cond block in `derived_state/1` is the behavior under test; re-deriving it outside the function breaks the proof |
| Evidence ingestion status | Manual status assignment | `ReconciliationInbox.ingest_evidence/2` | The proof must demonstrate the REAL ingestion path, not a substituted value |
| Struct construction | `%EntitlementSnapshot{...}` directly | `struct!(Contracts.EntitlementSnapshot, ...)` with the helper pattern | `struct!` raises on missing enforce_keys, catching construction errors at test time |

---

## Common Pitfalls

### Pitfall 1: Vacuous Snapshot Assertions

**What goes wrong:** A snapshot intended to produce `:stale` has `freshness.state: :fresh` by mistake (e.g. using the phase21 base defaults without the stale override). The test passes with `:denied` or `:pending` instead of `:stale` — or fails with a confusing mismatch message.

**Why it happens:** The phase21 `snapshot/1` base has `freshness: freshness_lane(:fresh)`. If the override map is missing `freshness`, the base applies.

**How to avoid:** The planner should specify the complete override map for EACH of the four states so the implementer cannot accidentally inherit a wrong default. Example: `snapshot(%{freshness: freshness_lane(:stale)})` is unambiguous.

**Warning signs:** All four assertions pass vacuously when they all produce the same state (check by temporarily flipping one assertion to `refute` and confirming it fails).

### Pitfall 2: Calling verify_and_broadcast instead of build_verified_snapshot

**What goes wrong:** Test crashes with `(UndefinedFunctionError)` or process-related errors when `verify_and_broadcast/2` is called without a running PubSub.

**Why it happens:** The proof needs to call `build_verified_snapshot/2` (pure) and then `project_snapshot/2` manually. The `verify_and_broadcast/2` function exists on MockBackend but calls `Phoenix.PubSub.broadcast/3` — unavailable in the hermetic lane.

**How to avoid:** The plan must explicitly name `build_verified_snapshot/2` as the function to call and state that `verify_and_broadcast/2` is NOT called.

### Pitfall 3: Using lib Reconciliation.ingest_evidence instead of example-host ReconciliationInbox.ingest_evidence

**What goes wrong:** Test accesses `result.event_key` on `%EvidenceResult{}` struct from the lib version — this field doesn't exist on `%EvidenceResult{}` (it has `.status`, `.replay?`, `.attempt`, `.idempotency_key`, `.source`).

**Why it happens:** Both `Crosswake.Commerce.Reconciliation` (lib) and `CrosswakeExample.Commerce.ReconciliationInbox` (example-host) have `ingest_evidence/2`. The lib version returns `{:ok, %EvidenceResult{}}` struct; the example-host version returns `{:ok, map()}`.

**How to avoid:** The proof must alias `CrosswakeExample.Commerce.ReconciliationInbox` (not the lib module) and access `result.status` from the map return. Only D-06.1 uses the lib `Reconciliation` module (for `authority_mutation_allowed_from_evidence?/1`).

### Pitfall 4: Self-scan guard matches itself

**What goes wrong:** The guard scanning for forbidden tokens like `"start_supervised"` matches the guard's OWN test assertion string, causing a false positive.

**Why it happens:** The guard is checking the full file source including its own test body.

**How to avoid:** Use concatenated string construction for forbidden tokens in assertions: `"start" <> "_supervised"`. This is the established pattern in phase34 (line 35-40: `"store" <> "kit"`, `"revenue" <> "cat"`).

### Pitfall 5: Code.require_file order — mock_backend.ex before entitlement_projection.ex

**What goes wrong:** If `mock_backend.ex` is required before `entitlement_projection.ex`, the `alias` expansion on line 38 of mock_backend.ex refers to a module not yet loaded. In Elixir, `alias` is compile-time syntax sugar and the module need not be loaded, but `verify_and_broadcast/2` would crash at runtime if called. More critically, if any compile-time macro uses the alias, it could fail.

**How to avoid:** Require files in dependency order: `reconciliation_keys.ex` → `reconciliation_inbox.ex` → `entitlement_projection.ex` → `mock_backend.ex`. This matches the data-flow dependency order and is the safest convention.

### Pitfall 6: Non-deterministic as_of in build_verified_snapshot

**What goes wrong:** `build_verified_snapshot/2` uses `System.system_time(:microsecond)` for `as_of`. When `project_snapshot(nil, snapshot)` is called (nil current), monotonicity is not checked — so this is fine for the proof's use case. But if the proof calls `project_snapshot(existing, new)` with two snapshots built in rapid succession, the monotonicity check could fail if timing is tight.

**How to avoid:** The D-05.3 path calls `project_snapshot(nil, verified)` — the nil form skips monotonicity checking. Do not call `project_snapshot(current_snapshot, build_verified_snapshot(...))` with a non-nil first argument.

---

## Code Examples

### Full pipeline: evidence → ingest → pending → verified → granted

```elixir
# Source: verified against reconciliation_inbox.ex + entitlement_projection.ex + mock_backend.ex

# 1. Build inline evidence (D-05.1)
evidence = %Contracts.ReconciliationEvidence{
  source: :storefront,
  provider: "mock",
  provider_reference: "mock_txn_sub_pro_monthly",
  event_kind: "purchase",
  evidence_ref: "mock_evt_sub_pro_monthly_purchase",
  captured_at: "2026-05-29T00:00:00Z"
}

# 2. Ingest evidence → :awaiting_verification
assert {:ok, result} = ReconciliationInbox.ingest_evidence(evidence)
assert result.status == :awaiting_verification

# 3. :pending state assertion (separate snapshot — explicit :awaiting_verification)
pending_snap = snapshot(%{reconciliation: reconciliation_lane(:awaiting_verification)})
assert derived_state(pending_snap) == :pending

# 4. Build verified snapshot (honest :granted source)
group_id = "sub_pro_monthly"
verified = MockBackend.build_verified_snapshot(evidence, group_id)

# 5. Project through the verification gate
assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, verified)

# 6. Assert :granted
assert EntitlementProjection.derived_state(projected) == :granted
```

### Mock-boundary fence assertions

```elixir
# Source: verified against lib/crosswake/commerce/reconciliation.ex:142
#         and entitlement_projection.ex:65-71

# Fence 1: authority_mutation_allowed_from_evidence?/1 returns false (D-06.1)
assert Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?(evidence) == false

# Fence 2: project_snapshot rejects unverified reconciliation state (D-06.2)
unverified_snap = snapshot(%{reconciliation: reconciliation_lane(:awaiting_verification)})
assert {:error, :unverified_reconciliation_outcome} =
         EntitlementProjection.project_snapshot(nil, unverified_snap)

# Fence 3: verified-but-not-refreshed does NOT grant (D-06.3)
# :verification_failed is in @verified_reconciliation_states so project_snapshot passes it,
# but resolved_reconciliation?/1 returns false for it, so granted_snapshot? is false
vfailed_snap = snapshot(%{
  reconciliation: reconciliation_lane(:verification_failed),
  authority: authority_lane(:active),
  access: access_lane(:granted)
})
assert {:ok, projected} = EntitlementProjection.project_snapshot(nil, vfailed_snap)
refute EntitlementProjection.derived_state(projected) == :granted
```

### Four-state assertions with distinct snapshots

```elixir
# Source: pattern from phase21_reconciliation_example_test.exs:91-107

assert derived_state(snapshot(%{freshness: freshness_lane(:stale)})) == :stale
assert derived_state(snapshot(%{freshness: freshness_lane(:unknown)})) == :stale
assert derived_state(snapshot(%{reconciliation: reconciliation_lane(:awaiting_verification)})) == :pending
assert derived_state(snapshot()) == :denied  # base: access :denied, reconciliation :projection_refreshed, freshness :fresh
assert derived_state(snapshot(%{authority: authority_lane(:active), access: access_lane(:granted),
                                 reconciliation: reconciliation_lane(:projection_refreshed),
                                 freshness: freshness_lane(:fresh)})) == :granted
```

---

## Runtime State Inventory

This is a test-only addition — no data migrations, no OS-registered state, no stored records, no secret renames. Skipped per the greenfield-test nature of this phase.

---

## Environment Availability

No external tools or services are required beyond the standard Elixir/Mix toolchain.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Test runner | Confirmed (project builds) | 1.19.5 (CI) | — |
| ExUnit | Test framework | Elixir stdlib | built-in | — |
| `lib/crosswake/commerce/` | fence assertions | In compilation path | shipped | — |
| Four pure example-host modules | Code.require_file | Confirmed in repo at expected paths | shipped | — |

---

## Validation Architecture

Nyquist validation is **enabled** (config.json: `workflow.nyquist_validation: true`). For a test-only phase, the deliverable IS the validation artifact — the proof file self-validates the corridor and the planner's plan must ensure that each assertion in the proof actually fails if the behavior regresses.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` (single line: `ExUnit.start()`) |
| Quick run command | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Success Criteria → Assertion Map

| SC | Behavior | Assertion(s) in Proof | Vacuity Risk | How to Avoid |
|----|----------|-----------------------|--------------|--------------|
| SC#1 | All four derived states asserted distinctly | Four separate `assert derived_state(snap) == :X` — one for each of :stale, :pending, :denied, :granted, each from a DIFFERENT snapshot | All four pass because the cond has a `true` fallthrough that absorbs any snapshot | Each snapshot must be verified to produce EXACTLY one state: temporarily flip each assertion to confirm it fails with the wrong value |
| SC#2 | :pending → :granted transition | `assert result.status == :awaiting_verification` (ingest), `assert derived_state(pending_snap) == :pending` (explicit), `{:ok, projected} = project_snapshot(nil, verified)` then `assert derived_state(projected) == :granted` | project_snapshot(nil, anything_verified) could pass vacuously if the projected snapshot has wrong fields | The snapshot from `build_verified_snapshot/2` is the actual shipped function — it produces the real fields |
| SC#3 | Mock-boundary fence (three real truths) | `assert authority_mutation_allowed_from_evidence?(evidence) == false` / `assert {:error, :unverified_reconciliation_outcome} = project_snapshot(nil, unverified)` / `refute derived_state(projected) == :granted` for verification_failed snap | The `authority_mutation_allowed_from_evidence?/1` assertion trivially passes (function always returns false) | Add a message: "returns false unconditionally for any ReconciliationEvidence — this is the lib contract"; the test IS documenting the contract, not behavior-testing a branch |
| SC#4 | async: false, Phase34-prefixed modules, self-scan guard | Self-scan: `assert String.contains?(source, "async: false")` / `refute String.contains?(source, "@module" <> "tag :requires_example_host")` / require_line scan for forbidden substrings | Guard could falsely pass if the checked strings are in comments that appear legitimate | Use exact call-form Regex for require_file lines (not just `String.contains?`) |
| SC#5 | CI job runs file cleanly | Verified by `mix test --exclude requires_example_host` in CI — no separate assertion in the proof | Proof passes locally but fails in CI due to compilation warnings promoted to errors by `mix compile --warnings-as-errors` | Run `mix compile --warnings-as-errors` locally before merging; ensure no undefined function warnings from Code.require_file'd modules |

### PROOF-01 → Assertion Map

| PROOF-01 sub-requirement | Assertion |
|--------------------------|-----------|
| Mock purchase (inline evidence) | `%Contracts.ReconciliationEvidence{provider: "mock", source: :storefront, event_kind: "purchase"}` construction |
| ingest_evidence/2 called | `ReconciliationInbox.ingest_evidence(evidence)` |
| project_snapshot/2 called | `EntitlementProjection.project_snapshot(nil, verified)` |
| derived_state/1 called | `EntitlementProjection.derived_state(projected)` and `derived_state(snap)` for all four states |
| No network or native SDK | Self-scan guard (D-03) + no test process requires external connectivity |
| All four states | Four distinct snapshot assertions |
| :pending → :granted transition | Three-step proof per D-05 |

### PROOF-03 → Assertion Map

| PROOF-03 sub-requirement | Assertion |
|--------------------------|-----------|
| Mock evidence can never directly grant | authority_mutation_allowed_from_evidence?(evidence) == false (lib returns false unconditionally) |
| project_snapshot rejects unverified | `{:error, :unverified_reconciliation_outcome}` for :awaiting_verification input |
| Verified-but-not-refreshed doesn't grant | derived_state of :verification_failed snapshot != :granted |

### Wave 0 Gaps

None — no new test infrastructure is needed. The ExUnit framework is already configured. The required modules are shipped/locked. The CI workflow already covers the hermetic lane.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Code.require_file("../../../examples/phoenix_host/...", __DIR__)` resolves correctly when the test is run from the project root via `mix test` | Standard Stack / Pattern: require_file header | Test fails to load modules if working directory differs from project root during test run; mitigated by the existing phase34/21 tests using the same path form successfully |
| A2 | `mock_backend.ex` compiles cleanly when Code.require_file'd without `entitlement_projection.ex` loaded first (the `alias` is module-load-time syntax, not compile-time execution) | Standard Stack | Compilation fails at load time; mitigated by requiring entitlement_projection.ex first in dependency order |

---

## Open Questions

1. **Private functions vs. separate defmodule for inline helpers (D-07)**
   - What we know: Phase21 uses private `defp` functions directly in the test module. CONTEXT D-07 mentions "Phase34-prefixed inline fixture module names" and gives example `Phase34PaywallCorridorSnapshots`.
   - What's unclear: Does D-07 require a separate `defmodule Phase34PaywallCorridorSnapshots` inside the test file, or are Phase34-prefixed private functions sufficient?
   - Recommendation: Private `defp` functions with `phase34_` prefix in their names (e.g. `defp phase34_snapshot/1`) achieves the collision-avoidance goal without introducing a nested module. The `defmodule` form is also valid and arguably more explicit. This is Claude's discretion per CONTEXT. The planner should choose and specify explicitly.

2. **Whether to assert on `result.event_key` in the :pending transition test**
   - What we know: The ingest_evidence/2 return map includes `event_key` and `subject_key` fields. D-05 only requires asserting `result.status == :awaiting_verification`.
   - What's unclear: Should the proof additionally assert `event_key` is constructed from the mock provider fields, or is status sufficient for PROOF-01?
   - Recommendation: Status-only assertion for PROOF-01 clarity. The event_key/subject_key correctness is already proven by phase34_mock_storefront_test.exs.

---

## Sources

### Primary (HIGH confidence)

All findings are VERIFIED against actual source files read in this session:

- `test/crosswake/proof/phase34_mock_storefront_test.exs` — Code.require_file idiom, untagged pattern, hermeticity moduledoc (lines 1-26)
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — snapshot builder helpers (lines 180-229), four-state precedence test (lines 90-108), @moduletag :requires_example_host (line 11)
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — self-scan guard precedent (lines 509-549)
- `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs` — simpler self-scan guard form (lines 88-99)
- `test/crosswake/proof/phase35_paywall_live_test.exs` — complement: what NOT to duplicate (PubSub, LiveViewTest, start_supervised)
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — full source: @pending_reconciliation_states, @verified_reconciliation_states, @grantable_authority_states, derived_state/1 cond, granted_snapshot?, resolved_reconciliation?, ensure_verified_reconciliation (lines 1-116)
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` — build_verified_snapshot/2 full source, @subscription_entry_id, verify_and_broadcast/2 (lines 1-142)
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — ingest_evidence/2 return shape (plain map), evidence_status/1, @success_like_event_kinds (lines 1-62)
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — standalone, only Contracts dependency (lines 1-92)
- `lib/crosswake/commerce/reconciliation.ex` — authority_mutation_allowed_from_evidence?/1:142, ingest_evidence/2:114 (lib variant), @verified_reconciliation_states equivalent (lines 1-180)
- `lib/crosswake/commerce/contracts.ex` — @enforce_keys for ReconciliationEvidence, EntitlementSnapshot, all lane structs (lines 1-363)
- `.github/workflows/phase34-proof.yml` — hermetic job command `mix test --exclude requires_example_host`, auto-discovery comment naming Phase 36 (lines 1-165)
- `mix.exs` — elixirc_paths confirms examples/ NOT in compilation path; Code.require_file is the only load mechanism (line 35-36)
- `.planning/config.json` — nyquist_validation: true confirmed

---

## Metadata

**Confidence breakdown:**
- Proof file structure and idiom: HIGH — verified against two existing hermetic proof files that are the direct templates
- Shipped API signatures: HIGH — all function signatures read from source
- CI lane behavior: HIGH — workflow file read; auto-discovery comment explicitly names Phase 36
- Self-scan guard design: HIGH — two precedents read; D-03 design is unambiguous

**Research date:** 2026-05-29
**Valid until:** This research is valid until the four example-host commerce modules or the lib reconciliation module are modified. Given they are SHIPPED/locked for this milestone, validity extends through Phase 37.
