---
phase: 197-public-docs-truth
plan: 08
subsystem: public-docs
tags: [docs, readme, install-guide, cleanroom-markers, bridge-hook, esbuild, attach, ios-host-deferral, d-01, d-06]

requires:
  - phase: 197-public-docs-truth
    provides: "197-04 to 197-07 docs leg: marker parser, apply modes, since=/NOT_APPLICABLE, required steps, ios_host deferral"
provides:
  - "README.md Integrating Crosswake and guides/install.md fully marked (cleanroom run/apply/clone/show) with the bridge hook, esbuild flags, a declared route, attach/1 and the :ios_host block (since=0.2.12)"
  - "197-EVIDENCE/cleanroom-docs-selftest-197.txt: final-text docs-leg run against published 0.2.11 in a real Phoenix 1.8 host, bound to both doc blobs"
affects: [197-09, 197-10, 197-13, 197-14, 199]

actuals:
  tokens: 14000
  tasks: 2
  commits: 2
plan_head_before: 9654e9c5380d0acd4286675122389e03bafa2c6f
plan_head_after: 6ad609a657151f204396fcf9822588cd178fadd3

tech-stack:
  added: []
  patterns:
    - "One documented host module (MyAppWeb.StudyLive) and one route id (study-session) shared by the router line, the attach assign and the :ios_host entry_route_id, in both docs"

key-files:
  created: []
  modified:
    - README.md
    - guides/install.md
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/cleanroom-docs-selftest-197.txt

key-decisions:
  - "The standalone heex snippet in install.md was folded into the StudyLive render/1 (its one-element comment kept) and the separate fence deleted; no test pinned it."
  - "The esbuild args fence is one line (was wrapped with a backslash) so the line-oriented esbuild-args apply mode sees every flag."
  - "The :ios_host reader sentence says 'Crosswake releases after 0.2.11' and points at the CHANGELOG [Unreleased] section; no doc test rejected the literal, so it was kept."

patterns-established:
  - "The selftest run is made without CLEANROOM_KEEP_WORK so the committed evidence holds no local paths."

requirements-completed: []

duration: 45min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 08: Marked, wired public docs executed against 0.2.11 Summary

**README §Integrating Crosswake and guides/install.md now mark every fence, carry the Hex-only wiring (bridge hook, `--external:/crosswake/*` and `--format=esm`, a declared `study-session` route, a complete `StudyLive` that calls `Crosswake.Bridge.attach()`), label every repo-only step as needing a clone, and the docs leg executes 18 steps from them against published crosswake 0.2.11 in a fresh Phoenix 1.8.13 host, with `:ios_host` the single named deferral.**

## Accomplishments

- Task 1 (tracer, `c1542d9f`): install.md has 14 fences, each preceded by one marker (`deps-crosswake`, `deps`, `install`, two `show`, `bridge-hook`, `esbuild`, `route`, `attach`, `ios-host`, a `show` for `gen.shell`, `doctor`, `phase5-example-hosts`, `native-checks`). README Integrating has the same sequence with `readme-` ids (6 apply blocks). The two clone fences in each file are followed by *Needs a clone of the Crosswake repository; skip this if you installed from Hex.* The D-06 summary line sits near the top of both files. Outside the marked scope: the italic label after the `bin/see-it-run.sh` fence, "(needs a clone)" on the two `Proof and support posture` bullets, on quick-list items 6 and 7, and on the lead-in of the `script/verify_generated_*_shell.sh` bullets. The quick list gained a step for the bridge wiring.
- The first selftest run against the real registry passed with no doc change needed. I inspected the kept host to rule out a pass that asserted nothing: the router holds the `live "/study" ... crosswake:` line, `config.exs` has `--external:/crosswake/* --format=esm` appended to Phoenix's own esbuild args, `app.js` imports `CrosswakeBridge` and registers it as `hooks: {CrosswakeBridge, ...colocatedHooks}`, `study_live.ex` is written with `CleanRoomHostWeb` names, and the harness compile and doctor ran (advisory output only).
- Task 2 (`6ad609a6`): the final-text run printed `cleanroom: leg docs PASS 0.2.11 executed=18 not_applicable=2 deferred=ios_host clone=4 shown=4 ... phx_new=1.8.13`, two `docs deferred ios_host <file> since=0.2.12 version=0.2.11` lines, `result SELFTEST`, `rc 0`, then the two blob lines (`README.md f4ef35cd...`, `guides/install.md 56a192a8...`). Both blobs still equal the working-tree blobs and neither doc changed after the run.

## Task Commits

1. Task 1: marked and wired docs, preliminary evidence: `c1542d9f` (docs)
2. Task 2: final-text evidence with blob lines: `6ad609a6` (docs)

## Verification Run (all through `script/mix_test_gate.sh`)

- Task 1 gate (architecture walkthrough, adopter profile, compat matrix): ran=22, failures=0, min 22: PASS.
- Task 2 gate (guides dir, adopter profile, compat matrix, hex page, published_cleanroom, renderer): ran=344, failures=0, min 303: PASS.
- Every other test file that reads the docs (14 files under `test/crosswake` and `test/mix/tasks`): ran=204, failures=0, min 100: PASS.
- Reader list: `grep -rlE 'README\.md|guides/install\.md|"install\.md"' test/` returned **34** paths: 30 `.exs` test files (all run above: 11 under `test/crosswake/guides`, `docs_report`, `doctor_test`, `doctor_threadline`, `hex_page`, `adopter_profile_contract`, `phase132_compat_matrix_drift`, `phase153_ios_mirror_unblock`, `phase165_ci_integrity`, `phase165_ci_policy`, `phase60_chimeway_registry`, `published_cleanroom`, `repository_root_allowlist`, `renderer_test`, and six under `test/mix/tasks`) plus `test_helper.exs` (31 `.exs` in all), two JSON fixtures and `phase167_pr_dispositions.test.mjs`, which only names README.md as an example path.
- `mix format --check-formatted` on the ten listed test files: clean (no test file was edited).
- Acceptance greps: `docs deferred ios_host` lines 2; `since=0.2.12` 1 per file; `cleanroom:` in install.md 14 (at least 13); `cleanroom:apply` in README 6 (at least 6); clone label 2 in install.md and 2 in README; `study-session` 3 in install.md; `git log origin/main..HEAD -- .planning/config.json` prints nothing.
- Privacy scan (`privacy-193.sh`, absolute paths) over the docs and evidence: clean before each commit. No push was made.

## Deviations from Plan

None - plan executed as written. No test pinned a deleted line (planning-time `grep -rnF` for `ONE element per page` and the old `my-route` fragment re-run before editing: no hits in `test/` or `lib/` other than the unrelated moduledoc and test helper), so no pinning test was edited.

## Notes for 197-09

- **The measured executed count is 18** (README 9 and install 9 under the real-registry run, including each file's harness `compile` step). `DOCS_EXECUTED_FLOOR` is still the placeholder `1`; 197-09 must pin it to 18 and 197-13 and 197-14 must not start while it is 1.
- Case (b) boundary (config that executes cleanly but that 0.2.11 never reads): beyond `:ios_host`, no further step of this kind was found by execution; the reader audit in 197-09 still has to confirm each executed step has a reader in the 0.2.11 tarball.
- The `:ios_host` reader sentence points at the CHANGELOG `[Unreleased]` section; 197-11 adds that bullet.

## Known Stubs

None.

## Threat Flags

None. T-197-17 is mitigated (every step except the named `:ios_host` deferral executed against 0.2.11, clone-labelled repo-only steps); T-197-18 holds (synthetic values only: `study-session`, `clean_room_host`, placeholder team id; privacy scan clean). No new dependency (T-197-SC-08).

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: 197-09 and later plans also carry it.

## Self-Check: PASSED

- FOUND: README.md, guides/install.md, 197-EVIDENCE/cleanroom-docs-selftest-197.txt
- FOUND commits: `c1542d9f`, `6ad609a6` (ancestors of HEAD); `commits: 2` measured from ledger base `9654e9c5`; no file deletions
