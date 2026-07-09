---
phase: 139-crosswake-threadline-extraction
plan: "03"
subsystem: crosswake_threadline
status: complete
tags: [publish-pipeline, release-please, cleanroom-proof, ci, threadline, independent-versioning, vacuity-safe]
dependency_graph:
  requires: [139-02-PLAN]
  provides: [threadline-release-please-component, publish-hex-threadline-job, cleanroom-proof-threadline-job, zero-sibling-dep-ci]
  affects:
    - script/verify_companion_cleanroom.sh
    - release-please-config.json
    - .release-please-manifest.json
    - .github/workflows/release-please.yml
    - examples/phoenix_host/mix.exs
    - guides/companion_compatibility.md
tech_stack:
  added:
    - crosswake_threadline as independent elixir release-please component (separate-pull-requests, one-shot release-as 0.1.0, NOT in linked-versions)
    - publish-hex-threadline CI job (CROSSWAKE_RELEASE=1, per-component gate on threadline_release_created)
    - clean-room-proof-threadline CI job (no-engine non-companion mode, zero-sibling-dep invariant at CI level)
    - threadline_release_created/tag_name/version output aliases in release-please job
  patterns:
    - suppress-guard pattern: companion-behaviour assertions SUPPRESSED for non-companion packages (if PACKAGE != crosswake_threadline)
    - module-shipment canary pattern: three canaries replace companion-behaviour assertions for threadline (Telemetry/Plug/Ledger)
    - zero-sibling-dep mode: no-engine non-companion invocation (neither sigra nor chimeway installed)
    - per-component gate: threadline_release_created never aggregate releases_created (D-8)
key_files:
  modified:
    - script/verify_companion_cleanroom.sh (threadline canary branch + suppress-guard + Step 6 no-companion config)
    - release-please-config.json (packages/crosswake_threadline block, NOT in linked-versions)
    - .release-please-manifest.json (packages/crosswake_threadline: 0.1.0)
    - .github/workflows/release-please.yml (threadline outputs + publish-hex-threadline + clean-room-proof-threadline + extended release-as-cleanup + release-failure-alert)
    - examples/phoenix_host/mix.exs (crosswake_threadline path dep)
    - guides/companion_compatibility.md (threadline row companion_id updated to N/A — not a :companions registrant)
decisions:
  - "threadline is NOT a Crosswake.Companion implementor: companion-behaviour assertions (enabled?/1, companion_id/0, validate_dependency/0) are fully SUPPRESSED via if/elif/else canary branch + explicit PACKAGE != crosswake_threadline suppress-guard in the else block"
  - "three module-shipment canaries replace companion-behaviour assertions: Telemetry.event_names/0 == 3 (Telemetry shipped), Plug.Threadline.init/1 header_name (Plug shipped), Audit.Ledger.actor_ref/2 64-hex (Ledger shipped)"
  - "zero-sibling-dep invariant: Step 6 for threadline skips :companions registration (not a registrant); smoke test asserts :crosswake_sigra and :crosswake_chimeway NOT in dep_names"
  - "companion_compatibility.md threadline row companion_id updated from :threadline to N/A (not a :companions registrant — wired via Plug/LiveView on_mount)"
  - "per-component gate: all threadline CI jobs gate on threadline_release_created, never aggregate releases_created (D-8, THREAD-03)"
  - "no real publish: publish is human-gated, deferred to Wave 4 (Plan 04) and the batched family publish"
metrics:
  duration: "~7 min"
  completed: "2026-07-02"
  tasks_completed: 3
  tasks_total: 3
  files_created: 0
  files_modified: 6
---

# Phase 139 Plan 03: CI Publish Pipeline + Clean-Room Threadline-Correct Summary

crosswake_threadline registered as an independent elixir release-please component with one-shot 0.1.0 pin, three CI jobs added (threadline outputs + publish-hex-threadline + clean-room-proof-threadline), verify_companion_cleanroom.sh made threadline-correct with module-shipment canaries and companion-behaviour assertions suppressed, and example host + compat matrix updated.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Threadline-correct cleanroom script (canaries + suppress-guard) | b2a12b53 | script/verify_companion_cleanroom.sh |
| 2 | Register crosswake_threadline as independent release-please component | d24481be | release-please-config.json, .release-please-manifest.json, examples/phoenix_host/mix.exs, guides/companion_compatibility.md |
| 3 | Add threadline outputs + publish-hex-threadline + clean-room-proof-threadline + extend cleanup/alert | 2b96db67 | .github/workflows/release-please.yml |

## What Was Built

**Task 1 — Threadline-correct cleanroom script:**

- Added non-companion no-engine invocation notes to the usage header comment
- Added a new `if [ "$PACKAGE" = "crosswake_threadline" ]; then` canary branch (first in the chain, before chimeway `elif`)
- Threadline canary emits three module-shipment tests:
  1. `Crosswake.Threadline.Telemetry.event_names()` is a list of length 3 (proves Telemetry shipped)
  2. `Crosswake.Plug.Threadline.init([])` returns opts with `header_name == "x-crosswake-thread-id"` (proves Plug shipped)
  3. `Crosswake.Audit.Ledger.actor_ref("test-user-id", secret: "test-secret")` is a 64-char lowercase hex binary (proves Ledger shipped)
  4. Zero-sibling-dep invariant test: asserts `:crosswake_sigra` and `:crosswake_chimeway` not in `Mix.Project.config()[:deps]` (non-vacuous: dep list must be non-empty)
- Added explicit `if [ "$PACKAGE" != "crosswake_threadline" ]; then` suppress-guard in the default `else` branch (companion-behaviour assertions — enabled?/1, companion_id/0, validate_dependency/0 — are never emitted for threadline)
- Step 6 config: threadline gets its own branch that skips `:companions` registration (not a registrant; registering would cause doctor to report companion.dependency_missing since threadline has no validate_dependency/0)
- `bash -n` parses clean; chimeway path and sigra path 100% unchanged (additive + suppress only)

**Task 2 — Independent release-please component + example host + compat matrix:**

- `release-please-config.json`: added `packages/crosswake_threadline` block — `component: "crosswake_threadline"`, `release-type: "elixir"`, `separate-pull-requests: true`, `_TODO_release_as` note citing Phase 139 and the one-shot removal pattern, `release-as: "0.1.0"`, `extra-files: ["packages/crosswake_threadline/mix.exs"]`, standard `changelog-sections` array. NOT added to `linked-versions` (D-8 independent versioning)
- `.release-please-manifest.json`: added `"packages/crosswake_threadline": "0.1.0"` (valid JSON, no trailing commas)
- `examples/phoenix_host/mix.exs`: added `{:crosswake_threadline, path: "../../packages/crosswake_threadline"}` path dep after chimeway; updated deps-block comment to mention Phase 139 and crosswake_threadline
- `guides/companion_compatibility.md`: updated threadline row companion_id from `:threadline` to `N/A (not a :companions registrant — wired via Crosswake.Plug.Threadline plug + on_mount: Crosswake.Live.Threadline)`; engine dep clarified as "pure-OTP audit/correlation observer; optional :plug + :phoenix_live_view"

**Task 3 — Full publish pipeline in release-please.yml:**

- Three output aliases in the `release-please` job: `threadline_release_created`, `threadline_tag_name`, `threadline_version` (reading `steps.release.outputs['packages/crosswake_threadline--*']`)
- `publish-hex-threadline` job: needs `release-please`, if `threadline_release_created == 'true'`, env `CROSSWAKE_RELEASE: "1"` (so hex.publish sees Hex dep not path:, and optional Plug/LiveView deps resolve), checkout at `threadline_tag_name`, working-dir `packages/crosswake_threadline`, cache `packages/crosswake_threadline/{deps,_build}` keyed on `runner.os-threadline-hashFiles(mix.lock)`, steps: deps.get → compile --warnings-as-errors → verify version grep → mix test → hex.publish --dry-run --yes → hex.publish --yes → poll Hex.pm (36 attempts/10s). Comments cite D-8/D-07 per-component gate and T-139-12
- `clean-room-proof-threadline` job: needs `[release-please, publish-hex-threadline]`, if `threadline_release_created == 'true'`, setup-beam via .tool-versions strict, install hex+rebar, then `bash script/verify_companion_cleanroom.sh crosswake_threadline "$threadline_version"` (NO engine args — uses the no-engine non-companion threadline mode from Task 1; installs crosswake + crosswake_threadline, NOT crosswake_sigra, NOT crosswake_chimeway)
- `release-as-cleanup`: `if:` extended with `|| needs.release-please.outputs.threadline_release_created == 'true'`; strip block added for crosswake_threadline
- `release-failure-alert`: `needs:` extended with `publish-hex-threadline` and `clean-room-proof-threadline`; issue body extended with both job results
- YAML valid; no real publish (publish is human-gated Wave 4, deferred to family batch)

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

| Gate | Result |
|------|--------|
| `bash -n script/verify_companion_cleanroom.sh` | PASS |
| `grep -q "crosswake_threadline" ... && grep -q "event_names" ...` | PASS (threadline-canary-present) |
| `grep -q 'PACKAGE" != "crosswake_threadline'` | PASS (suppress-guard-present) |
| `python3 -c "import json; json.load(open('release-please-config.json')); json.load(open('.release-please-manifest.json'))"` | PASS (valid json) |
| threadline component check (component == crosswake_threadline, release-as == 0.1.0) | PASS |
| manifest entry check (packages/crosswake_threadline: 0.1.0) | PASS |
| crosswake_threadline NOT in linked-versions | PASS |
| example host + compat matrix grep | PASS (host+matrix-wired) |
| `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))"` | PASS (valid yaml) |
| publish-hex-threadline, clean-room-proof-threadline, threadline_release_created present | PASS (jobs-present) |
| `grep -q "strip_release_as.py crosswake_threadline"` | PASS (cleanup-wired) |

## Known Stubs

None — all CI jobs are real pipeline gates; no mock/placeholder behavior.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced in this plan. CI pipeline changes are additive to the existing threadline-scoped trust boundaries (T-139-09/10/11/12/18 from plan threat register all mitigated).

## Self-Check: PASSED

All modified files exist on disk and all commits verified in git log.
