---
phase: "171"
plan: "171-04"
subsystem: infra
tags: [github-actions, release-please, shell, ci-scanner, version-authority, weld-06]
status: complete

requires:
  - phase: 171-version-authority-split
    plan: "171-01"
    provides: "approved-release-guard.outputs.approved_version, derived once from the release manifest at the approved head"
  - phase: 171-version-authority-split
    plan: "171-03"
    provides: "the CLI-entrypoint and Coordinate D-171-C precedent for format-check-over-literal generalization"
provides:
  - "guarded_hex_publish.sh's verify_approved_identity() requires a caller-supplied --expected-version for the crosswake package, fail-closed on unset/empty/mismatch, instead of a hardcoded 0.2.1 gate"
  - "android_publication.sh and ios_mirror.sh's candidate-mode version conjuncts generalized to anchored semver format checks; PUBLIC_POM and the gradle grep interpolate $VERSION"
  - "hex-publish.yml: stale recovery default removed, a new approved_version dispatch input cross-checked exactly against release_version before any phase168-pinned identity check runs"
  - "ios-mirror-backfill.yml's attest-candidate-receipt negative controls (D-171-D) parameterized to the dispatch-supplied candidate version - the path is satisfiable again for a fresh candidate"
  - "the scanner's two remaining self-referential assertions (recovery.ios.exact_identity_gate, release.partial.phase168_recovery_routes) updated in lockstep with the shell/YAML text they assert over"
affects: ["171-05", "175-rehearsal-and-publish"]

actuals:
  tokens: 5522
  tasks: 3
  commits: 4
  plan_head_before: d2978183a19e5423c1760cb7026e725c63e71d33

tech-stack:
  added: []
  patterns:
    - "Format-check-over-literal, applied uniformly to shell version conjuncts: replace `[ \"$VERSION\" = \"X.Y.Z\" ]` with an anchored `printf '%s' \"$VERSION\" | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+$'`, leaving all non-version identity pins (merge OID, tree, receipt SHAs) untouched where a job is genuinely single-incident."
    - "Fail-closed externally-supplied expected version: guarded_hex_publish.sh and hex-publish.yml's two recovery jobs now require an operator/caller-supplied approved-version value and abort if it is empty or mismatched, rather than silently skipping identity verification when a version-based gate condition isn't met."
    - "Scanner self-assertion lockstep (carried from 171-01): any check asserting the pre-fix literal shape of a file must be updated in the same wave the fix lands, with an explanatory in-source comment recording which fix motivated the change."

key-files:
  created: []
  modified:
    - script/guarded_hex_publish.sh
    - script/release_candidate/android_publication.sh
    - script/release_candidate/ios_mirror.sh
    - script/verify_ios_mirror_backfill.sh
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - .github/workflows/ios-mirror-backfill.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/release_candidate/workflow_test.exs

key-decisions:
  - "guarded_hex_publish.sh's verify_approved_identity() generalized to apply to the crosswake package at ANY version (dropping the `$VERSION != 0.2.1` half of the refusal entirely) rather than gating on a still-literal comparison, because its supporting identity checks (APPROVED_HEAD/APPROVED_TREE/MERGE_OID/CANDIDATE_RECEIPT) are already caller-supplied and version-independent - unlike android_publication.sh and hex-publish.yml's recovery jobs, which hardcode PHASE168_* SHA constants inline and are therefore genuinely single-incident."
  - "Because this fail-closed change would otherwise break release-please.yml's existing automatic crosswake publish-hex call (release-please.yml is outside this plan's files_modified list), one line was added there under Rule 1 (auto-fix a bug directly caused by this task's own change) to pass --expected-version from approved-release-guard's existing approved_version output. Documented here rather than silently diverging or leaving the automatic publish path broken."
  - "hex-publish.yml's two workflow-level 0.2.1 comparisons (gating the phase168-pinned identity blocks in the publish/recover-android-core jobs) are replaced with a new approved_version dispatch input, cross-checked via exact string equality against release_version, fail-closed if empty - rather than reintroducing a new hardcoded version constant (which would still fail the file's own zero-literal <verify> grep) or deleting the gate outright."
  - "ios-mirror-backfill.yml's publish-ios-mirror/recover-ios-mirror RELEASE_VERSION pins generalized to the same anchored-format-check pattern used in the shell scripts, rather than pinning them to a new PHASE168_RELEASE_VERSION constant (which would also fail the file's zero-literal grep). Every other identity field in those two jobs stays pinned to the phase168 event on purpose."
  - "Two scanner self-assertions and one pre-existing ExUnit test received Disposition 1 (generalize in lockstep) because Tasks 1-2 changed their subject text; one scanner occurrence (recovery_exact_ref_only's forbidden_samples list of illustrative rejected v0.2.0 branch-name examples) received Disposition 2 (pinned historical fixture) - it mirrors hex-publish.yml's own untouched case-pattern reject list and is not a live version-comparison gate."

requirements-completed: [WELD-06]

coverage:
  - id: D1
    description: "The Hex publish wrapper, the Android publication script, and the iOS mirror candidate mode accept the version they are told to publish rather than refusing anything but one hardcoded value"
    requirement: "WELD-06"
    verification:
      - kind: unit
        ref: "mix test test/crosswake/release_candidate/workflow_test.exs"
        status: pass
      - kind: manual
        ref: "grep -v '^\\s*#' script/guarded_hex_publish.sh | grep -cE '\"[0-9]+\\.[0-9]+\\.[0-9]+\"' returns 0; android_publication.sh and ios_mirror.sh's candidate-mode conjuncts are anchored format checks"
        status: pass
    human_judgment: false
  - id: D2
    description: "hex-publish.yml's recovery-dispatch path can authorize a recovery publish at any semver; its stale workflow_dispatch default no longer invites an operator to accept a wrong version unknowingly"
    requirement: "WELD-06"
    verification:
      - kind: manual
        ref: "release_version input has no default and is required:true; both recovery-path comparisons use exact string equality against a new approved_version input, fail-closed on empty"
        status: pass
    human_judgment: false
  - id: D3
    description: "ios-mirror-backfill.yml's attest-candidate-receipt negative controls assert the absence of the CANDIDATE version, making the attestation path satisfiable again"
    requirement: "WELD-06"
    verification:
      - kind: manual
        ref: "all six negative-control lines interpolate CANDIDATE_VERSION; polarity/strength/continue-on-error count unchanged"
        status: pass
    human_judgment: true
  - id: D4
    description: "Every remaining self-referential assertion inside the scanner is either updated in lockstep or explicitly recorded as an intentionally historical fixture, and each still asserts something falsifiable"
    requirement: "WELD-06"
    verification:
      - kind: unit
        ref: "elixir script/check_release_workflow_integrity.exs"
        status: pass
    human_judgment: false

duration: 70min
completed: 2026-09-17
---

# Phase 171 Plan 04: Recovery/Dispatch Surface + Scanner Self-Assertions Summary

**Generalized the last live version gates outside the main-line publish graph — three shell scripts, two dispatch-only workflows, and the scanner's own remaining self-assertions — closing WELD-06 across the recovery surface and restoring the previously-unsatisfiable iOS candidate-receipt attestation path (D-171-D).**

## Performance

- **Duration:** ~70 min
- **Tasks:** 3 (4 commits — Task 3 required one direct follow-up test fix)
- **Files modified:** 9

## Accomplishments

**Task 1 — shell scripts follow the given version:**
- `guarded_hex_publish.sh`: `verify_approved_identity()` no longer gates on `$VERSION != "0.2.1"`. It now applies to the `crosswake` package at any version, requires a caller-supplied `--expected-version`, aborts (fail closed) if that value is unset/empty, and aborts if it doesn't match the requested `$VERSION`. The package-name refusal (`!= "crosswake"`) is untouched and stays exact.
- `android_publication.sh`: version refusal is now an anchored semver format check; `PUBLIC_POM`, the `build.gradle.kts` grep, and all three OK/FAIL echo lines interpolate `$VERSION`. The `PHASE168_*` merge/tree/receipt SHA pins are untouched — they are historical identity, not version literals, and this whole script remains genuinely single-incident regardless of the version-check generalization.
- `ios_mirror.sh`: only the `candidate|publish|recovery` mode version conjunct generalized to a format check; the `baseline` mode's `0.2.0` conjunct (the permanent pre-candidate reference point) is untouched, per Pitfall 2.
- `verify_ios_mirror_backfill.sh`: exhaustive read confirms **no live version comparison exists in this file** — it `exec`s into `ios_mirror.sh`, passing `$VERSION` through unmodified. Only its usage/doc comments named `0.2.1`; updated to version-neutral placeholders. This is a positive statement, not an omission.
- `check_release_version_truth.exs`: logic already version-generic, left untouched; confirmed via `git diff` that only the historical PR-158 comment line changed (it didn't change at all in this plan).

**Task 2 — dispatch-driven workflows + D-171-D:**
- `hex-publish.yml`: `release_version`'s stale `default: '0.2.1'` removed and the input made `required: true`. A new `approved_version` input added; both recovery-path version comparisons (the `publish` job's "Validate recovery ref" step and `recover-android-core`'s validation step) now require `approved_version` non-empty (fail closed) and compare it via exact string equality (`[ "$A" = "$B" ]`) against the supplied `release_version`, instead of gating on the bare literal `"0.2.1"`. The `Guarded Hex recovery publish` step now passes `--expected-version` through to `guarded_hex_publish.sh`. Three input descriptions reworded to name no specific version.
- `ios-mirror-backfill.yml` (D-171-D): `attest-candidate-receipt` gained a format-validated `CANDIDATE_VERSION`; all six negative-control literals (git tag absence, Hex 404, Maven POM 404 across both path segments, iOS mirror tag absence) now interpolate it instead of `0.2.1`. Polarity, strength, and the `continue-on-error` count (0, unchanged) are all preserved — none became a warning or `|| true`. The `rehearse-ios-mirror-candidate` job's top-of-file version gate and its literal `--version 0.2.1` CLI argument were also generalized to the dispatch-supplied, format-checked version. `publish-ios-mirror`/`recover-ios-mirror`'s two `RELEASE_VERSION` pins generalized to the same anchored-format-check pattern used in the shell scripts — every other identity field in those two jobs (merge OID, approved head/tree/base, candidate receipt, mirror split) stays pinned to the phase168 event on purpose.
- `crosswake-ci.yml`: its step-summary example already used the `<semver>` placeholder introduced by 171-03's Mix task `@moduledoc` — confirmed identical, no change needed, so the two cannot drift apart.

**Answering the plan's D-171-D flag directly: the attest-candidate-receipt path is now satisfiable for a fresh candidate.** With `CANDIDATE_VERSION` bound to a genuinely-unpublished future version, all six negative controls will correctly evaluate to "absent" (assuming that version really is unpublished), unblocking Phase 175's rehearsal-and-publish dependency named in the RESEARCH.md Orchestrator Addendum.

**Task 3 — scanner self-assertions, with recorded dispositions:**

| Occurrence | Enclosing function | Disposition | Justification |
|---|---|---|---|
| `~s([ "$RELEASE_VERSION" = "0.2.1" ])` (ios-mirror-backfill.yml recover-ios-mirror) | `phase168_ios_recovery_exact_identity/1` (check `recovery.ios.exact_identity_gate`) | **generalized** | Task 2b's own text required generalizing this exact comparison in the workflow; pinning the scanner to the retired literal would make it permanently fail against a correctly-fixed tree. Needle now tracks the anchored format-check text. The six other `PHASE168_*` SHA pins in the same function are untouched (genuinely single-incident identity, not version literals). |
| `"io/github/sztheory/crosswake-shell-core-android/0.2.1/crosswake-shell-core-android-0.2.1.pom"` (android_publication.sh) | `phase168_partial_recovery_routes/3` (check `release.partial.phase168_recovery_routes`) | **generalized** | Task 1b interpolated `${VERSION}` into this exact string; needle updated to match. Still falsifiable — fails if the interpolation regresses. |
| `not includes?(android_publication, "io/crosswake/crosswake-shell-core/0.2.1")` | same function | **generalized** | Dropped the version suffix from this negative control — the defect it guards (wrong Maven groupId/artifact path) is not version-specific, so this makes the check strictly more robust for future candidates, not weaker. Well above the 12-character floor. |
| `~w(release/v0.2.0 feature/v0.2.0 refs/tags/v0.2.0 ...)` (`forbidden_samples`) | `recovery_exact_ref_only/1` (check `recovery.hex.exact_ref_only`) | **pinned historical fixture** | Mirrors hex-publish.yml's own untouched illustrative rejected-ref-shape case-pattern list (a fixed set of example bad ref strings in an error message, not a live version-comparison gate). Not a WELD-06 concern; changing it serves no purpose. |

**Completeness sweep (measured, not asserted):** `grep -v '^\s*#' script/check_release_workflow_integrity.exs | grep -cE '[0-9]+\.[0-9]+\.[0-9]+'` returns **1** after the fixes — exactly the `forbidden_samples` occurrence above, consciously assigned Disposition 2. `elixir script/check_release_workflow_integrity.exs` exits 0, roster count unchanged at **69/69**, zero `FAIL` lines. No check was dropped. No needle shortened below 12 characters. No assertion weakened to a substring/prefix match, wrapped in `|| true`, or downgraded to a warning.

## Task Commits

1. **Task 1: Make the publish and mirror shell scripts follow the version they are given** — `fa780fc9` (feat)
2. **Task 2: Generalize the dispatch-driven workflows and restore the candidate-receipt attestation** — `f4ee2e4f` (feat)
3. **Task 3: Resolve the scanner's remaining self-referential assertions, with a recorded decision for each** — `d4eb2315` (feat)
4. **Deviation fix (Rule 1, direct consequence of Task 1b): update workflow_test.exs's own Maven-coordinate assertion** — `4adc82fc` (fix)

## Files Created/Modified

- `script/guarded_hex_publish.sh` — `--expected-version` flag added; `verify_approved_identity()` generalized and made fail-closed
- `script/release_candidate/android_publication.sh` — version refusal → format check; `PUBLIC_POM`/gradle grep/echo text interpolate `$VERSION`
- `script/release_candidate/ios_mirror.sh` — candidate-mode version conjunct → format check
- `script/verify_ios_mirror_backfill.sh` — usage/doc text only; confirmed no live comparison
- `.github/workflows/release-please.yml` — one line added (`--expected-version`) to the existing "Guarded Hex publish" step, a Rule 1 deviation required by Task 1a's fail-closed change (see Deviations)
- `.github/workflows/hex-publish.yml` — stale default removed; new `approved_version` input; two recovery comparisons generalized; three descriptions reworded
- `.github/workflows/ios-mirror-backfill.yml` — `CANDIDATE_VERSION` added to two jobs; six D-171-D negative controls parameterized; two `RELEASE_VERSION` pins generalized; one description reworded
- `script/check_release_workflow_integrity.exs` — two self-referential assertion needles updated in lockstep, each with an explanatory in-source comment
- `test/crosswake/release_candidate/workflow_test.exs` — pre-existing test's Maven-coordinate assertion updated to match the `${VERSION}`-interpolated shape

## Decisions Made

See `key-decisions` in frontmatter. In summary: guarded_hex_publish.sh's identity check now applies unconditionally to `crosswake` (rather than staying gated on a version literal) because its supporting checks are already caller-supplied and version-independent; hex-publish.yml's and ios-mirror-backfill.yml's genuinely single-incident phase168-pinned jobs got format-check/cross-check generalizations for their version fields only, leaving every SHA-identity pin untouched; and the scanner/test fixes tracked the actual post-fix subject text rather than staying pinned to retired literals.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Auto-fix a bug directly caused by this task's own change] `release-please.yml`'s existing automatic crosswake publish call needed one new flag**
- **Found during:** Task 1 (writing `guarded_hex_publish.sh`'s fail-closed `--expected-version` requirement)
- **Issue:** `release-please.yml` is not in this plan's `files_modified` list, but its existing "Guarded Hex publish" step call to `guarded_hex_publish.sh` for the `crosswake` package would have started failing closed (no `--expected-version` supplied) the moment Task 1a's fail-closed requirement landed, breaking the primary automatic publish path.
- **Fix:** Added one line to that existing step — `--expected-version "${{ needs.approved-release-guard.outputs.approved_version }}"` — reusing the `approved_version` output plan 171-01 already wired (D-171-A: compare, never re-derive). No other line in that file touched.
- **Files modified:** `.github/workflows/release-please.yml`
- **Verification:** the job-level `if:` already gates this job on `needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version` (WELD-03, from 171-01), so `$VERSION` and `$EXPECTED_VERSION` are guaranteed equal at this call site — the added check is defense-in-depth, not a new failure mode.
- **Committed in:** `fa780fc9` (Task 1 commit)

**2. [Rule 1 - Auto-fix a bug directly caused by this task's own change] `workflow_test.exs`'s pre-existing Maven-coordinate assertion broke**
- **Found during:** Task 3 verification (`mix test --exclude requires_example_host`)
- **Issue:** `test/crosswake/release_candidate/workflow_test.exs`'s "partial 0.2.1 recovery is bound to the approved immutable release identity" test asserted the exact literal Maven POM string with `0.2.1` in both path segments — the same string Task 1b generalized in `android_publication.sh`. This test lives outside `script/check_release_workflow_integrity.exs` (which was already fixed in Task 3), so it surfaced only when the full ExUnit suite ran.
- **Fix:** Updated the assertion to the `${VERSION}`-interpolated shape and generalized the adjacent wrong-groupId negative control the same way the scanner's own equivalent assertion was fixed.
- **Files modified:** `test/crosswake/release_candidate/workflow_test.exs`
- **Verification:** `mix test test/crosswake/release_candidate/workflow_test.exs` — 15 tests, 0 failures; `mix test --exclude requires_example_host` — 1827 tests, 0 failures (74 excluded).
- **Committed in:** `4adc82fc`

---

**Total deviations:** 2 (both Rule 1, both direct mechanical consequences of Task 1b/1a's own fixes reaching files outside this plan's declared scope)
**Impact on plan:** No scope creep — both fixes were required to avoid landing a regression as a direct side effect of this plan's own changes. All three plan tasks completed exactly as specified.

## Issues Encountered

None beyond the deviations documented above. The plan's stated automated `<verify>` command for Task 2 — `grep -v '^\s*#' .github/workflows/hex-publish.yml | grep -cE "[0-9]+\.[0-9]+\.[0-9]+"` expecting `0` — can never return `0` as literally written: the file contains pre-existing, unrelated numeric literals (GitHub Action version-pin comments like `# v7.0.0`, and the illustrative `v0.2.0`-shaped rejected-ref-shape examples in the case-pattern reject list) that were present before this plan and are outside its scope. Verified this against `git show HEAD~4:.github/workflows/hex-publish.yml` — the count was already non-zero (17, including four genuine `0.2.1` occurrences) before any edit in this plan. This plan's actual, achieved result: the four genuine `0.2.1` comparisons/defaults are gone (count is now zero for that specific literal); the remaining matches are unrelated pre-existing tokens. Adapting to this per the executor's "if the plan is wrong about a fact in the tree, adapt and say so explicitly" instruction, rather than silently diverging.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 171-05 can proceed: this plan closes the recovery/dispatch surface's remaining `live gate` occurrences, feeding the occurrence-level weld inventory (WELD-01) with `resolved` rows for every file in this plan's scope.
- **Per the plan's `<atomicity_constraint>`:** no PR was opened, no branch was pushed, no branch operations performed. `STATE.md` and `ROADMAP.md` untouched. This plan's four commits sit on `gsd/phase-171-version-authority-split` alongside 171-01 through 171-03 and (pending) 171-05, all landing together in one PR at 171-05 Task 3 (human-gated).
- Phase 175 (Rehearsal and Publish) can now expect the `ios-mirror-backfill.yml` `attest-candidate-receipt` dispatch path to be satisfiable for a genuinely fresh, unpublished candidate version — the D-171-D cross-phase dependency flagged in RESEARCH.md's Orchestrator Addendum is closed.

---
*Phase: 171-version-authority-split*
*Completed: 2026-09-17*

## Self-Check: PASSED

All 9 modified files confirmed present on disk; all 4 task/deviation commit hashes (`fa780fc9`, `f4ee2e4f`, `d4eb2315`, `4adc82fc`) confirmed in `git log`.
