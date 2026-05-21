---
phase: "17-user-prompted-capabilities"
plan: "01"
title: "Prompt-free notification-token bridge contract and support truth"
executed_at: "2026-05-21T16:25:09Z"
commits:
  - "a0807e8"
  - "c8aca21"
files_changed:
  - "lib/crosswake/bridge/contract.ex"
  - "lib/crosswake/bridge/registry.ex"
  - "lib/crosswake/bridge/commands/notification_token.ex"
  - "lib/crosswake/manifest/builder.ex"
  - "guides/capabilities.md"
  - "guides/support_matrix.md"
  - "test/crosswake/bridge/contract_test.exs"
  - "test/crosswake/bridge/registry_test.exs"
  - "test/crosswake/manifest/manifest_test.exs"
---

# Phase 17 Plan 01 Summary

Implemented the Elixir-side `notification_token` bridge contract as a prompt-free, provider-explicit, evidence-only command using `notifications.token.get`, with manifest-backed registry resolution and fail-closed route declaration checks.

## Execution Path

- Executed in the forked workspace at `/Users/jon/projects/crosswake`.
- Chosen reconciliation path: branch-local reconciliation on top of an already-dirty workspace.
- Preserved unrelated in-progress edits in non-owned files, especially the native example host `BridgeChannel` changes.
- Layered Phase 17 Plan 01 changes only onto the owned files listed in the execution request.

## Completed Work

- Added `Crosswake.Bridge.Commands.NotificationToken` with:
  - empty one-shot request shape
  - explicit `provider`, `token`, `notification_status`, and optional `detail` response fields
  - reused normalized notification status vocabulary from `permissions.status`
  - non-empty token validation and fixed provider allowlist (`apns`, `fcm`)
- Added `notifications.token.get` to the bridge contract command set.
- Mapped `notifications.token.get` to the `notification_token` capability family in the registry.
- Kept registry behavior manifest-backed and fail-closed by resolving the manifest capability first, then checking route declarations against canonical and legacy capability ids.
- Updated manifest capability metadata and public support wording so `notification_token` now states:
  - prompt-free prerequisites
  - provider token snapshot dependency
  - evidence-only fallback semantics
- Added targeted tests for the command vocabulary, typed request/response shape, legacy route declaration compatibility, and manifest metadata truth.

## Verification

- `mix test test/crosswake/bridge/contract_test.exs test/crosswake/bridge/registry_test.exs test/crosswake/manifest/manifest_test.exs`
  - Result: `23 tests, 0 failures`
- `rg -n "notification_token|notifications\\.token\\.get|evidence|companion|required|provider" guides/capabilities.md guides/support_matrix.md lib/crosswake/manifest/builder.ex lib/crosswake/bridge/contract.ex lib/crosswake/bridge/registry.ex lib/crosswake/bridge/commands/notification_token.ex`
  - Result: matched the new command, provider-explicit contract fields, and evidence-only support wording.

## Deviations From Plan

### Rule 1 - Compatibility bug fix

- Found during implementation: the current repo state still uses legacy route capability declarations such as `push.notifications`.
- Issue: registry route checks only matched canonical capability ids, which would have denied `notification_token` on routes declared with the manifest legacy id even though the manifest already recorded that alias.
- Fix: changed route declaration checks to resolve the manifest capability first and then accept either the canonical id or any manifest-declared legacy ids.
- Files modified: `lib/crosswake/bridge/registry.ex`
- Commit: `c8aca21`

## Constraints Observed

- Did not revert or overwrite unrelated local edits.
- Did not modify global planning state files such as `.planning/STATE.md` or `.planning/ROADMAP.md` because the execution request limited ownership to the plan-01 files and this summary artifact.

## Self-Check

PASSED

- Summary file exists.
- Commits `a0807e8` and `c8aca21` exist in git history.
