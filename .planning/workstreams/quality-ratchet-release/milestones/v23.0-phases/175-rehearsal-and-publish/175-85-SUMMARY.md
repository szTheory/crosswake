---
phase: 175-rehearsal-and-publish
plan: 85
subsystem: testing
tags: [elixir, node, release-candidate, local-fixture, process-boundary]
requires:
  - phase: 175-84
    provides: Terminal Plan84 source/collector contract and immutable UNKNOWN receipt boundary
provides:
  - Test-only Mix-to-Port-to-Node loopback integration for one fixed-route GET
  - Closed local process/HTTP diagnostics and bounded collector regression coverage
affects: [REL-13, REL-17]
actuals:
  tokens: null
  tasks: 2
  commits: 5
commits: 5
plan_head_before: 8498a60dd68b5c9a061900e74ca2c8303cb1402c
plan_head_after: 11e73a7a73f5de97936b7fef313b3704baedf32f
tech-stack:
  added: []
  patterns: [test-only loopback fixture through the existing bounded collector process]
key-files:
  created:
    - test/crosswake/release_candidate/plan85_local_twin_test.exs
    - script/release_candidate/plan85_tag_collector.test.mjs
    - lib/crosswake/release_candidate/plan84_mirror_tag.ex
    - script/release_candidate/plan84_tag_collector.mjs
    - test/crosswake/release_candidate/plan84_mirror_tag_test.exs
    - script/release_candidate/plan84_tag_collector.test.mjs
  modified:
    - lib/crosswake/release_candidate/ios_mirror_tag_repair.ex
    - lib/mix/tasks/crosswake.release.mirror_tag_026.ex
    - script/release_candidate/ios_tag_source_collector.mjs
key-decisions:
  - "The production API origin remains fixed; only the test-only collector branch accepts a canonical loopback origin."
  - "Redirects in the local branch are observed with manual redirect handling and rejected without following them, so the local result can distinguish redirect from transport failure."
  - "Resolve the Node executable by path and use it directly so runtime discovery is inside the existing bounded child boundary, including when PATH resolves to an asdf shim."
patterns-established:
  - "Local fixture requests are counted only when observed; interrupted transport stays unknown."
  - "Process-boundary diagnostics expose a closed class and bounded counters, never child bytes or fixture bodies."
requirements-completed: []
coverage:
  - id: D1
    description: "Real test-only Mix/Elixir coordinator reaches the real bounded Node collector and one unauthenticated fixed-route loopback GET."
    requirement: REL-13
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan85_local_twin_test.exs --max-cases 1 (21 passed, 0 skipped)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Local process faults, HTTP response failures, count uncertainty, limits and pagination produce bounded diagnostics without release side effects."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "node --check script/release_candidate/plan84_tag_collector.mjs && node --check script/release_candidate/ios_tag_source_collector.mjs && node --test script/release_candidate/plan85_tag_collector.test.mjs (21 passed, 0 skipped)"
        status: pass
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan85_local_twin_test.exs --max-cases 1 (21 passed, 0 skipped)"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs --max-cases 1 (46 passed, 0 skipped)"
        status: pass
      - kind: other
        ref: "mix format --check-formatted <four named Elixir files>"
        status: pass
    human_judgment: false
  - id: D3
    description: "Plan84 history remains unchanged and release posture remains held."
    verification:
      - kind: other
        ref: "SHA-256 fingerprints captured before Plan85 execution match the five protected artifacts listed below."
        status: pass
    human_judgment: false
metrics:
  duration: 149min
  completed: 2026-10-06
  status: complete
---

# Phase 175 Plan 85: Local Collector Process Twin Summary

**The local-only test path now proves one fixed-route request through the real Elixir coordinator, bounded Port runner, Node collector and loopback fixture, with closed failure diagnostics and no release action.**

## Performance

- **Elapsed span:** approximately 149 minutes from 2026-10-06T17:31:24Z through 2026-10-06T20:00:26Z; this includes executor, integration checks and idle time, and is not an active-work measure.
- **Started:** 2026-10-06T17:31:24Z
- **Completed:** 2026-10-06T20:00:26Z
- **Tasks:** 2
- **Source/test paths:** 10 committed paths; four additional files contain local ratchet reconciliation alongside prior edits. Eight planning/state artifacts were updated locally.

## Accomplishments

- Added a test-only local twin that uses the real coordinator and child process to perform one unauthenticated GET against an ephemeral `127.0.0.1` fixture. The fixture observed exactly one request; the result reported zero dry-run, decision, tag and CI attempts.
- Added distinct closed diagnostics for child launch failure, timeout, nonzero exit, malformed/incomplete/oversized output and invalid envelope; local HTTP tests distinguish transport uncertainty, observed status, redirect, schema and limit failures.
- Exact child result keys, types and completeness are now enforced; local fault cases prove that extra success/failure keys and incomplete or mistyped data become `CHILD_ENVELOPE_INVALID`.
- Exact 16,384/16,385 body and input limits, 8,192/8,193 projected and child output limits, four ordered pages, 100/101 records per page, empty/invalid/route-changing links and the 8,000 ms HTTP deadline have boundary tests.
- Verified production mode rejects the local Mix entry, fixture environment cannot redirect the production API helper, listeners refuse reconnection after cleanup, and a timed-out process group cannot write a delayed descendant marker. Temporary `git`, `gh` and `curl` sentinels stayed untouched; Plan84 receipt and lifecycle digests stayed unchanged.
- Removed unbounded `System.cmd` runtime discovery. The PATH-resolved Node executable is passed directly into the bounded child chain; the real local integration passes with the installed Node path on this asdf-configured host.
- Added fixed route/origin, page ordering and cap, uniqueness, body/output cap, privacy and no-side-effect regressions. The production API remains pinned to GitHub.
- Tracked the Plan84 coordinator, collector and their regression tests as required source dependencies for the existing release-candidate fixture suite. The existing workflow already discovers the complete `test/crosswake/release_candidate` directory; no CI workflow change or dispatch was made.
- Compared the Plan84 plan, summary, receipt, lifecycle and requirements digests to the supplied baseline; all five remained unchanged.

## TDD Gate Compliance

- **Task 1 RED:** the machine-validated temporary gate `task1-red.json` recorded failure to reach the intended local collector integration test before implementation. The named target was “Plan85 Mix path reaches the local collector integration test.”
- **Task 1 GREEN:** the tracer completed the real Mix → coordinator → bounded Port → Node child → loopback path. The final ExUnit suite reported 21 tests passing with no skips.
- **Task 2 RED:** `task2-red.json` recorded the missing observed HTTP-status distinction; `task2-process-red.json` recorded missing process-fault diagnostics. Both were accepted by `gsd_run check tdd-red-evidence` before implementation.
- **Follow-up RED:** exact-result schema tests produced four targeted failures before strict validation. The exact 8,192-byte child-output regression and delayed-descendant cleanup regression also failed before their fault paths were wired; all failures were on their intended assertions.
- **Task 2 GREEN and follow-up:** ExUnit passed 21 tests and Node TAP passed 21 tests, both with zero failures and zero skips; Plan84 regressions passed 46 tests. The original temporary RED records remain under `.tmp/plan85/` and are excluded from commits and this summary.

## Task Commits

1. **Task 1 and Task 2 regression coverage** — `cd4573e4` (`test(175-85): add local twin regression coverage`).
2. **Task 1 and Task 2 implementation plus required Plan84 source dependencies** — `e2d2e993` (`feat(175-85): add local collector process twin`).
3. **Follow-up boundary and cleanup regressions** — `072b7257` (`test(175-85): cover boundary and cleanup contracts`).
4. **Follow-up result validation and bounded Node resolution** — `c9d26188` (`fix(175-85): validate local twin boundaries`).
5. **Post-wave nonempty assertion guards** — `11e73a7a` (`fix(175-85): guard collection assertions from empty fixtures`).

The plan-scoped commit count was measured as 5 from `8498a60dd68b5c9a061900e74ca2c8303cb1402c` through `11e73a7a73f5de97936b7fef313b3704baedf32f`. Runtime token usage was not measured; `actuals.tokens` is null. Phase documentation commits are disabled; this summary and validation addendum remain local workspace artifacts.

## Files Created/Modified

- `test/crosswake/release_candidate/plan85_local_twin_test.exs` — real loopback integration and process-fault assertions.
- `script/release_candidate/plan85_tag_collector.test.mjs` — focused HTTP, pagination, redirect, limit and privacy regression suite.
- `lib/crosswake/release_candidate/plan84_mirror_tag.ex` and `script/release_candidate/plan84_tag_collector.mjs` — Plan84 source dependencies, extended with the isolated local diagnostic path.
- `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex` — strict local operation/argument/environment allowlist and safe diagnostic mapping.
- `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` — test-only Mix mode.
- `script/release_candidate/ios_tag_source_collector.mjs` — additional outer-launcher allowlist and malformed-envelope test branch.
- `test/crosswake/release_candidate/plan84_mirror_tag_test.exs` and `script/release_candidate/plan84_tag_collector.test.mjs` — Plan84 regressions tracked alongside the source they exercise.
- `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` — nonempty guards required by the collection ratchet.
- `175-VALIDATION.md` and workstream handoff/state artifacts — local Plan85 execution results, deviation record and held release posture.

## Decisions Made

- Only the test-only local collector mode accepts a fixture origin, and it accepts only canonical loopback HTTP with a fixed route. The production collector keeps its fixed API origin.
- Local redirect handling uses `redirect: "manual"` solely so the fixture status can map to `HTTP_REDIRECT_REJECTED` without following a redirect. Production collection retains its existing redirect-error setting.
- Node runtime resolution now uses the executable path returned by PATH lookup directly, within the existing bounded child process chain.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Add the outer launcher validation omitted from the declared file list**
- **Found during:** Task 2 source audit.
- **Issue:** The plan requested a test-only operation through the existing child launcher, but `ios_tag_source_collector.mjs` did not allow that operation or constrain its fixture descriptor/fault arguments.
- **Fix:** Added an exact test-only request/environment allowlist and a closed malformed-envelope injection path.
- **Files modified:** `script/release_candidate/ios_tag_source_collector.mjs`.
- **Verification:** Plan85 process-fault ExUnit and Node TAP suites passed.
- **Committed in:** `e2d2e993`.

**2. [Rule 1 - Bug] Preserve an observable redirect class in the local fixture branch**
- **Found during:** Task 2 redirect regression.
- **Issue:** Native Node `fetch` with `redirect: "error"` surfaced only a generic TypeError, so the local path could not distinguish a redirect from another transport error without reading exception text.
- **Fix:** The local-only branch uses manual redirect handling, observes the 3xx response and rejects it without following it. The production collector remains unchanged.
- **Files modified:** `script/release_candidate/plan84_tag_collector.mjs`.
- **Verification:** Local 302 fixture test asserted one observed request and `HTTP_REDIRECT_REJECTED`; Node suite passed 13 tests.
- **Committed in:** `e2d2e993`.

**Total deviations:** five auto-fixed, including the post-wave collection-ratchet reconciliation below; all preserve fail-closed local diagnostics and add no release authority.

**3. [Rule 1 - Bug] Enforce complete child result schemas and bound Node resolution**
- **Found during:** Follow-up acceptance review.
- **Issue:** The coordinator accepted extra keys and incomplete success metadata; Node runtime discovery executed before the bounded Port watchdog.
- **Fix:** Require exact allowlisted result keys and typed, complete PR data. Pass the PATH-resolved Node executable directly into the existing bounded process chain.
- **Files modified:** `lib/crosswake/release_candidate/plan84_mirror_tag.ex`.
- **Verification:** Four targeted ExUnit assertions failed before the schema fix; the final focused suite passed 21 tests.
- **Committed in:** `c9d26188`.

**4. [Rule 2 - Missing critical verification] Prove caps and cleanup at their boundaries**
- **Found during:** Follow-up acceptance review.
- **Issue:** Earlier passing checks did not prove exact limits, listener closure, descendant termination or structural absence of release commands.
- **Fix:** Added exact boundary tests, finite local fault fixtures, reconnect refusal, delayed-descendant marker checks, evidence digest comparison and temporary command sentinels.
- **Files modified:** `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex`, `script/release_candidate/ios_tag_source_collector.mjs`, `test/crosswake/release_candidate/plan85_local_twin_test.exs`, `script/release_candidate/plan85_tag_collector.test.mjs`.
- **Verification:** Final Plan85 ExUnit 21, Node TAP 21 and Plan84 regression 46 passed with no skips; syntax and format checks passed.
- **Committed in:** `072b7257`, `c9d26188`.

## Validation Results

- `MIX_ENV=test mix test test/crosswake/release_candidate/plan85_local_twin_test.exs --max-cases 1` — 21 passed, 0 failures, 0 skipped.
- `node --check script/release_candidate/plan84_tag_collector.mjs && node --check script/release_candidate/ios_tag_source_collector.mjs && node --test script/release_candidate/plan85_tag_collector.test.mjs` — syntax passed; 21 passed, 0 failures, 0 skipped.
- `MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs --max-cases 1` — 46 passed, 0 failures, 0 skipped.
- `mix format --check-formatted lib/crosswake/release_candidate/plan84_mirror_tag.ex lib/crosswake/release_candidate/ios_mirror_tag_repair.ex lib/mix/tasks/crosswake.release.mirror_tag_026.ex test/crosswake/release_candidate/plan85_local_twin_test.exs` — passed.
- `gsd_run check evaluation-scope --plan "175-85" --commits-only --raw` — resolved all five commits on the current branch, with no missing or unreachable commits.

## Post-wave integration reconciliation

The first full Mix gate exposed stale collection-ledger expectations: 20 additional assertions
were present in the working tree, including two new Plan85 header checks; 17 needed explicit
nonempty guards. Added guards without weakening the assertions, regenerated the ledger from the
live AST scanner and updated its measured expectations. The exact scanner reports 250 classified
sites: 135 safe by construction, 77 guarded, 34 cardinality pinned and four compile-time literals;
zero need fixes. The corrected release fixture/ratchet bundle passed **388 tests, zero failures**.

The two independently clean test files were committed as `11e73a7a`. The additional guard and
ledger reconciliation in `ios_tag_source_evidence_test.exs`, `ios_tag_source_runner_test.exs`,
`phase170_vacuous_assertion_ledger_test.exs` and `script/collection_assertion_ledger.json` remains
uncommitted alongside their substantial pre-existing edits. Those files were not staged wholesale.
These test results describe the current working tree, not a clean-checkout CI result. Phase175
documentation commits are disabled; current state, roadmap, continuation and validation updates
remain local. No workflow dispatch or release-provider observation was made. An unrelated host-fixture setup in the project-wide Mix gate attempted public Hex dependency resolution; its cache write failed in the sandbox. The four invalidated tests subsequently passed using a task-local public registry/package cache with `HEX_OFFLINE=1` and no copied configuration. No product or fixture source change was needed for that environment failure.

### Final check results

- Fresh Node syntax and Plan85 TAP: 21 passed, zero failures/skips.
- First terminal full Mix run: 2,275 tests, zero assertion failures, four invalid (74 excluded), exit 2. All four invalidations shared `DoctorRouterTest` setup’s failed Hex cache write.
- Offline rerun of that setup module with the same seed: four tests, zero failures, exit 0.
- Complete offline rerun at seed 549400: **2,275 tests, zero failures or invalid tests, 74 expected exclusions**, exit 0. ExUnit runtime 473.2 seconds.
- Build and named formatting passed; collection ledger matches all 250 sites with zero needing fixes; schema and UI gates are clear. Codebase drift skipped advisory-only because STRUCTURE.md is absent.
- Final index: Plan85 has a complete summary; Plans46–48 remain incomplete, blocked, and none runnable. Phase verification/completion was not run for this partial wave.

### Protected Plan84 and requirements fingerprints

| Artifact | SHA-256 before and after Plan85 |
|---|---|
| `phases/175-rehearsal-and-publish/175-84-SUMMARY.md` | `791e821c249539ff1afe7064246469b0acd5822f54b8a9cf93a41a80b6a1fea5` |
| `phases/175-rehearsal-and-publish/175-84-PLAN.md` | `6bccb247d2523ef846958117f791d0ddb7a563cd5f23f59cd75bf293a8c747e8` |
| `phases/175-rehearsal-and-publish/evidence/175-plan84-mirror-tag-026.json` | `44e6980b3c84ccf8bef95129a8ac95e29e0400410569965e90c6642eb8149471` |
| `phases/175-rehearsal-and-publish/evidence/175-plan84-mirror-tag-026.lifecycle.jsonl` | `6a256c8cac0662bd134a67f243b7dac2c444930010d42bae81d56c0ddee7a04d` |
| `REQUIREMENTS.md` | `1224539255275de92809b2f6860de144ca5bd1737a33406df37934722274fb70` |

## Unchanged Release Posture

This proves only current local process and collector behavior. It does not explain Plan84's historical `UNKNOWN/OBSERVATION_UNAVAILABLE` result or convert its unknown historical provider request count to zero. REL-13/14/15/17 remain OPEN; candidate readiness remains BLOCKED; merge policy remains UNKNOWN; release hold remains ACTIVE; Plans45–48 remain HELD; Phase175 remains INCOMPLETE. Plan85 made no provider, credential, preflight, dry-run, decision, tag, CI dispatch, Gate2, merge, registry or publication action.

## Self-Check: PASSED

- Plan85 implementation and test files exist at the listed paths.
- `cd4573e4`, `e2d2e993`, `072b7257` `c9d26188` and `11e73a7a` are present on the current branch; plan-level evaluation scope resolves all five commits.
- All Plan85 acceptance gates and the final full offline Mix gate passed after the commits.
- Plan84 immutable artifact digests still match the supplied baseline.

## Current GSD handoff

Last completed phase: 174. Phase175 remains ACTIVE / INCOMPLETE; Plan85 local Wave 1 is complete. No next GSD command is eligible. Fresh, independently verifiable current candidate facts, or new evidence supporting a materially distinct bounded observation path, must support a separately scoped plan and its required authorization before work reopens. Keep all release holds; do not repeat Plan85 or consumed attempts.
