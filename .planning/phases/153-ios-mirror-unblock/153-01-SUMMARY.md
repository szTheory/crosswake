---
phase: 153-ios-mirror-unblock
plan: 01
subsystem: infra
tags: [git, ssh, github-actions, release-infra, splitsh-lite, elixir-scanner]

# Dependency graph
requires: []
provides:
  - "backfill lane (script/verify_ios_mirror_backfill.sh + ios-mirror-backfill.yml) authenticates over SSH via MIRROR_DEPLOY_KEY, structurally immune to the actions/checkout credential-hijack (D-01/D-04)"
  - "apply=false now runs a real git push --dry-run --porcelain probe before returning, proving WRITE scope instead of anonymous read (D-07) — the missing iOS fire-drill"
  - "--update-main uses the explicit-lease form --force-with-lease=\"refs/heads/main:${current_main}\", the only form empirically proven to work in a never-fetched CI checkout (D-13)"
  - "the ancestry guard distinguishes an unknown mirror-main object (advisory, proceed) from a known-but-not-ancestor object (fail-closed) (D-08)"
  - "three new scanner ids (release.ios_backfill.write_probe / .explicit_lease / .ssh_transport) make all four invariants above regression-proof in CI"
  - "hermetic bare-repo fixture proofs (test/crosswake/proof/phase153_ios_mirror_unblock_test.exs) for atomic+lease push semantics against disjoint mirror history, independent of any live GitHub call"
affects: [153-02, 153-03, 153-04]

# Tech tracking
tech-stack:
  added: [webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 (v0.10.0, SHA-pinned)]
  patterns:
    - "bare-repo git fixtures for offline git-transport proof (extends phase145's harness with a disjoint-history mirror shape)"
    - "explicit-lease force-with-lease read fresh via git ls-remote immediately before push, never bare/named-without-:expect"
    - "cat-file -e <sha>^{commit} to distinguish 'unknown object' from 'known, not ancestor' before deciding fail-closed vs advisory"

key-files:
  created:
    - test/crosswake/proof/phase153_ios_mirror_unblock_test.exs
  modified:
    - script/verify_ios_mirror_backfill.sh
    - .github/workflows/ios-mirror-backfill.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase145_ios_backfill_script_test.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs

key-decisions:
  - "SSH deploy key (MIRROR_DEPLOY_KEY) replaces MIRROR_PUSH_TOKEN entirely in the backfill lane; the HTTPS x-access-token branch is removed from mirror_push_remote(), not merely deprioritized"
  - "The write probe (git push --dry-run --porcelain) now runs unconditionally before the verify/apply branch point, so both apply=false and apply=true paths prove WRITE scope; the file therefore has 2 dry-run probe call sites by design (one always-run, one immediately before the real apply-path push), matching the plan's explicit acceptance criterion"
  - "No git fetch was added anywhere - the lease <expect> is read via the existing git ls-remote call, confirming RESEARCH's finding that the explicit-lease form needs no local knowledge of the remote object"
  - "Did not add a --rebaseline flag (per CONTEXT's discretion note) - the existing --update-main input plus the ls-remote read already carry the information the ancestry guard needs"

requirements-completed: [MIRROR-01, MIRROR-02]

coverage:
  - id: D1
    description: "Backfill lane checkout no longer persists a GITHUB_TOKEN extraheader that can hijack the mirror remote (D-01/D-04)"
    requirement: MIRROR-02
    verification:
      - kind: unit
        ref: "script/check_release_workflow_integrity.exs release.ios_backfill.ssh_transport"
        status: pass
    human_judgment: false
  - id: D2
    description: "Backfill lane authenticates to the mirror over SSH with MIRROR_DEPLOY_KEY, never an HTTPS URL-embedded token (D-03)"
    requirement: MIRROR-02
    verification:
      - kind: unit
        ref: "script/check_release_workflow_integrity.exs release.ios_backfill.ssh_transport"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase145_ios_backfill_script_test.exs script source keeps verify-first and exact-ref guardrails"
        status: pass
    human_judgment: false
  - id: D3
    description: "apply=false performs a real git push --dry-run --porcelain probe, proving WRITE scope rather than anonymous read (D-07)"
    requirement: MIRROR-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase153_ios_mirror_unblock_test.exs apply=false proves WRITE scope via a real dry-run push probe, not merely anonymous read (D-07)"
        status: pass
      - kind: unit
        ref: "script/check_release_workflow_integrity.exs release.ios_backfill.write_probe"
        status: pass
    human_judgment: false
  - id: D4
    description: "--update-main push uses the explicit-lease form --force-with-lease=refs/heads/main:<sha-read-via-ls-remote>, avoiding stale-info failure in a never-fetched CI checkout (D-13)"
    requirement: MIRROR-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase153_ios_mirror_unblock_test.exs atomic + explicit-lease push succeeds across disjoint mirror history (D-08 happy path)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase153_ios_mirror_unblock_test.exs a stale lease fails the WHOLE atomic transaction; no partial apply"
        status: pass
      - kind: unit
        ref: "script/check_release_workflow_integrity.exs release.ios_backfill.explicit_lease"
        status: pass
    human_judgment: false
  - id: D5
    description: "Ancestry guard distinguishes 'unknown to this repo' (advisory, proceed) from 'known and genuinely not an ancestor' (fail-closed) (D-08)"
    requirement: MIRROR-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase153_ios_mirror_unblock_test.exs ancestry guard logs an advisory (not fail-closed) when mirror main is an unknown object (D-08)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase153_ios_mirror_unblock_test.exs ancestry guard still fails closed when mirror main is known and genuinely not an ancestor (D-08)"
        status: pass
    human_judgment: false
  - id: D6
    description: "An existing published mirror tag is never moved inside the atomic push - lease scoped to main alone leaves the tag refspec unforced (D-10)"
    requirement: MIRROR-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase153_ios_mirror_unblock_test.exs an existing tag cannot be moved inside the atomic push, even with a correct main lease"
        status: pass
    human_judgment: false
  - id: D7
    description: "Hermetic bare-repo fixtures prove the push semantics offline, so a lease/atomic regression fails at mix test, not at release time (D-02)"
    requirement: MIRROR-01
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase153_ios_mirror_unblock_test.exs --only phase153_ios_mirror_unblock"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-13
status: complete
---

# Phase 153 Plan 01: Backfill Lane Transport + Write-Probe + Explicit Lease Summary

**Defused the checkout credential-hijack (D-01) and the D-08 ancestry-guard misdiagnosis on the iOS mirror backfill lane, and turned the already-dispatchable `apply=false` run into the missing iOS fire-drill by proving WRITE scope with a real dry-run push probe — no push to the live mirror was attempted; that remains plan 153-02's human-gated scope.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-13T17:24:00Z (approx, first Read call)
- **Completed:** 2026-07-13T17:38:39Z
- **Tasks:** 3 completed
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- `script/verify_ios_mirror_backfill.sh` now authenticates over SSH by default (`git@github.com:szTheory/crosswake-shell-core-ios.git`), with the entire `MIRROR_PUSH_TOKEN`/`x-access-token` HTTPS branch removed from `mirror_push_remote()`.
- `apply=false` now runs `git push --dry-run --porcelain` before its early return and reports `MIRROR_DEPLOY_KEY has WRITE scope` on success — the fire-drill this repo lacked for iOS.
- `--update-main` now uses `--force-with-lease="refs/heads/main:${current_main}"` (the explicit-lease form RESEARCH proved is the *only* one that works in a never-fetched CI checkout) instead of the broken named-without-`:expect` form that would have failed 100% of the time.
- The ancestry guard now runs `git cat-file -e "${current_main}^{commit}"` first, logging an advisory for an unknown object (the expected D-08 re-baseline case) instead of fail-closing, while still fail-closing when the object is known and genuinely not an ancestor.
- `.github/workflows/ios-mirror-backfill.yml` gained the three-step SSH block (`persist-credentials: false` + SHA-pinned `webfactory/ssh-agent` + `ssh-keyscan`), matching this repo's action-pinning discipline; the `MIRROR_PUSH_TOKEN` env entry is gone.
- Three new scanner checks (`release.ios_backfill.write_probe`, `.explicit_lease`, `.ssh_transport`) make all of the above regression-proof; two existing checks (`ios_backfill_verify_first`, `ios_backfill_no_default_main_force`) were rewritten (not just renamed) to assert the new mechanism.
- New hermetic test file proves git's own atomic+lease semantics against a disjoint-history bare-repo mirror fixture (the D-08 off-lineage shape), plus drives the real script for the write-probe and ancestry-guard contracts.

## Task Commits

1. **Task 1: Wave 0 — hermetic bare-repo fixtures for the atomic + explicit-lease push semantics** - `9651c612` (test)
2. **Task 2: Rewrite verify_ios_mirror_backfill.sh — SSH transport, write probe in the verify branch, correct lease, correct ancestry message** - `7b6754a7` (fix)
3. **Task 3: Backfill workflow SSH block + scanner checks that assert the new mechanism** - `60d2fcd5` (feat)

_Note: Task 1 (tdd="true") landed tests A/B/C green and D/E/decoy RED in a single commit per the plan's Wave-0 shape — RESEARCH's own findings meant tests A/B/C were expected to pass immediately as pure git-semantics proofs, not require a separate RED commit._

## Files Created/Modified

- `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` - new hermetic proof: disjoint-mirror atomic+lease push (A/B/C), real-script write-probe and ancestry-guard behavior (D/E), scanner-id decoys
- `script/verify_ios_mirror_backfill.sh` - SSH transport, unconditional write probe, explicit-lease `--update-main`, ancestry-guard unknown/known-non-ancestor split
- `.github/workflows/ios-mirror-backfill.yml` - `persist-credentials: false` + `webfactory/ssh-agent` + `ssh-keyscan`; `MIRROR_PUSH_TOKEN` env removed
- `script/check_release_workflow_integrity.exs` - rewrote 2 checks, added 3 new checks, registered in the `checks` list
- `test/crosswake/proof/phase145_ios_backfill_script_test.exs` - updated 2 assertions/tests tied to the retired token guard and the old lease form (Rule 1)
- `test/crosswake/proof/phase142_release_integrity_test.exs` - retargeted 2 mutation-fixture tests whose old target substrings no longer exist post-fix (Rule 1)

## Decisions Made

- Kept both dry-run probe call sites in the apply path (one unconditional before the verify/apply branch, one immediately before the real tag push) rather than deduplicating, matching the plan's explicit "≥2 occurrences" acceptance criterion and preserving idempotent-check redundancy at negligible cost.
- Used `~s(...)` sigils / raw `bash -c` command strings in the new test file so the source text literally contains the exact quoted `--force-with-lease="refs/heads/main:<expect>"` form the plan required byte-for-byte (a paraphrase would have re-armed the fuse).
- Did not touch `release-please.yml` in this plan — `mirror_token_preflight`/`workflow_mirror_token_preflight`/`mirror_token_write_preflight` (which check `publish-ios-core` in the main release workflow) are explicitly out of this plan's scope per its `files_modified` frontmatter and remain for a later plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `phase145_ios_backfill_script_test.exs` had two assertions tied to behavior this plan's own D-13/D-03 fix retired**
- **Found during:** Task 2 verification (`mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs`)
- **Issue:** (a) the source-guardrail assertion `assert script =~ "--force-with-lease=refs/heads/main"` no longer matched once the script uses the quoted explicit-lease form `--force-with-lease="refs/heads/main:${current_main}"`; (b) the `"apply mode requires MIRROR_PUSH_TOKEN before mutation"` test asserted a guard that no longer exists post-D-03 (SSH deploy key auth has no script-visible token to check presence of)
- **Fix:** (a) updated the substring assertion to the new quoted form; (b) replaced the test with an equivalent-purpose test that forces the new write-probe to fail (points the mirror remote at a nonexistent bare-repo path) and asserts the new `MIRROR_DEPLOY_KEY`-naming failure message
- **Files modified:** `test/crosswake/proof/phase145_ios_backfill_script_test.exs`
- **Verification:** `mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs` - 5/5 green
- **Committed in:** `7b6754a7` (part of task 2 commit)

**2. [Rule 1 - Bug] `phase142_release_integrity_test.exs` had two mutation-fixture tests whose target substrings this plan's Task 3 rewrite made obsolete, turning the mutation into a no-op**
- **Found during:** Task 3 verification (`mix test test/crosswake/proof/phase142_release_integrity_test.exs`)
- **Issue:** `String.replace(script, "MIRROR_PUSH_TOKEN is required for --apply", ...)` and `String.replace(script, "--force-with-lease=refs/heads/main", "--force")` no longer found their target text in the corrected script, so the "mutated" fixture was byte-identical to the passing real script — the scanner correctly reported `:ok`, but the test expected `:error` (a stale assertion, not a real regression)
- **Fix:** retargeted both mutations at the new marker text (`"MIRROR_DEPLOY_KEY has WRITE scope"` and the quoted explicit-lease substring) so they again exercise a genuine scanner-failure path
- **Files modified:** `test/crosswake/proof/phase142_release_integrity_test.exs`
- **Verification:** `mix test test/crosswake/proof/phase142_release_integrity_test.exs` - 63/63 green
- **Committed in:** `60d2fcd5` (part of task 3 commit)

**3. [Rule 1 - Bug] `requirements mark-complete` prematurely flipped MIRROR-01/MIRROR-02 to Complete**
- **Found during:** post-execution state update (`gsd-tools query requirements.mark-complete`)
- **Issue:** all 4 plans in this phase (`153-01` through `153-04`) share `requirements: [MIRROR-01, MIRROR-02]` in frontmatter (per this phase's plan structure, the requirement categories span multiple plans, not one-plan-one-requirement). Running `requirements mark-complete` with this plan's frontmatter IDs marked both requirements fully `Complete` in `REQUIREMENTS.md`, even though the live mirror tag push (153-02, human-gated) and the release-job atomic push + escalation guards (153-03/04) have not landed yet
- **Fix:** manually reverted `REQUIREMENTS.md`'s checkboxes to `[ ]` and the traceability table to `In Progress` with a note on which follow-on plan closes each requirement
- **Files modified:** `.planning/REQUIREMENTS.md`
- **Verification:** re-read the file to confirm the checkboxes/table reflect actual completion state
- **Committed in:** final metadata commit (this plan)

---

**Total deviations:** 3 auto-fixed (Rule 1 — pre-existing tests tracking behavior this plan intentionally changed, plus a premature requirements-completion flip corrected before commit)
**Impact on plan:** All fixes were necessary for correctness (test suite meaningfulness and requirements-traceability honesty). No scope creep — no `release-please.yml` changes were made.

## Issues Encountered

- Local shell environment's `grep` resolves to `ugrep`, which silently fails to match some of the plan's literal acceptance-criteria patterns containing `$`/`{`/`}` in default (non-`-F`) mode (e.g. `force-with-lease="refs/heads/main:${current_main}"` returned a false-negative count of 0). Re-verified every affected acceptance criterion with `grep -F` (fixed-string mode) and confirmed all patterns are genuinely present in the source. This is a local tooling quirk, not a script defect — standard GNU grep on `ubuntu-latest` (the real CI runner) does not have this issue.
- Ran the full `mix test` suite and found 14 failures unrelated to any file this plan touches (SaaS lane, session-handoff, step-up ceremony, telemetry contract, hex page, release-please-config, closeout-verifier tests). Verified via a temporary detached worktree at the pre-plan commit (`e64d2577`) that the identical file set fails there too (18 failures with the same seed) — confirmed pre-existing/order-dependent, not introduced by this plan. Worktree was removed after comparison; no state left behind.

## User Setup Required

None for this plan. `MIRROR_DEPLOY_KEY` minting/registration (D-05, four CLI commands) and the live `apply=false`/`apply=true` dispatch are explicitly plan 153-02's human-gated scope, per this plan's `<critical_safety_note>`.

## Next Phase Readiness

- The backfill lane (script + workflow) is ready for plan 153-02 to dispatch once `MIRROR_DEPLOY_KEY` is minted and registered — no further code changes to this lane are anticipated before that human step.
- `release-please.yml`'s `publish-ios-core`/`native-release-rollup`/`release-failure-alert`/`android-publish-fire-drill` (the `MIRROR_PUSH_TOKEN`→`MIRROR_DEPLOY_KEY` rename in 4 more locations, D-11 tag-pinned checkout, D-12 Hex-only gate, D-13 atomic push, D-15 alerting) remain untouched and are later-plan scope (153-03 per the phase's wave plan).
- No blockers. All targeted verification commands from the plan's `<verification>` block pass: `mix test --only phase153_ios_mirror_unblock` (7/7), `elixir script/check_release_workflow_integrity.exs` (exit 0, all `release.ios_backfill.*` ids OK), `bash -n script/verify_ios_mirror_backfill.sh` (exit 0), and no `x-access-token` HTTPS transport anywhere in the touched files.

---
*Phase: 153-ios-mirror-unblock*
*Completed: 2026-07-13*

## Self-Check: PASSED

All 7 files (6 created/modified + this SUMMARY) confirmed present on disk. All 3 task commit hashes (`9651c612`, `7b6754a7`, `60d2fcd5`) confirmed present in `git log --oneline --all`.
