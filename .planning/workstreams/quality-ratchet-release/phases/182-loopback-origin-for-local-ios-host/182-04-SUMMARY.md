---
phase: 182-loopback-origin-for-local-ios-host
plan: 04
subsystem: proof-lane-inspect-guides
tags: [proof-lane, inspect, guides, origin_mode, local_loopback]
requires: ["182-03"]
provides:
  - "Physical proof lane refuses local_loopback at load_host_config/1 (including --config) and Generator.normalize_host!/1"
  - "mix crosswake.inspect human trailing 'host origin:' line"
  - "Renderer strings, regenerated support_matrix/capability_map guides, native_shell paragraph, upgrade note"
affects: [182-05]
status: complete
commits: 4
plan_head_before: 1d569e553577800961c8b0d4ee253afaabc64e4b
plan_head_after: 9456e5cf799dea8fdf5ffd96655636c582c27351
actuals:
  tokens: 45000
  tasks: 3
  commits: 4
---

# Phase 182 Plan 04: Proof lane refusal, inspect line, guides Summary

The physical proof lane now refuses a local-loopback host config everywhere it can start, `mix crosswake.inspect` names the host origin in human output, and the support truth and guides describe the mode and its limits. All work is in `/private/tmp/crosswake-phase182-impl` on `phase182-impl`; the recovery checkout was not written to except this file.

## What was checked and what happened

- Candidate binding check passed before any edit.
- Task 1 verify (verbatim): exit 0, proof-lane test file 32 tests, 0 failures (9 new tests).
- Task 2 verify (verbatim): exit 0, inspect + phase52 14 tests, 0 failures; fixtures and operator_inspection untouched. RED was committed first (3 intended failures).
- Task 3 verify (verbatim, including freeze checks, docs.sync --check, ownership script): exit 0, 342 tests, 0 failures (7 excluded).
- Full suite (2300 tests, 78 excluded): 1 failure, the known open item `Phase134TemplateVersionDriftTest` (template hash, caused by 182-01's Info.plist.eex change). Untouched as instructed.

## Behavior

- `--config PATH` branch of `gen.proof_lane` now reads `Application.get_env(:crosswake, :ios_host)` and refuses with the D-10 string when the declaration carries `origin_mode: :local_loopback` (keyword or map, even if normalize would reject it). HTTPS or absent declarations keep `{:ok, nil}`. The message contains no origin.
- Generator `normalize_host!/1` raises `ArgumentError` with the exact D-10 string for a local struct and a raw local declaration, so generate/check/diff all refuse. The string lives in `Generator.local_mode_refusal/0`, reused by the Mix task.
- Inspect: human format appends `host origin: <canonical>` (with the local-loopback suffix in local mode); none for no/invalid declaration; JSON byte-equal.
- Renderers keep their HTTPS wording and add the local-mode clause; guides regenerated with `mix crosswake.docs.sync`. `native_shell.md` has the new paragraph (including the stale README banner note); `native_shell_upgrade.md` has the exact-block Info.plist note. No arbitrary-loads or exception-domain ATS key in any guide; WKAppBoundDomains not mentioned.

## Deviations from Plan

None - plan executed as written. (A first test draft used the wrong return shapes for `Generator.check/diff`; fixed in the test before commit.)

## Known Stubs

None.

## Commits (phase182-impl)

- bb43280 feat(182-04): physical proof lane refuses local loopback host config
- 0e6e711 test(182-04): RED for inspect host origin line
- bfc69f4 feat(182-04): inspect names the host origin mode in human output
- 9456e5c docs(182-04): describe local loopback mode in support truth and guides

Candidate head 9456e5cf799dea8fdf5ffd96655636c582c27351, tree 25c8b8157b9128d81a730913d82a1f31e31db933; clone tree clean.

## Next action

Execute 182-05. The orchestrator still owns the Phase 134 template-hash drift item.

## Self-Check: PASSED
