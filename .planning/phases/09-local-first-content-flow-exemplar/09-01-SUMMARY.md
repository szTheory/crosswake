---
phase: 09-local-first-content-flow-exemplar
plan: 01
subsystem: local_first
tags: [schema, context, sync, offline]
dependency_graph:
  requires: []
  provides: [ReviewEvent, Study]
  affects: [examples/phoenix_host/priv/repo/migrations, examples/phoenix_host/lib/crosswake_example/local_first]
tech_stack:
  added: [Ecto.Multi]
  patterns: [Append-only journal, Idempotent synchronization]
key_files:
  created:
    - examples/phoenix_host/priv/repo/migrations/20260518213507_create_review_events.exs
    - examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/study.ex
  modified: []
decisions:
  - "Used Ecto.Multi.insert_all with on_conflict: :nothing keyed by client_mutation_id to implement idempotent batch insert."
requirements-completed: [LOCAL-01]
metrics:
  duration: "10m"
  completed_date: "2026-05-18"
---

# Phase 09 Plan 01: Establish the core Ecto schema and context for the Local-First study flow Summary

**One-liner:** Implemented the `ReviewEvent` append-only journal schema and `Study` context for idempotent offline sync.

## Execution

The plan executed successfully. The `ReviewEvent` schema was added with standard Ecto validation and unique constraint indexing on `client_mutation_id`. The `Study` context uses `Ecto.Multi.insert_all` to support idempotency without silent failures, collecting accepted count and rejections directly.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None - the validation and unique constraint index handles the threat flags correctly.

## Self-Check: PASSED
FOUND: examples/phoenix_host/priv/repo/migrations/20260518213507_create_review_events.exs
FOUND: examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex
FOUND: examples/phoenix_host/lib/crosswake_example/local_first/study.ex
