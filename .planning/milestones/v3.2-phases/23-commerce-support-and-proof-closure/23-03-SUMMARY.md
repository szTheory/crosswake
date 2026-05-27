---
phase: 23-commerce-support-and-proof-closure
plan: 03
subsystem: guides
tags: [elixir, guides, commerce, reviewer-playbooks, non-claims, docs-contract, parity-tests]

# Dependency graph
requires:
  - phase: 23-01
    provides: doctor commerce_summary surface, proof_class metadata on commerce findings
  - phase: 23-02
    provides: enriched commerce corridor entries (prerequisite_classes, rebuild_requirement, proof_class), guides/commerce.md with Proof Posture subsection and denial-table proof_class column, advisory non-claim language
provides:
  - Layered commerce docs hub with three explicit H2 layers (Commerce Support Truth, Reviewer And Storefront Playbooks, Rough Edges And Non-Claims)
  - App Store and Play Store reviewer notes templates with five-column metadata (surface, owner, proof_class, failure_posture, rebuild_requirement)
  - "How To Use These Templates" preamble citing canonical SupportMatrix accessors
  - Canonical Source Cross-References subsection mapping every reviewer template column back to a specific SupportMatrix accessor
  - Explicit non-claims for StoreKit adapter, Play Billing adapter, storefront purchase UI, device-local entitlement authority, and offline purchase replay
  - Known Rough Edges subsection covering restore-flow pending states, backend reachability degradation, and advisory-lane non-promotion behavior
  - 7 new docs-contract tests in commerce_test.exs locking layered structure, advisory callouts, non-claims, reviewer metadata columns, canonical denial codes in fallback language, reviewer corridor-role parity, and preamble accessor citations
  - Focused byte-identity assertion in renderer_test.exs for guides/support_matrix.md after Plan 23-02 enrichment
affects:
  - 23-04-proof-lanes-ci  # Layer 3 non-claims and Layer 2 advisory boundaries inform proof-lane separation

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Layered docs hub: H2 boundaries separate canonical core contract truth from advisory provider-specific guidance from explicit non-claims"
    - "Reviewer template column-to-accessor mapping table makes adopter customization mechanically anchored to canonical support truth"
    - "Per-template AND per-layer Advisory — provider-specific guidance callouts so a reviewer reading only one playbook still sees the advisory boundary"
    - "Reviewer surface column uses canonical corridor role names parenthetically so parity tests can mechanically locate them"

key-files:
  created: []
  modified:
    - guides/commerce.md
    - test/crosswake/guides/commerce_test.exs
    - test/crosswake/support_matrix/renderer_test.exs

key-decisions:
  - "Layered structure uses H2 headings for the three layers (Commerce Support Truth, Reviewer And Storefront Playbooks, Rough Edges And Non-Claims) so navigation is mechanically unambiguous and the parity tests can split sections deterministically"
  - "Existing `## Non-Goals & explicit Rejections` H2 was moved INTO Layer 3 as an H3 subsection of Rough Edges And Non-Claims; the pre-existing `keeps reconciliation guidance provider-neutral` parity test was updated to use the new Layer 2 boundary (`## Reviewer And Storefront Playbooks`) since the old H2 boundary moved as part of the restructure"
  - "Reviewer surface column references canonical corridor role names (e.g. `` `paywall_entry` corridor (Phoenix-owned route render) ``) so the parity test asserting reviewer templates reference every SupportMatrix corridor role can mechanically locate them"
  - "Non-claims are stated with explicit `X is not shipped` language (uppercase X) so the docs-contract test cannot pass on prose that only implies absence — every non-claim must be explicit"
  - "Renderer byte-identity is asserted twice: once as a focused single-line test (the new Plan 23-03 test) and once as part of the broader phase-3 boundary test, so future planners see the byte-identity guarantee without having to read through the broader test"

patterns-established:
  - "Layered guide structure (truth → advisory playbooks → non-claims) with mechanical H2 boundaries for parity tests"
  - "Reviewer template column-to-accessor mapping table as the canonical extension point: adopters who add reviewer rows must still draw all four metadata columns from listed SupportMatrix accessors"
  - "Pre-existing docs-contract test boundaries get rescoped (not deleted) when layered restructure moves a section heading; commit message explicitly documents which boundary moved and why"

requirements-completed:
  - SUPP-05

# Metrics
duration: ~25 min
completed: 2026-05-27
---

# Phase 23 Plan 03: Reviewer/Storefront Guidance And Non-Claims — Summary

**Commerce guide is now a layered docs hub (support truth → advisory reviewer playbooks → explicit non-claims) with App Store and Play Store reviewer notes templates anchored to canonical SupportMatrix accessors and 8 new docs-contract tests that mechanically lock the layered structure, advisory boundary callouts, non-claims naming (StoreKit, Play Billing, device-local authority, offline replay), reviewer metadata columns (owner/proof_class/failure_posture/rebuild_requirement), canonical denial codes in fallback language, and reviewer corridor-role parity against `SupportMatrix.commerce_corridors/0`.**

## Performance

- **Duration:** ~25 minutes
- **Started:** 2026-05-27T15:35Z (approx — worktree spawn)
- **Completed:** 2026-05-27T16:00Z
- **Tasks:** 3
- **Files modified:** 3 (1 guide + 2 tests)

## Accomplishments

### Task 1 — Layered docs hub restructure

- Restructured `guides/commerce.md` into three explicit H2 layers:
  - **Layer 1 — Commerce Support Truth:** vocabulary, corridor ownership matrix (with proof_class + native_rebuild_required columns from Plan 23-02), Proof Posture subsection, entitlement snapshot lanes, authority vs evidence, commerce moment map, canonical denial taxonomy (with proof_class column), reconciliation flow, minimal reconciliation inbox example, backend idempotency, deterministic projection precedence, fallback behavior. All Layer 1 content is provider-neutral.
  - **Layer 2 — Reviewer And Storefront Playbooks:** layer-level `Advisory — provider-specific guidance` callout, "How To Use These Templates" preamble citing `Crosswake.SupportMatrix.commerce_corridor_denial_codes/0` and `Crosswake.SupportMatrix.commerce_corridor_prerequisite_taxonomy/0`, App Store reviewer notes template (sandbox setup + 5-column expectation table + purchase/restore flow expectations + fallback behavior + backend availability + advisory note on StoreKit adapter), Play Store reviewer notes template (parallel structure for Play Billing).
  - **Layer 3 — Rough Edges And Non-Claims:** original Non-Goals & explicit Rejections section retained as H3, new explicit non-claims subsection for v3.2 (StoreKit adapter not shipped, Play Billing adapter not shipped, storefront purchase UI not shipped, device-local entitlement authority not shipped, offline purchase replay not shipped), known rough edges subsection.
- Preserved all pre-existing content; restructure-only (no deletions of canonical truth).
- Updated the pre-existing `keeps reconciliation guidance provider-neutral` test to use the new Layer 2 boundary (the old `## Non-Goals & explicit Rejections` H2 boundary moved into Layer 3 as part of the restructure).

### Task 2 — Reviewer template anchoring

- Added "Canonical Source Cross-References" subsection that maps every reviewer template column (owner, proof_class, failure_posture, rebuild_requirement, corridor role names) back to specific SupportMatrix accessor functions (`commerce_corridors/0`, `commerce_corridor_proof_classes/0`, `commerce_corridor_denial_codes/0`).
- Made the contract violation explicit: adopters who add reviewer rows for additional surfaces must still draw all four metadata columns from canonical sources; adding a surface that does not map to a canonical corridor role is a contract violation.

### Task 3 — Docs-contract test lock

- Added 7 new tests in `test/crosswake/guides/commerce_test.exs`:
  1. `commerce guide publishes three explicit layer headings` — H2 regex assertions for all three layer headings.
  2. `reviewer playbooks carry explicit Advisory — provider-specific guidance callout` — layer-level callout + per-template (App Store, Play Store) callouts.
  3. `non-claims section explicitly names StoreKit, Play Billing, device-local authority, and offline replay` — explicit "X is not shipped" assertions for all five non-claims.
  4. `reviewer templates contain owner, proof_class, failure_posture, and rebuild_requirement columns` — exact header match assertion in at least two templates.
  5. `reviewer fallback language uses canonical commerce.corridor.* denial codes` — cross-reference against `SupportMatrix.commerce_corridor_denial_codes/0` for the three failure-posture-relevant codes.
  6. `reviewer template corridor roles cross-reference canonical SupportMatrix corridor roles` — parity assertion against `commerce_corridors/0`.
  7. `reviewer playbooks include How To Use These Templates preamble anchored to canonical accessors` — preamble must cite both `commerce_corridor_denial_codes/0` and `commerce_corridors/0`.
- Added focused byte-identity test in `test/crosswake/support_matrix/renderer_test.exs` (`guides/support_matrix.md is byte-identical to canonical renderer output after Plan 23-02 enrichment`) so the byte-identity guarantee is discoverable as a single-line test, separate from the broader phase-3 boundary test which already asserts it indirectly.
- Updated reviewer surface columns to reference canonical corridor role names parenthetically (e.g. `` `paywall_entry` corridor (Phoenix-owned route render) ``) so the parity test can mechanically locate them.

## Task Commits

Each task was committed atomically on branch `worktree-agent-ab458da7bc5e400a0`:

1. **Task 1: Restructure commerce guide into layered docs hub** — `cdaf285` (docs)
2. **Task 2: Anchor reviewer templates to canonical SupportMatrix accessors** — `c42d3f5` (docs)
3. **Task 3: Lock layered docs structure, non-claims, and reviewer parity** — `1574507` (test)

## Files Created/Modified

- `guides/commerce.md` — restructured into three explicit H2 layers; preserved canonical truth in Layer 1; added App Store + Play Store reviewer notes templates with five-column metadata in Layer 2; added explicit non-claims for StoreKit, Play Billing, storefront purchase UI, device-local entitlement authority, and offline purchase replay in Layer 3; added Canonical Source Cross-References subsection; reviewer surface columns now reference canonical corridor role names parenthetically.
- `test/crosswake/guides/commerce_test.exs` — added 7 new docs-contract tests for layered structure, advisory callouts, non-claims naming, reviewer metadata columns, canonical denial codes in fallback language, reviewer corridor-role parity, and preamble accessor citations; updated the pre-existing reconciliation-section provider-neutral test to use the new Layer 2 boundary (the old H2 boundary moved into Layer 3 as part of the restructure).
- `test/crosswake/support_matrix/renderer_test.exs` — added focused byte-identity assertion for `guides/support_matrix.md` after Plan 23-02 enrichment, with a determinism re-render guard.

## Verification

```
mix test test/crosswake/guides/commerce_test.exs test/crosswake/support_matrix/renderer_test.exs
→ 29 tests, 0 failures
```

```
rg "Reviewer And Storefront|Rough Edges And Non-Claims|Advisory.*provider-specific" guides/commerce.md
→ 10 matches (layer-level + per-template + intro list + cross-references)
```

```
rg "StoreKit.*not shipped|Play Billing.*not shipped|device-local.*not" guides/commerce.md
→ 3 matches (explicit non-claims in Layer 3 + device-local rejection in Non-Goals subsection)
```

Broader regression check:
```
mix test test/crosswake/guides/ test/crosswake/support_matrix/ test/crosswake/doctor/
→ 74 tests, 0 failures
```

## Self-Check: PASSED

All Task 1, Task 2, and Task 3 acceptance criteria are met; all three plan verification commands return green; broader regression across guides/, support_matrix/, and doctor/ passes cleanly (74/74). Plan-level success criteria are satisfied:
- All tasks completed.
- SUPP-05 is satisfied: public commerce guidance now explains reviewer/storefront sandbox setup, restore expectations, fallback behavior, and rough edges without implying provider adapters have shipped.
- Layered docs structure provides clear navigation from support truth → advisory playbooks → non-claims.
- Canonical fallback vocabulary is mechanically enforced via `SupportMatrix.commerce_corridor_denial_codes/0` cross-reference test.

## Deferred Issues

None new for this plan. Pre-existing deferred items from Plan 23-02 (`.planning/phases/23-commerce-support-and-proof-closure/deferred-items.md`) remain unchanged:
1. `Mix.Tasks.Crosswake.DoctorTest` JSON output test — pre-existing at the wave base ref, scoped for a future plan (likely a follow-up to 23-01).
2. 15 `test/crosswake/proof/phase{5,7,8,9}_*_test.exs` failures — pre-existing example-host router compilation issue, historically run via example-host verification scripts.

Both remain explicitly out of Plan 23-03 scope per the SCOPE BOUNDARY rule.

## Notable Deviations

**Rule 3 (blocking issue fix during Task 1):** The layered restructure moved the pre-existing `## Non-Goals & explicit Rejections` H2 heading from a standalone section into Layer 3 as an H3 subsection (`### Non-Goals & explicit Rejections` inside `## Rough Edges And Non-Claims`). This broke the pre-existing `keeps reconciliation guidance provider-neutral and non-authoritative` test (commerce_test.exs:113), which used the old H2 as a section terminator. The fix updated the test to terminate the reconciliation section at the new Layer 2 boundary (`## Reviewer And Storefront Playbooks`) and to start it at the H3 boundary `### The Canonical Reconciliation Flow` (the reconciliation flow heading dropped from H2 to H3 as part of nesting under Layer 1). This is a structural-restructure consequence, not a scope deviation — Task 3 explicitly authorized test adjustments, and committing the test rescope as part of Task 1 was necessary so Task 1's verification step (`mix test test/crosswake/guides/commerce_test.exs`) could pass before Task 2 ran.

**Rule 1 (correctness fix during Task 3):** The initial reviewer template "surface" column used human-readable prose like "paywall entry (Phoenix-owned route render)" without backtick-quoted canonical role names. The new parity test (`reviewer template corridor roles cross-reference canonical SupportMatrix corridor roles`) revealed this: `paywall_entry` and `account_management` literal role names were missing from the playbook section. Fixed by rewriting the surface column to lead with the canonical role name (e.g. `` `paywall_entry` corridor (Phoenix-owned route render) ``) so the parity test can mechanically locate every canonical corridor role inside the playbook layer. This is a docs-contract correctness fix consistent with the parity intent the planner specified.
