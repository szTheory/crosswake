---
phase: 165-efficient-and-maintainable-ci
plan: 08
subsystem: ci
tags: [github-actions, android-jvm, swift, playwright, compatibility, classification]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 07
    provides: 24 literal leaves, central fail-closed classification, and 22 frozen compatibility contexts
provides:
  - Literal native package, generated-shell, browser, offline, mirror, profile, and Threadline proof leaves
  - Linux and Apple runner placement aligned to actual command ownership
  - Manual-only Android emulator authority and focused public-documentation scheduling
  - Exact 40-leaf, one-control, and 26-compatibility authority graph
affects: [165-09, 165-10, 165-11, 165-12]
actuals:
  tokens: 23555
  tasks: 3
  commits: 7
tech-stack:
  added: []
  patterns:
    - Literal heterogeneous proof leaves remain purpose-named while sharing one closed umbrella
    - Android JVM and portable package proof uses Linux; only Apple invocations use macOS
    - Documentation classification carries affected families for focused public-doc proof
key-files:
  created: []
  modified:
    - .github/workflows/crosswake-ci.yml
    - .github/workflows/phase68-proof.yml
    - script/ci_leaf_manifest.json
    - script/classify_ci_change.py
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase165_ci_policy_test.exs
key-decisions:
  - "Keep Phase 68 emulator execution manual and advisory-only; it is not a manifest leaf, compatibility context, or umbrella dependency."
  - "Run iOS mirror parity on Linux because its exact proof uses Git and shell rather than Apple tooling."
  - "Schedule focused Threadline contract proof for public-documentation families while planning-only documentation continues to skip it explicitly."
patterns-established:
  - "Runner boundary: command invocation, not product label, determines Linux versus macOS ownership."
  - "Compatibility boundary: frozen contexts are checkout-free umbrella conclusions and never proof leaves themselves."
requirements-completed: [CIP-01, CIP-02, CIP-05, CIP-07]
coverage:
  - id: D1
    description: Native package and mixed generated-shell proof runs literally once on the runner its commands require.
    requirement: CIP-01
    verification:
      - kind: integration
        ref: actionlint plus phase165_ci_integrity_test.exs runner_placement and triggers tags
        status: pass
    human_judgment: false
  - id: D2
    description: Browser, offline, and Android JVM proof is consolidated while emulator proof remains manual advisory authority.
    requirement: CIP-02
    verification:
      - kind: integration
        ref: check_aggregator_result_semantics.py --self-test plus phase165_ci_integrity_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Mirror, profile, and focused Threadline proof has exact manifest, producer, and documentation-family scheduling authority.
    requirement: CIP-05
    verification:
      - kind: integration
        ref: classify_ci_change.py --self-test plus check_ci_leaf_manifest.py --self-test
        status: pass
      - kind: other
        ref: check_required_checks_registered.sh --local-only plus live required-context snapshot verification
        status: pass
    human_judgment: false
duration: 24 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 08: Cross-Runtime CI Migration Summary

**Native, browser, offline, package, mirror, and focused documentation proof now runs once through a 40-leaf closed PR graph with explicit runner and advisory boundaries.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-09-08T17:19:15Z
- **Completed:** 2026-09-08T17:43:40Z
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments

- Moved native package, generated Android/iOS shell, and Phase 5/18/79 proof into eight literal leaves, preserving the frozen native required context through one checkout-free compatibility conclusion.
- Moved offline honesty, production-route absence, Playwright E2E, route-tour evidence, and Phase 67 Android JVM proof into five literal Linux leaves while retaining Phase 68 as workflow-dispatch-only emulator advisory proof.
- Moved iOS mirror parity, Phase 10 profiles, and Threadline docs-contract proof into three literal Linux leaves; public documentation schedules the focused Threadline owner while planning-only documentation skips unrelated proof.
- Reconciled 40 proof leaves, `classify-change`, 26 compatibility contexts, static umbrella needs, producers, runner placement, and the unchanged live 27-context snapshot.

## Task Commits

All three TDD tasks committed failing contracts before their implementation:

1. **Task 1 RED: native migration contracts** - `5612f565` (test)
2. **Task 1 GREEN: native and mixed proof consolidation** - `10ada39a` (feat)
3. **Task 1 contract formatting/cardinality** - `4170de8a` (style)
4. **Task 2 RED: offline migration contracts** - `8d76f18f` (test)
5. **Task 2 GREEN: offline and Android JVM consolidation** - `31813737` (feat)
6. **Task 3 RED: final cross-runtime contracts** - `cf6fb13f` (test)
7. **Task 3 GREEN: mirror, profile, and focused docs-contract consolidation** - `4e6cf3fc` (feat)

## Files Created/Modified

- `.github/workflows/crosswake-ci.yml` - Adds sixteen literal cross-runtime leaves, three frozen-context compatibility conclusions, exact static needs, and closed documentation irrelevance.
- `.github/workflows/phase68-proof.yml` - Retains Android emulator execution only as a manual, non-required advisory.
- `.github/workflows/native-behavioral-proof-gate.yml`, `.github/workflows/phase5-proof.yml`, `.github/workflows/phase18-proof.yml`, `.github/workflows/phase79-proof.yml` - Deleted after native/mixed replacement and compatibility parity.
- `.github/workflows/offline-sync-e2e-gate.yml`, `.github/workflows/phase67-proof.yml` - Deleted after browser/offline/Android JVM replacement parity.
- `.github/workflows/merge-blocking-ios-mirror-parity.yml`, `.github/workflows/phase10-proof.yml`, `.github/workflows/phase96-proof.yml` - Deleted after mirror/profile/docs-contract replacement parity.
- `script/ci_leaf_manifest.json` - Declares 40 exact leaves, one required control, and 26 frozen compatibility contexts.
- `script/classify_ci_change.py` - Carries affected documentation families so public docs can schedule focused Threadline proof without scheduling unrelated leaves.
- `test/crosswake/proof/phase165_ci_integrity_test.exs`, `test/crosswake/proof/phase165_ci_policy_test.exs` - Prove runner, trigger, advisory, manifest, compatibility, and focused classification boundaries.

## Decisions Made

- Product labels do not determine runner class: iOS mirror parity stays on Ubuntu because it invokes only Git/shell, while Swift/Xcode/generated-iOS commands remain on macOS.
- The Phase 68 emulator lane retains its existing advisory label and manual invocation, with no PR/push trigger or path into required authority.
- Threadline's scheduled/manual advisory remains in `phase96-proof-advisory.yml`; its recurring PR contract becomes a focused literal leaf.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added affected documentation families to the classifier**
- **Found during:** Task 3
- **Issue:** The classifier emitted only a generic documentation family, so the focused Threadline owner could not distinguish public docs from planning-only changes as the acceptance contract required.
- **Fix:** Derived affected allowlist families from the already validated NUL-safe paths and scheduled `threadline_docs_contract` only when `public_docs` is present.
- **Files modified:** `script/classify_ci_change.py`, `test/crosswake/proof/phase165_ci_policy_test.exs`
- **Verification:** Classifier self-tests prove planning-only, public-doc, and mixed-documentation schedules while malformed/executable inputs remain full proof.
- **Committed in:** `4e6cf3fc`

**2. [Rule 2 - Missing Critical] Kept the original documentation policy gate valid for the expanded graph**
- **Found during:** Task 3 aggregate verification
- **Issue:** The Plan 01 policy test assumed documentation was the first manifest row and retained the old leaf/context cardinalities.
- **Fix:** Locate the documentation owner by literal ID and assert the final 39 executable leaves and 26 compatibility contexts.
- **Files modified:** `test/crosswake/proof/phase165_ci_policy_test.exs`
- **Verification:** All 33 Phase 165 integrity and policy tests pass together.
- **Committed in:** `cf6fb13f`

---

**Total deviations:** 2 auto-fixed (2 missing critical recurring contracts).
**Impact on plan:** Both changes are necessary to enforce the plan's focused documentation scheduling and preserve the existing policy gate; neither widens product or Android scope.

## Issues Encountered

- The user-owned `.tool-versions` edit names locally unavailable toolchains. Mix verification used command-scoped Erlang 28.4.1 and Elixir 1.19.5-otp-28 without changing or staging that file.
- The route-tour background server command required quoting `mix "do"` for shellcheck parsing after migration; the executed Mix task sequence and artifact contract remain unchanged.

## Known Stubs

None. Advisory language and documentation scheduling outputs describe explicit authority boundaries rather than unimplemented product behavior.

## Threat Flags

None. PR jobs remain `contents: read`, receive no publication/recovery secrets, compatibility conclusions fail closed, and advisory emulator proof has no required-authority path.

## Authentication Gates

None. Live snapshot verification was read-only and succeeded before each source-trigger cohort changed.

## User Setup Required

None - no package installation, credential change, remote mutation, or human verification was required.

## Next Phase Readiness

Plan 165-09 can migrate the next CI cohort against 40 literal leaves and the same central classifier. The strict live 27-context snapshot remains exact, and Plan 165-12 still exclusively owns legacy-context retirement.

## Self-Check: PASSED

- All six retained modified files exist, nine planned source workflow deletions are present in Git, and the manual Phase 68 and scheduled/manual Threadline advisories remain.
- All seven Plan 165-08 task/TDD commits resolve.
- Actionlint, classifier and aggregator negatives, exact manifest/static-needs parity, producer authority, all 33 Phase 165 CI tests, local required-check audit, and live snapshot verification pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
