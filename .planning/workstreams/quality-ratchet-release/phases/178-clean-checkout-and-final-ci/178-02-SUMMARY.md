---
phase: 178-clean-checkout-and-final-ci
plan: "02"
subsystem: testing
tags: [repository-proof, nodejs, git, artifact-policy, local-ci]
requires:
  - phase: 178-clean-checkout-and-final-ci
    provides: renewed candidate binding and clean exact candidate clone from Plan01
provides:
  - strict local proof collector bound to the candidate and a distinct final-source binding
  - retained preliminary all-stage proof with private invocation, logs, snapshots, and source binding
affects: [178-04, 178-05]
actuals:
  tokens: 17210
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [real facade output capture, private raw-index byte comparison, policy-aware ignored-output validation]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/preliminary-local-proof.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/failed-before-final-preliminary-local-proof.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-02-SUMMARY.md
  modified: []
key-decisions:
  - "The collector joins the current candidate through its private binding and public projection; it has no hardcoded source commit or tree."
  - "New ignored paths are accepted only when the candidate artifact policy explicitly classifies them as ignored local tooling and each new entry is a regular current-user-owned file reached through a symlink-free path inside the proof clone."
  - "Preliminary MAINT-07 evidence does not resolve MAINT-07/08; Plan05 must run the exact observed final source and join it with hosted CI."
patterns-established:
  - "Keep raw index snapshots owner-private, hash-check them, compare the bytes, and publish only safe pass/count fields."
  - "For final proof, bind a separate fresh clone to the final source while retaining the original candidate commit/tree in the same private source-binding record."
requirements-completed: []
coverage:
  - id: D1
    description: "Strict collector accepts real nine-stage facade output and rejects malformed, incomplete, changed-source, unsafe-output, or leaking evidence."
    verification:
      - kind: unit
        ref: "178-evidence/local_proof.test.mjs (13 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Preliminary exact-candidate local proof completed all nine verifier stages with unchanged independent source and raw-index snapshots."
    verification:
      - kind: integration
        ref: "script/verify_repository.sh --all and local_proof.mjs --collect"
        status: pass
    human_judgment: false
duration: 127m
completed: 2026-10-12
status: complete
---

# Phase 178 Plan 02: Clean Checkout and Final CI Summary

**A renewed candidate now has a retained nine-stage local proof, and the collector binds source identity and raw index bytes before publishing its safe result.**

## Performance

- **Duration:** 127 minutes
- **Started:** 2026-10-12T20:23:46Z (private owner-root creation time)
- **Completed:** 2026-10-12T22:30Z
- **Tasks:** 2
- **Files created:** 5

## Accomplishments

- Added a strict collector that consumes the real `runVerification({selection: 'all'})` output, validates nine ordered stage results and eight retained logs, binds the dynamic Plan01 candidate identity, validates separate preliminary/final output paths, and rejects malformed output, source/status/index drift, missing or unsafe logs, unapproved ignored artifacts, and secret sentinels.
- Retained a successful `script/verify_repository.sh --all` run on candidate commit `3e8a4b2601b542323edfd6053f25e56c67873b47` and tree `27f4073039b4dd976492127549603a76ce22499b`. All nine stages passed; all eight stage logs and raw invocation output remain private. The before/after supplemental raw index snapshots are mode 0600, hash-valid and byte-identical; the live index still matches them. HEAD, tree, index-entry digest, and NUL status remained unchanged.
- Wrote the allowlisted preliminary projection and an owner-private `local-proof-binding.json` alongside the retained run. The public result records nine passes, eight logs, and aggregate ignored-path counts only; it contains no raw output, private paths, or index bytes.
- Added policy-aware ignored-output handling. The proof test created 20 temporary shim files under the candidate policy's `ignored_local_tooling` `tmp` tree. The collector admits these only after confirming policy classification, regular-file type, current-user ownership, and symlink-free containment in the proof clone. It still rejects unrelated ignored output and symlink escapes.

## Task Commits

**Task 2: Verify the existing renewed candidate (source reference, no new commit)** — `3e8a4b2601b542323edfd6053f25e56c67873b47` — the existing Plan01 renewal commit in the independent delivery clone. Plan02 created no new source commit. This is the source used by both verification tasks and the phase scope gate.

No task or summary commits were created. The execution assignment explicitly reserves the shared checkout from staging, commits, branch changes, and worktree changes; these artifacts remain available for the root orchestrator to reconcile under that restriction.

## Files Created

- [local_proof.mjs](./178-evidence/local_proof.mjs) — source-bound facade collector, private snapshot validation, and safe projection.
- [local_proof.test.mjs](./178-evidence/local_proof.test.mjs) — real-facade and collector security/false-green fixtures.
- [preliminary-local-proof.json](./178-evidence/preliminary-local-proof.json) — public allowlisted 9/9 preliminary result.
- [failed-before-final-preliminary-local-proof.json](./178-evidence/failed-before-final-preliminary-local-proof.json) — retained historical blocked projection from the initial collection attempt.
- Private owner-root `local-proof-binding.json` — invocation/capture pointers, candidate identity, and private raw-index snapshot pointers; mode 0600 under mode 0700 owner root.

## Verification

- `node --check 178-evidence/local_proof.mjs` — passed.
- `node --test 178-evidence/local_proof.test.mjs` — 13 passed, 0 failed. Includes real-policy `tmp` acceptance, unapproved ignored output rejection, symlink escape rejection, dynamic renewed-candidate identity, and no-launch rejection for missing/recovery-root pointers.
- `script/verify_repository.sh --all` — one complete corrected run; all nine ordered stages passed. The invocation record has exit status 0, eight stage logs have terminal status 0, and private raw index snapshots match the live source index.
- `node 178-evidence/local_proof.mjs --collect` with `CROSSWAKE_178_PROOF_KIND=preliminary` and the retained invocation record — passed and wrote the preliminary projection.
- Private post-collection checks confirmed the before/after raw index files are mode 0600, each file matches its recorded SHA-256, both files are byte-identical, and the current index hash equals the after snapshot. Working-tree status is empty.

The exact final-source binding contract for Plan05 is: owner-private `final-source-binding.json` at mode 0600 under a mode 0700 owner root, with JSON fields `schemaVersion: 1`, `phase: 178`, `plan: "05"`, `candidateCommit`, `candidateTree`, `finalCommit`, `finalTree`, and `proofRoot`. The candidate fields must equal the immutable Plan01 candidate; the final fields must equal the observed runner-tested commit and its tree; `proofRoot` must resolve to a new independent clean clone and must differ from the preliminary candidate proof root. For collection, set `CROSSWAKE_178_PROOF_KIND=final`, `CROSSWAKE_178_INVOCATION_RECORD` to the private final run record, and `CROSSWAKE_178_FINAL_SOURCE_BINDING` to that binding file, then run `node .../local_proof.mjs --collect`. With kind `final`, the collector defaults to `final-local-proof.json`; preliminary collection independently defaults to `preliminary-local-proof.json`.

## Decisions Made

- Keep private invocation output, logs, NUL snapshots, and raw index bytes in the owner root; publish only the closed allowlisted proof projection.
- Treat the 20 `tmp` shims as policy-approved transient test output only after checking each live entry. No cleanup was performed.
- Keep MAINT-07 and MAINT-08 pending: this preliminary result does not substitute for Plan05's fresh final-source proof and hosted CI join.

## Deviations from Plan

### Bounded corrections and environment repairs

1. **Collector policy correction:** the first corrected all-pass collection was blocked because the collector required every newly ignored entry to be named in the stage manifest's `owned_outputs`, even when the selected artifact policy explicitly classified the entry as ignored local tooling. The collector now honors that existing policy category only after checking type, ownership, and containment. A real-policy positive fixture and unapproved-output/symlink negatives pass. No source or policy files were changed.
2. **Private toolchain and environment repair:** the first proof attempts exposed missing standard tools and private cache paths, a browser `SIGTRAP`, Swift sandbox denial, Gradle metrics permission failure, Android preferences-path conflict, and the approved guide formatting issue. These were corrected in the independent private proof environment; Android SDK 34 and Build Tools 34.0.0 were installed with the user's scoped license/setup authorization. `ANDROID_SDK_HOME` was omitted, the conflicting private Android user path was used, and private Gradle metrics/cache settings were applied. No manifest versions were changed and no Phase177 build/dependency tree was copied.
3. **Index-preserving Git check:** disposable reproduction showed `git diff --check` could refresh stat cache entries while generated outputs were restored. The complete rerun used only the per-process `diff.autoRefreshIndex=false` Git configuration appended to the runner child environment; whitespace/content checking remained active and the raw index stayed byte-identical. The verifier source and manifest were not changed.
4. **Earlier wrong-cwd invocation:** an early Mix/formatter setup command was misbound to the recovery checkout and failed before formatting. Subsequent protection checks confirmed source bytes/modes, raw index, staged entries, HEAD, branch, worktrees, and 1,677 protected historical files were unchanged. No before/after ignored-residue snapshot was retained for that attempt, so any invocation-owned ignored residue cannot be established. The current 20 shims belong to the separate proof clone and are not attributed to the earlier attempt.
5. **Checkout commit restriction:** no commits, staging, branch changes, worktree changes, or STATE/ROADMAP/requirements edits were made, following the execution assignment's explicit protected-checkout scope. The phase root owns state synchronization.

**Total deviations:** 5 bounded corrections/constraints. **Impact:** the full requested local proof and collector checks pass; no product source, artifact policy, or verifier manifest was changed.

## Issues Encountered

- Two earlier full-run projections remain retained as blocked history. The corrected final run passed all nine stages. A previous index-drift cause was reproduced on a disposable clone and fixed only through per-process Git behavior; the exact bytes from the older failed run were not retained, so its historical byte-level attribution remains unproven.
- The final proof is preliminary. Hosted CI and the fresh exact runner-tested final-source proof remain for the later plans.

## User Setup Required

None. The one scoped Android SDK license/setup authorization was already supplied and applied to private toolchain storage.

## Next Phase Readiness

Plans04/05 can consume the owner-private `local-proof-binding.json` and the public preliminary projection. Plan05 must create the exact final-source binding described above and run a fresh complete `--all` on the actual observed runner-tested commit. MAINT-07/08 remain pending until their exact-source local and hosted evidence is joined.

## Self-Check: PASSED

- Collector and test files exist; 13/13 fixtures pass.
- Preliminary public projection exists with `status: pass`, nine stages, and eight logs.
- Private binding exists with mode 0600; private owner directory is mode 0700.
- Retained raw before/after index bytes are 0600, hash-valid, byte-identical, and still match the live index.
- No checkout commit, staging, branch, or worktree mutation was made.

---
*Phase: 178-clean-checkout-and-final-ci*
*Completed: 2026-10-12*
