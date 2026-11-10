---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 06
subsystem: release-train
tags: [rel-06, rel-17, cleanroom, premerge, trailer, remote-form-build, privacy-carry, release-0.2.14]

requires:
  - phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
    provides: "201-05 candidate (PR 283 head 407398160bb5, base fdc218f9), rehearsals, READY FOR APPROVAL receipt"
provides:
  - "candidate README.md and guides/install.md (read from head 407398160bb5) rehearsed against published 0.2.13: PASS on all four legs, deferred=none, executed=20"
  - "no-flag remote-form default iOS build of the exact candidate head against the public mirror 0.2.13: remote_from=0.2.14 remote_min=0.2.13 resolved=0.2.13, control detected, verdict PASS"
  - "REL-17 pre_merge PASS for linked_release crosswake 0.2.14 with the policy digest unchanged since 0.2.11; trailer rendered and checked; merge staged and not run"
  - "privacy carry list of the 23 retained raw pre-merge sources with 13 hits, each dispositioned exclude-from-landing"
affects: [201-07, 201-08]

plan_head_before: 21b0b8f21c093e30af4870f93e0dc35503e56d38
plan_head_after: 65c0a29bf8080e18d989624fabe43e7bccfcdbd7
commits: 3

actuals:
  tokens: 158000
  tasks: 3
  commits: 3
# tokens: chars/4 over `git diff 21b0b8f2..65c0a29b` (634689 bytes), dominated by the 23 retained raw source files.
# commits: MEASURED from the ledger (git rev-list --count 21b0b8f2..HEAD, taken before this summary commit).

pr: 283
candidate_head: 407398160bb5761d90ade7182676dd76691617be
leg_run_id: 42706539601
trailer_authorization: "publish successor core 42706539601"

tech-stack:
  added: []
  patterns:
    - "docs read from the candidate commit via CLEANROOM_DOCS_REF, published legs from the latest public version 0.2.13"
    - "remote form: generator = candidate head in the 201 worktree detached at the head, pin 0.2.14 rewritten to the public 0.2.13 in a scratch copy only"
    - "trailer check run against a scratch AUTHORIZED copy of the gate record; the committed gate record stays PENDING"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/cleanroom-candidate-docs-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/candidate-remote-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/premerge-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/premerge-result-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/premerge-gate-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/premerge-trailer-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/premerge-authorization-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/premerge-201-sources/
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/privacy-carry-201.txt
  modified: []

key-decisions:
  - "Every file with a privacy hit is dispositioned exclude-from-landing, because each carries class home_path and the disposition rule allows not-identifying only for the SSH clone-URL form and the scanner-allowed noreply address"
  - "The expected policy digest 0f851ff0... was reused from 0.2.11, 0.2.12 and 0.2.13 and matched the live branch-protection and ruleset digest again"

requirements-completed: [REL-08, REL-09]

coverage:
  - id: D1
    description: "Candidate docs pass REL-06 against published 0.2.13 on all four legs with deferred=none, read from the captured head"
    requirement: REL-08
    verification:
      - kind: integration
        ref: "cleanroom-candidate-docs-201.txt: three Task 1 verifies exit 0; result PASS legs hex,maven,ios,docs version 0.2.13; rc 0; executed=20"
        status: pass
    human_judgment: false
  - id: D2
    description: "No-flag remote form of the exact candidate head builds against the public mirror 0.2.13 with its negative control detected (REL-08 edge adjacency)"
    requirement: REL-08
    verification:
      - kind: integration
        ref: "candidate-remote-201.txt: source equals head_oid and worktree HEAD; rc=0; remote_from=0.2.14 remote_min=0.2.13 resolved=0.2.13 build_rc=0 control=detected verdict=PASS; worktree status empty after"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pre-merge REL-17 gate passes on the captured head, trailer rendered and checked, merge staged and unrun"
    requirement: REL-09
    verification:
      - kind: integration
        ref: "premerge-201.json: Task 3 jq verify exit 0; render prints 'publish successor core 42706539601'; check PASS with a scratch AUTHORIZED record; tampered-head and PENDING controls rc 1; guard predicate rc 0; PR 283 OPEN at the head"
        status: pass
    human_judgment: false
  - id: D4
    description: "Retained raw pre-merge sources scanned, with one counted disposition per file with a hit"
    requirement: REL-09
    verification:
      - kind: other
        ref: "privacy-carry-201.txt: carry: total files=23 with_hits=13; 13 carry lines with hits, 13 carry-disposition lines, 0 not-identifying"
        status: pass
    human_judgment: false

duration: "about 17 min of agent work on 2026-11-09 (22:12Z to 22:29Z)"
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 06: Candidate docs, remote-form build and pre-merge evidence Summary

**The docs that will ship in 0.2.14 (read from PR 283 head `40739816`) pass the REL-06 clean-room against published 0.2.13 on all four legs with `deferred=none` and `executed=20`; the exact head's no-flag remote form builds against the public mirror at 0.2.13 with its negative control detected; the REL-17 pre-merge gate passes on that head with the policy digest unchanged since 0.2.11, and the `publish successor core 42706539601` trailer is rendered, checked and staged in an unrun merge command. Nothing was merged, tagged, published, dispatched or pushed.**

## What was checked and what happened

- **Head unchanged.** I read PR 283 (`gh pr view`, read only) before the docs run, after it, after the remote build, before the capture and before and after the final commit. Every read said OPEN at `407398160bb5761d90ade7182676dd76691617be`, equal to `candidate-201.json`. No restart. The precondition also held: receipt state READY FOR APPROVAL and no `201-05-BLOCKED.md`.
- **Docs rehearsal (Task 1, tracer).** `CLEANROOM_DOCS_REF=<head>`, toolchain `1.19.5-otp-27` / `27.3`, no pipe, against `0.2.13`. Hex (checksum `5bc56ef49a79`), Maven (aar `76adb1341a57`), iOS (tag commit `095267ea23c9`) and docs legs all PASS. The docs line reads `executed=20 not_applicable=0 deferred=none clone=4 shown=4 source=commit:40739816... phx_new=1.8.13`, preceded by `docs source commit 40739816...`. Result `PASS legs hex,maven,ios,docs version 0.2.13`, `cleanroom: rc 0`. All three Task 1 verifies exit 0 and no `docs deferred` line exists. **`executed=20`, the same as 200-05's `executed=20` for 0.2.12** (floor 18). No `setpgid` stderr line this time (200-05 had one).
- **Remote-form build (Task 2).** In `~/projects/crosswake-201-wt` (clean before and after): `git fetch origin release-please--branches--main`, `FETCH_HEAD` equal to the head, `git switch --detach <head>`, `mix deps.get`. Source recorded right before the run, then `bash script/verify_default_ios_generation_build.sh --remote-version 0.2.13`, status read directly: `rc=0`, `mode=remote project=generated generator=40739816... generator_dirty=no remote_from=0.2.14 remote_min=0.2.13 resolved=0.2.13 build_rc=0 build_seconds=18 control_rc=65 control=detected verdict=PASS first_error=none`. Both Task 2 verifies exit 0; `git status --porcelain` in the worktree is empty. The candidate generates the 0.2.14 pin; only the scratch copy was pointed at the public 0.2.13 core, resolved from the mirror. The worktree is left detached at the candidate head, clean.
- **Pre-merge capture (Task 3).** `mix crosswake.release.gate --capture-live` for `linked_release`, package `crosswake`, version 0.2.14, PR 283, leg run id 42706539601 (the Hex rehearsal run), CI run 42703531929, receipt run 42708405663, receipt artifact 13715575685, receipt digest `aecf5b14...`, base `fdc218f9`, head `40739816`, tree `16aca5eb`, runbook commit `d3401e51` (still the `RUNBOOK_SHA` in the candidate's `release-please.yml`), expected policy digest `0f851ff0...` reused unchanged. Output `REL-17 PASS stage=pre_merge operation=linked_release next=request_exact_gate`, so branch protection and rulesets have not changed since 0.2.11. The envelope sha256 is `3ae238b2...`. The candidate-readiness fact reads `ci_conclusion success`, `policy_current true`, `receipt_artifact_live true`, `required_checks_complete true`.
- **Trailer.** `linked_release_authorization.sh render` printed exactly `publish successor core 42706539601`. `check` passed against a scratch AUTHORIZED copy of the gate record (`Gate 2 authorization binding PASS`); a trailer with a changed head and the committed (PENDING) gate record were each rejected with rc 1; the `release-please.yml` guard's jq predicate also passed on the trailer line with the live receipt facts. The staged merge command is `gh pr merge 283 --repo szTheory/crosswake --merge --match-head-commit 40739816... --subject 'Merge pull request #283 from szTheory/release-please--branches--main' --body 'REL17-AUTHORIZATION: {...}'`: no `--admin`, `--squash`, `--rebase` or `--auto`, and the shell-parsed body equals the one trailer line. `merge_executed` is false.
- **Privacy carry list.** `premerge-201-sources/` holds 23 files. I scanned each with `privacy-193.sh`, one file per invocation, absolute paths, from a `while IFS= read -r` loop over a scratch file list: 13 files have hits and 10 are clean, the same split as 200-05. Class `home_path` in all 13 (the scanner's case-insensitive match of the public `users/<name>` segment of `api.github.com` and `hex.pm/api` URLs; a case-sensitive search for the capitalised segment found no local home directory in any file). Class `email` also appears in 2 files (`live/request-1.source`, `raw/candidate_readiness.source`): the generic SSH clone-URL form. `privacy-carry-201.txt` ends `carry: total files=23 with_hits=13` with 13 `carry-disposition:` lines. The sources were not edited.

## What is unknown, and why

- The `check` result comes from a scratch copy of the gate record marked AUTHORIZED because `check` only accepts an authorized record. That proves the binding of trailer to evidence, not that anyone authorized a merge. The committed gate record stays PENDING and no `core-merge` allow exists.
- The trailer's `policy_sha256` equals the live policy only as of this capture. Plan 07 must re-read PR 283's head, state and CI, and `hex_latest` (still 2.7.0 at this plan's start; not re-read here), right before the merge. A moved head restarts from 201-05 Task 1.
- The remote-form rehearsal proves the generated project builds from the public 0.2.13 mirror with the settings file present. It cannot prove the build against the 0.2.14 mirror tag, which exists only after publication.
- The receipt artifact itself was not re-downloaded; 201-05 recorded its sha256 and the capture's `receipt_artifact_live` read true.

## Task Commits

1. **Task 1 (tracer): docs rehearsal against 0.2.13** - `f454170a`
2. **Task 2: remote-form build of the candidate** - `eef72aae`
3. **Task 3: pre-merge capture, trailer, privacy carry list** - `65c0a29b`

Measured from the plan ledger: 3 commits on `docs/199-release-0-2-12`, base `21b0b8f2`. Local only; nothing pushed.

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan variances

- **Extra Task 3 files.** The plan lists three Task 3 outputs; the gate, render and check tools read a result file, a gate record, a trailer record and an authorization input from one evidence directory, so those four were committed beside `premerge-201.json` (the 200-05 set, named `premerge-result-201.json`, `premerge-gate-201.json`, `premerge-trailer-201.json`, `premerge-authorization-201.json`). The result, gate and trailer files were built with `jq` from the retained envelope and facts; the key sets match the 200 files, and evidence paths are repo-relative.
- **Script not executable.** `script/release_candidate/linked_release_authorization.sh` has no execute bit in this checkout, so I ran it with `bash`; behaviour is identical.
- **`wc -l` verify lines** would fail on macOS space padding; no verify line of this plan used one, and the carry counts were checked numerically with `grep -c`.
- **Privacy scan of my own carry file.** My first draft of `privacy-carry-201.txt` quoted the literal SSH clone-URL text, which the scanner flagged as an email hit on the carry file itself; I reworded those note and reason lines ("the git user at github.com") and the file scans clean. Only that file was edited, never a retained source.
- **Disposition is stricter than 200-05's note.** 200-05 recorded `home_path` as a scanner artefact without a disposition. The 201 rule allows `not-identifying` only for the SSH clone-URL form and the noreply address, so `home_path` files are `exclude-from-landing`, including the 2 that also carry the SSH form.

**Total deviations:** 0 auto-fixed, 5 variances. **Impact:** none on scope or gates; no gate loosened, nothing merged, tagged, published, dispatched or approved.

## Issues Encountered

None blocking. One zsh slip in my own scratch loop (a `read` into a variable named `path`, which zsh ties to `PATH`) broke commands in that single call; I redid it in a fresh call with a different variable name before anything was committed. The faulty output was overwritten.

## Decision for Plan 08 (landing scope)

All 13 files with hits are `exclude-from-landing`. That includes `premerge-201-sources/envelope.json`, which `premerge-result-201.json` pins by sha256 and which names the other sources. `premerge-result-201.json` itself inlines the `registry_response` fact (1 `home_path` hit, the same public API URL class) and is flagged as a note, not a counted disposition. Plan 08 must either land the evidence without these files and record them with a receiver, or decide explicitly that `home_path` public API URL segments are non-identifying and say why. This plan did not make that wider call.

## Known Stubs

None.

## Threat Flags

None. Reads were unauthenticated or read-only `gh` calls; the only network effect beyond reads was `git fetch` of the release branch into the worktree and the clean-room downloads, all inside scratch or the worktree's own work root; no secret values were read or recorded.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 201-07 (the merge). Facts it needs: PR 283 head `407398160bb5761d90ade7182676dd76691617be`, trailer and staged merge command in `premerge-201.json`, remote-form PASS for the same head in `candidate-remote-201.txt`, receipt expiry 2026-11-23T22:05:52Z, `hex_latest` 2.7.0 to be re-read at the core-merge and core-hex prechecks.
- Before the merge, Plan 07 must re-read the head, state and CI. If the head moved, restart from 201-05 Task 1 with a new `core-maven-drill` display and allow.
- Nothing was merged, tagged, published, dispatched or approved. PRs 283 and others were only read; no remote branch was deleted; the worktree is left detached at the candidate head, clean.

## Self-Check: PASSED

- Files present: cleanroom-candidate-docs-201.txt, candidate-remote-201.txt, premerge-201.json, premerge-result-201.json, premerge-gate-201.json, premerge-trailer-201.json, premerge-authorization-201.json, premerge-201-sources/envelope.json, privacy-carry-201.txt.
- Commits `f454170a`, `eef72aae` and `65c0a29b` are ancestors of HEAD; the measured count from the plan ledger is 3.
- `.planning/config.json`, `.review-diagnostics/` and the phase `.gitkeep` are in no plan commit.
