---
phase: 21-reconciliation-example
plan: 02
subsystem: docs
tags: [commerce, reconciliation, guides, docs-contract, example-host]
requirements-completed:
  - RECN-01
  - RECN-02
  - RECN-03
key-files:
  created:
    - .planning/phases/21-reconciliation-example/21-02-SUMMARY.md
  modified:
    - guides/commerce.md
    - test/crosswake/guides/commerce_test.exs
    - examples/phoenix_host/README.md
commits:
  - 570d439
  - d7f32fa
  - 02788db
completed: 2026-05-27
---

# Phase 21 Plan 02 Summary

Published reconciliation example guidance and locked it behind docs-contract tests so RECN semantics stay explicit, provider-neutral, and backend-authoritative.

## Outcomes

- Added `## Minimal Reconciliation Inbox Example` to `guides/commerce.md` with explicit `purchase`/`restore`/`webhook`/`support` ingestion sequence and Phoenix-owned authority boundary language.
- Added dual-key idempotency guidance (`event_key`, `subject_key`) with explicit exclusion of transient `correlation_id` from authority identity.
- Added deterministic projection precedence guidance (`stale`, `pending`, `denied`, `granted`) plus monotonic `as_of` ordering guard language.
- Expanded `test/crosswake/guides/commerce_test.exs` to assert new reconciliation wording and enforce provider-neutral vocabulary in reconciliation sections.
- Updated `examples/phoenix_host/README.md` with reconciliation example module pointers under `CrosswakeExample.Commerce.*` and explicit non-core billing-engine / non-adapter posture.

## Verification

- `mix test test/crosswake/guides/commerce_test.exs` ✅ (9 tests, 0 failures)
- `rg "Minimal Reconciliation Inbox Example|event_key|subject_key|stale|pending|denied|granted|as_of|example/docs-only" guides/commerce.md test/crosswake/guides/commerce_test.exs` ✅
- `rg "reconciliation example|CrosswakeExample.Commerce|core billing engine|adapter" examples/phoenix_host/README.md` ✅
- `rg "Minimal Reconciliation Inbox Example|event_key|subject_key|storekit|play_billing|revenuecat" guides/commerce.md test/crosswake/guides/commerce_test.exs examples/phoenix_host/README.md` ✅

## Deviations

None - plan executed exactly as written.
