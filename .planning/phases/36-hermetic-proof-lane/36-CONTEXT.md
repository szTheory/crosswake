# Phase 36: Hermetic Proof Lane - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Author the single merge-blocking, fully **hermetic** ExUnit proof for the mock paywall
corridor: `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`. The proof drives
the full lane — inline `ReconciliationEvidence` → `ingest_evidence/2` → `project_snapshot/2`
→ `derived_state/1` — and asserts:

1. All four `derived_state/1` outcomes (`:stale`, `:pending`, `:denied`, `:granted`) with
   distinct assertions.
2. The `:pending` → `:granted` transition: ingestion yields `:awaiting_verification` (the
   `:pending` origin), then the `MockBackend` verified snapshot projects to `:granted`.
3. The **mock-boundary fence** (PROOF-03).
4. Hermeticity discipline + a self-scan guard.
5. Clean run in the `phase34-proof.yml` hermetic job under
   `--exclude requires_example_host --warnings-as-errors`.

**In scope:** ONE new test file (`phase34_paywall_corridor_proof_test.exs`) and whatever CI
glue is needed to confirm it runs in the existing `phase34-proof.yml` hermetic lane.
**Requirements:** PROOF-01, PROOF-03.

**Out of scope:** Any change to shipped lib code (`lib/crosswake/commerce/*`) or example-host
modules (`MockBackend`, `EntitlementProjection`, `ReconciliationInbox`, `MockStorefront`) —
those are SHIPPED/locked from Phases 21/34/35 and asserted *against*, never modified. The
`guides/commerce.md` walkthrough + docs-contract lock is Phase 37 (DOCS-01/02). No
StoreKit/Play Billing/provider-SDK code; no network, no process start, no Phoenix server.

</domain>

<decisions>
## Implementation Decisions

### A. Hermeticity mechanism — resolving the SC#4 contradiction (PROOF-01, SC#4)
- **D-01 (USER-CONFIRMED):** The proof reaches the real projection code via the
  **established phase21/phase34 idiom**: `Code.require_file` the **pure** example-host
  commerce modules at module scope. Required files (relative to the test, mirroring
  `phase34_mock_storefront_test.exs`):
  - `../../../examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex`
  - `../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex`
  - `../../../examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex`
  This tests the **real shipped code**, not a copy. It matches `MockBackend`'s own moduledoc
  ("reachable via `Code.require_file` at module scope in the proof test"), the phase35 test
  comment ("the Phase 36 hermetic proof asserts the pure MockBackend/projection core"), and
  Phase 35 D-02 (the proof calls `MockBackend.build_verified_snapshot/2` directly).
- **D-02 (SC#4 REINTERPRETATION — flag for verifier):** SC#4's literal wording ("no
  `Code.require_file` on example-host paths") is **in direct conflict** with the locked Phase
  35 design and the phase21/34 precedent, and is reinterpreted exactly as Phase 35 D-08
  reinterpreted its own SC#1. The correct reading: the proof must not depend on the
  example-host **runtime/server** — no `Code.require_file` of example-host *runtime* paths
  (`*_live.ex`, `endpoint.ex`, `application.ex`, `router.ex`, `repo.ex`, `*_web.ex`) and no
  process start / network / server boot. Loading the three **pure** commerce modules is the
  hermetic idiom, not a violation. The verifier should evaluate SC#4 against this
  reinterpretation; ROADMAP SC#4 wording should be reworded to "no `Code.require_file` of
  example-host *runtime* paths (LiveView/endpoint/application/router/Repo)".
- **D-03:** The **hermeticity self-scan guard** is a test that reads the proof file's OWN
  source (`File.read!(__ENV__.file)`) and asserts:
  - No `Code.require_file` line whose path matches a forbidden runtime substring
    (`_live`, `endpoint`, `application`, `router`, `repo`, `_web`) — only the three allowed
    pure commerce modules may be required.
  - No process-start / server tokens (`start_supervised`, `Phoenix.PubSub`, `GenServer.start`,
    `Endpoint`, `LiveViewTest`) appear in the proof body.
  - The file carries `async: false` and is **untagged** (no `@tag :requires_example_host`),
    so it runs in the merge-blocking lane.

### B. Four-state coverage (PROOF-01, SC#1)
- **D-04:** All four `derived_state/1` outcomes are asserted with **distinct** assertions, each
  from a snapshot built inline (see D-07). Anchors (from `entitlement_projection.ex`,
  precedence stale → pending → granted → denied):
  - `:stale` — `freshness.state ∈ [:stale, :unknown]` (fail-closed; wins over everything).
  - `:pending` — `freshness :fresh` + `reconciliation.state ∈ [:pending_purchase,
    :pending_restore, :awaiting_verification]`.
  - `:granted` — `freshness :fresh` + `reconciliation :projection_refreshed` + `authority`
    grantable (`:active`) + `access.decision :granted` (use
    `MockBackend.build_verified_snapshot/2` as the honest source — Phase 35 D-02/D-03).
  - `:denied` — `freshness :fresh`, verified reconciliation, but NOT a granting combination
    (the `true ->` fallthrough; e.g. `access.decision :denied`).

### C. The `:pending` → `:granted` transition (PROOF-01, SC#2)
- **D-05:** Modeled honestly along the real runtime path, NOT via the 2-arity monotonic
  `project_snapshot/2`:
  1. Build inline mock `%ReconciliationEvidence{}` (`provider: "mock"`, `source: :storefront`),
     call `ReconciliationInbox.ingest_evidence/2`, assert the result's
     `status == :awaiting_verification` — this **is** the `:pending` origin (WIRE-01 contract).
  2. Independently assert `derived_state/1` on an `:awaiting_verification` + fresh snapshot
     equals `:pending` (makes the derived `:pending` state explicit, not just the ingest status).
  3. Call `MockBackend.build_verified_snapshot(evidence, group_id)` →
     `EntitlementProjection.project_snapshot(nil, verified)` → assert `{:ok, projected}` →
     `derived_state(projected) == :granted`. Same path the LiveView/controller use at runtime
     (Phase 35 D-02), so the proof and the example share one verification core.

### D. Mock-boundary fence — asserting the real behavior (PROOF-03, SC#3) [USER-CONFIRMED]
- **D-06:** SC#3's literal claim ("`project_snapshot/2` rejects any snapshot with
  non-`:projection_refreshed` reconciliation state") is **factually wrong** against the shipped
  code: `ensure_verified_reconciliation/1` accepts FOUR verified states
  (`[:projection_refreshed, :verification_failed, :conflict, :stale_authority]`); only the
  *grant* (`granted_snapshot?/1` via `resolved_reconciliation?/1`) requires
  `:projection_refreshed`. The fence is asserted as the **three real truths** instead:
  1. `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` returns
     `false` for mock-produced evidence (shipped LIB code — fully hermetic, no require_file).
  2. `EntitlementProjection.project_snapshot(nil, snapshot)` where `reconciliation.state` is
     **unverified** (e.g. `:awaiting_verification`) returns
     `{:error, :unverified_reconciliation_outcome}` — raw ingested evidence can't be projected.
  3. A snapshot whose reconciliation state is **verified-but-not-refreshed** (e.g.
     `:verification_failed`) does **not** derive `:granted` — only a real
     `:projection_refreshed` outcome grants.
  Together these assert "mock evidence can never directly grant entitlement authority" honestly.
  The verifier should evaluate SC#3 against this reinterpretation; ROADMAP SC#3 wording may be
  tightened to distinguish the *verification gate* from the *grant requirement*.

### E. Fixture / collision discipline (SC#4)
- **D-07:** Snapshots for `:stale`/`:pending`/`:denied` and the inline evidence are built by
  **`Phase34`-prefixed inline helpers defined in the proof file itself** (mirroring the
  phase21 builders `snapshot/1`, `*_lane/1`), NOT by `Code.require_file`-ing or aliasing the
  phase21 test file (no cross-test-file coupling). Any inline fixture module is `Phase34`-
  prefixed (e.g. `Phase34PaywallCorridorSnapshots`) to avoid collision with phase23 fixtures.
- **D-08:** `use ExUnit.Case, async: false`; no `@tag :requires_example_host` (untagged →
  merge-blocking lane). The `@moduledoc`/header comment states the hermeticity contract
  explicitly, mirroring `phase34_mock_storefront_test.exs`.

### F. CI lane (PROOF-01, SC#5)
- **D-09:** The file lives at `test/crosswake/proof/` and, being untagged + pure, is picked up
  by the existing `phase34-proof.yml` hermetic job under
  `--exclude requires_example_host --warnings-as-errors`. Verify the job actually exercises
  this file (it already globs `test/crosswake/proof/`); add an explicit reference only if the
  workflow enumerates files rather than globbing. No new CI job is expected.

### Claude's Discretion
- Exact inline-evidence field values (`provider_reference`, `evidence_ref`, `captured_at`) —
  must be `provider: "mock"`, `source: :storefront`, and pass `ingest_evidence/2` to
  `status: :awaiting_verification`. A fixed `captured_at` keeps it deterministic (Phase 34 D-09).
- Concrete `group_id` (anchor to `MockStorefront`/`MockBackend` `@subscription_entry_id
  "sub_pro_monthly"`).
- Exact regex/substring set and structure of the self-scan guard (D-03) and the precise
  inline-helper signatures (D-07).
- Whether the `:denied` snapshot expresses non-grant via `access.decision: :denied` or another
  non-granting lane combination (any combination that hits the `derived_state/1` `true ->`
  branch with `freshness :fresh` + verified reconciliation is valid).
- Test/describe block naming and assertion message wording.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements
- `.planning/REQUIREMENTS.md` — v3.4 requirements; **PROOF-01** (hermetic full-lane proof,
  all four states + `:pending → :granted` transition, no network/native SDK) and **PROOF-03**
  (mock-boundary fence anchored on `authority_mutation_allowed_from_evidence?/1 == false`) for
  this phase. Out of Scope table AF-01 (provider-SDK ban), AF-02 (no persistence),
  AF-07 (`provider: "mock"` only).
- `.planning/ROADMAP.md` §"Phase 36: Hermetic Proof Lane" — goal + 5 success criteria.
  **Read with D-02 + D-06:** SC#4 ("no Code.require_file on example-host paths") is
  reinterpreted to mean example-host *runtime* paths only; SC#3 ("project_snapshot rejects
  non-`:projection_refreshed`") is asserted as the three real truths in D-06.
- `.planning/threads/commerce-archetype-proof.md` — milestone thread / strategic intent.

### Prior-phase context (decisions this proof asserts against)
- `.planning/phases/35-reconciliation-wiring-and-four-state-liveview/35-CONTEXT.md` — D-02/D-03
  (proof calls `MockBackend.build_verified_snapshot/2` directly; synchronous deterministic
  verify→project→derive core), D-05 (async wrapper is LiveView-only — never in the proof),
  D-08 (the SC-reinterpretation precedent this phase mirrors).
- `.planning/phases/34-mockstorefront-and-idempotency-invariants/34-CONTEXT.md` — D-08/D-09
  (determinism / injectable `captured_at`), `@subscription_entry_id "sub_pro_monthly"`,
  hermetic `Code.require_file`-at-module-scope idiom + untagged → merge-blocking lane.
- `.planning/phases/33-corridor-routes-and-ci-infrastructure/33-CONTEXT.md` — `phase34-proof.yml`
  two-job CI split (hermetic merge-blocking vs advisory); `@tag :requires_example_host` convention.

### Code asserted against (reuse, DO NOT modify — shipped/locked)
- `lib/crosswake/commerce/reconciliation.ex` §142 —
  `authority_mutation_allowed_from_evidence?/1` returns `false` (the fence anchor, D-06.1).
  §114 — `ingest_evidence/2` (shipped-lib variant; note the example-host variant below is the
  one this corridor uses).
- `lib/crosswake/commerce/contracts.ex` — `ReconciliationEvidence` (enforced keys: `source,
  provider, provider_reference, event_kind, evidence_ref, captured_at`) and
  `EntitlementSnapshot` + lanes (`AuthorityLane`, `AccessLane`, `ReconciliationLane`,
  `FreshnessLane`, `EffectiveLane`, `EvidenceLane`) — the structs the inline builders construct.
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` —
  `ingest_evidence/2`; `"purchase"`/`"restore"` → `status: :awaiting_verification` (D-05.1).
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` —
  `project_snapshot/2` (verification gate: `@verified_reconciliation_states` = the four states;
  monotonic `as_of`) and `derived_state/1` (precedence stale→pending→granted→denied;
  `granted_snapshot?/1` requires `:projection_refreshed`). The exact source for D-04/D-05/D-06.
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` —
  `build_verified_snapshot/2` (synchronous `:granted` snapshot core, callable without a server,
  D-05.3) and `verify_and_broadcast/2` (LiveView-only; the proof does NOT call it — it touches
  PubSub). Moduledoc confirms the require_file-at-module-scope contract (D-01).

### Test patterns to mirror
- `test/crosswake/proof/phase34_mock_storefront_test.exs` §1-26 — exact `Code.require_file`
  header form, `async: false`, untagged hermetic idiom, header-comment hermeticity contract.
- `test/crosswake/proof/phase21_reconciliation_example_test.exs` §90-200 — snapshot builder
  helpers (`snapshot/1`, `authority_lane/1`, `access_lane/1`, `reconciliation_lane/1`,
  `freshness_lane/1`) producing all four derived states; the **pattern** the inline
  `Phase34`-prefixed helpers reproduce (do not require_file this test file — D-07).
- `test/crosswake/proof/phase35_paywall_live_test.exs` — the COMPLEMENT: it asserts the
  LiveView callbacks + PubSub *with* a process (`@tag :requires_example_host`). Phase 36 is the
  process-free counterpart. Useful to see what NOT to duplicate (no mount/render/PubSub here).

### CI
- `.github/workflows/phase34-proof.yml` — confirm the hermetic job globs/runs
  `test/crosswake/proof/` under `--exclude requires_example_host --warnings-as-errors` (SC#5).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MockBackend.build_verified_snapshot/2` — the honest `:granted` snapshot source (synchronous,
  server-free). The proof's `:granted` + transition assertions route through it (D-05.3).
- `EntitlementProjection.project_snapshot/2` + `derived_state/1` — the projection core under
  test; pure, loaded via `Code.require_file` (D-01).
- `ReconciliationInbox.ingest_evidence/2` — yields `status: :awaiting_verification` for the
  `:pending` origin (D-05.1).
- `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` — shipped-lib
  fence anchor; needs no require_file (D-06.1).
- phase21 test snapshot-builder pattern — reproduced inline as `Phase34`-prefixed helpers (D-07).

### Established Patterns
- Hermetic proof = `Code.require_file` PURE example-host modules at module scope + untagged +
  `async: false` → runs in the merge-blocking `phase34-proof.yml` lane. Server/PubSub-backed
  tests get `@tag :requires_example_host` and run advisory only (the phase35 split).
- `provider: "mock"`, `source: :storefront`; no provider-SDK tokens anywhere in the proof.
- Determinism via fixed/injected `captured_at` (Phase 34 D-08/D-09) — no clock behaviour abstraction.

### Integration Points
- The proof is a pure consumer of already-shipped code — it adds NO product code and modifies
  nothing. Its only "integration" is being discovered by the `phase34-proof.yml` hermetic job.
- The self-scan guard (D-03) is self-referential — it reads the proof file's own source to
  enforce the hermeticity contract structurally rather than by reviewer vigilance.

</code_context>

<specifics>
## Specific Ideas

- The proof and the running example share **one** verification core (`MockBackend` +
  `EntitlementProjection`); the proof exercises it synchronously (no Task, no PubSub), the
  LiveView wraps it in a Task + broadcast. This is the "same code path for example and proof"
  thesis from Phase 35 D-02, now asserted.
- Two contradictions in the locked roadmap criteria were surfaced and resolved with the user:
  SC#4 (no example-host require_file) → reinterpreted as no *runtime*-path require_file (D-02);
  SC#3 (project_snapshot rejects non-`:projection_refreshed`) → asserted as the three real
  truths because the code accepts four verified states (D-06). Both mirror the Phase 35 D-08
  "reinterpret-and-flag-for-verifier" pattern.
- Self-scan guard reads `__ENV__.file` and greps its own source — hermeticity proven by the
  test, not asserted in prose.

</specifics>

<deferred>
## Deferred Ideas

- **ROADMAP SC#3 / SC#4 rewording** — the criteria text should be tightened to match D-02/D-06
  (runtime-path require_file fence; verification-gate vs grant-requirement distinction). Suggest
  via `/gsd-phase` edit before or during verification so the verifier checks the accurate claim.
- **`guides/commerce.md` walkthrough + docs-contract lock** — Phase 37 (DOCS-01, DOCS-02). The
  proof authored here is what that walkthrough's "this is merge-blocking" claim points to.
- **StoreKit / Play Billing real adapters + graduating their proofs to merge-blocking** — out of
  scope (AF-01); deferred to v3.6 (ADPT-01/02/03), advisory CI only.
- **ExDoc zero-warnings cleanup (HEX-03)** — deferred (STATE), unrelated to this proof.

### Reviewed Todos (not folded)
None — `todo.match-phase` surfaced no matches for Phase 36. The two STATE pending todos
(verification-simulation shape; PubSub-not-started) were resolved in Phases 35 (D-01/D-02) and
35 (D-12) respectively and do not bear on this test-only phase.

</deferred>

---

*Phase: 36-Hermetic Proof Lane*
*Context gathered: 2026-05-29*
