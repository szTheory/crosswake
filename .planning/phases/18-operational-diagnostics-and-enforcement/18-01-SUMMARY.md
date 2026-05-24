---
phase: "18-operational-diagnostics-and-enforcement"
plan: "01"
title: "Family-first route capability validation and command-aware bridge lookup"
executed_at: "2026-05-21T20:00:00Z"
commits: []
files_changed:
  - "lib/crosswake/policy/validator.ex"
  - "lib/crosswake/bridge/registry.ex"
  - "lib/crosswake/manifest/builder.ex"
  - "guides/capabilities.md"
  - "test/support/router_fixtures.ex"
  - "test/crosswake/bridge/registry_test.exs"
  - "test/crosswake/manifest/validator_test.exs"
---

# Phase 18 Plan 01 Summary

Crosswake now validates route capabilities against the public family-first Phase 18 vocabulary while keeping runtime bridge lookup command-aware and fail-closed.

## Completed Work

- Switched policy validation hints and accepted vocabulary toward semantic family ids such as `app_info`, `haptics`, `share`, `permissions.status`, `notification_token`, and `file_picker`.
- Preserved explicit compatibility ids and v1 boundary ids so older fixtures and doctor boundary checks still resolve honestly.
- Mapped bridge commands back to canonical families (`app.info.get` -> `app_info`, `haptics.impact` -> `haptics`, `share.invoke` -> `share`) without widening runtime authority.
- Kept `files.pick` as the only transfer-backed exception that still requires a declared `transfer_id` and `native_picker` seam.
- Added proof coverage for family-first route declarations, legacy alias handling, and the separate deep-link non-bridge boundary.

## Verification

- `mix test test/crosswake/manifest/validator_test.exs test/crosswake/bridge/registry_test.exs`
  - Result: passed

## Constraints Observed

- The repository was already dirty, so this execution layered onto the existing worktree and did not create atomic plan commits.

## Self-Check

PASSED
