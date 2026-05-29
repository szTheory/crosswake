# Phase 34: MockStorefront And Idempotency Invariants - Research

**Researched:** 2026-05-29
**Domain:** Pure-Elixir example module + ExUnit hermetic proof tests
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**A. Provider identity derivation (MOCK-01, WIRE-03)**
- D-01: `provider_reference` is a deterministic function of `PurchaseIntent.entry_id` (e.g. `"mock_txn_" <> entry_id`).
- D-02: `evidence_ref` is deterministic from the same stable identity + `event_kind` (e.g. `"mock_evt_" <> entry_id <> "_purchase"`). Must NOT be random per-call.
- D-03: `correlation_id` is NEVER part of identity. It passes through to `ingest_evidence/2` via `opts[:correlation_id]`, landing in `trace_metadata` only.
- D-04: Evidence shape is fixed: `source: :storefront`, `provider: "mock"`, `event_kind: "purchase"` for purchases.

**B. Restore identity semantics (MOCK-02)**
- D-05: `MockStorefront` owns a single canonical subscription product identity as a module constant (`@subscription_entry_id`).
- D-06: `simulate_restore/1` resolves to the canonical product's stable `provider_reference` (NOT `RestoreIntent.correlation_id`). `event_kind: "restore"`.
- D-07: Restore product selection is a fixed module constant, not a configurable opt.

**C. Determinism / clock seam (Phase 36 hermeticity)**
- D-08: Both functions take an optional keyword (`simulate_purchase(intent, opts \\ [])`) where `captured_at` defaults to `DateTime.utc_now() |> DateTime.to_iso8601()` but can be injected.
- D-09: No RNG/seed or clock behaviour abstraction. Optional keyword + pure refs is sufficient.

**D. Function / return shape + swap documentation (MOCK-03)**
- D-10: Both functions return the raw `%ReconciliationEvidence{}` struct directly — no `{:ok, _}` wrapper.
- D-11: The `@moduledoc` explicitly names `simulate_purchase/1` and `simulate_restore/1` as the two functions a real StoreKit / Play Billing adapter would replace.

### Claude's Discretion
- Exact string forms of `provider_reference` / `evidence_ref` prefixes, the concrete `@subscription_entry_id` value, and the precise `@moduledoc` swap-target wording.
- Whether identity derivation uses simple string concatenation vs a small private helper.
- Exact structure of the replay invariant test and the provider-vocabulary fence test.

### Deferred Ideas (OUT OF SCOPE)
- Reconciliation/LiveView wiring + `project_snapshot/2` — Phase 35.
- Merge-blocking hermetic full-lane proof + mock-boundary fence on `authority_mutation_allowed_from_evidence?/1` — Phase 36.
- `guides/commerce.md` walkthrough + docs-contract lock — Phase 37.
- Multi-product / consumable / non-consumable paywalls — AF-04; single subscription product only.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOCK-01 | Adopter can see `MockStorefront` consume a `PurchaseIntent` and return `ReconciliationEvidence{source: :storefront, provider: "mock"}` in pure Elixir | `ReconciliationEvidence` struct verified; all enforce_keys confirmed; D-01/D-02/D-04 locked |
| MOCK-02 | Adopter can see `MockStorefront` consume a `RestoreIntent` and return restore evidence (`event_kind: "restore"`) | `RestoreIntent` struct verified (single field: `correlation_id`); D-05/D-06/D-07 locked |
| MOCK-03 | `MockStorefront` is shaped and documented as a drop-in swap target | `@moduledoc` pattern confirmed; D-11 locked |
| WIRE-03 | Adopter can observe provider-aware idempotency-key construction and replay detection (`replay?: true`) | `ReconciliationInbox.ingest_evidence/2` and `ReconciliationKeys.event_key/1` verified; `seen_event_keys` mechanic confirmed |
</phase_requirements>

---

## Summary

Phase 34 adds one new module — `CrosswakeExample.Commerce.MockStorefront` — to the example host and two ExUnit proof tests. The module is a pure-Elixir evidence emitter with no external dependencies; it constructs `Crosswake.Commerce.Contracts.ReconciliationEvidence` structs from incoming `PurchaseIntent` and `RestoreIntent` structs using deterministic string derivation, making the identity independent of the transient `correlation_id`.

All structural facts needed for planning have been verified directly against live source:
(1) the exact `@enforce_keys` of all three contract structs, (2) the precise composition of `event_key/1` and `subject_key/2` in `ReconciliationKeys`, (3) the `ingest_evidence/2` signature and its `seen_event_keys` / `replay?` mechanic in `ReconciliationInbox`, (4) the established `Code.require_file` + untagged hermetic test idiom from phase21, and (5) the vocabulary fence pattern from both phase21 and phase23 (project-root-relative `File.read!` + `String.downcase` + `refute String.contains?`).

The `phase34-proof.yml` CI lane runs `mix test --exclude requires_example_host`. Untagged tests land in the merge-blocking job automatically. Phase 21's reconciliation test (`phase21_reconciliation_example_test.exs`) carries `@moduletag :requires_example_host` and is excluded from the hermetic lane. The Phase 34 invariant test must be untagged — it uses `Code.require_file` at module scope and exercises only pure function calls, so it is legitimately hermetic.

**Primary recommendation:** Create `mock_storefront.ex` in `examples/phoenix_host/lib/crosswake_example/commerce/`, then create `test/crosswake/proof/phase34_mock_storefront_test.exs` with two test groups: the replay invariant test (untagged, hermetic, mirrors phase21 idiom) and the provider-vocabulary fence test (reads the `.ex` source via project-root-relative path, asserts token absence case-insensitively).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Evidence construction (simulate_purchase/1, simulate_restore/1) | Example host module | — | Pure-Elixir function, no lib changes; lives alongside other example commerce modules |
| Idempotency key composition (event_key/1) | Example host (ReconciliationKeys) | — | Already ships in Phase 21; Phase 34 only exercises it, does not modify it |
| Replay detection (ingest_evidence/2) | Example host (ReconciliationInbox) | — | Already ships in Phase 21; Phase 34 feeds mock evidence to it, asserts replay? |
| Provider-vocabulary fence | Test layer (proof test) | — | Source-text assertion at test time; no runtime component |
| Swap-target documentation | MockStorefront @moduledoc | — | Static documentation; no runtime component |

---

## Standard Stack

### Core
| Library / Module | Version / Status | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Crosswake.Commerce.Contracts` (lib) | shipped 0.1.0 | `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence` structs | These are the canonical contract types; must not be modified |
| `CrosswakeExample.Commerce.ReconciliationKeys` (example host) | Phase 21 | `event_key/1`, `subject_key/2`, `trace_metadata/2` | Pre-existing idempotency key machinery; Phase 34 feeds it |
| `CrosswakeExample.Commerce.ReconciliationInbox` (example host) | Phase 21 | `ingest_evidence/2` | Pre-existing ingestion + replay detection; Phase 34 drives it |
| `ExUnit.Case` | Elixir stdlib | Test framework | Project-wide test framework; `async: false` for hermetic proof tests |

### Supporting
| Library / Module | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `DateTime.utc_now/0` + `DateTime.to_iso8601/1` | Elixir stdlib | Default `captured_at` in mock | Only when opts does not inject `captured_at` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Simple string concatenation for `provider_reference` | A private helper function | Both are valid (Claude's discretion); helper improves readability but adds indirection; concatenation is simpler for example-clarity |
| `Code.require_file` at module scope | Compiled example host dependency | `Code.require_file` keeps the test hermetically loadable without the example host being compiled separately |

**Installation:** No new packages. Zero new dependencies. [VERIFIED: crosswake mix.exs + REQUIREMENTS.md]

---

## Package Legitimacy Audit

> Not applicable — this phase installs zero external packages. All code is pure Elixir using existing stdlib and project modules.

---

## Architecture Patterns

### System Architecture Diagram

```
PurchaseIntent{entry_id, correlation_id}
        │
        ▼
MockStorefront.simulate_purchase/2
  ├── provider_reference = f(entry_id)          ← stable identity
  ├── evidence_ref       = g(entry_id, "purchase") ← stable identity
  ├── captured_at        = opts[:captured_at] || DateTime.utc_now()
  └── returns %ReconciliationEvidence{source: :storefront, provider: "mock", ...}
        │
        ▼
ReconciliationInbox.ingest_evidence/2
  opts: [correlation_id: ..., seen_event_keys: [...]]
        │
        ├── ReconciliationKeys.event_key/1
        │     = "event::mock::<provider_reference>::purchase::<evidence_ref>"
        │       (correlation_id EXCLUDED)
        │
        ├── replay? = event_key in seen_event_keys
        │
        └── returns {:ok, %{event_key:, subject_key:, status: :awaiting_verification, replay?:, ...}}

RestoreIntent{correlation_id}
        │
        ▼
MockStorefront.simulate_restore/2
  ├── entry_id = @subscription_entry_id (module constant)
  ├── provider_reference = f(@subscription_entry_id)   ← SAME as purchase of that entry
  ├── evidence_ref       = g(@subscription_entry_id, "restore")
  └── returns %ReconciliationEvidence{source: :storefront, provider: "mock", event_kind: "restore", ...}
```

### Recommended Project Structure

```
examples/phoenix_host/lib/crosswake_example/commerce/
├── mock_storefront.ex       ← NEW (Phase 34)
├── reconciliation_keys.ex   ← existing Phase 21 (no changes)
├── reconciliation_inbox.ex  ← existing Phase 21 (no changes)
└── entitlement_projection.ex ← existing Phase 21 (no changes)

test/crosswake/proof/
├── phase34_mock_storefront_test.exs  ← NEW (Phase 34) — TWO test groups
├── phase33_commerce_corridor_routes_test.exs  ← existing
└── phase21_reconciliation_example_test.exs    ← existing
```

### Pattern 1: MockStorefront Module Shape

**What:** Pure-Elixir evidence emitter module with two public functions, a module constant, and `@moduledoc` swap-target documentation.

**When to use:** Whenever example code needs to manufacture stable provider identity from intent structs.

**Example (synthesized from contracts.ex + CONTEXT.md decisions):**

```elixir
# Source: verified against lib/crosswake/commerce/contracts.ex + 34-CONTEXT.md decisions
defmodule CrosswakeExample.Commerce.MockStorefront do
  @moduledoc """
  Pure-Elixir mock storefront for the Crosswake v3.4 Commerce Archetype proof corridor.

  Manufactures deterministic `ReconciliationEvidence` from `PurchaseIntent` and
  `RestoreIntent` structs using stable provider identity — no native payment SDK code.

  ## Drop-in swap target

  A real provider adapter would replace exactly two functions in this module:

    * `simulate_purchase/1` — returns `ReconciliationEvidence` for a purchase event.
      A real adapter (one wrapping a native payment SDK) would call the native payment
      sheet here and return a receipt or transaction token as `provider_reference`.

    * `simulate_restore/1` — returns `ReconciliationEvidence` for a restore event.
      A real adapter would call the native restore flow here.

  Everything downstream — `ReconciliationInbox.ingest_evidence/2`,
  `ReconciliationKeys.event_key/1`, `EntitlementProjection.project_snapshot/2` —
  is provider-neutral and unchanged by the swap.
  """

  alias Crosswake.Commerce.Contracts

  # Single canonical subscription product. Both simulate_purchase (for this entry)
  # and simulate_restore anchor provider identity on this constant, so restore evidence
  # shares the same subject_key as the prior purchase.
  @subscription_entry_id "sub_pro_monthly"

  @spec simulate_purchase(Contracts.PurchaseIntent.t(), keyword()) ::
          Contracts.ReconciliationEvidence.t()
  def simulate_purchase(%Contracts.PurchaseIntent{} = intent, opts \\ []) do
    captured_at = Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601())

    %Contracts.ReconciliationEvidence{
      source: :storefront,
      provider: "mock",
      provider_reference: provider_reference(intent.entry_id),
      event_kind: "purchase",
      evidence_ref: evidence_ref(intent.entry_id, "purchase"),
      captured_at: captured_at
    }
  end

  @spec simulate_restore(Contracts.RestoreIntent.t(), keyword()) ::
          Contracts.ReconciliationEvidence.t()
  def simulate_restore(%Contracts.RestoreIntent{} = _intent, opts \\ []) do
    captured_at = Keyword.get(opts, :captured_at, DateTime.utc_now() |> DateTime.to_iso8601())

    %Contracts.ReconciliationEvidence{
      source: :storefront,
      provider: "mock",
      provider_reference: provider_reference(@subscription_entry_id),
      event_kind: "restore",
      evidence_ref: evidence_ref(@subscription_entry_id, "restore"),
      captured_at: captured_at
    }
  end

  defp provider_reference(entry_id), do: "mock_txn_" <> entry_id
  defp evidence_ref(entry_id, event_kind), do: "mock_evt_" <> entry_id <> "_" <> event_kind
end
```

### Pattern 2: Replay Invariant Test — Hermetic ExUnit Shape

**What:** Untagged hermetic test that uses `Code.require_file` at module scope to load example-host modules, then exercises `simulate_purchase` + `ingest_evidence` to prove `replay?: true` when `provider_reference` is stable.

**When to use:** Any Phase 34 proof test that calls example-host modules directly.

**Example (synthesized from phase21_reconciliation_example_test.exs pattern):**

```elixir
# Source: verified against test/crosswake/proof/phase21_reconciliation_example_test.exs
# Code.require_file at module scope (top-level, before defmodule) — NOT inside setup/test
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)

defmodule Crosswake.Proof.Phase34MockStorefrontTest do
  use ExUnit.Case, async: false
  # NO @moduletag :requires_example_host — this test is hermetic / merge-blocking

  alias Crosswake.Commerce.Contracts
  alias CrosswakeExample.Commerce.MockStorefront
  alias CrosswakeExample.Commerce.ReconciliationInbox
  alias CrosswakeExample.Commerce.ReconciliationKeys

  test "same entry_id with different correlation_id yields replay?: true" do
    intent1 = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c1"}
    intent2 = %Contracts.PurchaseIntent{entry_id: "sub_pro_monthly", correlation_id: "c2"}

    evidence1 = MockStorefront.simulate_purchase(intent1)
    evidence2 = MockStorefront.simulate_purchase(intent2)

    {:ok, first} = ReconciliationInbox.ingest_evidence(evidence1, correlation_id: "c1")
    {:ok, replay} = ReconciliationInbox.ingest_evidence(evidence2,
                      correlation_id: "c2",
                      seen_event_keys: [first.event_key])

    assert replay.replay? == true
    assert replay.event_key == first.event_key
  end

  test "different entry_id yields distinct event_key and replay?: false" do
    intent_a = %Contracts.PurchaseIntent{entry_id: "entry_a", correlation_id: "c1"}
    intent_b = %Contracts.PurchaseIntent{entry_id: "entry_b", correlation_id: "c1"}

    evidence_a = MockStorefront.simulate_purchase(intent_a)
    evidence_b = MockStorefront.simulate_purchase(intent_b)

    {:ok, result_a} = ReconciliationInbox.ingest_evidence(evidence_a)
    {:ok, result_b} = ReconciliationInbox.ingest_evidence(evidence_b,
                        seen_event_keys: [result_a.event_key])

    refute result_b.replay?
    refute result_a.event_key == result_b.event_key
  end
end
```

### Pattern 3: Provider-Vocabulary Fence Test

**What:** Test that reads the `MockStorefront` source file with `File.read!/1` (project-root-relative path), lowercases it with `String.downcase/1`, and asserts absence of forbidden tokens with `refute String.contains?/2`.

**When to use:** Any source-text vocabulary fence for this phase.

**Key detail:** The path passed to `File.read!` is a plain string relative to the mix project root (the working directory when `mix test` runs), NOT relative to `__DIR__`. This is the exact idiom from `phase21_reconciliation_example_test.exs` lines 149-163. [VERIFIED: phase21_reconciliation_example_test.exs]

```elixir
# Source: verified against test/crosswake/proof/phase21_reconciliation_example_test.exs lines 141-163
test "MockStorefront source contains no forbidden provider tokens" do
  forbidden_tokens = [
    "store" <> "kit",
    "play" <> "_billing",
    "play" <> " " <> "billing",
    "revenue" <> "cat"
  ]

  content =
    File.read!("examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex")
    |> String.downcase()

  for forbidden <- forbidden_tokens do
    refute String.contains?(content, forbidden),
           "mock_storefront.ex leaked provider token #{forbidden}"
  end
end
```

**Why tokens are split across string concatenation:** The `"store" <> "kit"` idiom (not `"storekit"`) prevents the fence test's own source from triggering the fence if the fence were ever applied to the test file itself. This is the established project convention. [VERIFIED: phase21_reconciliation_example_test.exs, phase23_commerce_support_proof_test.exs]

### Anti-Patterns to Avoid

- **Putting `correlation_id` in `provider_reference` or `evidence_ref`:** This would make `event_key` differ between retries of the same purchase, so `replay?: true` would never fire. The entire WIRE-03 invariant depends on stable identity derived from `entry_id`.
- **Using `{:ok, evidence}` return shape:** D-10 specifies direct struct return. A pure mock cannot fail; wrapping in a tuple adds ceremony with no benefit.
- **Adding `@moduletag :requires_example_host` to the Phase 34 invariant test:** This would exclude it from the hermetic lane, breaking the merge-blocking contract. The test is hermetic (uses `Code.require_file` + pure function calls).
- **Modifying `lib/crosswake/commerce/contracts.ex`:** These are SHIPPED structs in `crosswake 0.1.0`. No changes whatsoever.
- **Modifying `ReconciliationKeys`, `ReconciliationInbox`, or `EntitlementProjection`:** Phase 34 reuses these modules as-is; changes belong in later phases.
- **Using `async: true` in the proof test module:** The established pattern for proof tests using `Code.require_file` is `async: false`. [VERIFIED: phase21_reconciliation_example_test.exs line 6]
- **Reading the fence file with `Path.join(__DIR__, "...")` path arithmetic:** The project convention uses bare project-root-relative strings (e.g. `"examples/phoenix_host/..."`) passed to `File.read!`. [VERIFIED: phase21_reconciliation_example_test.exs lines 150-153]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Idempotency key composition | Custom key builder | `ReconciliationKeys.event_key/1` | Already ships (Phase 21); key composition formula (`event::provider::provider_reference::event_kind::evidence_ref`) is proven correct |
| Replay detection | Custom seen-set lookup | `ReconciliationInbox.ingest_evidence/2` with `seen_event_keys:` opt | Already ships (Phase 21); handles MapSet and list forms |
| Source canonicalization | Custom atom/string check | `Contracts.canonical_reconciliation_evidence_source/1` (used internally by `ingest_evidence`) | Already in lib; incorrect source values return `{:error, ...}` |
| Evidence struct construction | Map or keyword list | `struct!(Contracts.ReconciliationEvidence, ...)` OR direct `%Contracts.ReconciliationEvidence{}` | `struct!` raises on missing enforce_keys at build time, surfacing bugs immediately |

**Key insight:** The entire idempotency machinery is pre-built. Phase 34's job is to feed it correctly-constructed mock evidence, not to re-implement any part of it.

---

## Verified Struct Signatures

These are the exact enforce_keys and field lists verified against live source. The planner must use these exact fields — no assumptions.

### `Crosswake.Commerce.Contracts.PurchaseIntent` [VERIFIED: lib/crosswake/commerce/contracts.ex lines 19-28]

```
@enforce_keys [:entry_id, :correlation_id]
defstruct [:entry_id, :correlation_id]
```
- `entry_id :: String.t()` — stable purchase identity
- `correlation_id :: String.t()` — transient device/session id

### `Crosswake.Commerce.Contracts.RestoreIntent` [VERIFIED: lib/crosswake/commerce/contracts.ex lines 30-38]

```
@enforce_keys [:correlation_id]
defstruct [:correlation_id]
```
- `correlation_id :: String.t()` — only field; no `entry_id`; that is why D-07 uses a module constant

### `Crosswake.Commerce.Contracts.ReconciliationEvidence` [VERIFIED: lib/crosswake/commerce/contracts.ex lines 150-183]

```
@enforce_keys [:source, :provider, :provider_reference, :event_kind, :evidence_ref, :captured_at]
defstruct [:source, :provider, :provider_reference, :event_kind, :evidence_ref, :captured_at,
           :integrity_digest, :idempotency_ref]
```
- `source :: :device | :storefront | :webhook | :support` — atom, not string
- `provider :: String.t()` — plain string; `"mock"` for this phase
- `provider_reference :: String.t()` — stable per-purchase identity
- `event_kind :: String.t()` — `"purchase"` or `"restore"`
- `evidence_ref :: String.t()` — stable per-event identity
- `captured_at :: String.t()` — ISO 8601 string
- `integrity_digest :: String.t() | nil` — optional
- `idempotency_ref :: String.t() | nil` — optional

---

## Verified Key Compositions

### `ReconciliationKeys.event_key/1` [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex lines 14-24]

```
"event" <> "::" <> canonical(provider) <> "::" <> opaque(provider_reference)
       <> "::" <> canonical(event_kind) <> "::" <> opaque(evidence_ref)
```

Where `canonical/1` = downcased+trimmed string, `opaque/1` = trimmed string (case-preserved).
`correlation_id` is **NOT** a component of `event_key`. [VERIFIED]

For mock purchase of `entry_id = "sub_pro_monthly"`:
- `event_key = "event::mock::mock_txn_sub_pro_monthly::purchase::mock_evt_sub_pro_monthly_purchase"`

Two calls with same `entry_id`, different `correlation_id` → **identical** `event_key`.

### `ReconciliationKeys.subject_key/2` [VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex lines 26-43]

```
"subject" <> "::" <> canonical(provider) <> "::" <> opaque(provider_reference)
           [+ "::" <> "group" <> "::" <> opaque(group_id)  — only if opts[:group_id] present]
```

For mock: `subject_key = "subject::mock::mock_txn_sub_pro_monthly"`.
Purchase and restore of the same canonical subscription product share the same `subject_key` because `provider_reference` is derived from the same `@subscription_entry_id` constant. [VERIFIED]

---

## Verified `ingest_evidence/2` Signature and Return Shape

[VERIFIED: examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex lines 14-37]

```elixir
@spec ingest_evidence(Contracts.ReconciliationEvidence.t(), keyword()) ::
        {:ok, map()} | {:error, term()}
def ingest_evidence(%Contracts.ReconciliationEvidence{} = evidence, opts \\ [])
```

**Opts consumed:**
- `opts[:seen_event_keys]` — list or MapSet of previously-seen event keys; replay if `event_key in seen_event_keys`
- `opts[:correlation_id]` — flows to `trace_metadata` only (not identity)
- `opts[:group_id]` — threaded to `subject_key/2`

**Return map keys on `{:ok, ...}`:**
- `source` — canonicalized atom (`:storefront` etc.)
- `event_key` — string from `ReconciliationKeys.event_key/1`
- `subject_key` — string from `ReconciliationKeys.subject_key/2`
- `status` — `:awaiting_verification` for `"purchase"` and `"restore"` event_kinds (success-like); `:verification_failed` for unknown kinds
- `replay?` — boolean
- `captured_at` — from evidence
- `trace_metadata` — map (includes `correlation_id` if provided)

**Success-like event_kinds** (status = `:awaiting_verification`): `"purchase"`, `"restore"`, `"renewal"`, `"grace_period"`, `"billing_retry"`. [VERIFIED]

---

## CI Lane and Tagging Rules

[VERIFIED: .github/workflows/phase34-proof.yml lines 77-83]

**Merge-blocking job** (`merge-blocking-commerce-proof`) runs:
```bash
mix test --exclude requires_example_host
```

This excludes only tests tagged `@tag :requires_example_host` or `@moduletag :requires_example_host`. All other tests — including untagged tests that use `Code.require_file` — are picked up and run.

**Phase 34 proof test must be untagged** (no `@moduletag :requires_example_host`) to land in the merge-blocking lane. It is legitimately hermetic because it uses `Code.require_file` at module scope and calls only pure functions + in-memory `ingest_evidence`.

**Phase 21 test** (`phase21_reconciliation_example_test.exs`) carries `@moduletag :requires_example_host` (line 11) — it is EXCLUDED from the hermetic lane. The Phase 34 test follows a different model: no `@moduletag`, `Code.require_file` at top, same pure-function shape as phase21 but without the server dependency.

---

## Common Pitfalls

### Pitfall 1: Using `correlation_id` in identity derivation
**What goes wrong:** `provider_reference` or `evidence_ref` includes `correlation_id` → `event_key` differs between retries → `replay?: true` never fires → WIRE-03 invariant broken.
**Why it happens:** `correlation_id` is available on `PurchaseIntent` and it's tempting to use it as a "unique" identifier.
**How to avoid:** `provider_reference = "mock_txn_" <> intent.entry_id` (D-01). `correlation_id` only passes through via `opts[:correlation_id]` to `ingest_evidence`.
**Warning signs:** Replay test fails; `first.event_key != replay.event_key` despite same `entry_id`.

### Pitfall 2: Tagging the Phase 34 proof test with `:requires_example_host`
**What goes wrong:** Test is excluded from `mix test --exclude requires_example_host` → merge-blocking lane never exercises it → WIRE-03 is not merge-blocking.
**Why it happens:** Phase 21's test has this tag and uses the same `Code.require_file` pattern, causing confusion.
**How to avoid:** Phase 21's test has the tag because it depended on the compiled example host at phase5-proof time. Phase 34 uses `Code.require_file` precisely to avoid that dependency. No `@moduletag`.
**Warning signs:** Running `mix test --exclude requires_example_host` doesn't run the Phase 34 proof test.

### Pitfall 3: Writing `async: true` in the proof test
**What goes wrong:** Possible race conditions on shared modules loaded via `Code.require_file`.
**Why it happens:** Test author assumes hermetic = async-safe.
**How to avoid:** Use `async: false` following the phase21 pattern. [VERIFIED: phase21_reconciliation_example_test.exs line 6]

### Pitfall 4: Using `{:ok, evidence}` return from simulate_purchase/simulate_restore
**What goes wrong:** Downstream test assertions fail; Phase 35 LiveView call sites would need pattern-matching boilerplate for a function that cannot fail.
**Why it happens:** Convention in Elixir to wrap fallible operations.
**How to avoid:** D-10 specifies direct struct return. A pure mock cannot fail.

### Pitfall 5: Fence test reads file with `__DIR__`-relative path
**What goes wrong:** `File.read!(Path.join(__DIR__, "../../../examples/..."))` may work but diverges from project convention.
**Why it happens:** Confusion between `Code.require_file` (uses `__DIR__` as second argument) and `File.read!` (uses project-root-relative bare string).
**How to avoid:** `File.read!("examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex")` — bare project-root-relative path, same as phase21 lines 150-153. [VERIFIED]

### Pitfall 6: Placing the fence token strings as literals (not split)
**What goes wrong:** If a fence test guards the test file itself, the literal token in the test source would trigger the fence.
**Why it happens:** Writing `"storekit"` directly instead of `"store" <> "kit"`.
**How to avoid:** Use the established concatenation idiom: `"store" <> "kit"`, `"play" <> "_billing"`, `"play" <> " " <> "billing"`, `"revenue" <> "cat"`. [VERIFIED: phase21 line 142-147, phase23 lines 33-38]

### Pitfall 7: Modifying shipped lib modules
**What goes wrong:** `crosswake 0.1.0` contracts change → downstream adopters see breaking changes → version contract violation.
**Why it happens:** Apparent missing field or convenience constructor not in `contracts.ex`.
**How to avoid:** Zero changes to anything under `lib/crosswake/`. Build mock entirely in `examples/phoenix_host/`.

---

## Code Examples

### evidence_ref formula for restore
```elixir
# Source: CONTEXT.md D-02 + verified field names from contracts.ex
evidence_ref = "mock_evt_" <> @subscription_entry_id <> "_restore"
# = "mock_evt_sub_pro_monthly_restore"
```

### struct! construction idiom (from phase21 sample_evidence helper)
```elixir
# Source: verified against test/crosswake/proof/phase21_reconciliation_example_test.exs lines 165-178
struct!(Contracts.ReconciliationEvidence, %{
  source: :device,
  provider: "provider_a",
  provider_reference: "tx_123",
  event_kind: "purchase",
  evidence_ref: "receipt_123",
  captured_at: "2026-05-27T10:00:00Z",
  integrity_digest: "sha256:abc",
  idempotency_ref: "idem_123"
})
```

### ingest_evidence replay detection call (from phase21 test)
```elixir
# Source: verified against test/crosswake/proof/phase21_reconciliation_example_test.exs lines 35-49
{:ok, first_attempt} = ReconciliationInbox.ingest_evidence(evidence)

{:ok, replay_attempt} =
  ReconciliationInbox.ingest_evidence(
    evidence,
    seen_event_keys: [first_attempt.event_key]
  )

assert replay_attempt.replay?
assert replay_attempt.event_key == first_attempt.event_key
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 21 test used `@moduletag :requires_example_host` (full example host compile required) | Phase 34 uses `Code.require_file` at module scope — hermetic, no server needed | Phase 33 established `phase34-proof.yml` hermetic lane | Phase 34 tests are merge-blocking without a running example host |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@subscription_entry_id "sub_pro_monthly"` as the concrete constant value | Standard Stack / Pattern 1 | Cosmetic only — Claude's discretion per CONTEXT.md; any valid string works |
| A2 | `provider_reference` prefix `"mock_txn_"` and `evidence_ref` prefix `"mock_evt_"` | Pattern 1 | Cosmetic only — Claude's discretion per CONTEXT.md; any stable prefix works |
| A3 | Phase 34 proof test file name `phase34_mock_storefront_test.exs` | Recommended Project Structure | Naming convention only; no functional impact |

**All structural facts** (struct fields, function signatures, key compositions, CI commands, test idioms, path conventions) have been verified directly against live source files.

---

## Open Questions (RESOLVED)

> Both questions below are answered inline with `[VERIFIED]` source citations; neither
> blocks planning or execution.

1. **Does `seen_event_keys` accept a plain list in the actual implementation?**
   - What we know: Yes — `ReconciliationInbox` line 60: `defp seen_event_key?(event_key, seen_event_keys) when is_list(seen_event_keys), do: event_key in seen_event_keys` [VERIFIED]
   - What's unclear: Nothing. Both list and MapSet are accepted.
   - Recommendation: Use a plain list in the replay test (simplest form).

2. **Does the phase33 hermeticity guard assert against `code.require_file` presence?**
   - What we know: Yes — `phase33_commerce_corridor_routes_test.exs` lines 96-98 assert `refute Regex.match?(~r/code\.require_file\s*\(/, source)`. [VERIFIED]
   - What's unclear: Whether a Phase 34 test should have a similar self-guard.
   - Recommendation: The Phase 34 test uses `Code.require_file` legitimately, so it does NOT need a self-guard against it. The phase23-style hermeticity guard (`refute String.contains?(source, "crosswakeexample.router")`) is appropriate to prevent accidentally importing the example-host router; the Phase 34 test is already purely functional.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — phase is pure Elixir code + test with no new tools, services, or runtimes beyond what is already in the project).

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib, no version needed) |
| Config file | `test/test_helper.exs` (single line: `ExUnit.start()`) |
| Quick run command | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOCK-01 | `simulate_purchase/1` returns `ReconciliationEvidence{source: :storefront, provider: "mock", event_kind: "purchase"}` | unit | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ Wave 0 |
| MOCK-02 | `simulate_restore/1` returns evidence with `event_kind: "restore"` | unit | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ Wave 0 |
| MOCK-03 | `@moduledoc` names the two swap-target functions | source-text assertion | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ Wave 0 |
| WIRE-03 | Replay: same `entry_id`, different `correlation_id` → `replay?: true`; restore shares `subject_key` with purchase | unit | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ Wave 0 |
| WIRE-03 (fence) | MockStorefront source has no `storekit`, `play_billing`, `play billing`, `revenuecat` tokens | source fence | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase34_mock_storefront_test.exs`
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Nyquist Coverage: Minimum Test Cases

The following test cases adequately sample the observable behaviors (Nyquist principle: one positive + one negative case per invariant is sufficient):

| Test Case | What It Proves |
|-----------|---------------|
| `simulate_purchase` with explicit `entry_id` returns correct struct fields | MOCK-01 shape |
| `simulate_restore` returns `event_kind: "restore"`, `source: :storefront`, `provider: "mock"` | MOCK-02 shape |
| Same `entry_id`, `correlation_id = "c1"` → `correlation_id = "c2"` → `replay?: true` | WIRE-03 replay (positive) |
| Different `entry_id` values → `replay?: false` | WIRE-03 replay (negative: not all purchases are replays) |
| Restore `subject_key` == purchase `subject_key` for same canonical entry | WIRE-03 restore shares identity |
| MockStorefront source text contains none of the four forbidden tokens | Success Criterion #5 vocabulary fence |

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase34_mock_storefront_test.exs` — covers all 6 test cases above
- [ ] `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` — the module under test

*(No framework install needed — ExUnit ships with Elixir. No shared fixtures file needed — the test is self-contained.)*

---

## Security Domain

> `security_enforcement` is not explicitly set to `false` in `.planning/config.json`, so this section is included. However, Phase 34 is a pure-Elixir example module with no network I/O, no user input, no authentication, no cryptography, and no persistence. The applicable ASVS analysis is brief.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — no auth |
| V3 Session Management | No | N/A — no sessions |
| V4 Access Control | No | N/A — no access control |
| V5 Input Validation | No | N/A — inputs are typed structs enforced by `@enforce_keys`; no user string input |
| V6 Cryptography | No | N/A — no cryptography used |

**Note:** `integrity_digest` and `idempotency_ref` fields are optional and are NOT set by MockStorefront (they are nil). This is correct for a mock — these fields are for real provider receipts.

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Provider token leakage into source | Information Disclosure | Vocabulary fence test (Success Criterion #5) |

---

## Sources

### Primary (HIGH confidence)
- `lib/crosswake/commerce/contracts.ex` — verified exact struct fields and enforce_keys for `PurchaseIntent`, `RestoreIntent`, `ReconciliationEvidence`
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` — verified `event_key/1`, `subject_key/2`, `trace_metadata/2` composition
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — verified `ingest_evidence/2` signature, opts, return shape, `seen_event_keys` mechanic
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — verified `derived_state/1` and `project_snapshot/2` (downstream, Phase 35)
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — verified `Code.require_file` idiom, `@moduletag :requires_example_host`, `sample_evidence` fixture shape, vocabulary fence pattern (project-root-relative `File.read!`)
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — verified `@forbidden_provider_tokens` module attribute and `String.downcase` fence pattern
- `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs` — verified untagged hermetic test shape, `__ENV__.file` self-guard pattern
- `.github/workflows/phase34-proof.yml` — verified `mix test --exclude requires_example_host` command and merge-blocking lane conditions
- `.planning/phases/34-mockstorefront-and-idempotency-invariants/34-CONTEXT.md` — locked decisions D-01..D-11
- `.planning/REQUIREMENTS.md` — MOCK-01/02/03, WIRE-03, AF-01..AF-08

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` — confirmed `async: false` for proof tests (project-level decision)

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — no new packages; all modules verified against live source
- Architecture: HIGH — all three key compositions and return shapes verified from live code
- Pitfalls: HIGH — derived from direct reading of phase21/phase23 test idioms and CI workflow
- Test patterns: HIGH — every assertion format verified against existing test files

**Research date:** 2026-05-29
**Valid until:** Stable (no external dependencies; only changes if example-host modules are modified, which is out of scope for Phase 34)
