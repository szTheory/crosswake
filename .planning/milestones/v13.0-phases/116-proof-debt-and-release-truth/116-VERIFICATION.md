---
phase: 116-proof-debt-and-release-truth
status: passed
verified_at: 2026-06-18T20:24:58Z
verifier: codex-inline
requirements:
  - PROOF-01
  - REL-TRUTH-01
  - DRIFT-01
---

# Phase 116 Verification

## Result

Passed. Phase 116 completed all three planned slices and satisfied PROOF-01, REL-TRUTH-01, and DRIFT-01.

## Evidence

- `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs test/crosswake_example/chimeway/registry_notification_open_test.exs` - passed, 10 tests, 0 failures.
- `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs` - passed, 14 tests, 0 failures.
- `gsd-tools query phase.complete 116` - passed, no warnings, reported `plans_executed: "3/3"` and next phase 117.

## Requirement Coverage

- PROOF-01: Flashcards schema/API drift and Chimeway notification-open fixture nondeterminism are repaired; targeted example-host proof tests pass.
- REL-TRUTH-01: Public release truth is reconciled to `crosswake 0.1.2` across README, CHANGELOG, guides, example metadata, and manifests.
- DRIFT-01: `Crosswake.Guides.ReleaseBoundariesTest` now derives the current version from `Application.spec(:crosswake, :vsn)`, scans public docs and three example manifests, and includes synthetic stale-claim regressions.

## Notes

- The documented post-execute hook command `gsd-tools loop render-hooks execute:post --raw` is not supported by the installed `gsd-tools` entrypoint; `gsd-tools query loop render-hooks execute:post` and `gsd-tools query hooks render execute:post` also fail because no `loop` or `hooks` command is registered. No callable code-review hook renderer was available in this environment.
- Example-host test runs modified local SQLite runtime artifacts under `examples/phoenix_host/`; those files are intentionally not part of Phase 116 commits.
