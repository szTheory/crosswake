---
phase: 168-0-2-1-release-candidate-readiness
reviewed: 2026-09-15T00:00:00Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - .github/workflows/crosswake-ci.yml
  - .github/workflows/hex-publish.yml
  - .github/workflows/ios-mirror-backfill.yml
  - .github/workflows/release-please.yml
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - lib/crosswake/release_candidate.ex
  - lib/crosswake/release_candidate/artifact.ex
  - lib/crosswake/release_candidate/cleanroom.ex
  - lib/crosswake/release_candidate/coordinate.ex
  - lib/crosswake/release_candidate/identity.ex
  - lib/crosswake/release_candidate/mirror.ex
  - lib/crosswake/release_candidate/projection.ex
  - lib/crosswake/release_candidate/receipt.ex
  - lib/crosswake/release_candidate/workflow.ex
  - lib/crosswake/release_status.ex
  - lib/mix/tasks/crosswake.release.candidate.ex
  - lib/mix/tasks/crosswake.release.status.ex
  - script/check_ci_leaf_manifest.py
  - script/check_phase167_pr_dispositions.py
  - script/check_release_workflow_integrity.exs
  - script/ci_leaf_manifest.json
  - script/guarded_hex_publish.sh
  - script/release_candidate/android_publication.sh
  - script/release_candidate/hex_artifacts.sh
  - script/release_candidate/ios_mirror.sh
  - script/verify_companion_cleanroom.sh
  - script/verify_hex_publish_dry_run.sh
  - script/verify_ios_mirror_backfill.sh
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/proof/phase166_repository_quality_test.exs
  - test/crosswake/release_candidate/artifact_test.exs
  - test/crosswake/release_candidate/cleanroom_test.exs
  - test/crosswake/release_candidate/coordinate_test.exs
  - test/crosswake/release_candidate/mirror_test.exs
  - test/crosswake/release_candidate/receipt_test.exs
  - test/crosswake/release_candidate/workflow_test.exs
  - test/fixtures/phase167_runtime_authority/milestone.lock
  - test/js/phase167_pr_dispositions.test.mjs
  - test/mix/tasks/crosswake_release_candidate_test.exs
  - test/mix/tasks/crosswake_release_status_test.exs
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 168: Code Review Report

**Reviewed:** 2026-09-15T00:00:00Z
**Depth:** standard
**Files Reviewed:** 39
**Status:** issues_found

## Summary

This phase implements a heavily fail-closed "exact release candidate" authority: a set of pure
Elixir evaluator modules (`Crosswake.ReleaseCandidate.*`) that turn normalized observations into a
single closed state, plus shell adapters and GitHub Actions workflows that gather those
observations and perform the one authorized mutation once approved. The Elixir side is
disciplined — closed-map validation (`exact_map?`), explicit enums, digest binding, and rescue
clauses that collapse every unexpected shape to a single `invalid!()` — and I could not find a
correctness bug in the evaluator logic itself (`Mirror`, `Receipt`, `Cleanroom`, `Coordinate`,
`Workflow`, `Artifact`, `Identity`) after tracing the disposition functions and their guard
conditions.

The one substantive gap is in `.github/workflows/ios-mirror-backfill.yml`: every other irreversible
mutation path in this phase (Hex `recovery`, Android `android-recovery`, iOS `publish`) pins the
operation to an exact, hardcoded Phase 168 identity (merge OID, approved head/tree, candidate
receipt digest) before it will run. The iOS mirror `recovery` job — the one mode explicitly
documented elsewhere as "the sole mode that permits exact-ref force-with-lease semantics" — has no
such gate. See CR-01.

The remaining findings are lower-severity quality/maintainability issues in the very large,
copy-pasted shell scripts (`verify_companion_cleanroom.sh`'s legacy positional path,
`hex_artifacts.sh`) and one dead/unreachable branch.

## Critical Issues

### CR-01: `recover-ios-mirror` job lacks the exact-identity authorization gate every sibling recovery/publish job has

**File:** `.github/workflows/ios-mirror-backfill.yml:393-424`
**Issue:** Every other mutating job in this phase's release-candidate authority chain pins itself
to one hardcoded, single-use identity before doing anything irreversible:

- `hex-publish.yml`'s `publish` job (recovery) validates `RECOVERY_REF`/`MERGE_OID`/`APPROVED_HEAD`/
  `APPROVED_TREE`/`CANDIDATE_RECEIPT` against `PHASE168_*` constants (lines 192-200) before checkout.
- `hex-publish.yml`'s `recover-android-core` job validates the same `PHASE168_*` constants
  (lines 293-313) before checkout.
- `ios-mirror-backfill.yml`'s own `publish-ios-mirror` job validates `PHASE168_MERGE_OID`,
  `PHASE168_APPROVED_HEAD/TREE/BASE`, `PHASE168_CANDIDATE_RECEIPT`, `PHASE168_MIRROR_MAIN`, and
  `PHASE168_MIRROR_SPLIT` (lines 317-343) before checkout.
- `script/release_candidate/android_publication.sh` independently re-asserts the same hardcoded
  `PHASE168_*` SHAs at the script layer (lines 14-17, 49-52) as defense in depth.

`recover-ios-mirror` (lines 393-424) has none of this. It goes straight to
`actions/checkout@... ref: ${{ inputs.release_ref }}`, loads the `MIRROR_DEPLOY_KEY` write-access
SSH key, and invokes `ios_mirror.sh recovery ... --approval-receipt ... --expected-old-ref ...
--expected-new-ref ...` with `CROSSWAKE_IOS_MIRROR_EXECUTE=true`. The only authorization performed
is inside `ios_mirror.sh`/`Crosswake.ReleaseCandidate.Mirror`, which checks *shape* (SHA/digest
regex format, `approval.status == "RECOVERY APPROVED"`, `ancestry == "DIVERGED"`, a passing
`git push --dry-run --force-with-lease`) — not that the operator-supplied `version`, `release_ref`,
`approval_receipt`, `expected_old_ref`, and `expected_new_ref` match one specific, previously
reviewed recovery transaction. Recovery is explicitly the most dangerous mode
(`verify_ios_mirror_backfill.sh`'s own usage text: "Recovery is the sole mode that permits exact-ref
force-with-lease semantics") and the only one of the four iOS mirror `workflow_dispatch` operations
that can force-push `refs/heads/main` on the public mirror. Anyone with permission to trigger this
`workflow_dispatch` (any actor with `workflow_dispatch` + write access, not necessarily the same
person who produced the approved candidate receipt) can supply any structurally-valid
`expected_old_ref`/`expected_new_ref` pair and force-with-lease main to an arbitrary commit, as long
as the live ancestry happens to read `DIVERGED` and the dry-run porcelain check passes — with no
requirement that the target correspond to the one approved 0.2.1 recovery.
**Fix:** Add the same hardcoded `PHASE168_*` validation step used by `publish-ios-mirror`,
`recover-android-core`, and the Hex `publish` (recovery) job to `recover-ios-mirror`, e.g.:
```yaml
recover-ios-mirror:
  ...
  steps:
    - name: Validate exact Phase 168 iOS recovery authority
      env:
        RECOVERY_VERSION: ${{ inputs.version }}
        RECOVERY_REF: ${{ inputs.release_ref }}
        APPROVAL_RECEIPT: ${{ inputs.approval_receipt }}
        EXPECTED_OLD_REF: ${{ inputs.expected_old_ref }}
        EXPECTED_NEW_REF: ${{ inputs.expected_new_ref }}
        PHASE168_MERGE_OID: b780a19863936619394087f1ffd384f1dca17c93
        PHASE168_CANDIDATE_RECEIPT: 359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78
      run: |
        set -euo pipefail
        [ "$RECOVERY_VERSION" = "0.2.1" ]
        [ "$RECOVERY_REF" = "$PHASE168_MERGE_OID" ]
        [ "$APPROVAL_RECEIPT" = "$PHASE168_CANDIDATE_RECEIPT" ]
        # plus the same expected-old/new-ref pinning publish-ios-mirror performs
    - uses: actions/checkout@...
```
If `recovery` is genuinely meant to stay general-purpose across future incidents (unlike the other
three exact-pinned jobs), that divergence should at minimum be a deliberate, documented decision —
today it reads as an omission given every sibling job in the same file and the same phase pins
exact identity.

## Warnings

### WR-01: `hex_artifacts.sh` companion source prep silently trusts a stale `deps/crosswake` symlink filter

**File:** `script/release_candidate/hex_artifacts.sh:110-114`
**Issue:** `prepare_companion_source` symlinks every entry under
`$REPO_ROOT/packages/$package/deps/*` into the isolated companion source tree except one literally
named `crosswake` (`[ "$(basename "$dependency_source")" != "crosswake" ]`). This assumes the
monorepo's on-disk `packages/$package/deps/` never contains a second entry that also needs
excluding (e.g. a stale `_build`-adjacent artifact, or a future test-only path dependency that
should likewise not leak host filesystem state into the hermetic tree). Because the check is a
literal string compare rather than validation against an explicit allow-list, a new dependency
directory silently gets symlinked in with no assertion step confirming the resulting isolated
source tree is exactly what was intended — a regression here would only surface as a confusing
downstream `mix deps.get` failure or, worse, a subtly wrong resolved lockfile, not a clear
"unexpected dependency" error.
**Fix:** Assert the resulting symlinked set against the expected non-crosswake dependency list per
package (the caller already knows exactly which companions declare which test-only path deps, e.g.
chimeway → sigra) rather than relying on exclusion-by-name of a single literal.

### WR-02: `verify_companion_cleanroom.sh` duplicates ~700 lines of legacy positional-interface logic that is superseded by the `--source-mode` matrix path

**File:** `script/verify_companion_cleanroom.sh:745-1445`
**Issue:** The file's own comment at line 63-65 states "The option-based interface is the
candidate-grade path. The positional interface below remains available for the existing
independently versioned companion publication jobs until their workflow owner migrates them in a
later plan." The legacy path (lines 745-1445) re-implements almost the same Phoenix-host
generation, dependency patching, smoke-test writing, and doctor-proof steps that
`matrix_write_host`/`matrix_write_smoke` (lines 289-505) already implement for the matrix path,
via separate bash + inline `python3 -`/heredoc code with its own bugs surface (e.g. the smoke-test
generation logic for `chimeway`/`sigra`/`threadline` is duplicated almost verbatim between
`matrix_write_smoke` and the legacy `cat > test/smoke_test.exs` blocks at lines 1244-1372, with
independent divergence risk — a fix to one path's smoke assertions will not automatically apply to
the other). This is acknowledged tech debt, but at ~700 duplicated lines it is a substantial
quality/maintainability liability for a script that gates registry publication safety.
**Fix:** Track and complete the "workflow owner migrates them in a later plan" removal so only one
implementation of the companion clean-room proof exists; until then, consider extracting the shared
smoke-test-body generation into one function callable from both paths to close the divergence risk.

### WR-03: `Crosswake.ReleaseStatus.candidate_public_checks/2` and `release_candidate/2` compute live registry checks the caller doesn't reuse for `core`/`companions`

**File:** `lib/crosswake/release_status.ex:181-292` and `620-712`
**Issue:** `release_candidate/4` (private, called from `build/1`) performs its own independent set
of `maybe_hex_live`/`maybe_ios_mirror_live`/`maybe_maven_live` probes for the 0.2.1 candidate
coordinates (lines 182-186), while `core_components/4` and `companion_components/5` perform a
second, separate round of the *same* probe functions for the same packages/versions (lines
294-326, 328-353) when `live?` is true — i.e. `crosswake@0.2.1` is probed via `maybe_hex_live`
twice per `mix crosswake.release.status --live` invocation (once for `core`, once inside
`release_candidate`), each retrying up to `@probe_attempts` (3) times with `@probe_retry_sleep_ms`
(200ms) backoff. This isn't a correctness bug (both probes are read-only and idempotent), but it
doubles outbound network calls and worst-case latency for the `--live` command with no caching
between the two computations, which is surprising for a "fast and deterministic" CLI tool whose own
moduledoc explicitly markets local-only mode as the fast path.
**Fix:** Compute the shared live probe results once and pass them into both `core_components` and
`release_candidate` rather than re-invoking `maybe_hex_live`/`maybe_ios_mirror_live` a second time
for the same coordinate.

## Info

### IN-01: `guarded_hex_publish.sh` positional-shift arithmetic is easy to misread

**File:** `script/guarded_hex_publish.sh:15-18`
**Issue:** `shift "$(( $# >= 3 ? 3 : $# ))"` after reading `$1`/`$2`/`$3` into `PACKAGE`/`VERSION`/
`RELEASE_REF` is correct (it shifts by the smaller of 3 or the actual arg count, so calling the
script with fewer than 3 positional args doesn't error), but the ternary-in-arithmetic-expansion
idiom is non-obvious at a glance and undocumented. A future edit that changes the number of leading
positional parameters without touching this line would silently misparse the remaining `--flag
value` pairs.
**Fix:** Add a one-line comment explaining the shift covers "however many of the 3 positional args
were actually supplied" or replace with an explicit `if [ "$#" -ge 3 ]; then shift 3; else shift
"$#"; fi` for readability.

### IN-02: `Crosswake.ReleaseCandidate.Workflow.rollup!/1` only enforces the dependency invariant for children reported `"success"`

**File:** `lib/crosswake/release_candidate/workflow.ex:28-32`
**Issue:** The `Enum.each` loop only rejects the input when a child is `"success"` but one of its
declared `@dependencies` is not `"success"`. A child reported `"failed"` or `"skipped"` whose
dependency graph is internally inconsistent (e.g. `exact_public: "failed"` while every one of its
six `@dependencies` is `"success"`) passes validation unexamined, relying entirely on the CI
producer to report `failed`/`skipped` honestly for jobs whose GitHub Actions `needs:` already
should have skipped them. This is consistent with the module's stated purpose (validate a closed,
already-produced observation, not re-derive it), so it's not a defect, but it does mean `rollup!/1`
cannot catch a CI misconfiguration that lets a dependent job run to `"failed"` despite an upstream
failure — only that a job can't unexpectedly claim `"success"` it didn't earn.
**Fix:** No action required unless the module's fail-closed contract is intended to extend to
non-success dependency-consistency as well; if so, extend the `Enum.each` check to run for every
child, not only ones reporting `"success"`.

---

_Reviewed: 2026-09-15T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
