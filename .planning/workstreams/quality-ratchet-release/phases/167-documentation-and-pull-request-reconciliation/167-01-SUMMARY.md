---
phase: 167-documentation-and-pull-request-reconciliation
plan: 01
subsystem: documentation
tags: [elixir, capability-map, support-matrix, privacy, first-adopter]

requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: deterministic repository verification and generated-artifact hygiene
provides:
  - typed and fail-closed current first adopter claim owner
  - two deterministic generated projections with explicit owner metadata
  - aligned public first-read and codename-only parked activation truth
affects: [167-02-documentation-sync, 167-03-documentation-ci, first-b2c-adopter-readiness]

actuals:
  tokens: 8918
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns: [typed claim dimensions, shared validated projections, destination-aware privacy proof]

key-files:
  created: []
  modified:
    - lib/crosswake/capability_map.ex
    - lib/crosswake/capability_map/renderer.ex
    - lib/crosswake/support_matrix/renderer.ex
    - guides/capability_map.md
    - guides/support_matrix.md
    - README.md
    - guides/physical_iphone_handoff.md
    - .planning/workstreams/first-b2c-adopter-readiness/STATE.md

key-decisions:
  - "Keep the three current claim layers in Crosswake.CapabilityMap and require both generated projections to consume the validated set."
  - "Bind retained reference evidence to 2026-08-27 and iOS 26.6 without transferring it to first adopter activation."
  - "Keep public recovery copy generic while durable state retains the exact codename, TODO-002, and Phase 163.1 resume point."

patterns-established:
  - "Typed current claims: evidence subject, source binding, and activation state are closed before rendering."
  - "Generated claim projections name their executable owner and the future mix crosswake.docs.sync correction command."

requirements-completed: [DOC-01, DOC-02]

coverage:
  - id: D1
    description: Typed claims reject five impossible evidence and activation combinations before rendering.
    requirement: DOC-01
    verification:
      - kind: unit
        ref: "mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/support_matrix/renderer_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Capability and support guides project one reusable, one retained reference, and one blocked activation claim.
    requirement: DOC-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/capability_map test/crosswake/support_matrix/renderer_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: Public first-read guidance and the parked adopter lane preserve their distinct terminology and exact external gates.
    requirement: DOC-02
    verification:
      - kind: integration
        ref: "mix crosswake.adoption_context.scan && mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/planning/first_adopter_context_test.exs"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-09-10
status: complete
---

# Phase 167 Plan 01: Typed Current-Claim Reconciliation Summary

**A validated three-layer claim owner now keeps reusable contracts, dated reference-host evidence, and blocked first adopter activation distinct across generated guides and parked state.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-10T20:35:57Z
- **Completed:** 2026-09-10T20:45:14Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added closed evidence-subject, source-binding, and activation-state dimensions plus bounded validation for all five prohibited D-20 combinations.
- Projected the same validated claim set into support and capability guides with explicit executable-owner and regeneration metadata.
- Reconciled README, physical-iPhone handoff, and parked workstream state without widening support, exposing adopter facts, or resuming the parked lane.

## Task Commits

Each task was committed atomically using RED/GREEN TDD commits where behavior changed:

1. **Task 1: Carry one blocked first-adopter claim from typed owner to support guide** — `ecbd857d` (RED), `f3775969` (GREEN)
2. **Task 2: Expand the validated claim set through the capability projection** — `0c610421` (RED), `29293c51` (GREEN)
3. **Task 3: Reconcile first-read and parked-state truth in the same claim transaction** — `f765e398` (RED), `20fe20e1` (GREEN)
4. **Authorized blocker correction** — `552a9019` (fix)

## Files Created/Modified

- `lib/crosswake/capability_map.ex` — Owns closed claim dimensions, the canonical three-claim set, and fail-closed validation.
- `lib/crosswake/capability_map/renderer.ex` — Projects the shared claim set into the capability guide.
- `lib/crosswake/support_matrix/renderer.ex` — Projects the same claim set into support truth while preserving platform and scope non-claims.
- `guides/capability_map.md` and `guides/support_matrix.md` — Byte-identical generated projections with owner and regeneration metadata.
- `README.md` and `guides/physical_iphone_handoff.md` — Lead with the direct public blocked recovery statement and generated authority link.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — Preserves the codename-only Phase 163.1-08 Task 2 resume point and both external gates.
- Capability, renderer, and guide drift tests — Pin typed validation, deterministic projection, privacy, and parked-state semantics.
- `167-PATTERNS.md` — Uses named Swift closure parameters so tuple shorthand is not misclassified as commercial data.

## Decisions Made

- Kept `Crosswake.CapabilityMap` as the only current first adopter claim owner; neither renderer carries a second table.
- Preserved existing public support labels and unrelated iOS/Android posture; the new fields are internal claim dimensions.
- Treated retained physical evidence as dated, source-bound reference-host evidence rather than present support for another host.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected a pre-existing privacy-scan false positive in the Phase 167 pattern map**
- **Found during:** Task 3 verification
- **Issue:** Swift dollar-prefixed shorthand tuple parameters in a fenced example matched the commercial-detail detector, blocking the required repository privacy scan.
- **Fix:** With orchestrator authorization, replaced only the shorthand parameters with semantically equivalent named `waiter` parameters; the scanner was not weakened and no adopter fact changed.
- **Files modified:** `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-PATTERNS.md`
- **Verification:** `mix crosswake.adoption_context.scan` passed, followed by 29 focused privacy/guide tests.
- **Committed in:** `552a9019`

**2. [Rule 1 - Bug] Removed a hyphenated public phrase introduced in the claim moduledoc**
- **Found during:** Task 3 privacy verification
- **Issue:** The new moduledoc used `first-adopter`, which the destination-aware public scanner correctly rejects.
- **Fix:** Changed the phrase to the required public spelling `first adopter` without altering code identifiers.
- **Files modified:** `lib/crosswake/capability_map.ex`
- **Verification:** The adoption-context scan and focused privacy suite pass.
- **Committed in:** `20fe20e1`

---

**Total deviations:** 2 auto-fixed (1 blocking issue, 1 public-wording bug)
**Impact on plan:** Both corrections were narrow and semantics-preserving; no support, product, Android, or adopter scope expanded.

## Issues Encountered

- The repository pin `erlang 27.3` required explicit asdf selection of installed patch runtime `27.3.4.15`; Mix 1.19.5 then ran successfully on OTP 27.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- Task 1 RED `ecbd857d` precedes GREEN `f3775969`.
- Task 2 RED `0c610421` precedes GREEN `29293c51`.
- Task 3 RED `f765e398` precedes GREEN `20fe20e1`.

## Next Phase Readiness

- Plan 167-02 can add the no-write `mix crosswake.docs.sync` command against the owner/regeneration contract now published by both renderers.
- The First B2C Adopter lane remains parked at Phase 163.1-08 Task 2 pending validated TODO-002 input and a fresh source-bound signed-device run.

## Self-Check: PASSED

- All modified production, guide, state, and test files exist.
- All seven task/deviation commits are present in git history.
- All task-level and plan-level automated verification commands passed with non-zero test counts.
- No unknown stubs, skipped tests, unrun verification, or uncovered threat surface was introduced.

---
*Phase: 167-documentation-and-pull-request-reconciliation*
*Completed: 2026-09-10*
