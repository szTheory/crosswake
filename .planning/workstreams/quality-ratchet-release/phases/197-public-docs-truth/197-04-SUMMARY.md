---
phase: 197-public-docs-truth
plan: 04
subsystem: release-tooling
tags: [cleanroom, docs-leg, marker-parser, env-scrub, process-group-timeout, need-tools, d-07a]

requires:
  - phase: 197-public-docs-truth
    provides: "197-03 hardened fetch, per-leg need_tools, mix_test_gate"
provides:
  - "script/verify_published_cleanroom.sh: fourth leg `docs` (commit-pinned README.md + guides/install.md, marker parser, pinned phx_new host, scrubbed-env run-block executor, per-step time bound)"
  - "published_cleanroom_test.exs: hermetic mix-stub proof incl. the D-07a doctor mutation control, env sentinel with an unscrubbed mutation control, per-tool removal loop, timeout, interrupt and invalid-bound cases"
affects: [197-05, 197-06, 197-07, 197-09, 197-13, 197-14, 199]

actuals:
  tokens: 9600
  tasks: 3
  commits: 3
plan_head_before: 2af935def77678ad31a191d6dc453cc0b9eb64d9
plan_head_after: 76eba5d885d270a7750467c734a6879d16ae7dff

tech-stack:
  added: []
  patterns:
    - "dependency-free awk fence parser mirroring strip_fences/1; one awk call per file, ids carried across files through a scratch file"
    - "env -i allowlist for documented steps, proven by a captured-environment sentinel test plus a mutation control that removes the scrub"
    - "job-control process group + watchdog subshell for a per-command time bound; flag file distinguishes timeout from a command that exits 124 itself"

key-files:
  created: []
  modified:
    - script/verify_published_cleanroom.sh
    - test/crosswake/release/published_cleanroom_test.exs

key-decisions:
  - "A failed run block stops only its own file's sequence; the other file still runs, so one run reports both docs' failures (plan text: `stops that file's sequence`)."
  - "Parse reasons beyond the plan's list were added so that absence cannot read as success: unterminated_fence, no_fences (a file with no fence in scope), readme_scope_missing (no `### Integrating Crosswake` heading), bad_id (id not [A-Za-z0-9_-]+, since it names a file)."
  - "`since=`, `file=` and `mode=` are accepted and recorded by the parser but not acted on; `since=` steps still execute until 197-07, and `apply` fails the leg with parse apply_unsupported until 197-06."
  - "docs_bounded signals a timeout through DOCS_BOUND_TIMEOUT, not an exit code, so a step that itself exits 124 is reported as `exit 124`, not as a timeout."

patterns-established:
  - "Interrupt path: trap INT TERM only while a bounded command runs, kill the group, name the step, print result FAIL, exit 1 (never 0)"

requirements-completed: []

duration: 95min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 04: docs leg in the clean-room script Summary

**`verify_published_cleanroom.sh` now has a fourth `docs` leg that fetches README.md and guides/install.md at a 40-hex commit, parses every marked fence, builds a pinned `phx_new 1.8.13` Phoenix host with assets, and runs each `run` block verbatim under `bash -e` with an allowlisted environment and a per-step process-group time bound; the D-07a doctor mutation fails exactly `cleanroom: FAIL docs step doctor exit 1`.**

## Accomplishments

- Task 1 (tracer): `DEFAULT_LEGS=hex,maven,ios,docs`, `docs` in the leg allowlist, `CLEANROOM_DOCS_REF` validated against `^[0-9a-f]{40}$` (a selector: accepted without selftest, bad value exits 2 before any fetch), `CLEANROOM_DOCS_BASE` and `CLEANROOM_KEEP_WORK` added to the refusal chain, `DOCS_DEFAULT_BASE` and `PHX_NEW_VERSION` constants. Docs come only through `fetch` (the BASH_SOURCE / dirname / rev-parse refutations stay green). The marker parser follows the plan: README scope is the `### Integrating Crosswake` section, install.md is whole, a trimmed line starting with three backticks toggles a fence, the nearest preceding non-blank line must be a `cleanroom:` marker. PASS line: `cleanroom: leg docs PASS <v> executed=<n> not_applicable=0 clone=<n> shown=<n> source=commit:<ref> phx_new=<v>`.
- Task 2: the sentinel test passes the caller credential as an env tuple (never a `KEY=value` literal); the captured environment is non-empty, never contains the sentinel, `HOME`, `MIX_HOME` and `HEX_HOME` all start with the work dir printed by `CLEANROOM_KEEP_WORK=1`, and every captured variable name is in the allowlist. A mutation control (copy of the script with `env -i` removed) leaks the sentinel, so the refute can go red. `need_tools docs` is the first statement of `leg_docs`; a loop over the live list removes each tool in turn (`awk` and `env` also as named tests); every case is exactly `FAIL docs tool_unavailable`, no `leg docs PASS`, and the capture stub (placed as `mix` in the test PATH) never wrote its file. A static test (with an injected-`sort` control) requires every command word used in a docs function to be listed.
- Task 3: `docs_bounded` runs each command as a job-control background group, a watchdog in its own group sends TERM then KILL after 5 s, and a flag file marks a timeout. `CLEANROOM_DOCS_STEP_TIMEOUT` (default 900, `^[1-9][0-9]*$`, otherwise usage exit 2) is a selector. Timeout prints `cleanroom: FAIL docs step <id> timeout <secs>`; INT/TERM prints `... interrupted` followed by `result FAIL`, exit 1; the step's whole group (including a background `sleep`) is dead afterwards. All four host-generation commands go through it as step `host_setup`.
- Real smoke (not committed evidence): with the repo's toolchain selectors, real `mix archive.install hex phx_new 1.8.13` and `mix phx.new ... --no-install --no-version-check` ran under the scrubbed env; the generated host has `assets/js/app.js` (assets enabled) and two real run blocks passed in about 3.5 s. Without the selectors asdf reports `No version is set for command mix` in the isolated HOME and the leg is `tool_unavailable`; callers on asdf must set `CLEANROOM_ELIXIR_VERSION` and `CLEANROOM_ERLANG_VERSION` exactly as for the hex leg.

## Task Commits

1. Task 1: docs leg with commit-pinned sources and run-block executor: `4b466137` (feat)
2. Task 2: scrubbed env and complete tool list proof: `3ddc790f` (test)
3. Task 3: `docs_bounded` per-step time bound: `76eba5d8` (feat)

## Verification Run

- `published_cleanroom_test.exs` through `script/mix_test_gate.sh`: 39 tests after Task 1 (floor 29), 46 after Task 2 (floor 33), 51 after Task 3 (floor 36), 0 failures each, verdict PASS. Baseline at plan start was 26.
- `absence_is_not_success_test.exs`: 59 tests, PASS (floor 59), after each task.
- `bash -n` clean; `mix format --check-formatted` clean; `CLEANROOM_DOCS_REF=xyz bash script/verify_published_cleanroom.sh 0.2.11` exits 2; `CLEANROOM_DOCS_STEP_TIMEOUT=abc` exits 2; the `need_tools docs` awk check exits 0; the no-`rm`-in-docs-functions awk check exits 0 (at least five docs functions); `grep -cE 'HEX_API_KEY[[:space:]]*[=:]'` on the test file prints 0; `git log origin/main..HEAD -- .planning/config.json` prints nothing. Privacy scan (`privacy-193.sh` through bash) over both changed files: clean. No push was made.

## need_tools audit (non-builtin commands the docs leg calls)

| Tool | Function (line in final script) |
|---|---|
| curl | `fetch` via `docs_fetch_sources` (348, 350) |
| mkdir | `docs_fetch_sources` 347, `docs_make_host` 574 |
| awk | `docs_parse_file` 365, `docs_parse` 467 |
| head | `docs_parse_file` 453 |
| env | `docs_env` 485 |
| bash | `docs_step_exec` 598 |
| mix | `docs_make_host` 582-585 |
| cp | `docs_make_host` 590-591, `docs_run_step` 604 |
| sleep | `docs_interrupt` 503, `docs_bounded` watchdog 528, 531 |
| mktemp | `mk_work` (called first thing in `leg_docs`) |
| sed, grep, tr, tail, cut, tar, gzip | listed per the plan's starting list; not called by any docs function today. `tar` and `gzip` are for the Hex tarball default (197-05); the rest are headroom for the `apply` modes (197-06). They only make the leg stricter. |
| rm | none; only the script-level EXIT `cleanup` trap |
| perl | not added: `set -m` job control works without a tty (proven by the hermetic timeout and interrupt tests, which run without one) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Existing source refutation flagged copying `.tool-versions`**
- **Found during:** Task 1 verify (`the script locates nothing relative to itself or a checkout` failed on `cp ... tool-versions`)
- **Issue:** copying the setup dir's version file into the template matched the refutation that forbids copying a version file.
- **Fix:** the file is written with `printf` in both places; nothing is copied.
- **Commit:** `4b466137`

**2. [Rule 1 - Bug] Interrupt path printed shell job noise**
- **Found during:** Task 3 manual interrupt run
- **Issue:** the main shell printed a `Killed: 9 ( sleep ... )` job notice for the watchdog before the FAIL line.
- **Fix:** `docs_interrupt` reaps both jobs with `wait ... 2>/dev/null`; the output is now exactly the FAIL line and the result line.
- **Commit:** `76eba5d8`

**3. [Rule 2 - Missing critical] Extra fail-closed parse reasons**
- `no_fences`, `readme_scope_missing`, `unterminated_fence`, `bad_id` (see key-decisions). Without them an empty or unscoped file would parse to zero steps and read as success; a path-bearing id could write outside the steps dir.
- **Commit:** `4b466137`

**4. [Rule 2 - Missing critical] Step stdin closed**
- Every documented step and host-generation command runs with stdin from `/dev/null`: the run loop reads `steps.tsv` on its own stdin and a step could otherwise consume the step list.
- **Commit:** `4b466137`

**5. [Process] Task 2 changed no script text**
- The scrub (`docs_env`) and the first-statement `need_tools` were already written in Task 1; Task 2's commit is the proof (tests only), and the audit above is the Task 2 audit.

### Left as the plan specified
- phx_new stays at 1.8.13 (real install and generation succeeded); no version change to record.
- `since=` is parsed and recorded but ignored; the NOT_APPLICABLE logic, required-step list, `deferred=` field and executed floor are 197-07, `apply` is 197-06, the Hex-tarball default source and real-network smoke are 197-05.

## Known Stubs

None. The `parse no_docs_source` failure when no ref is given is the intended interim behavior until 197-05.

## Threat Flags

None. The new network surface is the existing `fetch` to `raw.githubusercontent.com` at a 40-hex commit (T-197-11). T-197-10 (scrub), T-197-12 (provenance printed, no sibling reads), T-197-13 (time bound) and T-197-SC-04 (phx_new pinned, isolated MIX_HOME inside the work dir) are mitigated and tested as listed above.

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: 197-05 to 197-07 and later plans also carry it.

## Self-Check: PASSED

- FOUND: script/verify_published_cleanroom.sh, test/crosswake/release/published_cleanroom_test.exs
- FOUND commits: 4b466137, 3ddc790f, 76eba5d8 (ancestors of HEAD); `commits: 3` measured from the ledger base `2af935de`; no file deletions in any commit
- `.planning/config.json` still shows an uncommitted modification and is in no commit.
