---
phase: 143-guarded-auto-publish-train
status: passed
verified: 2026-07-07T22:10:55Z
requirements:
  - AUTO-01
  - AUTO-02
  - AUTO-03
score: 3/3
human_verification: []
---

# Phase 143 Verification

## Result

Phase 143 passes. The guarded auto-publish train is implemented, the recovery path is component-aware and exact-ref only, and the version graph checks keep core/native lockstep separate from independently versioned companions.

## Requirement Mapping

- AUTO-01 passed: Release Please Hex publish jobs now route through `script/guarded_hex_publish.sh`; the helper performs exact package/version preflight, treats already-live Hex releases as success, emits structured GitHub outputs, and never uses `mix hex.publish --replace`.
- AUTO-02 passed: release integrity checks verify that only core/native artifacts stay lockstep, companions remain independent Release Please components, and companion core floors stay honest instead of flattened.
- AUTO-03 passed: `.github/workflows/hex-publish.yml` accepts `package`, `ref`, and `release_version`, rejects branch-like refs, allows only full SHAs or explicit `refs/tags/vX.Y.Z`, and reuses the same guarded helper as the automatic train.

## Evidence

- `script/guarded_hex_publish.sh`
- `.github/workflows/release-please.yml`
- `.github/workflows/hex-publish.yml`
- `script/check_release_workflow_integrity.exs`
- `test/crosswake/proof/phase142_release_integrity_test.exs`
- `docs/COMPANION-PUBLISH-RUNBOOK.md`
- `guides/companion_compatibility.md`
- `.planning/phases/143-guarded-auto-publish-train/143-01-SUMMARY.md`
- `.planning/phases/143-guarded-auto-publish-train/143-02-SUMMARY.md`
- `.planning/phases/143-guarded-auto-publish-train/143-03-SUMMARY.md`

## Automated Verification

- `bash -n script/guarded_hex_publish.sh` passed.
- `elixir script/check_release_workflow_integrity.exs` passed with all Phase 143 check IDs OK.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs` passed: 21 tests, 0 failures.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_auto_publish` passed.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery` passed.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_version_graph` passed.
- `MIX_ENV=test mix verify` passed: 938 tests, 0 failures, 61 excluded.

## Notes

- A plain `mix verify` run failed before the final root test step because the alias invokes `mix test` under `dev`; rerunning with `MIX_ENV=test` completed successfully.
- Live Hex probes for `crosswake_rulestead 0.1.0` and `crosswake_rindle 0.1.0` returned 404, so those releases remain publish-needed only when Release Please emits the matching package release.
