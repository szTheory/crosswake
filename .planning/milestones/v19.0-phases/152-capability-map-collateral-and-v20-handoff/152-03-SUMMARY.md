---
phase: 152-capability-map-collateral-and-v20-handoff
plan: 03
subsystem: proof-collateral
tags: [route-tour, evidence-manifest, reset-proof, ci, support-truth]
requires:
  - phase: 152-capability-map-collateral-and-v20-handoff
    provides: 152-01 RED evidence-manifest and claim-scanner contracts
  - phase: 152-capability-map-collateral-and-v20-handoff
    provides: 152-02 typed capability-map truth and generated guide
provides:
  - Showcase hub screenshot captured after semantic assertions
  - Generalized 33-row route-tour evidence manifest
  - Stable committed example manifest fixture
  - Reset proof assertions for server-only deterministic fixture reset
  - CI required artifact checks for all captured route-tour screenshots
affects: [route-tour, evidence-manifest, ci, reset-proof, capability-map-collateral]
tech-stack:
  added: []
  patterns: [semantic-first-screenshots, typed-evidence-manifest, unavailable-capability-pressure]
key-files:
  modified:
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - examples/phoenix_host/e2e/support/evidence_manifest.ts
    - examples/phoenix_host/evidence/evidence-manifest.example.json
    - examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs
    - .github/workflows/offline-sync-e2e-gate.yml
key-decisions:
  - "Captured route-tour rows remain merge-blocking so missing screenshots fail before manifest write."
  - "Unavailable pressure rows use explicit proof_class, support_label, capability_posture, package_owner, unavailable_reason, and non-claim limitations."
  - "Server reset proof keeps browser_state_reset false; IndexedDB and outboxes stay browser-owned."
patterns-established:
  - "The committed manifest fixture is generated from route-tour output, then normalized to stable metadata."
  - "Workflow required-file checks enumerate every captured screenshot represented by the generalized manifest."
requirements-completed:
  - PROOF-01
  - PROOF-02
requirements-advanced:
  - CAPMAP-03
  - PROOF-04
duration: 10 min
completed: 2026-07-12
status: complete
---

# Phase 152 Plan 03: Route-Tour Evidence Summary

**Generalized route-tour collateral and evidence metadata without expanding native/offline/commerce support claims.**

## Performance

- **Duration:** 10 min
- **Completed:** 2026-07-12
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `showcase-hub.png` capture immediately after `proveShowcaseHub(page)` and before the route tour leaves the hub.
- Generalized `EvidenceRoute` and `routeTourEntries/1` to emit 33 rows covering the hub, AdminPilot, Fieldserv, LearnLoop, library, bridge proof, offline study, native fallback, unavailable capability pressure, permissions status evidence, and notification token evidence.
- Refreshed `examples/phoenix_host/evidence/evidence-manifest.example.json` from real route-tour output, normalized to stable fixture metadata.
- Strengthened reset proof so two server resets explicitly preserve stable counts/digest, keep `browser_state_reset` false, and include all three lane count keys.
- Expanded the CI route-tour evidence check to require every captured screenshot and updated the step summary to state that screenshots are collateral and native/device/provider/offline-mutation/commerce authority is not claimed.

## Task Commits

Each task was committed atomically:

1. **Task 1: Capture showcase hub proof screenshot** - `fce06ecd` (test)
2. **Task 2: Generalize evidence manifest and fixture** - `10b0cef7` (test)
3. **Task 3: Preserve reset proof and CI evidence summary honesty** - `619a6e02` (ci)

**Plan metadata:** committed with this summary.

## Files Modified

- `examples/phoenix_host/e2e/route_tour.spec.ts` - hub screenshot capture after semantic assertions.
- `examples/phoenix_host/e2e/support/evidence_manifest.ts` - typed manifest vocabularies, full route set, captured/unavailable row helpers, artifact enforcement.
- `examples/phoenix_host/evidence/evidence-manifest.example.json` - 33-route stable fixture with current Crosswake version.
- `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` - explicit two-reset browser-state and lane-key assertions.
- `.github/workflows/offline-sync-e2e-gate.yml` - generalized route-tour required artifact checks and honest summary text.

## Decisions Made

- Kept all captured browser route rows as `proof_class: "merge-blocking"` so the manifest writer enforces screenshot presence before it writes evidence.
- Used `advisory` only for metadata-only permissions and notification token evidence rows, keeping them unavailable in browser route-tour proof.
- Modeled Fieldserv, LearnLoop, native controls, media upload, scanner, document scan, native storage, sync productization, and commerce pressure as unavailable rows with explicit limitations.

## Deviations from Plan

- `test/crosswake/guides/evidence_manifest_test.exs` did not need further edits in this plan because Plan 152-01 had already added the required RED contract vocabulary.

---

**Total deviations:** 1 plan-anticipated no-op.
**Impact on plan:** None. The implementation satisfied the existing RED contracts without weakening schema tests.

## Issues Encountered

- A bare `ruby` YAML sanity check was blocked by the local version manager. Retried with `/usr/bin/ruby`, which parsed `.github/workflows/offline-sync-e2e-gate.yml` successfully.

## Verification

- `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts --grep @learnloop` - passed, 2 tests.
- `mix test test/crosswake/guides/evidence_manifest_test.exs` - passed, 8 tests.
- `mix test test/crosswake/guides/capability_claims_test.exs` - passed, 5 tests.
- `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/showcase/reset_test.exs` - passed, 4 tests.
- `cd examples/phoenix_host && mix format --check-formatted test/crosswake_example/showcase/reset_test.exs` - passed.
- `/usr/bin/ruby -e "require 'yaml'; YAML.load_file('.github/workflows/offline-sync-e2e-gate.yml')"` - passed.
- `git diff --check` - passed.

## User Setup Required

None.

## Next Phase Readiness

Plan 152-04 can add public README entry points and the planning-only v20 Native Controls Pack 1 handoff using the typed capability map, generated guide, generalized evidence manifest, and CI collateral checks from this plan.

---
*Phase: 152-capability-map-collateral-and-v20-handoff*
*Completed: 2026-07-12*
