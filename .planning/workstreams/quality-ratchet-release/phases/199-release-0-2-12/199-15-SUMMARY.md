---
phase: 199-release-0-2-12
plan: 15
subsystem: release
tags: [rel-06, rel-07, cleanroom, reader-audit, sc5, sc6, published-0.2.14]
status: complete

requires:
  - phase: 199-release-0-2-12
    provides: "published core 0.2.14 (release run 42713010358, COMPLETE); D-27 target amendment"
provides:
  - "SC5 (as amended by D-27) met on published 0.2.14: REL-06 PASS on all four legs, docs read from the Hex tarball, deferred=none, executed=20"
  - "Reader audit of the published 0.2.12, 0.2.13 and 0.2.14 tarballs: every SC6 claim and the four CHANGELOG-only claims found in all three; first release 0.2.12 for each"
affects: [199-16, 199-17, 199-18, 199-19]

plan_head_before: 35fd2d6d4359e878663ec9ba299c8770c36ec915
plan_head_after: 83d250a81c1fd6c264bab392ba56e9856a104241
commits: 2

actuals:
  tokens: 12000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Clean-room run 1 is kept unchanged in its own file; the counted file is a byte copy when run 1 passes"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/cleanroom-0.2.14-run1-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/cleanroom-0.2.14-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/cleanroom-reader-audit-199.txt
  modified: []

key-decisions:
  - "Run 1 passed, so no second run was made; cleanroom-0.2.14-199.txt is a byte copy (cmp verified) of cleanroom-0.2.14-run1-199.txt"

requirements-completed: []
---

# Phase 199 Plan 15: Clean-room against published 0.2.14 and reader audit Summary

The REL-06 clean-room command passed all four legs against the published 0.2.14 artifacts with the docs read from the Hex tarball and no override, and a reader audit shows every SC6 claim already shipped in 0.2.12 and still present in 0.2.13 and 0.2.14.

## What was checked and what happened

**Task 1 (tracer), commit cd7dc761.** Preconditions read first: Hex tarball `crosswake-0.2.14.tar` HTTP 200, Maven POM 0.2.14 HTTP 200, mirror tag `refs/tags/v0.2.14` at `095267ea23c94cf397b620ab5015a7bf19377660`. Ran
`CLEANROOM_ELIXIR_VERSION=1.19.5-otp-27 CLEANROOM_ERLANG_VERSION=27.3 bash script/verify_published_cleanroom.sh 0.2.14` with no pipe and no override. Output lines that decide SC5:

```
cleanroom: leg hex PASS 0.2.14 checksum 2b336242c38f
cleanroom: leg maven PASS 0.2.14 aar 76adb1341a57
cleanroom: leg ios PASS 0.2.14 tag_commit 095267ea23c9
cleanroom: docs source tarball crosswake-0.2.14.tar
cleanroom: leg docs PASS 0.2.14 executed=20 not_applicable=0 deferred=none clone=4 shown=4 source=tarball phx_new=1.8.13
cleanroom: result PASS legs hex,maven,ios,docs version 0.2.14
cleanroom: rc 0
```

`docs deferred` appears 0 times (0.2.11 printed 2); no `CLEANROOM_SELFTEST` or `docs source commit` line; executed 20 is above the 0.2.11 count of 18. All four plan verify commands passed. The script on the local branch is identical to origin/main's (`git diff HEAD origin/main -- script/verify_published_cleanroom.sh` empty).

**Task 2, commit 83d250a8.** Downloaded each Hex tarball into its own scratch directory under the session scratchpad (outside the repository), extracted the outer tar and `contents.tar.gz`, and searched with fixed-string greps. Nothing extracted was executed. All fetches rc 0, HTTP 200; each tree has 159 `.ex` files under `lib/`. The three SC6 lines and the first-release line, as recorded in `cleanroom-reader-audit-199.txt`:

```
reader-audit: ios_host reader=Application.get_env(:crosswake, :ios_host) in extracted lib/ 0.2.12=found 0.2.13=found 0.2.14=found
reader-audit: schema_1_2_0 reader=@manifest_schema_version "1.2.0" in extracted lib/crosswake/manifest/types.ex 0.2.12=found 0.2.13=found 0.2.14=found
reader-audit: parity_ledger reader=lib/crosswake/parity_ledger/renderer.ex present in extracted contents 0.2.12=found 0.2.13=found 0.2.14=found
reader-audit: first_release ios_host=0.2.12 schema_1_2_0=0.2.12 parity_ledger=0.2.12
```

The four CHANGELOG-only claims (`host_command_seam`, `legacy_manifest_denial`, `doctor_offline_fidelity`, `nav_shell_provenance`) are found in all three versions; the file records `first_release_changelog_only ...=0.2.12` for each. The Phase 197 0.2.11 comparison line (`ios_host ... 0.2.11=not_found disposition=deferred`) is carried at the end. Both plan verify commands (format check and the awk first_release cross-check) passed.

Note for 199-16/199-17: the `:ios_host` read is by `Application.get_env(:crosswake, :ios_host)` in `lib/mix/tasks/crosswake.gen.shell.ex` in all three; 0.2.13 additionally reads it in `crosswake.gen.proof_lane.ex`. The audit supports naming 0.2.12 as the first release for each claim, but 0.2.12 and 0.2.13 are not complete releases (D-27), so any guide sentence that tells a reader to install a version should name 0.2.14.

## Deviations from Plan

None - plan executed exactly as written. The `reader-audit: fetch V rc <n> http <code>` lines were written from the observed curl result (rc 0, HTTP 200 for each) by a scratch script that also computed the claim lines.

## Privacy scan

`privacy-193.sh` over the three evidence files (absolute paths as separate args, bash): `privacy: clean files 3`, rc 0. 199-19 decides landing dispositions.

## Irreversible changes

None. Read-only proof on published artifacts; two local commits on `docs/199-release-0-2-12`, nothing pushed.

## Known Stubs

None.

## Threat Flags

None.

## Unknowns

- The clean-room run executes at one moment against live registries; it is not a standing guarantee for later times.
- The local branch is behind origin/main (PR 289, 290, 291 not merged in); the plan's files and the script are unaffected, but 199-19 will need to reconcile.

## Self-Check: PASSED

- Files found: cleanroom-0.2.14-run1-199.txt, cleanroom-0.2.14-199.txt, cleanroom-reader-audit-199.txt
- Commits found: cd7dc761, 83d250a8
