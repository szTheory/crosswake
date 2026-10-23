---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
plan: 04
status: complete
requirements: [TWIN-01, TWIN-06]
commits: 0
---

# Phase 183 Plan 04: Twin-04 inputs from committed bytes

Summary: the twin-04 prepared record, the superseding identity file, the preflight and the one-shot run wrapper now exist and were built only from committed bytes at the fix(183-03) commit (50fcd574). The twin was not run and no twin-04 run root exists.

## What was checked and what happened

- `prepare-record.sh` was proven on a scratch repo first: clean tree exit 0 (record mode 600, all four digests equal to `git show` hashes), second run to the same output exit 5 (record_exists), untracked file exit 3 (source_dirty). The scratch dir was deleted.
- The real record `twin-04-candidate.json` (mode 600) was then written. It names head 50fcd574 and tree d71bc587. Manifest, activation, study script and media digests are byte-identical to twin-02's (the fix commit did not touch those files).

Old (twin-02) versus new (twin-04):

| Field | twin-02 | twin-04 |
|---|---|---|
| head | da53c54d | 50fcd574 |
| tree | d1cbbe30 | d71bc587 |
| manifest / activation / study_js / media digests | same | same |

- `183-IDENTITY.json` written (plain uncommitted file): supersedes `180-IDENTITY.json`, head and tree of the fix commit, media size 33706 plus sha256, manifest and activation sha256, all computed from `git show`. Its media digest equals the record's.
- `preflight-04.sh`: exit 1 with "clean probe failed" on a clone with a stray untracked file; exit 0 ("preflight: ok") on the real candidate. `twin-run-count.before-04` = 3.
- `run-once-04.sh` is written (zsh, set -eu, preflight, 0700 root, .started, twin-run-path-04, .exit with set +e only around the run) and was NOT executed.

## Deviations

**[Rule 3 - Blocking] gen.shell check runs under MIX_ENV=test.** The plan said the plain default environment. Plain `mix crosswake.gen.shell ios --check` reports "stale" (the manifest depends on MIX_ENV; the frozen digests are the test ones, as 180-05 and 180-06 already recorded). The preflight therefore runs it with `MIX_ENV=test`, which reports current, and re-checks that the candidate is still clean afterwards.

Other note: the dirty-clone smoke clone ignored `--local` because the candidate is shallow; harmless.

## Boundaries kept

- Candidate: HEAD still 50fcd574, porcelain empty, nothing edited or committed.
- Recovery checkout: nothing staged, HEAD d0f3e2f1. Planning-doc commits were skipped (commit_docs ignored per the hard rules); STATE.md and ROADMAP.md untouched.
- `shasum -a 256 -c history-183.before.sha256` passes; twin-01..03 history and twin-02 record untouched.
- Files written (outside the repo): `/private/tmp/crosswake-phase180-run/{prepare-record.sh,twin-04-candidate.json,preflight-04.sh,run-once-04.sh,twin-run-count.before-04}`.

## Known Stubs

None.

## Self-Check: PASSED
