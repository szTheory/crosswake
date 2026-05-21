---
phase: "17-user-prompted-capabilities"
plan: "02"
title: "Transfer-bound file_picker contract, manifest truth, and support wording"
executed_at: "2026-05-21T16:33:14Z"
commits:
  - "d9f0d07"
  - "7079744"
files_changed:
  - "lib/crosswake/bridge/commands/file_picker.ex"
  - "lib/crosswake/bridge/registry.ex"
  - "lib/crosswake/transfer/contracts.ex"
  - "lib/crosswake/manifest/builder.ex"
  - "guides/capabilities.md"
  - "guides/support_matrix.md"
  - "test/support/router_fixtures.ex"
  - "test/crosswake/bridge/registry_test.exs"
  - "test/crosswake/manifest/manifest_test.exs"
  - "test/crosswake/transfer/contracts_test.exs"
---

# Phase 17 Plan 02 Summary

Implemented `file_picker` as a typed `files.pick` bridge seam that only resolves through declared inbound `native_picker` transfers, then aligned manifest and support truth to a copy-first, transfer-verified staged-handle posture.

## Execution Path

- Executed in the forked workspace at `/Users/jon/projects/crosswake`.
- Layered this plan onto the current post-17-01 repo state without reverting unrelated edits.
- Limited changes to the user-owned plan-02 files plus this summary artifact.

## Completed Work

- Added `Crosswake.Bridge.Commands.FilePicker` with typed request, item, success, and cancel payloads.
- Kept request-time MIME filters advisory and modeled cancelation as a distinct typed outcome rather than `items: []`.
- Extended `Crosswake.Bridge.Registry.lookup/4` so `files.pick` requires a request payload with `transfer_id`.
- Gated `files.pick` to declared inbound `source: :native_picker` transfer seams only, rejecting ambient or outbound file authority.
- Added transfer-contract validation for picker-backed declarations in `Crosswake.Transfer.Contracts`.
- Published `file_picker` in the manifest capability catalog as `bounded_bridge`, `core`, `native_required`, and copy-first plus verification-backed.
- Extended router fixtures so library flows expose both picker-backed `import` and picker-backed `upload` preparation seams.
- Updated `guides/capabilities.md` and `guides/support_matrix.md` so public wording matches staged-handle `items`, nullable metadata truth, explicit cancelation, and transfer verification.

## Verification

- `mix test test/crosswake/bridge/registry_test.exs test/crosswake/transfer/contracts_test.exs`
  - Result: `15 tests, 0 failures`
- `mix test test/crosswake/manifest/manifest_test.exs`
  - Result: `9 tests, 0 failures`
- `mix test test/crosswake/bridge/registry_test.exs test/crosswake/transfer/contracts_test.exs test/crosswake/manifest/manifest_test.exs`
  - Result: `24 tests, 0 failures`
- `rg -n "file_picker|native_picker|copy|verification|items" guides/capabilities.md guides/support_matrix.md lib/crosswake/manifest/builder.ex test/support/router_fixtures.ex`
  - Result: matched the new capability row, `native_picker` seam wording, copy-first verification language, and public `items` shape references.

## Deviations From Plan

None. The plan was executed as written.

## Known Stubs

None.

## Threat Flags

None.

## Constraints Observed

- Did not modify `.planning/STATE.md`, `.planning/ROADMAP.md`, or other shared planning artifacts because the execution request limited ownership to the plan-02 files and this summary artifact.
- Did not revert or overwrite unrelated workspace changes.

## Self-Check

PASSED

- Summary file exists.
- Commits `d9f0d07` and `7079744` exist in git history.
