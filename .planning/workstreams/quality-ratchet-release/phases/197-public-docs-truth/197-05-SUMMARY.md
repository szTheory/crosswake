---
phase: 197-public-docs-truth
plan: 05
subsystem: release-tooling
tags: [cleanroom, docs-leg, hex-tarball, erl-tar, real-network-smoke, d-03]

requires:
  - phase: 197-public-docs-truth
    provides: "197-04 docs leg (marker parser, pinned phx_new host, scrubbed-env run-block executor)"
provides:
  - "script/verify_published_cleanroom.sh: default docs source is the Hex tarball of the version under test (HEX_REPO_DEFAULT, CLEANROOM_HEX_REPO selftest override); PASS line field source=tarball"
  - "published_cleanroom_test.exs: hermetic tarball-source tests built with :erl_tar"
  - "Real-network evidence: published 0.2.11 tarball read from repo.hex.pm; run-block tracer proven on the real toolchain"
affects: [197-06, 197-07, 197-09, 197-13, 197-14, 199]

actuals:
  tokens: 6200
  tasks: 2
  commits: 1
plan_head_before: 24122c326b0293de34af2701fbc70fb7a44fb6cb
plan_head_after: 01bbade3986492c2e1fd278bec4d53a9c3a535f9

tech-stack:
  added: []
  patterns:
    - "Hex tarball = outer tar holding contents.tar.gz; two-step extraction of only the named members into a dir inside the work dir, with symlink and regular-file checks"
    - "Hermetic tarball fixtures built with :erl_tar (outer uncompressed around a :compressed inner), no external tar in the test"

key-files:
  created: []
  modified:
    - script/verify_published_cleanroom.sh
    - test/crosswake/release/published_cleanroom_test.exs

key-decisions:
  - "A ref wins over the tarball: CLEANROOM_DOCS_REF set means the commit source is used and the Hex repo is never read (tested)."
  - "Extraction failure of a member is `fetch <member>`, fetch or outer/inner-archive failure is `fetch tarball`; a tarball for a different version is `fetch tarball` (the URL carries the version)."
  - "Extracted members must be regular files and neither the member nor `guides` may be a symlink; the files are then copied (cp is already in the need_tools list, so no new command word)."

patterns-established:
  - "DOCS_SOURCE variable carries `tarball` or `commit:<ref>` from the fetch step to the PASS line."

requirements-completed: []

duration: 25min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 05: Hex tarball docs source and real-network smoke Summary

**Without `CLEANROOM_DOCS_REF` the docs leg now reads README.md and guides/install.md from `repo.hex.pm/tarballs/crosswake-<v>.tar` (only those two members extracted), so docs and code are one artifact; against the real published 0.2.11 it prints the tarball source line and fails `parse unmarked_fence README.md`, and a real-network smoke generated a pinned Phoenix host, ran real `mix deps.get` under the scrubbed env, and failed exactly `step doctor exit 1`.**

## Accomplishments

- Task 1 (tracer): `docs_fetch_tarball` fetches through the existing https-pinned `fetch`, runs `tar -xf <tar> -C <dir> contents.tar.gz`, then `tar -xzf contents.tar.gz -C <dir> README.md` and `... guides/install.md` one member at a time. A fetch failure, a non-tar file or a missing `contents.tar.gz` is `fail docs "fetch tarball"`; a missing member is `fail docs "fetch <member>"`. `no_docs_source` is gone from the script (0 occurrences). `CLEANROOM_HEX_REPO` joined the selftest refusal chain and `@selftest_env`. The header names `CLEANROOM_DOCS_REF` (selector), `CLEANROOM_DOCS_BASE`, `CLEANROOM_HEX_REPO` and `CLEANROOM_KEEP_WORK` (selftest overrides) and says a default run against a version without markers fails `parse unmarked_fence` (0.2.11 and earlier).
- Tests (hermetic, `:erl_tar` fixtures): default tarball source passes with `source=tarball`; no `guides/install.md`; no `README.md`; missing tarball; tarball of another version; non-tar garbage; only the two named members extracted (kept work dir inspected: `mix.exs`, `guides/other.md`, `lib` absent); ref wins over the tarball; `CLEANROOM_HEX_REPO` refused without selftest (exit 2); default URL and refusal-chain source checks; header names every override. The old `no_docs_source` test was replaced by these.
- Task 2: the networked smoke passed first time (see below). It changed no file, so it has no commit of its own; the Task 1 commit holds all code.

## Real-registry evidence

Tarball source, no `CLEANROOM_HEX_REPO`, no ref, no pipe (`CLEANROOM_LEGS=docs`, toolchain selectors, real repo.hex.pm):

```
cleanroom: selftest overrides active
cleanroom: docs source tarball crosswake-0.2.11.tar
cleanroom: FAIL docs parse unmarked_fence README.md
cleanroom: result FAIL legs docs version 0.2.11
rc 1
```

Run-block smoke (docs base `file://$TMPDIR/cw-197-docs-smoke-base`, ref `0000...0000`, run blocks `readme-deps`, `deps` = `mix deps.get`, `doctor` = `mix crosswake.doctor`; real `mix local.hex`, `archive.install hex phx_new 1.8.13`, `phx.new` with assets, real `mix deps.get` from hex.pm, all under the scrubbed env):

```
cleanroom: selftest overrides active
cleanroom: docs source commit 0000000000000000000000000000000000000000
cleanroom: toolchain elixir 1.19.5-otp-27 erlang 27.3
cleanroom: FAIL docs step doctor exit 1
cleanroom: result FAIL legs docs version 0.2.11
rc 1
```

Elapsed time of the leg: 34 s wall clock. No `tool_unavailable`, no `readme-deps` or `deps` failure. A second run with `CLEANROOM_KEEP_WORK=1` (not committed evidence) confirmed the cause in `docs.log`: `** (Mix) The task "crosswake.doctor" could not be found`, after the host compiled (`Generated clean_room_host app`). Work dirs and temp files were deleted; `ls -d $TMPDIR/crosswake-cleanroom.*` finds nothing.

## Superseded smoke attempts

None. The first smoke attempt reached the doctor step with the expected output.

## Task Commits

1. Task 1: Hex tarball default docs source, hermetic tests: `01bbade3` (feat)
2. Task 2: smoke only, no file change, no commit.

## Verification Run

- `published_cleanroom_test.exs` through `script/mix_test_gate.sh`: 61 tests, 0 failures, verdict PASS (floor 40), after Task 1 and again at the end. Baseline at plan start was 51.
- `test/crosswake/proof/absence_is_not_success_test.exs`: 59 tests, PASS (floor 59).
- `mix format --check-formatted` clean on the changed test file; `bash -n` clean; `grep -c no_docs_source script/verify_published_cleanroom.sh` is 0.
- Privacy scan (`privacy-193.sh` through bash, absolute paths) over both changed files: clean, exit 0. No push was made.
- `git log --format=%H origin/main..HEAD -- .planning/config.json` prints nothing; `.planning/config.json` is still an uncommitted modification and is in no commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Symlink guard on extracted members**
- **Found during:** Task 1
- **Issue:** extracting two named members from an untrusted tarball could still yield a symlink (member or `guides`) that `cp` would follow outside the extraction dir.
- **Fix:** each member must be a regular file and neither it nor `guides` may be a symlink; otherwise `fetch <member>`.
- **Commit:** `01bbade3`

**2. [Process] Task 2 changed no script text**
- The smoke passed on the 197-04 code, so Task 2 has no commit; its evidence is above and in the temp output the plan told us to delete.

**3. [Process] Extra tests beyond the four named cases**
- Added: missing `README.md`, different-version tarball, non-tar file, named-members-only extraction, ref-wins, header check. These cover T-197-16 and T-197-33 more completely than the four required cases.

## Known Stubs

None.

## Threat Flags

None. Network surface added is one `fetch` to `https://repo.hex.pm/tarballs/crosswake-<v>.tar` through the existing https-pinned fetch (T-197-33); extraction is limited to two named members inside the work dir (T-197-16); the smoke's installs run inside the throwaway work dir (T-197-SC-05).

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: 197-06 and later plans also carry it.

## Self-Check: PASSED

- FOUND: script/verify_published_cleanroom.sh, test/crosswake/release/published_cleanroom_test.exs
- FOUND commit: 01bbade3 (ancestor of HEAD); `commits: 1` measured from ledger base `24122c32`; no file deletions
