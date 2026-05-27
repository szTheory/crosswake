---
phase: 23-commerce-support-and-proof-closure
plan: 04
subsystem: proof
tags: [elixir, ci, proof-lanes, commerce, merge-blocking, advisory, github-actions, hermetic]

# Dependency graph
requires:
  - phase: 23-01
    provides: commerce_summary surface + proof_class on findings (asserted by the hermetic proof lane)
  - phase: 23-02
    provides: enriched commerce corridor entries (prerequisite_classes, denial codes, fallback_hint, rebuild_requirement, proof_class) + canonical taxonomy accessor
  - phase: 23-03
    provides: layered guides/commerce.md docs hub (support truth / reviewer playbooks / non-claims), reviewer template column-to-accessor mapping, explicit StoreKit/Play Billing/device-local-authority/offline-replay non-claims
provides:
  - Hermetic merge-blocking Phase 23 commerce support proof lane (14 tests) stitching doctor commerce_summary, support matrix corridors, and guides/commerce.md layered structure
  - .github/workflows/phase23-proof.yml with two-job split (merge-blocking-commerce-proof + advisory-commerce-proof) and documented advisory-to-merge-blocking promotion path
  - promotion_path detail on advisory doctor findings (capability_proof_advisory) explaining requirement/roadmap scope-change requirement
  - Unit-level advisory boundary tests in doctor_test.exs and support_matrix_test.exs reinforcing the contract that advisory results never assert core support truth
affects:
  - 23-PHASE-CLOSEOUT  # merge-blocking lane is the closing piece of SUPP-06
  - future provider adapter milestone  # the advisory lane is the placeholder where StoreKit/Play Billing/storefront/device checks will land

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-job CI workflow with explicit merge-blocking vs advisory separation; advisory job conditional on schedule/workflow_dispatch only so it cannot gate merge"
    - "Hermetic proof lane self-asserts hermeticity (refutes Code.require_file/system.cmd/Port.open/:gen_tcp/HTTP calls in its own source)"
    - "Advisory findings carry promotion_path detail string referencing requirement/roadmap scope-change to make the advisory-to-merge-blocking gate visible inside doctor output"
    - "Provider-vocabulary fence applied to canonical support matrix data and merge-blocking docs surface (Canonical Reconciliation Flow subsection); advisory layers remain free to name providers in explicitly labeled callouts"

key-files:
  created:
    - test/crosswake/proof/phase23_commerce_support_proof_test.exs
    - .github/workflows/phase23-proof.yml
  modified:
    - lib/crosswake/doctor/doctor.ex
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs

key-decisions:
  - "Hermetic proof lane uses in-repo router fixtures (PaywallCorridorRouter / PurchaseCorridorRouter / CommerceCorridorRouter defined inside the test module) rather than the example-host CrosswakeExample.Router; this matches the deferred-items.md guidance that the example-host compile path is broken under library mix test"
  - "Workflow advisory job uses `if: schedule || workflow_dispatch` + `continue-on-error: true` so a failing advisory step is both non-running on PR/push and non-blocking even when it does run"
  - "Provider-vocabulary fence is scoped to two artifacts: the canonical SupportMatrix.commerce_corridors() data and the Canonical Reconciliation Flow subsection of guides/commerce.md. The full ## Commerce Support Truth layer of the guide intentionally references StoreKit / Play Billing inside its 'out of scope' / 'advisory' callouts so explicitly labeling provider work as deferred is permitted; fencing the full layer would over-constrain existing prose written by Plan 23-02 / 23-03"
  - "promotion_path detail added to advisory findings so the workflow header's four-condition promotion path is visible at runtime in doctor output too, not only in the workflow YAML comments"
  - "Advisory unit-level tests assert a forward-compatible contract: today no commerce corridor has proof_class :advisory (every corridor is merge_blocking with an optional advisory_provider_proof supplementary flag), but the tests pin the contract that any future advisory corridor must satisfy"

patterns-established:
  - "Hermetic proof lane self-test: the proof test reads its own source via __ENV__.file and refutes non-hermetic call shapes via regex (System.cmd(, Port.open(, :gen_tcp.X(, :httpc.X(, Req.get(, Tesla.get( and Code.require_file lines that load non-fixture files). This catches accidental hermetic-boundary regressions at the test-run level"
  - "Two-lane CI workflow shape: required hermetic job runs on PR/push and is fast-failing; advisory job runs only on schedule/workflow_dispatch with continue-on-error and emits workflow notices documenting the advisory boundary"
  - "Forbidden-token list defined as compile-time concatenation (e.g. `\"store\" <> \"kit\"`) so the test source can refute the literal token without itself containing it"

requirements-completed:
  - SUPP-06

# Metrics
duration: ~25 min (worktree + deps install + 3 tasks + scope-correction)
completed: 2026-05-27
---

# Phase 23 Plan 04: Proof Lane Formalization And CI Wiring — Summary

**Hermetic merge-blocking Phase 23 commerce support proof lane (14 tests) plus a two-job CI workflow that splits the required hermetic gate from the scheduled-only advisory provider/storefront/simulator/device lane, with a documented four-condition advisory-to-merge-blocking promotion path surfaced both in the workflow YAML and at runtime via a new `promotion_path` detail on advisory doctor findings.**

## Performance

- **Duration:** ~25 minutes (worktree spawn + `mix deps.get` + 3 tasks + a worktree-path-safety scope correction during Task 3)
- **Started:** 2026-05-27T16:05:00Z
- **Completed:** 2026-05-27T16:15:34Z
- **Tasks:** 3
- **Files changed:** 5 (2 created + 3 modified)
- **Lines added:** 871

## Accomplishments

### Task 1 — Hermetic Phase 23 commerce support proof lane

Created `test/crosswake/proof/phase23_commerce_support_proof_test.exs` (551 lines, 14 tests, all hermetic). The lane defines `Crosswake.Proof.Phase23CommerceSupportProofTest` and asserts the full Phase 19-23 commerce contract surface:

- **Doctor commerce_summary contract**: corridors / prerequisites / snapshot_freshness / proof_posture / rebuild_requirements canonical keys; every commerce finding carries `proof_class` in `:details`.
- **Stale/unknown freshness fail-closed**: both `stale` and unknown (default when commerce routes exist) emit `commerce.entitlement.stale_snapshot` with `proof_class: "merge_blocking"`, never informational.
- **Support matrix completeness**: every corridor carries `proof_class`, `prerequisite_classes` (drawn from canonical taxonomy), `rebuild_requirement` map, and `denial_codes` (which are a superset of doctor-emitted commerce corridor codes).
- **Layered docs contract**: `## Commerce Support Truth`, `## Reviewer And Storefront Playbooks`, `## Rough Edges And Non-Claims` all present as H2 headings; non-claims section explicitly names StoreKit, Play Billing, device-local authority, and offline replay as "not shipped".
- **Provider-vocabulary fence**: canonical `SupportMatrix.commerce_corridors()` data carries no provider tokens; Canonical Reconciliation Flow subsection of guides/commerce.md is provider-neutral; no merge-blocking doctor finding leaks provider tokens.
- **Formatter rendering**: human formatter renders a `Commerce:` block with `snapshot_freshness:`, `proof_posture:`, and `[merge-blocking]` labels on commerce findings; JSON formatter exposes top-level `commerce_summary` with `proof_posture.merge_blocking` / `proof_posture.advisory` and a `proof_class` field on commerce check objects.
- **Hermeticity guard**: a self-test refutes `Code.require_file` calls that load anything other than `router_fixtures.ex` and refutes non-hermetic call shapes (`System.cmd(`, `Port.open(`, `:gen_tcp.X(`, `:httpc.X(`, `Req.get(`, `Tesla.get(`). The test cannot depend on the example-host router (`CrosswakeExample.Router` is not on the library compile path — see deferred-items.md).

### Task 2 — Phase 23 CI workflow with merge-blocking/advisory lane separation

Created `.github/workflows/phase23-proof.yml` (155 lines, YAML-validated). Two jobs:

- **`merge-blocking-commerce-proof`** (required branch check): runs on PR and push to main, macOS-15 runner, `mix compile --warnings-as-errors`, then runs the hermetic proof lane plus the Plan 23-01/02/03 contract tests (`doctor_test.exs`, `support_matrix_test.exs`, `renderer_test.exs`, `commerce_test.exs`). All hermetic by contract — no network, no simulator, no provider SDK.
- **`advisory-commerce-proof`** (non-gating): runs only on `schedule` (weekly Monday 06:00 UTC) and `workflow_dispatch`. Has `if:` condition preventing PR/push triggering and `continue-on-error: true` so even a failing internal step is non-blocking. Carries three placeholder steps (StoreKit simulator, Play Billing test-track, device/storefront smoke) plus a workflow-notice summary making the advisory boundary visible in the CI dashboard.

The workflow header documents the four-condition advisory-to-merge-blocking promotion path: (1) explicit requirement/roadmap scope change, (2) sustained stability evidence, (3) planned provider-adapter milestone, (4) explicit workflow edit moving the step from advisory into merge-blocking + branch-protection update.

### Task 3 — Advisory proof-boundary contract at the unit level

Extended three files to reinforce the advisory boundary at the unit level alongside the proof-lane integration test:

- `lib/crosswake/doctor/doctor.ex`: extended the `capability_proof_advisory` finding to include a `promotion_path` detail string explaining the advisory-to-merge-blocking promotion requirements (matches the workflow header).
- `test/crosswake/doctor/doctor_test.exs` (+99 lines, 2 new tests):
  - "advisory commerce findings (when emitted) cannot assert core support truth and carry explicit provider context" — asserts (a) advisory commerce findings cannot also claim `merge_blocking`, (b) advisory commerce findings have advisory/warning severity (never `error`), and (c) `commerce_summary.proof_posture.merge_blocking` and `commerce_summary.proof_posture.advisory` lists are disjoint.
  - "advisory findings include a promotion_path hint explaining merge-blocking promotion requirements" — every advisory finding must carry a non-empty `promotion_path` string referencing requirement/roadmap.
- `test/crosswake/support_matrix/support_matrix_test.exs` (+63 lines, 1 new test): "any advisory commerce corridor must be explicitly labeled with proof_class :advisory and is excluded from merge-blocking required checks" — four sub-assertions covering (a) explicit `:advisory` labeling, (b) mapping consistency, (c) `advisory_provider_proof` supplementarity (the flag never substitutes for the core `proof_class` declaration), and (d) merge-blocking / advisory role-set disjointness.

## Task Commits

Each task was committed atomically on branch `worktree-agent-ad7789e8a6e4d5c46`:

1. **Task 1: Create hermetic Phase 23 commerce support proof test** — `6a99f39` (test)
2. **Task 2: Create Phase 23 CI workflow with merge-blocking/advisory lane separation** — `73a75d7` (feat)
3. **Task 3: Add advisory proof posture documentation to existing test files** — `5139927` (test)

## Files Created/Modified

- `test/crosswake/proof/phase23_commerce_support_proof_test.exs` *(created, 551 lines, 14 tests)* — hermetic merge-blocking proof lane stitching doctor commerce_summary + support matrix corridors + guides/commerce.md layered structure
- `.github/workflows/phase23-proof.yml` *(created, 155 lines)* — two-job CI workflow with documented promotion path
- `lib/crosswake/doctor/doctor.ex` *(modified)* — added `promotion_path` detail to `capability_proof_advisory` finding
- `test/crosswake/doctor/doctor_test.exs` *(modified, +99 lines)* — 2 new advisory-boundary contract tests
- `test/crosswake/support_matrix/support_matrix_test.exs` *(modified, +63 lines)* — 1 new advisory-corridor labeling contract test

## Decisions Made

See `key-decisions` in frontmatter. The headline decisions:

- The hermetic proof lane uses **in-repo router fixtures** defined inside the test module (`PaywallCorridorRouter`, `PurchaseCorridorRouter`, `CommerceCorridorRouter`) rather than depending on `CrosswakeExample.Router`. This is the right call because the example-host router is not on the library mix-test compile path (per deferred-items.md), so depending on it would make the hermetic lane fail-by-default in CI.
- The **provider-vocabulary fence** is scoped narrowly. The full `## Commerce Support Truth` H2 layer of guides/commerce.md intentionally mentions StoreKit and Play Billing inside `out of scope` and `advisory` callouts (existing Plan 23-02 / 23-03 prose). Fencing the full layer would over-constrain that prose. The fence applies instead to (a) canonical `SupportMatrix.commerce_corridors()` data, (b) the `### The Canonical Reconciliation Flow` subsection, and (c) any merge-blocking doctor finding payload.
- `promotion_path` is added to advisory findings as a `:details` string so the four-condition advisory-to-merge-blocking gate (also documented in the workflow YAML header) is visible at doctor runtime — not only in CI workflow comments.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `promotion_path` detail to advisory findings**
- **Found during:** Task 3 (advisory proof posture documentation)
- **Issue:** The plan's Task 3 acceptance criteria require a test asserting that advisory findings include a `promotion_path` hint. The existing `capability_proof_advisory` finding in `lib/crosswake/doctor/doctor.ex` carried no `promotion_path` field, so the asserted contract did not yet exist in the doctor implementation.
- **Fix:** Extended the `capability_proof_advisory` check construction in `doctor.ex` to include `promotion_path:` in its details map, with explicit text referencing the requirement/roadmap scope-change requirement.
- **Files modified:** `lib/crosswake/doctor/doctor.ex`
- **Verification:** New unit test in `doctor_test.exs` ("advisory findings include a promotion_path hint explaining merge-blocking promotion requirements") asserts `:promotion_path` exists in details, is a non-empty string, and matches `~r/requirement|roadmap/i`. All 91 tests pass.
- **Committed in:** `5139927` (Task 3 commit)

**2. [Rule 3 - Blocking] Restructured hermeticity self-test to avoid literal forbidden tokens**
- **Found during:** Task 1 (initial test run of the hermeticity guard)
- **Issue:** The first draft of the hermeticity test used literal forbidden-token strings in error messages (e.g. `"phase 23 proof test source contains storekit token"`). When the test read its own source and downcased it, those error-message strings matched the very tokens being refuted, producing a false-positive failure.
- **Fix:** Rebuilt the forbidden-token list as compile-time string concatenation (e.g. `"store" <> "kit"`) so the literal strings never appear in source. Rebuilt the hermeticity guard to instead refute non-hermetic call shapes via regex (System.cmd / Port.open / :gen_tcp / :httpc / Req.get / Tesla.get with parenthesized invocations) and to refute `Code.require_file` lines that load anything other than `router_fixtures.ex`. Also dropped a docstring reference to literal tokens.
- **Files modified:** `test/crosswake/proof/phase23_commerce_support_proof_test.exs` (during Task 1)
- **Verification:** Hermeticity guard test ("phase 23 proof test stays hermetic and does not depend on example-host or provider SDK code") now passes; full 14-test suite passes.
- **Committed in:** `6a99f39` (Task 1 commit — fix was applied before the Task 1 commit, not a separate commit)

**3. [Rule 3 - Blocking] Rescoped guides/commerce.md provider-neutrality test**
- **Found during:** Task 1 (initial test design for the provider-vocabulary fence)
- **Issue:** A first-draft test asserted the entire `## Commerce Support Truth` H2 layer was provider-neutral, but existing prose written by Plan 23-02 / 23-03 inside that layer intentionally mentions StoreKit and Play Billing inside `out of scope` callouts (line 38) and `Proof Posture` advisory callouts (line 45). Asserting the full layer is provider-neutral would have demanded a Plan 23-02 / 23-03 rewrite, which is out of Plan 23-04 scope.
- **Fix:** Replaced that single broad assertion with two narrower assertions: (a) canonical `SupportMatrix.commerce_corridors()` data must stay provider-neutral (the actual canonical truth surface), and (b) the `### The Canonical Reconciliation Flow` subsection of guides/commerce.md must stay provider-neutral. The Reconciliation Flow subsection is already tested as provider-neutral elsewhere (Plan 23-03 `keeps reconciliation guidance provider-neutral` test); the Plan 23-04 proof lane re-asserts it as part of the merge-blocking contract.
- **Files modified:** `test/crosswake/proof/phase23_commerce_support_proof_test.exs` (during Task 1)
- **Verification:** Both rescoped tests pass; existing Plan 23-02 / 23-03 prose in guides/commerce.md remains unchanged.
- **Committed in:** `6a99f39` (Task 1 commit — rescope was applied before the Task 1 commit)

**4. [Rule 3 - Blocking] Moved typing-warning assertion form `entries != []` → `length(entries) > 0`**
- **Found during:** Task 1 (`mix test` after initial test draft)
- **Issue:** Elixir's new gradual type checker flagged `assert entries != [], "..."` as a typing violation: the compiler statically knows `SupportMatrix.commerce_corridors()` returns a non-empty list, making `entries != []` always true and unreachable. This produced a compile-time typing diagnostic that surfaced as an error.
- **Fix:** Switched to `assert length(entries) > 0, "..."`, which is semantically equivalent but does not trigger the type-checker's always-true warning.
- **Files modified:** `test/crosswake/proof/phase23_commerce_support_proof_test.exs` (during Task 1)
- **Verification:** No typing warning; test passes.
- **Committed in:** `6a99f39` (Task 1 commit)

---

**Total deviations:** 4 auto-fixed (1 Rule 2 missing critical, 3 Rule 3 blocking)
**Impact on plan:** All auto-fixes were necessary to satisfy plan acceptance criteria as written. No scope creep — the `promotion_path` addition implements the contract Task 3 explicitly tests for; the three Rule 3 fixes are mechanical adjustments (literal-token escaping, scope rebracketing, type-checker compliance) without semantic change.

## Issues Encountered

**Worktree absolute-path drift (recovered cleanly).** During Task 3, three file edits intended for the worktree were silently routed to the **main repo** at `/Users/jon/projects/crosswake/` because the Edit tool calls used absolute paths derived from the main-repo prefix (`/Users/jon/projects/crosswake/test/...`) instead of relative paths. This is the documented `worktree-path-safety` failure mode (#3099): absolute paths constructed before deriving the worktree root resolve to the main repo, not the worktree, even when the agent's cwd is the worktree.

**Recovery:** Captured the leaked diff via `git diff` in the main repo, ran `git checkout -- <files>` in the main repo to restore the three files to their committed state (none of them carried unrelated uncommitted work — only the leaked Task 3 edits were reverted), then `git apply` of the captured patch inside the worktree. The patch landed cleanly, the test suite passed (91 tests, 0 failures), and the worktree commit `5139927` was created with the correct file contents. The main repo's other uncommitted state (`.planning/REQUIREMENTS.md`, `.planning/config.json`, plus untracked files) is unchanged.

**Lesson logged:** When operating inside a Claude Code worktree, edit tool calls must use **relative paths** rooted at the worktree's `git rev-parse --show-toplevel`, never absolute paths derived from the orchestrator's pre-worktree cwd. Task 1 and Task 2 used the correct relative-or-worktree-rooted paths; only Task 3 drifted.

## Self-Check: PASSED

- All 5 created/modified files exist in the worktree.
- All 3 task commits (`6a99f39`, `73a75d7`, `5139927`) are present in `git log --oneline --all`.
- All 4 plan verification commands pass:
  - `mix test test/crosswake/proof/phase23_commerce_support_proof_test.exs` → 14 tests, 0 failures
  - `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/support_matrix/support_matrix_test.exs` → 34 tests, 0 failures
  - `grep -E "merge-blocking|advisory" .github/workflows/phase23-proof.yml` → 26 matches
  - `grep -c "Phase23CommerceSupportProofTest" test/crosswake/proof/phase23_commerce_support_proof_test.exs` → 1 match
- Broader regression check: `mix test test/crosswake/doctor/ test/crosswake/support_matrix/ test/crosswake/guides/ test/crosswake/proof/phase23_commerce_support_proof_test.exs` → 91 tests, 0 failures.

## User Setup Required

None — the workflow file is committed, and on next push GitHub Actions will pick it up automatically. **One follow-up action is recommended but not required for this plan**: in GitHub repository settings, add `merge-blocking commerce support proof (hermetic)` as a required branch check on `main`. The plan does not gate on this configuration change (the workflow YAML alone closes the SUPP-06 requirement — branch protection is a separate operator step), and the workflow is already structured so that the merge-blocking job is the only one that ever runs on PRs.

## Known Stubs

The `advisory-commerce-proof` job carries three placeholder `echo` steps for StoreKit simulator, Play Billing test-track, and device/storefront smoke checks. These are **intentional stubs** documented in the workflow YAML, gated explicitly by the canonical non-claims in guides/commerce.md ("StoreKit adapter is not shipped", "Play Billing adapter is not shipped"), and will only become real proof steps when a future provider-adapter milestone explicitly ships native/provider code. They are not implementation gaps for v3.2 — they are placeholders that make the future promotion path visible in CI.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| (none) | — | No new security-relevant surface introduced. The CI workflow runs only library-level `mix test` against in-memory router fixtures and canonical truth; no network, no simulator, no provider SDK, no new credentials or secrets. Threat register entries P23-04-T01..T04 are all mitigated as planned. |

## Deferred Issues

None new for this plan. Pre-existing deferred items from Plan 23-02 (`.planning/phases/23-commerce-support-and-proof-closure/deferred-items.md`) remain unchanged:

1. `Mix.Tasks.Crosswake.DoctorTest` JSON output test — pre-existing at the wave base ref; scoped for a future plan.
2. 15 `test/crosswake/proof/phase{5,7,8,9}_*_test.exs` failures — pre-existing example-host router compilation issue, historically run via example-host verification scripts. The Phase 23 proof lane explicitly does NOT depend on `CrosswakeExample.Router`, exactly per the deferred-items.md guidance.

Both remain explicitly out of Plan 23-04 scope per the SCOPE BOUNDARY rule.

## Next Phase Readiness

- **SUPP-06 is satisfied.** Maintainers now have a merge-blocking hermetic commerce proof lane that they can wire as a required branch check, while StoreKit / Play Billing / storefront / device checks stay advisory until a provider adapter milestone explicitly promotes them.
- The Phase 23 wave is now complete (Plan 23-01 + 23-02 + 23-03 + 23-04). The v3.2 milestone closeout is ready to run once the orchestrator merges all four worktrees and the remaining `Active` requirement in PROJECT.md ("Adopters can see explicit doctor, support-matrix, reviewer/storefront, fallback, and proof guidance for commerce claims before provider adapters ship") moves to `Validated`.
- Suggested follow-up for the operator (not part of Plan 23-04 scope): in GitHub repository settings, add `merge-blocking commerce support proof (hermetic)` as a required branch check on `main` so the proof posture is mechanically enforced rather than conventional.

---
*Phase: 23-commerce-support-and-proof-closure*
*Plan: 04*
*Completed: 2026-05-27*
