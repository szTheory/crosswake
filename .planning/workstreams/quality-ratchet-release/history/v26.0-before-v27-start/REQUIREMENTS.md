# Requirements: v26.0 Harden Before Trust

**Defined:** 2026-10-15
**Workstream:** quality-ratchet-release
**Core value:** one real Phoenix application on one physical iPhone, with explicit route ownership and one honest offline mutation island.

**Scope.** On 2026-10-15 the user picked "Harden before trust" and seeds SEED-018 (v25 code only), SEED-023 and SEED-014. They also asked for research first, and for the synthesized recommendations to be followed without further questions. The bounded design comes from three files:
- the [research synthesis](../../research/v26/SUMMARY.md), which includes the resolved decisions;
- the [adversarial challenge](../../research/v26/CHALLENGE.md);
- the [finding inventory](../../research/v26/FEATURES.md).

**Inclusion rule.** An item is in scope if it can report healthy while something is missing, unreadable or unchecked, or if it leaks private data. Items that only fail closed, or that are cosmetic, are deferred with a reopen trigger.

**Where the work happens.** All product work happens in the `/private/tmp/crosswake-phase180-impl` candidate, starting from `50fcd57`. The v25 requirements are archived in [milestones/v25.0-REQUIREMENTS.md](milestones/v25.0-REQUIREMENTS.md).

## v26.0 Requirements

### PROBE: twin source binding cannot be fooled

- [x] **PROBE-01:** The twin's clean-tree check blocks with `source_dirty` whenever a tracked file differs from HEAD in content or mode. This holds even when the difference is hidden by any of these: assume-unchanged, skip-worktree, `core.ignoreStat`, `core.checkStat=minimal`, `core.trustctime=false`, or `core.filemode=false` set in the repo or in global config.
  - Method: compare the worktree against a fresh index built from HEAD outside the repo. Separately, count any `git ls-files -v` tag other than `H` as dirty. An unknown tag, or zero tracked entries, fails closed.
- [x] **PROBE-02:** Every git call made by the twin uses one shared configuration:
  - `core.filemode=true`, no global or system config, global excludes disabled, fsmonitor off;
  - caller `GIT_*` repository variables scrubbed;
  - `freeze`, `checked_identities` and `observe_identities` all use it (183 IN-01).
  
  A git failure, including an argv that git rejects, yields an `unavailable` cause whose message contains no path (183 IN-04).
- [x] **PROBE-03:** Tests build real temporary git repos with one fixture for each hiding mechanism in PROBE-01, plus untracked and exclude-rule cases. Each fixture asserts a `source_dirty` block, and an untouched control passes.
  - A recorded mutation control shows that each guard is load-bearing.
  - The blocking message reports the flagged and modified counts separately, and accurately (183 WR-03, WR-04).
- [x] **PROBE-04:** A maintainer can run a read-only twin preflight. It reports whether a run would be allowed, but it never writes `receipt.json`, never creates or consumes a run root, and never leaves behind a refused root (183 IN-03).

### GUARD: checks cannot pass by examining nothing

- [x] **GUARD-01:** `script/check_absence_is_not_success.exs` exits non-zero when its root does not exist, when a derived scope is empty, or when a derived scope falls below its pinned expected count. This uses an Elixir copy of `assertFullScope`, the SEED-023 semantics, with no shared module and no new dependency.
  - OK lines print the counts that were scanned.
  - Red and green self-tests cover each case.
- [x] **GUARD-02:** Loops in v25 tests that are not covered by the ledger assert a non-empty collection before iterating (`twin_receipt_test.exs:289`). A report-mode measurement table records each v25 loop site and what was done with it.
  - No new repo-wide blocking rule lands unless that measurement shows zero findings (SEED-018 is limited to v25 code).
- [x] **GUARD-03:** `TwinRuntime.stop_children/1` reports an error rather than `:ok` when the registry it should stop is already gone. `lock_digests/1` fails closed unless both expected lockfiles are digested.

### SEAM: the host-command seam fails closed

- [x] **SEAM-07:** When a manifest route has no `host_commands` key (the legacy path), the native session no longer grants every registered `host.*` command (181 M-02).
  - It denies each command with the existing `not_registered` or `version_unsupported` reason.
  - Doctor reports the legacy manifest with a repair hint, and the guide explains it.
  - A legacy-shaped fixture proves the denial.
  - Manifest schema 1.2.0 and the public API stay unchanged.
- [x] **SEAM-08:** Doctor's `host_commands_stale` check reports an error instead of passing in each of these cases (181 M-03):
  - the generated fixture is unreadable or malformed;
  - a router route that declares host commands is missing from the manifest.
  
  An absent fixture is still reported as skipped.
- [x] **SEAM-09:** Doctor findings, gate messages and raised errors about package paths contain only paths relative to the project root, never an absolute home path or local username (181 M-04).
  - One copied redaction helper handles this.
  - A sentinel-directory test covers doctor output, exception text and evidence files.
  - The guide's version wording matches the code's floor semantics (181 M-01).

### LOOP: the loopback harness tells the truth

- [x] **LOOP-06:** The loopback Simulator harness (`script/verify_loopback_origin_simulator.sh`) fails in each of these cases:
  - its hash check does not cover the file it swaps (182 WR-03);
  - writing evidence fails (182 WR-04);
  - uninstall or restoring the device fails (182 WR-05).
  
  Each failure path is proved with broken-state shims rather than a live Simulator. The harness is documented as manually run phase evidence, not a required CI lane.
- [x] **LOOP-07:** A regression test proves that physical-iPhone proof preparation cannot reach a host generated in local loopback mode. Preflight code is added only if that test shows the generator refusal does not already cover it.

### DOCTOR: doctor and proof evidence are actionable (SEED-014)

- [x] **DOCTOR-01:** `mix crosswake.doctor --format json` includes the unmanaged route paths and router as structured `details` on the `unmanaged_routes` finding (CW-REQ-E).
- [x] **DOCTOR-02:** Doctor flags every `:offline_island` route declared `offline: :local_first` without an `island_contract`, rather than filtering it out before the check (CW-REQ-F).
  - When no routes claim offline behavior, doctor reports "not claimed" rather than vacuously coherent.
  - The compile-time rule is deferred with a reopen trigger.
- [x] **DOCTOR-03:** The `verify_navigation_shell` provenance header carries the real crosswake version, generated template version, `git rev-parse HEAD` and device class. Any value that is not known is an explicit sentinel, never an all-zero hash (CW-REQ-C), and the evidence validator rejects an all-zero commit reference.
- [x] **DOCTOR-04:** The CW-REQ-A (haptics assertion) and CW-REQ-D (denial view) deferrals are recorded with their evidence and reopen triggers. CW-REQ-A records both readings of its pipeline trigger, so the question is not argued again.

### TWIN: one clean run against the hardened code

- [x] **TWIN-07:** After all code changes are frozen in one candidate commit:
  - a scripted refresh updates the seam and loopback handoff records;
  - the read-only preflight (PROBE-04) and a scripted go/no-go both pass. Go/no-go requires the frozen HEAD, a clean probe, matching digests, and a 0700 `twin-05` root with no receipt.
  
  Then run root `twin-05` is run exactly once.
- [x] **TWIN-08:** twin-05 exits 0, with all ten groups and all seven identity joins passing. Its result is byte-copied into planning, and it lists the disclosed fidelity limits:
  - edit-and-revert during a run is not detected;
  - ignored files are not counted;
  - the Phase 179 identity join is deferred.
  
  If twin-05 fails, it records a privacy-safe cause and there is no retry to green. A further run would be a new decision.

## Acceptance Boundaries

- No commit after the freeze commit may change twin-attested source. twin-01 through twin-04 and their records stay byte-unchanged.
- Every fix ships with a negative control that fails when the fix is reverted. A citation by test name that runs 0 tests fails.
- No new dependencies. No changes to manifest schema 1.2.0 or the receipt schema version.
- Recovery checkout: no staging, commits, tags, branches or worktrees. Never push, merge, release or open a PR. Moving the candidate commits into the main tree needs separate authorization.

## Future Requirements (deferred)

| Item | Reopen trigger |
|---|---|
| CW-REQ-A haptics assertion (vocabulary 2→3) | Any one of: (a) a planned release that deliberately breaks the proof-lane contract with its pipeline already proven by an earlier ordinary publish; (b) the first adopter asks to retire its own haptics gate; (c) the physical-iPhone run resumes under first-b2c-adopter-readiness (see 187-DEFERRALS.md) |
| CW-REQ-D `RouteUnavailableView` debug line and visual defaults | (a) A diff that touches shell-core Swift or generated template sources and already changes the template version; (b) the first adopter adopts the shipped view (see 187-DEFERRALS.md) |
| Compile-time `:local_first` without `island_contract` rule | (a) A second `:local_first` runtime or route family besides `:offline_island`; (b) a host route ships `:local_first` without `island_contract` although doctor ran; (c) the first adopter's physical-iPhone proof shows doctor is not run before a build (see 187-DEFERRALS.md) |
| Repo-wide non-empty-collection rule (VACG-01); lifting and deleting the ledger | A report-mode measurement shows zero findings |
| Phase 179 identity join in the twin | A twin run that must bind a non-reference bundle id |
| 181 L-01, L-02, L-04, L-05, L-06; 182 WR-01, WR-06, GEN-W02, GEN-W06; route-id mismatch | Next change in that file, or a consumer reading `island.route_id` |
| MIX_ENV drift friction; `local_ios_package` cwd; remote package with no seam release | Adopter onboarding outside the monorepo |
| Nyquist validation for 180–183 | Milestone closeout |

## Out of Scope

| Item | Reason |
|---|---|
| Android | Frozen |
| New companions, native controls, generic sync or storage, dashboards, brand polish | ADR stop list |
| Physical signed-iPhone run; first adopter route handoff | External gates, unchanged |
| A shared `assertFullScope` module | Only one second caller; copy is better than a shared abstraction |
| `doctor --strict` | The adopter rejected it; the host owns that policy |
| Inferring why case 3 stalled in twin-02 | No cause was retained |
| `WKAppBoundDomains` example.com | Pinned placeholder; fails closed |

## Traceability

| Requirement | Phase | Status |
|---|---|---|
| PROBE-01 | Phase 184 | Complete (candidate b898e110) |
| PROBE-02 | Phase 184 | Complete (candidate b898e110) |
| PROBE-03 | Phase 184 | Complete (candidate b898e110) |
| PROBE-04 | Phase 184 | Complete (candidate b898e110) |
| GUARD-01 | Phase 185 | Complete |
| GUARD-02 | Phase 185 | Complete |
| GUARD-03 | Phase 185 | Complete |
| SEAM-07 | Phase 186 | Complete |
| SEAM-08 | Phase 186 | Complete |
| SEAM-09 | Phase 186 | Complete |
| LOOP-06 | Phase 186 | Complete |
| LOOP-07 | Phase 186 | Complete |
| DOCTOR-01 | Phase 187 | Complete |
| DOCTOR-02 | Phase 187 | Complete |
| DOCTOR-03 | Phase 187 | Complete |
| DOCTOR-04 | Phase 187 | Complete |
| TWIN-07 | Phase 188 | Complete (twin-05 exit 0, passed; 188-TWIN-RESULT.json) |
| TWIN-08 | Phase 188 | Complete (twin-05 exit 0, passed; 188-TWIN-RESULT.json) |

**Coverage:** 18/18 v26 requirements mapped to phases 184–188; no orphans, no duplicates.

---
*Requirements defined: 2026-10-15*
