---
phase: 152-capability-map-collateral-and-v20-handoff
verified: 2026-07-12T20:40:47Z
status: passed
requirements: [CAPMAP-01, CAPMAP-02, CAPMAP-03, CAPMAP-04, PROOF-01, PROOF-02, PROOF-03, PROOF-04]
score: "8/8 must-haves verified"
behavior_unverified: 0
overrides_applied: 0
re_verified_after:
  - "Phase 152.1 Plan 01 support-truth repair for scanner/document_scan unsupported deferred rows"
---

# Phase 152: Capability Map, Collateral, and v20 Handoff Verification Report

**Phase Goal:** Publish a typed capability map, evidence-backed collateral, public entry points, and a planning-only v20 Native Controls Pack 1 handoff without widening v19 into unsupported native-control implementation.
**Verified:** 2026-07-12T20:40:47Z
**Status:** passed
**Re-verification:** Yes - after Phase 152.1 support-truth repair.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | CAPMAP-01: User can read capability classifications as shipped, demoed, missing, deferred, or next-pack candidate. | VERIFIED | Plan 152-02 added `Crosswake.CapabilityMap`, `Crosswake.CapabilityMap.Renderer`, and generated `guides/capability_map.md`; fresh capability-map tests passed. |
| 2 | CAPMAP-02: Package ownership is visible for core, companion, native shell, example/docs-only, and deferred surfaces. | VERIFIED | Capability-map rows separate package owner from route owner, proof posture, support label, fallback, and v20 implication. |
| 3 | CAPMAP-03: Proof posture distinguishes merge-blocking, advisory, not-yet-proven, and unsupported states. | VERIFIED | Plan 152-03 generalized the evidence manifest with proof_class, support_label, capability_posture, package_owner, limitations, unavailable_reason, and retention fields; fresh evidence-manifest tests passed. |
| 4 | CAPMAP-04: Maintainer can use the map to define v20 Native Controls Pack 1 without re-litigating the strategic arc. | VERIFIED | Plan 152-04 created `152-V20-HANDOFF.md` with Pack 1 candidates, explicit exclusions, later packs, promotion criteria, and planning questions. |
| 5 | PROOF-01: Reset proof shows deterministic showcase data does not duplicate or drift. | VERIFIED | Fresh `examples/phoenix_host` reset tests passed; Plan 152-03 strengthened two-reset digest/count assertions and keeps browser_state_reset false. |
| 6 | PROOF-02: Browser route-tour coverage exercises the showcase hub and one happy path per domain lane. | VERIFIED | Fresh Playwright route-tour and LearnLoop route-tour runs passed; route-tour evidence covers hub, AdminPilot, Fieldserv, LearnLoop, bridge/offline/native fallback surfaces. |
| 7 | PROOF-03: Structural docs/support tests prevent unsupported native controls from being presented as shipped. | VERIFIED | Fresh support-matrix, capability-map, public-claim, evidence-manifest, and collateral-table tests passed. Phase 152.1 Plan 01 corrected scanner/document_scan support-matrix rows to unsupported/deferred. |
| 8 | PROOF-04: Collateral and docs describe current support, demo pressure, and v20+ plans honestly. | VERIFIED | Public README links, example-host README links, generated capability map, evidence manifest, and v20 handoff all preserve non-claims and future/deferred boundaries. |

**Score:** 8/8 truths verified, 0 present-but-behavior-unverified.

### Required Artifacts

| Artifact Group | Expected | Status | Details |
|---|---|---|---|
| Typed capability map | Canonical capability rows and vocabularies | VERIFIED | `152-02-SUMMARY.md` records `lib/crosswake/capability_map.ex` and renderer implementation. |
| Generated capability guide | Byte-derived public guide | VERIFIED | `guides/capability_map.md` is renderer-backed and covered by tests. |
| Public claim scanner | Blocks unsupported native/offline/commerce/plugin/screenshot overclaims | VERIFIED | Fresh `capability_claims_test.exs` passed after README entry points. |
| Evidence manifest | Generalized route-tour evidence fixture and CI artifact checks | VERIFIED | `152-03-SUMMARY.md` records 33 route rows and CI required artifact checks; fresh evidence-manifest/collateral tests passed. |
| v20 handoff | Planning-only Pack 1 scope and exclusions | VERIFIED | `152-V20-HANDOFF.md` exists and is cited from Plan 152-04 summary. |

### Key Link Verification

| From | To | Status | Details |
|---|---|---|---|
| `152-04-SUMMARY.md` | CAPMAP-04 / PROOF-04 | VERIFIED | Final summary records public entry points and v20 handoff, with docs-only/planning-only scope. |
| `Crosswake.CapabilityMap` | `guides/capability_map.md` | VERIFIED | Renderer parity tests keep generated guide derived from canonical capability truth. |
| Evidence manifest fixture | Route-tour Playwright proof | VERIFIED | Route-tour writes/validates captured and unavailable route evidence; screenshots remain collateral after semantic assertions. |
| `guides/support_matrix.md` | `guides/capability_map.md` | VERIFIED | Phase 152.1 Plan 01 fixed scanner/document_scan support-matrix rows to unsupported/deferred so support matrix and capability map agree. |
| README entry points | Generated capability guide | VERIFIED | Root README and example-host README link to the capability map without duplicating or widening support claims. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Support matrix, capability map, public claims, evidence manifest, and collateral table | `mix test test/crosswake/support_matrix test/crosswake/capability_map test/crosswake/guides/capability_claims_test.exs test/crosswake/guides/evidence_manifest_test.exs test/crosswake/guides/collateral_table_test.exs` | 96 tests, 0 failures | PASS |
| Showcase reset determinism | `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/showcase/reset_test.exs` | 4 tests, 0 failures | PASS |
| Browser route-tour and LearnLoop proof | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts e2e/learnloop_route_tour.spec.ts` | 4 tests passed | PASS |

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| CAPMAP-01 | SATISFIED | Typed map and generated guide classify relevant capabilities, including unsupported scanner/document_scan future gaps. |
| CAPMAP-02 | SATISFIED | Rows expose package owner and route/runtime owner separately for core, companions, native shell, examples/docs-only, and deferred surfaces. |
| CAPMAP-03 | SATISFIED | Evidence manifest and capability map expose proof posture without treating advisory screenshots or unavailable rows as shipped support. |
| CAPMAP-04 | SATISFIED | `152-V20-HANDOFF.md` carries Pack 1 candidate scope and exclusions forward. |
| PROOF-01 | SATISFIED | Reset tests prove deterministic server-side showcase reset and stable digest/count behavior. |
| PROOF-02 | SATISFIED | Playwright route tours cover hub and lane happy paths with semantic assertions before screenshots. |
| PROOF-03 | SATISFIED | Structural tests pass and support truth now agrees that scanner/document_scan are unsupported/deferred. |
| PROOF-04 | SATISFIED | Capability map, README entry points, evidence manifest, and handoff describe current support, demo pressure, and future v20+ plans. |

### Re-Verification After Support-Truth Repair

Phase 152.1 Plan 01 changed canonical support-matrix derivation so `package_class: :defer` capability-family rows render `unsupported` baseline and `unsupported` proof status. `scanner` and `document_scan` now appear as future/deferred unsupported gaps in `guides/support_matrix.md`, matching `guides/capability_map.md` and the v20 handoff boundary.

### Non-Claims and Rough Edges

- Phase 152 does not implement broad native controls, scanner/document scan, media upload providers, production permission dashboards, native storage/sync productization, commerce/paywall SDKs, notification delivery assurance, an operator dashboard, or a plugin catalog.
- The v20 handoff is planning-only; it does not ship alert/confirm, action menus, haptics/share expansion, toast/review prompt, permission status, or notification token UX contracts.
- Screenshots and visual collateral remain evidence artifacts after semantic route-tour assertions; they are not correctness proof by themselves.
- Device/emulator proof remains advisory or unavailable unless a specific deterministic lane proves it.

### Human Verification Required

None. Fresh automated tests and route-tour proof cover the phase goal after the support-truth repair.

### Gaps Summary

No blocking gaps remain. CAPMAP-01 through CAPMAP-04 and PROOF-01 through PROOF-04 are covered by historical plan summaries plus fresh post-support-truth reruns.

---
_Verified: 2026-07-12T20:40:47Z_
_Verifier: Codex execute-phase inline executor_
