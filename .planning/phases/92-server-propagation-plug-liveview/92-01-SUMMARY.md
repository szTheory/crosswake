---
phase: 92-server-propagation-plug-liveview
plan: 01
subsystem: threadline
tags:
  - plug
  - telemetry
  - uuid
dependency_graph:
  requires:
    - Phase 91 (Crosswake.Threadline.Telemetry)
  provides:
    - Crosswake.Threadline.Id
    - Crosswake.Plug.Threadline
  affects:
    - HTTP requests
tech_stack:
  added: []
  patterns:
    - Plug reading/minting custom header
    - Logger.metadata updates
    - Telemetry triplets via register_before_send
key_files:
  created:
    - lib/crosswake/threadline/id.ex
    - lib/crosswake/plug/threadline.ex
    - test/crosswake/threadline/id_test.exs
    - test/crosswake/plug/threadline_test.exs
  modified: []
metrics:
  duration: 5m
  completed_date: "2026-06-09"
---

# Phase 92 Plan 01: HTTP-side server propagation surface Summary

Implemented the foundational HTTP plug `Crosswake.Plug.Threadline` and `Crosswake.Threadline.Id` for the `thread_id` propagation.

## Deviations from Plan
- None - plan executed exactly as written.

## Outcomes
- **UUID Minting**: `Crosswake.Threadline.Id.generate/0` produces RFC-4122 v4 UUIDs using `:crypto.strong_rand_bytes/1` without introducing external dependencies.
- **Plug implementation**: `Crosswake.Plug.Threadline` accurately reads the `X-Crosswake-Thread-Id` header (using it verbatim if present, or minting a new one). It correctly assigns the `Logger.metadata` with keyword lists and emits the three required telemetry events (`:start`, `:stop`, `:exception`) routing everything through the `Crosswake.Threadline.Telemetry.execute/3` Phase 91 allowlist.

## Key Decisions
- No external packages were introduced for UUIDs (adhered strictly to D-11).
- `Logger.info/warning/error` calls were strictly avoided (adhered to D-05).

## Self-Check: PASSED
- `lib/crosswake/threadline/id.ex` exists.
- `lib/crosswake/plug/threadline.ex` exists.
- `mix test` passes all tests cleanly with expected telemetry behavior.
