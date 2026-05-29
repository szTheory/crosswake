# Pitfalls Research

**Domain:** Mocked paywall/subscription example added to a contract-first, backend-owned entitlement system (Crosswake v3.4 Commerce Archetype Proof)
**Researched:** 2026-05-29
**Confidence:** HIGH — grounded in repo source (contracts.ex, reconciliation.ex, phase23-proof.yml, existing test isolation patterns, STATE.md Phase 30 post-mortem, MILESTONE-ARC.md locked guardrails)

---

## Critical Pitfalls

### Pitfall 1: Mock Storefront Accidentally Granting Entitlement Authority (Non-Authoritative-Evidence Violation)

**What goes wrong:**
`MockStorefront` returns a value that the example host code promotes directly to `authority.state = :active` and `access.decision = :granted` without going through `EntitlementProjection.project_snapshot/2`. The mock short-circuits the reconciliation inbox and publishes a `:granted` snapshot bypassing the verification step. This violates ENTL-03 ("Device, storefront, webhook, and support evidence can feed reconciliation but cannot directly grant entitlement authority in core contracts").

**Why it happens:**
The convenience pressure of "make the demo work end-to-end" is highest when wiring the LiveView. The shortest path is: mock purchase → set snapshot to granted → LiveView shows paywall lifted. The reconciliation inbox feels like ceremony. Developers paste code from the guide's "canonical flow" narrative but skip the `awaiting_verification` → `projection_refreshed` hop because the mock has no real backend verifier.

The existing `Crosswake.Commerce.Reconciliation.outcome_implies_authority_grant?/1` already returns `false` for every reconciliation outcome, and `authority_mutation_allowed_from_evidence?/1` always returns `false` — but these guards only activate if `ingest_evidence/2` is on the call path. If `MockStorefront` is wired to call `EntitlementProjection.project_snapshot/2` directly with a hand-built snapshot that already has `:active` authority, the guards are bypassed entirely.

**How to avoid:**
1. The proof test must assert `Crosswake.Commerce.Reconciliation.outcome_implies_authority_grant?(attempt.status) == false` for every status the mock produces.
2. The example `EntitlementProjection` must enforce `ensure_verified_reconciliation/1` before accepting any snapshot — it already does; the proof test must drive through it, not around it.
3. `MockStorefront` must produce a `ReconciliationEvidence` struct (source: `:storefront`, event_kind: `"purchase"`) and pass it through `ReconciliationInbox.ingest_evidence/2`, not return a pre-baked entitlement snapshot.
4. Add an explicit test: `assert {:error, :unverified_reconciliation_outcome} = EntitlementProjection.project_snapshot(nil, snapshot_with_pending_reconciliation)` — proving a `:pending_purchase` reconciliation state cannot produce a `:granted` snapshot.

**Warning signs:**
- `MockStorefront` module has a return type of `EntitlementSnapshot.t()` rather than `ReconciliationEvidence.t()`.
- Example code assigns `authority: %AuthorityLane{state: :active}` inside the mock module itself.
- The proof test passes without ever touching `ReconciliationInbox.ingest_evidence/2`.
- `reconciliation.state` in the "granted" snapshot is `:pending_purchase` or `:awaiting_verification` rather than `:projection_refreshed`.

**Phase to address:**
Phase implementing `MockStorefront` and `EntitlementProjection` wiring (the reconciliation → entitlement snapshot phase). A dedicated test asserting `authority_mutation_allowed_from_evidence? == false` for mock-produced evidence must be in the merge-blocking proof lane, not deferred.

---

### Pitfall 2: Example Drifts Into a De-Facto Billing Engine or Implies Provider Adapters Shipped

**What goes wrong:**
`MockStorefront` accumulates provider-shaped logic: product catalog lookups, receipt validation stubs, sandbox receipt URLs, retry/refund state machines. The module grows into a thin StoreKit simulator wrapper. Guides start describing the mock as "how StoreKit integration works." Adopters copy the mock and fill in real StoreKit/Play Billing calls, treating the example as the provider adapter scaffolding. The non-claims section of `guides/commerce.md` (currently asserting "StoreKit adapter is not shipped" and "Play Billing adapter is not shipped") becomes implicitly false.

The same drift can happen from the other direction: the guide walkthrough for the mock paywall corridor is written so generically that it reads as universal billing guidance, and an adopter opening a support issue about their RevenueCat integration cites the guide as justification for expecting Crosswake to handle it.

**Why it happens:**
The mock needs enough realism to prove the corridor end-to-end. Each "what if the mock simulated X" improvement seems harmless. The line between "minimum viable mock" and "aspirational billing example" blurs during execution.

**How to avoid:**
1. `MockStorefront` must implement only the v3.2 contract surface: accept `PurchaseIntent` / `RestoreIntent`, emit `ReconciliationEvidence` with `source: :storefront`, `provider: "mock"`, `event_kind: "purchase"` or `"restore"`. No receipt fields, no sandbox URLs, no catalog map.
2. The guide walkthrough must open with an explicit callout: "This example uses `MockStorefront` (provider: `\"mock\"`). It proves the corridor contract without StoreKit or Play Billing. See Rough Edges And Non-Claims for what is not shipped."
3. The existing `@forbidden_provider_tokens` fence in `phase23_commerce_support_proof_test.exs` covers the support matrix and doctor findings. Extend it (or add a parallel test) to scan the example-host `MockStorefront` source for `storekit`, `play_billing`, `play billing`, `revenuecat` tokens.
4. The docs-contract test must assert the guide still carries all four non-claims (`StoreKit adapter is not shipped`, `Play Billing adapter is not shipped`, `Device-local entitlement authority is not shipped`, `Offline purchase replay is not shipped`) after the walkthrough is updated.

**Warning signs:**
- `MockStorefront` has a `@products` module attribute that looks like a real product catalog.
- The mock accepts or returns receipt-like binary data.
- Guide text says "replace `mock` with your StoreKit adapter" rather than "a real provider adapter is out of scope."
- `provider` field in mock-produced `ReconciliationEvidence` is `"storekit"` or `"com.apple"` instead of `"mock"`.

**Phase to address:**
Phase writing `MockStorefront` and updating `guides/commerce.md`. The non-claims docs-contract test (already in `commerce_test.exs`) must be re-run against the updated guide as a merge-blocking gate.

---

### Pitfall 3: Docs-Contract Drift — Guide Walkthrough Diverges From Working Example Code

**What goes wrong:**
`guides/commerce.md` is updated to describe the new paywall corridor walkthrough, but the code shown in the guide (module names, function signatures, struct field names, idempotency key construction) drifts from the actual `examples/phoenix_host/lib/crosswake_example/commerce/` files. An adopter copies the guide snippet and gets a compile error or a runtime crash because `ReconciliationKeys.event_key/1` has a different arity than what the guide shows.

This is a concrete version of the v3.2 risk: `guides/commerce.md` already has a `Minimal Reconciliation Inbox Example` section (locked by `commerce_test.exs`) describing `event_key`, `subject_key`, `correlation_id`, `stale`, `pending`, `denied`, `granted`, `as_of`, and "Ingestion outcomes are non-authoritative." The v3.4 guide update adds a paywall entry + MockStorefront walkthrough on top of this. If the new walkthrough is written before the example code is final, or edited by hand after the fact, it drifts.

**Why it happens:**
Docs are written during phase planning (before code is final) or copy-pasted from earlier drafts and not re-verified after the code settles. The existing `commerce_test.exs` locks structural headings and keyword presence — it does not verify that named function arities, module references, or inline code snippets are accurate.

**How to avoid:**
1. Write example code first, then write the guide walkthrough from the running code — not from the planning spec.
2. Add a docs-contract test that asserts the exact module names referenced in the new guide section exist as compiled modules (using `Code.ensure_loaded?/1` or a `@moduledoc` scan).
3. Assert the guide mentions `MockStorefront` by its exact module name (`CrosswakeExample.Commerce.MockStorefront` or the chosen canonical name).
4. Assert the guide uses the canonical `ReconciliationEvidence` field names (`provider`, `provider_reference`, `event_kind`, `evidence_ref`, `captured_at`) rather than invented aliases.
5. The Phase 23 pattern of locking guide section headings with regex assertions in `commerce_test.exs` should be extended: add assertions that lock the new "Paywall Corridor Walkthrough" or equivalent heading as soon as it is written.

**Warning signs:**
- Guide uses `receipt_token:` as a field name; contracts use `evidence_ref:`.
- Guide calls `ReconciliationInbox.record_purchase/1`; the actual module exports `ingest_evidence/2`.
- Guide shows `MockStorefront.buy/1`; implementation uses `MockStorefront.submit_purchase_intent/1`.
- The docs-contract test suite passes but the adopter example at the top of the guide still references a function that was renamed during implementation.

**Phase to address:**
Phase updating `guides/commerce.md` — the docs-contract test extension must be in the same phase, not deferred to a separate tech-debt phase. Write the code, then write (and lock) the guide in the same phase boundary.

---

### Pitfall 4: Proof-Honesty Failures — Hermetic Lane That Secretly Depends on Environment, or Advisory/Merge-Blocking Confusion

**What goes wrong:**
Two failure modes in the same category:

**4a. Hidden environment dependency.** The new v3.4 proof test is added to the merge-blocking CI job, but the test silently calls `Code.require_file` on an example-host file that is not compiled in the hermetic `mix test` run. Under normal `mix test`, the example host is excluded. The test passes locally (where the example host is compiled) and fails in CI. The existing `phase23_commerce_support_proof_test.exs` has an explicit hermeticity guard that scans its own source for `crosswake_example.router` and `Code.require_file` calls — but the v3.4 proof test is a new file, and that guard does not automatically extend to it.

The Phase 30 post-mortem already documented two latent races: (1) parallel-compile `require_file` collision (two async tests both `Code.require_file`-ing the same file and racing on first-load), and (2) global-cwd `File.cd` race (a test using `File.cd!/2` interfering with async tests that use relative paths like `File.read!("guides/...")` at compile time via `@guide_path`).

**4b. Advisory/merge-blocking confusion.** A future maintainer adds a MockStorefront-level test that uses a simulated clock or a mock provider response and marks it `@tag :requires_example_host`, assuming it will be excluded from the hermetic lane. But it is added to the wrong CI step, so it now blocks merges on a non-deterministic timer or a test-double response that depends on module load order.

**Why it happens:**
The hermetic/advisory split is enforced at the workflow level (`if: github.event_name == 'pull_request'` on the merge-blocking job, `continue-on-error: true` on the advisory job), but it is NOT enforced at the test tag level by default. Tags like `:requires_example_host` are excluded via `--exclude` flags that must be manually kept in sync with each CI step's `mix test` invocation. A new test file added without the tag will be picked up by every step.

**How to avoid:**
1. Create a dedicated `phase34-proof.yml` (mirroring `phase23-proof.yml` two-job split) for the v3.4 proof lane. The merge-blocking job must include the hermeticity guard — either as a self-scan test (like the one in phase23) or as an explicit `--exclude requires_example_host` flag.
2. Any test that drives the full paywall corridor using `Code.require_file` on example-host modules must carry `@moduletag :requires_example_host` and run in the `phase5-proof.yml` lane (which builds the example host first), NOT in the hermetic lane.
3. Tests that prove the contracts in isolation (MockStorefront produces valid `ReconciliationEvidence`, `EntitlementProjection.project_snapshot/2` enforces verification gate, freshness fail-closed) can use in-memory fixtures and are safe for the hermetic lane.
4. Use `async: false` for any test that uses `File.cd!/2`. Use `@guide_path Path.join([File.cwd!(), ...])` computed at module compile time (not inside a test body) to avoid the global-cwd race.
5. `Code.require_file` calls on example-host modules must appear only in tests tagged `:requires_example_host` and must be at the top of the file (module scope), not inside test callbacks — parallel `require_file` calls inside async tests race on first-load.

**Warning signs:**
- A new proof test file does not have `@moduletag :requires_example_host` but contains `Code.require_file` on a path under `examples/`.
- The `phase34-proof.yml` merge-blocking job runs `mix test` without `--exclude requires_example_host`.
- A test in the hermetic lane calls `File.cd!/2` while another async test reads `guides/commerce.md` via a compile-time `@guide_path`.
- The advisory-to-merge-blocking promotion commentary is missing from the new workflow file (copying the 4-condition `promotion_path` from `phase23-proof.yml` is required).

**Phase to address:**
Phase writing the merge-blocking proof lane. The CI workflow and the hermeticity guard must be in the same phase as the proof test itself — not a later "CI cleanup" phase.

---

### Pitfall 5: LiveView State Reflecting Stale, Pending, or Denied Entitlement Incorrectly

**What goes wrong:**
The PaywallEntryLive (or equivalent) render function has a single `:granted` / not-`:granted` branch. It treats any non-`:granted` snapshot as "show paywall" without distinguishing `:pending` (purchase in flight, show spinner), `:stale` (freshness expired, show refresh prompt), and `:denied` (access genuinely denied, show paywall with clear denial reason). This means:

- A user who just purchased sees the paywall again because the snapshot is still `:pending_purchase` during the reconciliation window.
- A user whose snapshot has gone `:stale` (freshness lane) sees the same paywall as a rejected user, with no way to distinguish a stale read from a genuine denial.
- The LiveView does not subscribe to snapshot refresh events, so once mounted with `:stale` state it never re-renders even after the backend publishes a fresh `:granted` snapshot.

This maps directly to the `EntitlementProjection.derived_state/1` function in the example host, which already returns `:stale | :pending | :denied | :granted`. The LiveView must use all four derived states.

**Why it happens:**
The simplest LiveView template is `if @snapshot.access.decision == :granted, do: render_content, else: render_paywall`. This compiles and "works" for the happy path. The `:stale` and `:pending` states only appear under timing or environment conditions that are easy to ignore during example development.

**How to avoid:**
1. The PaywallEntryLive must pattern-match on `EntitlementProjection.derived_state/1` — all four branches: `:granted`, `:pending`, `:stale`, `:denied`.
2. The proof test must assert each derived state produces a distinct LiveView render outcome. Use `Phoenix.LiveViewTest` to mount the LiveView with injected snapshots covering all four `derived_state/1` values.
3. `:stale` must render a "refreshing" or "checking your subscription" UI, not the same paywall as `:denied`. The difference is load-bearing: `:stale` means the backend might grant access once the snapshot is refreshed; `:denied` means access is explicitly withheld.
4. The LiveView must subscribe to a PubSub topic (or equivalent) that the `EntitlementProjection` publishes to on snapshot refresh, so `:pending` → `:granted` transitions re-render without a full page reload.
5. The mock scenario must exercise the `:pending` → `:granted` transition in the proof test (mock purchase emits evidence → reconciliation inbox ingests → projection publishes `:granted` snapshot → LiveView receives message and re-renders).

**Warning signs:**
- LiveView has `if snapshot.access.decision == :granted` rather than `case EntitlementProjection.derived_state(snapshot)`.
- Proof test only verifies the `:granted` case.
- No PubSub subscription or `handle_info/2` clause in the LiveView for snapshot refresh events.
- `:stale` and `:denied` render the same template in the test output.

**Phase to address:**
Phase implementing PaywallEntryLive and the end-to-end proof test. The four-state render test and the `:pending` → `:granted` transition test must both be in the merge-blocking proof lane.

---

### Pitfall 6: Idempotency / Replay Pitfalls in Reconciliation Evidence

**What goes wrong:**
The mock purchase flow calls `ReconciliationInbox.ingest_evidence/2` but uses `PurchaseIntent.correlation_id` as the idempotency key instead of `ReconciliationEvidence.provider_reference` + `event_kind`. When a retry or a reconnect re-submits the same `PurchaseIntent`, a new `correlation_id` is generated (because the device generates it fresh), creating a second non-replay evidence record for the same underlying provider transaction. The backend double-counts the purchase.

The existing `Crosswake.Commerce.Reconciliation.IdempotencyKey` struct already encodes the correct key: `{provider, provider_reference, event_kind}` — explicitly excluding transient device correlation IDs (RECN-02: "Host apps can follow idempotency guidance that uses provider-aware identity rather than transient device correlation IDs"). `ReconciliationKeys.event_key/1` in the example host mirrors this. But `MockStorefront` must generate a stable `provider_reference` (e.g. a UUID derived from the `entry_id`, not from the `correlation_id`), or the idempotency key will be `correlation_id`-shaped by accident.

A second sub-pitfall: the proof test for replay (already present in `phase21_reconciliation_example_test.exs`) passes `seen_event_keys:` as an explicit list. In production code the "seen keys" come from a database query. The example must make clear that `seen_event_keys` is the host's responsibility to populate from persistent storage, not an in-memory set held in the MockStorefront process.

**Why it happens:**
`PurchaseIntent.correlation_id` is the only device-side identifier available at the point where the mock generates `ReconciliationEvidence`. Using it as `provider_reference` is the path of least resistance. The distinction between "transient device correlation ID" and "stable provider transaction reference" is only meaningful when a real provider (Apple, Google) assigns a canonical transaction ID. The mock has to simulate this distinction explicitly, or the idempotency contract is accidentally tested with correlation IDs.

**How to avoid:**
1. `MockStorefront` must generate a stable `provider_reference` that does NOT derive from `correlation_id`. Use a deterministic UUID seeded from `entry_id` + a monotonic counter, or a fixed UUID per test scenario. Document in the mock's `@moduledoc` that real providers assign `provider_reference` (e.g. Apple's `originalTransactionIdentifier`).
2. The proof test must demonstrate idempotency by replaying the same evidence (same `provider_reference` + `event_kind`) with a different `correlation_id` and asserting `replay?: true` and no double-count.
3. The guide walkthrough must include a callout: "Real provider adapters must use the provider's canonical transaction ID as `provider_reference`, not the device-generated `correlation_id`."
4. `seen_event_keys` must be documented as a value the host populates from its database, not an in-memory accumulation inside the mock. Show a commented-out `Repo.all(from e in ReconciliationAttempt, select: e.event_key)` pattern in the example.

**Warning signs:**
- `MockStorefront` sets `provider_reference: evidence.correlation_id` or `provider_reference: intent.correlation_id`.
- Proof test for replay uses the same `correlation_id` as the distinguishing variable instead of `provider_reference`.
- `IdempotencyKey` in the proof output has `provider_reference` equal to a UUID that changes on every test run.
- `seen_event_keys` in the example host is held in a module attribute or process-level ETS table rather than persisted to a database.

**Phase to address:**
Phase implementing `MockStorefront` and the idempotency proof test. This must be in the same phase as the mock — not deferred. The existing phase21 replay test already covers the contract; the v3.4 mock must pass the same invariant.

---

### Pitfall 7: Test Isolation Failures in the Example Host Proof Lane

**What goes wrong:**
Three concrete races documented in the Phase 30 post-mortem reappear when new example-host proof tests are added without the same isolation discipline:

**7a. Parallel `Code.require_file` race.** Two `async: true` tests both call `Code.require_file` on the same example-host file at the top of their test module. The first call compiles and loads the file; the second call races on the first-load state and either raises a `CompileError` or silently succeeds with stale bytecode.

**7b. Global-cwd `File.cd` race.** A new proof test uses `File.cd!(target, fn -> ... end)` to test the mock in an isolated temp directory (the same pattern used in `crosswake_doctor_test.exs`). If this test uses `async: true`, any other async test that reads `guides/commerce.md` via a compile-time `@guide_path = Path.join([File.cwd!(), "guides", "commerce.md"])` will resolve to the wrong path while the `File.cd!` call is active, causing `File.read!` failures.

**7c. Module name collision.** New proof tests define inline `defmodule PaywallCorridorRouter` fixtures. If the module name matches an existing fixture module in another test file (the phase23 test already defines `PaywallCorridorRouter` and `PurchaseCorridorRouter` as inline modules), and both tests run in the same `mix test` invocation, Elixir raises a module-redefinition warning that becomes an error under `--warnings-as-errors`.

**Why it happens:**
Example-host tests reuse the `Code.require_file` pattern established in `phase21_reconciliation_example_test.exs`, but add it to new files that also define async tests. The isolation rules from Phase 30 are not written down as a policy; they live in test-file comments (`async: false — this test changes the global process working directory via File.cd!/2`). New contributors (or the planner) copy the pattern without the comment and without reading the prior post-mortem.

**How to avoid:**
1. Any test file that calls `Code.require_file` on an example-host path must use `async: false`. Put the `Code.require_file` calls at module scope (top of file), not inside `setup` or test bodies.
2. Any test file that uses `File.cd!/2` must use `async: false`. The `crosswake_doctor_test.exs` comment is the canonical rationale; copy it verbatim.
3. Inline router fixture modules defined inside proof test files must use unique, test-file-scoped names. Convention: prefix with the phase number (`Phase34PaywallCorridorRouter`) to avoid collision with Phase 23's `PaywallCorridorRouter`.
4. The new `phase34-proof.yml` merge-blocking step must include `--warnings-as-errors` (matching the existing pattern) so module-redefinition warnings surface as CI failures immediately.
5. Compile-time `@guide_path` assignments (using `File.cwd!()` at module load time) are safe only if no concurrent test changes the cwd. Verify that any test defining `@guide_path` is either `async: false` or that it runs in a suite that does not include `File.cd!`-using tests.

**Warning signs:**
- A new proof test file contains `Code.require_file` and `use ExUnit.Case, async: true` in the same file.
- A new proof test defines a module named `PaywallCorridorRouter` without a phase-scoped prefix.
- CI log shows `warning: redefining module PaywallCorridorRouter` followed by a test failure under `--warnings-as-errors`.
- A `File.read!("guides/commerce.md")` fails with `no such file` in CI but passes locally (cwd contamination from a concurrent `File.cd!` test).

**Phase to address:**
Phase writing the merge-blocking proof lane for the full paywall corridor. The isolation rules must be applied when the test file is first written — retrofit is painful. The `phase34-proof.yml` step must replicate the `--exclude requires_example_host` and `--warnings-as-errors` flags from existing proof workflows.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| MockStorefront returns `EntitlementSnapshot` directly | Less wiring to implement | Bypasses non-authoritative-evidence guardrail; proof test validates wrong boundary | Never — the mock must return `ReconciliationEvidence` |
| Single `:granted`/not-`:granted` LiveView branch | Simpler template | `:stale` and `:pending` render as paywall; adopters copy the wrong pattern | Never — all four `derived_state/1` branches are part of the proof contract |
| Use `correlation_id` as `provider_reference` in mock | No UUID generation needed | Idempotency test proves wrong key; adopters copy correlation-id-based dedup | Never — `provider_reference` must be stable and provider-assigned |
| Add new proof test to existing `phase23-proof.yml` step | One fewer workflow file | Phase 23 scope expands; hermeticity guard scans only its own file | Acceptable only if the new test is 100% hermetic (no `Code.require_file`, no example-host dependency) |
| Write guide walkthrough before example code is final | Earlier docs review | Structural drift between guide and implementation; docs-contract test fails silently if locked assertions are too coarse | Never for code-referencing sections; acceptable for conceptual overview |
| `async: true` with `Code.require_file` at test scope | Faster test suite | Parallel-compile race; intermittent CI failures | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `ReconciliationInbox.ingest_evidence/2` | Pass `authority_state:` as an opt to force a grant | `reject_direct_authority_override/1` already rejects `:authority_state` opts with `{:error, :authority_lane_mutation_forbidden}`; the mock must not attempt this | Return `ReconciliationEvidence` and let `ingest_evidence/2` produce `EvidenceResult` with `status: :awaiting_verification` |
| `EntitlementProjection.project_snapshot/2` | Call with a snapshot whose `reconciliation.state` is `:pending_purchase` or `:awaiting_verification` expecting `:ok` | Returns `{:error, :unverified_reconciliation_outcome}` — only `:projection_refreshed`, `:verification_failed`, `:conflict`, `:stale_authority` are "verified" states | Mock must produce a snapshot with `reconciliation.state: :projection_refreshed` to pass the projection gate; the proof test must assert the gate fires correctly for unverified states |
| `phase23-proof.yml` advisory lane | Add mock purchase test to `advisory-commerce-proof` job assuming it can block merge | `continue-on-error: true` means advisory failures never block merge; a test that must gate the PR belongs in the hermetic job | Route merge-blocking tests to the hermetic job; advisory job is for environment-sensitive placeholders only |
| `guides/commerce.md` non-claims section | Add "MockStorefront ships a paywall UI" language | The non-claims test asserts `Storefront purchase UI is not shipped` — adding UI language breaks the lock | Mock proves the corridor contract, not the UI; guide must state explicitly that the paywall UI template is example-only |
| `ReconciliationKeys.event_key/1` | Use `correlation_id` as a key component | `ReconciliationKeys` derives the key from `provider + provider_reference + event_kind` (stable, provider-assigned) | Mock must assign a stable `provider_reference` UUID and document that `correlation_id` is intentionally excluded |

---

## "Looks Done But Isn't" Checklist

- [ ] **MockStorefront boundary:** Verify `MockStorefront` returns `ReconciliationEvidence`, not `EntitlementSnapshot`. Check that no `authority:` or `access:` field is set inside the mock module.
- [ ] **Non-authoritative-evidence test:** Verify the proof lane includes a test asserting `Crosswake.Commerce.Reconciliation.outcome_implies_authority_grant?(attempt.status) == false` for mock-produced evidence.
- [ ] **Four-state LiveView render:** Verify PaywallEntryLive has explicit branches for `:granted`, `:pending`, `:stale`, `:denied` — not just `:granted` vs everything else.
- [ ] **Pending-to-granted transition:** Verify the proof test drives the `:pending_purchase` → `:awaiting_verification` → `:projection_refreshed` → LiveView re-render transition, not just the steady-state `:granted` case.
- [ ] **Idempotency key source:** Verify `MockStorefront` uses a stable `provider_reference` UUID unrelated to `correlation_id`. Check the proof replay test uses `provider_reference` as the stable key.
- [ ] **Guide walkthrough accuracy:** Verify module names, function arities, and struct field names in the guide walkthrough match the actual example-host implementation (run the docs-contract test against the final code, not the planning draft).
- [ ] **Non-claims still intact:** Verify `guides/commerce.md` still carries all five non-claims (`StoreKit`, `Play Billing`, `Device-local authority`, `Offline purchase replay`, `Storefront purchase UI`) after the walkthrough is added.
- [ ] **Hermetic proof lane:** Verify the new proof test file does not contain `Code.require_file` on example-host paths. Verify it runs clean under `mix test --exclude requires_example_host`.
- [ ] **CI workflow:** Verify `phase34-proof.yml` (or equivalent) has the two-job split (hermetic merge-blocking + advisory placeholder) with `continue-on-error: true` on the advisory job and the 4-condition `promotion_path` comment.
- [ ] **async: false:** Verify any test using `File.cd!/2` or `Code.require_file` on example-host files uses `async: false`.
- [ ] **Module name uniqueness:** Verify inline fixture modules in the new proof test use phase-scoped names (e.g. `Phase34PaywallCorridorRouter`) to avoid collision with phase23 fixtures.
- [ ] **Provider-vocabulary fence:** Verify the new proof test or an extended existing test scans `MockStorefront` source for provider token leakage (`storekit`, `play_billing`, `revenuecat`).

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Mock grants entitlement authority directly | Phase implementing MockStorefront + EntitlementProjection wiring | Proof test: `outcome_implies_authority_grant? == false`; `project_snapshot` rejects `:pending_purchase` state |
| Example drifts into billing engine | Phase writing MockStorefront | Provider-vocabulary fence test scans mock source; non-claims section still intact after guide update |
| Docs-contract drift (guide vs. example code) | Phase updating `guides/commerce.md` (same phase as code, not after) | Extended `commerce_test.exs` assertions on walkthrough heading and module references |
| Hermetic lane with hidden env dependency | Phase writing the proof lane CI workflow | Phase34-proof.yml hermetic job runs clean without example-host build; hermeticity guard test in merge-blocking lane |
| Advisory/merge-blocking job confusion | Phase writing `phase34-proof.yml` | Advisory job has `continue-on-error: true`; promotion_path 4-condition comment present |
| LiveView reflects only :granted/:not-granted | Phase implementing PaywallEntryLive | Proof test exercises all four `derived_state/1` values and asserts distinct render outcomes |
| Pending-to-granted transition not proved | Same phase as LiveView | Proof test drives full `:pending_purchase` → `:projection_refreshed` → re-render sequence |
| Idempotency key derived from correlation_id | Phase implementing MockStorefront | Replay proof test: same `provider_reference` + different `correlation_id` → `replay?: true` |
| Seen-event-keys held in memory not DB | Phase implementing MockStorefront | `@moduledoc` and guide callout explicitly document persistence responsibility; proof test comment explains `seen_event_keys` source |
| Parallel `Code.require_file` race | Phase writing example-host proof test | Test file uses `async: false`; `Code.require_file` at module scope |
| Global `File.cd` race | Same phase | Test file uses `async: false`; comment mirrors `crosswake_doctor_test.exs` rationale |
| Module name collision in test fixtures | Same phase | Fixture modules use `Phase34` prefix; `--warnings-as-errors` in CI catches redefinition |

---

## Sources

- `lib/crosswake/commerce/contracts.ex` — `ReconciliationEvidence`, `EntitlementSnapshot` lane types, `authority_mutation_allowed_from_evidence?/1`, `outcome_implies_authority_grant?/1` (direct inspection)
- `lib/crosswake/commerce/reconciliation.ex` — `IdempotencyKey` struct, `reject_direct_authority_override/1`, `ingest_evidence/2` authority guardrails (direct inspection)
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` — `derived_state/1` four-state function, `ensure_verified_reconciliation/1` gate (direct inspection)
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` — `ingest_evidence/2`, `seen_event_key?/2`, idempotency pattern (direct inspection)
- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` — hermeticity guard pattern, `@forbidden_provider_tokens` fence, inline fixture module naming (direct inspection)
- `test/crosswake/guides/commerce_test.exs` — non-claims lock, corridor role parity test, docs-contract patterns (direct inspection)
- `test/mix/tasks/crosswake_doctor_test.exs` — `async: false` + `File.cd!/2` isolation pattern and rationale comment (direct inspection)
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` — `Code.require_file` at module scope, `async: false`, `:requires_example_host` tag, replay test shape (direct inspection)
- `.github/workflows/phase23-proof.yml` — two-job split, `continue-on-error: true`, 4-condition `promotion_path`, hermetic job `if:` guard (direct inspection)
- `.planning/STATE.md` — Phase 30 post-mortem: parallel-compile `require_file` race, global-cwd `File.cd` race (direct inspection)
- `.planning/MILESTONE-ARC.md` — Locked guardrails: "Entitlement truth remains backend- and Phoenix-owned; device purchase events are not sufficient by themselves" (direct inspection)
- `.planning/PROJECT.md` — ENTL-03, RECN-02, Key Decisions on hermetic/advisory split, docs-contract as merge-blocking (direct inspection)
- `.planning/threads/commerce-archetype-proof.md` — v3.4 goal, MockStorefront design constraints, advisory→hermetic promotion criteria (direct inspection)

---
*Pitfalls research for: Crosswake v3.4 Commerce Archetype Proof — mocked paywall/subscription example in a contract-first backend-owned entitlement system*
*Researched: 2026-05-29*
