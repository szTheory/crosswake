# Phase 37: Guides Walkthrough And Docs-Contract Lock - Research

**Researched:** 2026-05-29
**Domain:** Elixir ExUnit docs-contract testing, guides/commerce.md structure
**Confidence:** HIGH (all findings verified directly from codebase; no external sources needed)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (USER-CONFIRMED):** The walkthrough is a new `### Paywall Corridor Walkthrough` H3 subsection inside Layer 1 "Commerce Support Truth", placed after the existing `### Minimal Reconciliation Inbox Example`.
- **D-02 (USER-CONFIRMED):** Do NOT add a 4th top-level H2 layer. The three H2 layers remain exactly: `## Commerce Support Truth` / `## Reviewer And Storefront Playbooks` / `## Rough Edges And Non-Claims`.
- **D-03 (USER-CONFIRMED):** Anchor-only. Each walkthrough step renders prose + named example-host module/function + its relative file path. No copied code blocks.
- **D-04:** Steps to anchor, in order: route declaration → MockStorefront purchase/restore call → ReconciliationInbox.ingest_evidence/2 evidence ingestion → project_snapshot/2 snapshot projection → derived_state/1 derived state → PaywallLive rendering.
- **D-05 (USER-CONFIRMED):** The walkthrough opens with an explicit mock-vs-real callout stating MockStorefront uses `provider: "mock"` and that no StoreKit or Play Billing code is shipped.
- **D-06 (USER-CONFIRMED):** Hybrid binding — two complementary assertion classes appended to `commerce_test.exs`: (1) string-presence mirroring `content =~ ...` idiom; (2) live-code guard via `Code.require_file` of PURE example commerce modules at module scope + `function_exported?/3` assertions.
- **D-07 (USER-CONFIRMED):** Regression fences — phase23 three-layer assertion + four-non-claims assertion must still pass unchanged.
- **D-08 (USER-CONFIRMED):** The walkthrough explicitly cites `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` as the hermetic merge-blocking proof.

### Claude's Discretion

- Whether the guide test gains `async: false` once it `Code.require_file`s the pure example modules.
- Exact relative `Code.require_file` paths from `test/crosswake/guides/` to the example-host pure commerce modules.
- Whether to assert the proof-file path string appears in the guide (locking D-08).
- Exact step prose, anchor formatting, describe/test block naming, assertion message wording.
- Whether to factor the new live-guard module list into a shared `@anchored_functions` attribute.

### Deferred Ideas (OUT OF SCOPE)

- Embedded/extracted code snippets in the walkthrough (D-03 anchor-only).
- Live-guarding `PaywallLive` / runtime modules (Phase 36 D-02).
- ROADMAP SC#3/SC#4 rewording from Phase 36.
- ExDoc zero-warnings cleanup (HEX-03).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-01 | `guides/commerce.md` gains an end-to-end mock-corridor walkthrough section that anchors each step to a named example-host module and function | Confirmed: insertion point is after `### Minimal Reconciliation Inbox Example` (line 103). All six anchor targets verified. D-05 mock-vs-real callout vocabulary sourced from Layer 3. |
| DOCS-02 | A docs-contract test locks the walkthrough's module/function references against the example host without weakening the existing phase23 three-layer guide-structure assertions | Confirmed: existing test idioms, `async:` setting, phase23 fence line ranges, and `Code.require_file` idiom all documented. |
</phase_requirements>

---

## Summary

Phase 37 is a DOCS + TEST phase only. Two files change: `guides/commerce.md` (one new H3 subsection inserted within the existing Layer 1 H2) and `test/crosswake/guides/commerce_test.exs` (new assertions appended; no scaffolding changes). All shipped lib and example-host code is locked from Phases 33-36.

The guide edit is mechanical: insert a `### Paywall Corridor Walkthrough` H3 after the existing `### Minimal Reconciliation Inbox Example` H3 (currently ending around line 115 of `guides/commerce.md`). The walkthrough contains six anchor steps in prose+name+path form (no code blocks per D-03) preceded by a `provider: "mock"` / no-StoreKit / no-Play-Billing callout (D-05, SC#2).

The test edit adds two assertion classes to `commerce_test.exs`: string-presence assertions (D-06.1) in the existing `content =~ ...` idiom, and live-code guards (D-06.2) using the same `Code.require_file` pattern as the Phase 34/36 hermetic proofs. The live guards require `async: false` (see Discretion resolution below). The phase23 regression fences at lines 217-289 are structurally unchanged because no new H2 is added.

**Primary recommendation:** Add the H3 walkthrough to `guides/commerce.md`, then append one `describe "paywall corridor walkthrough (DOCS-01/DOCS-02)"` block to `commerce_test.exs` containing both the string-presence and `function_exported?` assertions, with `async: false` set at module level.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Walkthrough prose + anchor steps | Docs (guides/commerce.md) | — | Static markdown; no runtime |
| String-presence assertions (D-06.1) | ExUnit test (commerce_test.exs) | — | Reads file at test time |
| Live-code guard (D-06.2) | ExUnit test (commerce_test.exs) | Pure example commerce modules | Requires example modules at module scope; no server |
| Regression fences (D-07) | Existing tests (unchanged) | — | Phase23 assertions structurally preserved by H3-only insertion |

---

## Research Finding 1: guides/commerce.md — Current Structure

**Source:** Direct file read. [VERIFIED: codebase]

### Three H2 headings (verbatim)

```
## Commerce Support Truth
## Reviewer And Storefront Playbooks
## Rough Edges And Non-Claims
```

These are the exact strings asserted by the phase23 three-layer test at lines 217-228 of `commerce_test.exs`. D-02 requires them to remain the ONLY H2s — no new H2.

### Layer 1 internal H3 structure (Commerce Support Truth)

```
### Normalized Commerce Vocabulary           (line ~17)
### Commerce Corridor Ownership              (line ~29)
#### Proof Posture                           (line ~42)
### Entitlement Snapshot Lanes               (line ~49)
### Authority vs Evidence                    (line ~64)
### Commerce Moment Map                      (line ~70)
### Canonical Corridor Denial And Fallback Codes  (line ~79)
### The Canonical Reconciliation Flow        (line ~93)
### Minimal Reconciliation Inbox Example     (line ~103)
### Backend Idempotency                      (line ~117)
### Deterministic Projection Precedence      (line ~128)
### Fallback Behavior                        (line ~140)
```

**Insertion point for D-01:** After `### Minimal Reconciliation Inbox Example` section ends (~line 115). The new `### Paywall Corridor Walkthrough` H3 goes between `### Minimal Reconciliation Inbox Example` and `### Backend Idempotency`.

### Layer 3 canonical "X is not shipped" non-claim vocabulary (D-05 source)

The exact phrases from `## Rough Edges And Non-Claims` for reuse in the D-05 mock-vs-real callout:

- `"StoreKit adapter is not shipped"` (line 250)
- `"Play Billing adapter is not shipped"` (line 251)
- `provider: "mock"` appears in `mock_storefront.ex` (not in the guide text itself, but in the CONTEXT D-05 callout requirement)

For the walkthrough's mock-vs-real callout, the vocabulary to reuse is:
- **"no StoreKit"** maps to: `"Crosswake does not ship a StoreKit adapter"`
- **"no Play Billing"** maps to: `"Crosswake does not ship a Play Billing adapter"`
- **`provider: "mock"`** is the explicit value in `MockStorefront` — name it verbatim

The four non-claims tested at lines 265-289 (D-07 fence):
1. `~r/StoreKit adapter is not shipped/i`
2. `~r/Play Billing adapter is not shipped/i`
3. `~r/Device-local entitlement authority is not shipped/i`
4. `~r/Offline purchase replay is not shipped/i`
5. (fifth) `~r/Storefront purchase UI is not shipped/i`

All five must remain passing after the guide edit. The walkthrough's mock-vs-real callout must not accidentally satisfy or break any of these by reusing their exact phrasing — it should reference mock-vs-real positioning, not restate the non-claims (they remain in Layer 3).

---

## Research Finding 2: commerce_test.exs — Current Test Idioms

**Source:** Direct file read. [VERIFIED: codebase]

### Module header

```elixir
defmodule Crosswake.Guides.CommerceTest do
  use ExUnit.Case, async: true   # CURRENTLY async: true

  @guide_path Path.join([File.cwd!(), "guides", "commerce.md"])

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end
```

The `@guide_path` macro-time computation uses `File.cwd!()` (project root). The `setup_all` reads the file once and passes `content` to all tests.

### Existing `content =~ ...` assertion form

All existing assertions use one of these forms:
```elixir
assert content =~ "exact string"
assert content =~ ~r/regex pattern/i
```

And section-split helpers:
```elixir
content
|> String.split("## Section Heading")
|> List.last()
|> String.split("## Next Heading")
|> hd()
```

New assertions follow this exact pattern — no new helpers needed.

### Phase23 regression fences (D-07) — exact location and content

**Three-layer heading test** (lines 217-228):
```elixir
test "commerce guide publishes three explicit layer headings", %{content: content} do
  assert content =~ ~r/^## Commerce Support Truth\s*$/m, ...
  assert content =~ ~r/^## Reviewer And Storefront Playbooks\s*$/m, ...
  assert content =~ ~r/^## Rough Edges And Non-Claims\s*$/m, ...
end
```

**Four-non-claims test** (lines 265-289):
```elixir
test "non-claims section explicitly names StoreKit, Play Billing, device-local authority, and offline replay",
     %{content: content} do
  non_claims_section = content |> String.split("## Rough Edges And Non-Claims") |> List.last()
  assert non_claims_section =~ ~r/StoreKit adapter is not shipped/i, ...
  assert non_claims_section =~ ~r/Play Billing adapter is not shipped/i, ...
  assert non_claims_section =~ ~r/Device-local entitlement authority is not shipped/i, ...
  assert non_claims_section =~ ~r/Offline purchase replay is not shipped/i, ...
  assert non_claims_section =~ ~r/Storefront purchase UI is not shipped/i, ...
end
```

These assertions pass structurally unchanged because:
1. The new H3 is inside Layer 1 — doesn't add or remove any H2 heading.
2. The non-claims remain unmodified in Layer 3.

---

## Research Finding 3: Code.require_file Idiom (Phase 34/36 Pattern)

**Source:** Direct file read of `phase34_mock_storefront_test.exs` and `phase34_paywall_corridor_proof_test.exs`. [VERIFIED: codebase]

### The idiom (verbatim from phase34 proof files)

File-level, BEFORE the `defmodule` declaration:

```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
```

### Relative path from `test/crosswake/guides/` (VERIFIED)

The `guides/` test directory is at the same depth as `proof/` — both are `test/crosswake/{guides,proof}/`. The relative path from `test/crosswake/guides/` to the example commerce modules is **identical** to the proof path:

```
"../../../examples/phoenix_host/lib/crosswake_example/commerce/<module>.ex"
```

Verified by computing: `os.path.relpath` from `test/crosswake/guides` to `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` = `../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex`.

### Module load order (dependency-correct)

The load order matters because `ReconciliationInbox` aliases `ReconciliationKeys`. Load order must be:

```
1. reconciliation_keys.ex       (no example-host dependencies)
2. reconciliation_inbox.ex      (depends on ReconciliationKeys)
3. mock_storefront.ex           (depends on Contracts only — lib/)
4. entitlement_projection.ex    (depends on Contracts only — lib/)
5. mock_backend.ex              (depends on EntitlementProjection + Logger + Phoenix.PubSub)
```

The proof tests load `reconciliation_keys` first, then `reconciliation_inbox`, then the others. Mirror this order in the guide test.

### async: false is required

Both Phase 34 proof tests use `async: false`:
```elixir
use ExUnit.Case, async: false
```

The Phase 34 corridor proof explicitly tests this at line 193:
```elixir
test "proof uses async: false (required for hermetic determinism)" do
  source = File.read!(__ENV__.file)
  assert String.contains?(source, "async: false"), ...
end
```

**Recommendation for the guide test:** Switch `commerce_test.exs` from `async: true` to `async: false` once `Code.require_file` calls are added at module scope. Rationale: module-scope `require_file` runs at compile/load time before any test can run. If two test modules race to `require_file` the same Elixir module, the second call is a no-op (Elixir deduplicates compiled modules) but the internal module state could be in an inconsistent compilation state. The proof tests both use `async: false` for this reason. The guide test should follow the same pattern for safety.

---

## Research Finding 4: Shipped Example Module Functions — Live-Guard Targets

**Source:** Direct file reads of all shipped commerce modules. [VERIFIED: codebase]

### MockStorefront (pure, require_file-safe)

File: `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`
Module: `CrosswakeExample.Commerce.MockStorefront`

| Function | Arity | `function_exported?` safe? |
|----------|-------|---------------------------|
| `simulate_purchase/2` | 2 (intent, opts \\ []) | YES |
| `simulate_restore/2` | 2 (intent, opts \\ []) | YES |

Note: opts default to `[]` so arity is 2.

### ReconciliationInbox (pure, require_file-safe)

File: `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
Module: `CrosswakeExample.Commerce.ReconciliationInbox`

| Function | Arity | `function_exported?` safe? |
|----------|-------|---------------------------|
| `ingest_evidence/2` | 2 (evidence, opts \\ []) | YES |

### EntitlementProjection (pure, require_file-safe)

File: `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
Module: `CrosswakeExample.Commerce.EntitlementProjection`

| Function | Arity | `function_exported?` safe? |
|----------|-------|---------------------------|
| `project_snapshot/2` | 2 (current, incoming) | YES |
| `derived_state/1` | 1 (snapshot) | YES |

### MockBackend (has Phoenix.PubSub reference, but require_file-safe)

File: `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex`
Module: `CrosswakeExample.Commerce.MockBackend`

| Function | Arity | `function_exported?` safe? |
|----------|-------|---------------------------|
| `build_verified_snapshot/2` | 2 (evidence, group_id) | YES |
| `verify_and_broadcast/2` | 2 (evidence, group_id) | NO — calls Phoenix.PubSub |

**Critical:** `MockBackend` uses `require Logger` (safe — compile-time macro) and `Phoenix.PubSub.broadcast/3` inside `verify_and_broadcast/2`. The module compiles cleanly with `Code.require_file` — PubSub is only called at function invocation, not at module load. The Phase 34 corridor proof already `require_file`s `mock_backend.ex` at module scope successfully. The guide test only calls `function_exported?(MockBackend, :build_verified_snapshot, 2)` — never invokes `verify_and_broadcast/2` — so this is hermetic.

**Do NOT assert `function_exported?(MockBackend, :verify_and_broadcast, 2)` in the guide test** — the guide does not anchor that function; only `build_verified_snapshot/2` is narrated.

### PaywallLive (NOT require_file-safe — runtime module)

Module: `CrosswakeExample.PaywallEntryLive` (file: `paywall_entry_live.ex`)

This is a LiveView runtime module. Per Phase 36 D-02 and CONTEXT.md, it MUST NOT be `Code.require_file`d in any test. Anchor it by name in the guide prose only. No `function_exported?` assertion for this module.

### Complete `function_exported?` assertion list for D-06.2

```elixir
assert function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_purchase, 2)
assert function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_restore, 2)
assert function_exported?(CrosswakeExample.Commerce.ReconciliationInbox, :ingest_evidence, 2)
assert function_exported?(CrosswakeExample.Commerce.EntitlementProjection, :project_snapshot, 2)
assert function_exported?(CrosswakeExample.Commerce.EntitlementProjection, :derived_state, 1)
assert function_exported?(CrosswakeExample.Commerce.MockBackend, :build_verified_snapshot, 2)
```

---

## Research Finding 5: Canonical Field Names — provider_reference and evidence_ref

**Source:** Direct read of `lib/crosswake/commerce/contracts.ex` (lines 150-183) and `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex`. [VERIFIED: codebase]

`ReconciliationEvidence` struct (`Contracts.ReconciliationEvidence`) defines:
- `provider_reference` — canonical field name (enforce_keys), type `String.t()`
- `evidence_ref` — canonical field name (enforce_keys), type `String.t()`

Both appear verbatim in `mock_storefront.ex`:
```elixir
provider_reference: provider_reference(intent.entry_id),
evidence_ref: evidence_ref(intent.entry_id, "purchase"),
```

And in the Phase 34 proof fixtures:
```elixir
provider_reference: "mock_txn_sub_pro_monthly",
evidence_ref: "mock_evt_sub_pro_monthly_purchase",
```

These are the CANONICAL names — not aliases. The guide must name them exactly. String-presence assertion (D-06.1):
```elixir
assert content =~ "provider_reference"
assert content =~ "evidence_ref"
```

Note: `provider_reference` appears in the guide's existing `### Backend Idempotency` section (line ~123: `"event_key: dedupe/replay identity for one evidence event (provider, provider_reference, event_kind, evidence_ref)."`), so both strings already exist in the guide. The new assertions will pass even before the walkthrough is added, but adding them explicitly to the guide test makes the D-06.1 contract visible and intentional.

---

## Research Finding 6: Discretion Resolutions

### (a) async: false recommendation

**Recommendation: YES, switch to `async: false`.**

Both Phase 34 proof tests (`phase34_mock_storefront_test.exs` and `phase34_paywall_corridor_proof_test.exs`) use `async: false`. The Phase 36 corridor proof self-tests for `async: false` presence. Module-scope `Code.require_file` calls happen at beam load time — if the same module is required from two concurrently-loading test files, Elixir's `Code` module handles it safely via internal locking, BUT it is conventional in this codebase to use `async: false` alongside module-scope require_file. There is no module-scope collision risk since `Code.require_file` is idempotent (second call is a no-op), but `async: false` is the established pattern and should be adopted.

**Change:** Replace `use ExUnit.Case, async: true` with `use ExUnit.Case, async: false` in `commerce_test.exs`.

### (b) Exact require_file paths from test/crosswake/guides/

**Verified path form** (identical to proof/ path, since both dirs are at `test/crosswake/<dir>/`):

```elixir
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)
```

Load order: keys → inbox → storefront → projection → backend (dependency order).

### (c) Whether to assert the proof-file path string in the guide

**Recommendation: YES, assert the path string.** Low-cost, directly locks D-08, and follows the `content =~` idiom already used everywhere:

```elixir
assert content =~ "test/crosswake/proof/phase34_paywall_corridor_proof_test.exs"
```

This costs one assertion and ensures renaming the proof file without updating the guide breaks the guide test — the exact guarantee D-08 intends.

---

## Architecture Patterns

### Guide Insertion Pattern

```
# guides/commerce.md (Layer 1, after ### Minimal Reconciliation Inbox Example)

### Paywall Corridor Walkthrough

[mock-vs-real callout: provider: "mock", no StoreKit, no Play Billing]

[Step 1: route declaration — corridor: :subscription_default, role: :paywall_entry]
  → CrosswakeExample.Router (examples/phoenix_host/lib/crosswake_example/router.ex)

[Step 2: MockStorefront purchase/restore]
  → CrosswakeExample.Commerce.MockStorefront.simulate_purchase/2
  → CrosswakeExample.Commerce.MockStorefront.simulate_restore/2
  (examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex)

[Step 3: evidence ingestion]
  → CrosswakeExample.Commerce.ReconciliationInbox.ingest_evidence/2
  (examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex)

[Step 4: snapshot projection]
  → CrosswakeExample.Commerce.EntitlementProjection.project_snapshot/2
  (examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex)

[Step 5: derived state]
  → CrosswakeExample.Commerce.EntitlementProjection.derived_state/1
  → four states: :stale | :pending | :denied | :granted

[Step 6: LiveView rendering]
  → CrosswakeExample.PaywallEntryLive
  (examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex)
  — renders the four derived states; see MockBackend.build_verified_snapshot/2 for the
    :granted path (examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex)

[D-08 citation: proof file + CI workflow]
  The full lane runs end-to-end in:
  test/crosswake/proof/phase34_paywall_corridor_proof_test.exs (merge-blocking)
  .github/workflows/phase34-proof.yml (hermetic CI job)
```

### Test Appended Pattern

```elixir
# At file TOP — new require_file lines before defmodule
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)
Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex", __DIR__)

defmodule Crosswake.Guides.CommerceTest do
  use ExUnit.Case, async: false   # changed from async: true

  # ... existing content unchanged ...

  # --- Phase 37: Paywall Corridor Walkthrough docs-contract assertions ---

  describe "paywall corridor walkthrough (DOCS-01 / DOCS-02)" do
    # D-06.1: string-presence assertions
    test "walkthrough heading exists (SC#1)", %{content: content} do
      assert content =~ "### Paywall Corridor Walkthrough", ...
    end

    test "MockStorefront named exactly (SC#3)", %{content: content} do
      assert content =~ "CrosswakeExample.Commerce.MockStorefront", ...
    end

    test "canonical field names present, not aliases (SC#3)", %{content: content} do
      assert content =~ "provider_reference", ...
      assert content =~ "evidence_ref", ...
    end

    test "mock-vs-real callout present (SC#2)", %{content: content} do
      assert content =~ ~s(provider: "mock"), ...
      assert content =~ ~r/no StoreKit/i, ...   # or exact "StoreKit" w/ context
      assert content =~ ~r/no Play Billing/i, ...
    end

    test "proof file cited (D-08)", %{content: content} do
      assert content =~ "test/crosswake/proof/phase34_paywall_corridor_proof_test.exs", ...
    end

    # D-06.2: live-code guard via function_exported?/3
    test "example host functions resolve to real exports (SC#3 live-lock)", _context do
      assert function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_purchase, 2)
      assert function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_restore, 2)
      assert function_exported?(CrosswakeExample.Commerce.ReconciliationInbox, :ingest_evidence, 2)
      assert function_exported?(CrosswakeExample.Commerce.EntitlementProjection, :project_snapshot, 2)
      assert function_exported?(CrosswakeExample.Commerce.EntitlementProjection, :derived_state, 1)
      assert function_exported?(CrosswakeExample.Commerce.MockBackend, :build_verified_snapshot, 2)
    end
  end
end
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Module existence check | Custom file-parsing to check if a function is defined | `function_exported?/3` | Built-in to Elixir; works after `Code.require_file` at module scope; used by all hermetic proofs |
| Guide-to-code binding | Comparing guide prose strings against source code AST | String-presence (`content =~ ...`) + `function_exported?/3` | Established idiom in this codebase; low fragility, high signal |
| Test file loading | `Application.ensure_all_started` or starting a Phoenix server | `Code.require_file` of pure modules only | Phase 36 D-02 hermetic discipline; no server needed for pure functions |

---

## Common Pitfalls

### Pitfall 1: Adding a new H2 heading instead of H3

**What goes wrong:** The phase23 three-layer heading test at line 217 asserts exactly `## Commerce Support Truth`, `## Reviewer And Storefront Playbooks`, and `## Rough Edges And Non-Claims` using `~r/^## ...\s*$/m` (multiline anchored regex). A fourth H2 doesn't break this test — the test checks for presence, not exact count. However, the guide's intro prose says "three explicit layers" — a fourth H2 would contradict it.

**How to avoid:** Insert as `### Paywall Corridor Walkthrough` (H3) — D-01 is explicit. The intro prose stays accurate.

**Warning signs:** grep output showing a 4th `^## ` line in the guide.

### Pitfall 2: require_file ordering breaks compilation

**What goes wrong:** `ReconciliationInbox` aliases `ReconciliationKeys` at compile time. If `reconciliation_inbox.ex` is loaded before `reconciliation_keys.ex`, the alias resolution fails.

**How to avoid:** Load in dependency order: `reconciliation_keys` → `reconciliation_inbox` → others. The Phase 34 proofs establish this order exactly.

### Pitfall 3: Keeping async: true with module-scope require_file

**What goes wrong:** While `Code.require_file` is idempotent (second call for an already-loaded module is a no-op), the module load itself happens at file-evaluation time (before any test runs). With `async: true`, other test files may be running concurrently. While Elixir's Code module is internally safe, the established project convention is `async: false` for any test file with module-scope `require_file`. Deviating creates inconsistency and may trigger the Phase 34 corridor proof's self-scan guard if it ever checks other test files.

**How to avoid:** Set `async: false` in the guide test.

### Pitfall 4: Live-guarding PaywallLive or verify_and_broadcast

**What goes wrong:** `CrosswakeExample.PaywallEntryLive` uses Phoenix.LiveView (runtime). `MockBackend.verify_and_broadcast/2` calls `Phoenix.PubSub.broadcast/3` — this will raise if called without a running PubSub process.

**How to avoid:** Never `Code.require_file` `paywall_entry_live.ex`. Never call `verify_and_broadcast/2` in the guide test. Only assert `function_exported?(MockBackend, :build_verified_snapshot, 2)` — not `verify_and_broadcast`.

### Pitfall 5: Mock-vs-real callout accidentally triggers non-claims regex tests

**What goes wrong:** The D-07 four-non-claims test checks `non_claims_section =~ ~r/StoreKit adapter is not shipped/i`. If the walkthrough callout in Layer 1 uses the exact phrase "StoreKit adapter is not shipped", the non-claims test still passes (the split is against `## Rough Edges And Non-Claims` so Layer 1 text is excluded). BUT if the walkthrough's callout text is tested for by a new D-06.1 assertion using exact phrasing, an accidental mismatch is caught immediately.

**How to avoid:** Use D-05-scoped prose in the callout (e.g., "no StoreKit or Play Billing code is shipped") rather than copying the Layer 3 "X adapter is not shipped" non-claim text verbatim into Layer 1 — they serve different purposes.

### Pitfall 6: Asserting function_exported? without require_file in scope

**What goes wrong:** If the `Code.require_file` lines are added inside the `describe` block or inside a test, rather than at module scope (file-level), the modules may not be loaded when `function_exported?` is called from other tests.

**How to avoid:** Place all five `Code.require_file` calls at file level, BEFORE the `defmodule` declaration — exactly as in `phase34_mock_storefront_test.exs` and `phase34_paywall_corridor_proof_test.exs`.

---

## Validation Architecture

### Overview

This phase's Nyquist contract is the `commerce_test.exs` file itself. All five success criteria are mechanically checkable in one file with no manual UAT. The test suite runs in the merge-blocking CI lane.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir test framework) |
| Config file | `test/test_helper.exs` (standard Mix project) |
| Quick run command | `mix test test/crosswake/guides/commerce_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Success Criteria → Test Map

| SC | Behavior | Test Type | Automated Command | Assertion |
|----|----------|-----------|-------------------|-----------|
| SC#1 | Walkthrough section exists, each step anchors to named module/function | String-presence | `mix test test/crosswake/guides/commerce_test.exs` | `content =~ "### Paywall Corridor Walkthrough"` + `content =~ "CrosswakeExample.Commerce.MockStorefront"` etc. |
| SC#2 | Mock-vs-real callout present (provider: "mock", no StoreKit, no Play Billing) | String-presence | same | `content =~ ~s(provider: "mock")` + StoreKit/Play Billing presence assertions |
| SC#3 | `CrosswakeExample.Commerce.MockStorefront` named exactly; canonical field names; functions resolve | String-presence + live-code guard | same | `content =~ "CrosswakeExample.Commerce.MockStorefront"` + `content =~ "provider_reference"` + `content =~ "evidence_ref"` + all six `function_exported?/3` assertions |
| SC#4 | Phase23 three-layer heading assertions still pass | Regression fence (existing test) | same | `content =~ ~r/^## Commerce Support Truth\s*$/m` etc. (lines 217-228) |
| SC#5 | All four non-claims remain present | Regression fence (existing test) | same | `non_claims_section =~ ~r/StoreKit adapter is not shipped/i` etc. (lines 265-289) |

### Nyquist Sampling — Drift Detection Coverage

The hybrid assertion strategy (string-presence + `function_exported?`) samples the guide↔code contract at these drift points:

| Drift Event | Caught By |
|-------------|-----------|
| Rename `simulate_purchase` to `simulate_purchase_v2` | `function_exported?(MockStorefront, :simulate_purchase, 2)` fails |
| Remove `ingest_evidence/2` from ReconciliationInbox | `function_exported?(ReconciliationInbox, :ingest_evidence, 2)` fails |
| Rename `provider_reference` field to `provider_ref` | `content =~ "provider_reference"` fails (IF guide is updated but assertion name isn't) |
| Drop the walkthrough heading | `content =~ "### Paywall Corridor Walkthrough"` fails |
| Add a 4th H2 layer | Intro prose becomes inaccurate (structural assertion doesn't catch count; prose check is reviewer-only — acceptable given D-02 is structurally enforced by H3 placement) |
| Drop Layer 3 non-claim | `non_claims_section =~ ~r/StoreKit adapter is not shipped/i` fails |
| Drop one of the three H2s | `content =~ ~r/^## ...\s*$/m` fails |
| Rename proof file without updating guide | `content =~ "test/crosswake/proof/phase34_paywall_corridor_proof_test.exs"` fails |

**Sampling density assessment:** The six `function_exported?` assertions cover all anchored functions. The string-presence assertions cover the heading, module name, field names, mock-vs-real vocabulary, and proof citation. Combined, they make `guides/commerce.md` a genuinely merge-blocking artifact: renaming or removing any anchored symbol breaks the test immediately.

### Wave 0 Gaps

None. `commerce_test.exs` already exists with full ExUnit scaffolding. The new assertions append to the existing file. No new test files, fixtures, or framework setup required.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `async: false` is required for module-scope `require_file` in this codebase convention | Finding 3 / Discretion (a) | Low — even if `async: true` would technically work (Code module is idempotent), the project established `async: false` as the pattern; deviating is only a convention risk |

All other claims in this research were verified by direct file read — no external sources needed.

---

## Open Questions (RESOLVED)

> Both items below are CONTEXT.md "Claude's Discretion" choices, now resolved in 37-01-PLAN.md
> (single `test` block for the six `function_exported?` assertions; concrete mock-vs-real callout prose).

1. **`@anchored_functions` module attribute for readability**
   - What we know: The six `function_exported?` assertions can be factored into a module attribute list for readability.
   - What's unclear: Whether the planner wants a single `test` block with all six, or separate named tests per function.
   - Recommendation: Single test block `"example host functions resolve to real exports"` with all six assertions is cleanest — mirrors the existing proof file style where related invariants are grouped.

2. **Exact mock-vs-real callout prose**
   - What we know: Must say `provider: "mock"`, no StoreKit, no Play Billing. Must not use the exact Layer 3 "not shipped" phrases verbatim in Layer 1.
   - What's unclear: Exact sentence form (the planner chooses).
   - Recommendation: "This walkthrough uses `provider: \"mock\"`. No StoreKit or Play Billing code is shipped — see `## Rough Edges And Non-Claims` for the explicit non-claims."

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely code/markdown editing + ExUnit assertions with no external tools, services, or CLIs beyond `mix test` (already available in the standard Elixir/Mix project).

---

## Security Domain

Step: SKIPPED — this is a DOCS + TEST phase with no runtime code, no auth, no network I/O, no data persistence, and no new library dependencies. No ASVS categories apply.

---

## Sources

### Primary (HIGH confidence — all verified by direct codebase file reads)

- `guides/commerce.md` — full structure, H2/H3 headings, insertion point, Layer 3 non-claim vocabulary
- `test/crosswake/guides/commerce_test.exs` — current `async:` setting, `@guide_path` idiom, `content =~` assertion form, section-split helpers, phase23 regression fence locations (lines 217-289)
- `test/crosswake/proof/phase34_mock_storefront_test.exs` — `Code.require_file` idiom, `async: false` pattern, relative path form
- `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` — full `Code.require_file` set, `async: false`, hermeticity self-scan guard
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` — `simulate_purchase/2`, `simulate_restore/2` signatures, `provider: "mock"`, `@subscription_entry_id`
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — `ingest_evidence/2` signature
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — `project_snapshot/2`, `derived_state/1` signatures
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` — `build_verified_snapshot/2` (pure/safe), `verify_and_broadcast/2` (PubSub-dependent/unsafe to call)
- `lib/crosswake/commerce/contracts.ex` (lines 150-183) — canonical `provider_reference` and `evidence_ref` field names in `ReconciliationEvidence` struct
- `examples/phoenix_host/lib/crosswake_example/router.ex` (lines 220-243) — exact route declaration `commerce: [corridor: :subscription_default, role: :paywall_entry]`
- `examples/phoenix_host/lib/crosswake_example/paywall_entry_live.ex` — module name `CrosswakeExample.PaywallEntryLive` confirmed; runtime module (do not require_file)

### Secondary (MEDIUM confidence)

None — all claims sourced directly from the codebase.

---

## Metadata

**Confidence breakdown:**
- Guide structure (current state): HIGH — read directly from `guides/commerce.md`
- Test idioms and fence locations: HIGH — read directly from `commerce_test.exs`
- require_file idiom and paths: HIGH — verified from proof test files + path computation
- Function signatures and arities: HIGH — read directly from all four pure commerce modules
- Canonical field names: HIGH — read from `Contracts.ReconciliationEvidence` struct definition
- async: false recommendation: HIGH — both proof tests verified; minor convention risk noted
- MockBackend safety: HIGH — PubSub only in `verify_and_broadcast`, not in `build_verified_snapshot`; Phase 34 proof already loads the module successfully

**Research date:** 2026-05-29
**Valid until:** No external dependencies; valid until any of the five shipped modules are renamed or refactored (stable while Phases 33-36 code is locked)
