---
phase: 140-family-discipline-close
plan: 02
subsystem: telemetry-contract-tests
tags: [telemetry, testing, side-a, family-discipline, FAMILY-03]
requires:
  - "Companion Telemetry.event_names/0 + execute/3 (sigra, chimeway, threadline)"
  - "Crosswake.Plug.Threadline call/2 rescue clause (:exception emission)"
  - "Crosswake.TestSupport.ProofAssertions.stable_id_message/7"
provides:
  - "Per-package Side-A declared⇔emitted telemetry contract tests (sigra, chimeway)"
  - "Catalog-iterating threadline Side-A test + live :exception plug-behavior proof"
  - "Merge-blocking regression guard proof.telem_04.no_reserved_count_assertion"
affects:
  - packages/crosswake_sigra/test/crosswake/companions/sigra/telemetry_test.exs
  - packages/crosswake_chimeway/test/crosswake/companions/chimeway/telemetry_test.exs
  - packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs
  - test/crosswake/proof/phase133_telemetry_contract_test.exs
tech-stack:
  added: []
  patterns:
    - "Catalog-driven Side-A: iterate Telemetry.event_names/0 live (never hardcoded), drive execute/3, subset Map.has_key? assertion"
    - "Self-referential source-inspection regression guard (filter comment lines, match idiom, assert absence)"
key-files:
  created: []
  modified:
    - packages/crosswake_sigra/test/crosswake/companions/sigra/telemetry_test.exs
    - packages/crosswake_chimeway/test/crosswake/companions/chimeway/telemetry_test.exs
    - packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs
    - test/crosswake/proof/phase133_telemetry_contract_test.exs
decisions:
  - "Emission proof lives in each emitter's own suite (no core-side aggregation reaching into companion emission)"
  - "Subset Map.has_key? assertions only — never exact event/metadata count (avoids >=24 cross-package coupling)"
  - "threadline :exception metadata is empty by design — kind/reason are not allowlisted keys; assert metadata == %{} (PII-safe contract)"
metrics:
  duration: ~9m
  completed: 2026-07-02
status: complete
---

# Phase 140 Plan 02: Per-Package Side-A Telemetry Contract Tests Summary

Each companion package now proves its own "declared ⇔ emitted" telemetry contract in its own
suite via catalog-driven subset assertions, and the already-done `>= 24` reserved-event
count-assertion removal is locked against regression by a merge-blocking source-inspection guard.

## What Was Built

- **sigra + chimeway Side-A tests (Task 1):** Each package's `telemetry_test.exs` gained one new
  test that iterates every name from `Telemetry.event_names/0` (pulled live from the catalog, never
  hardcoded), attaches a per-event handler, drives the real `Telemetry.execute/3` emitter path with
  declared metadata keys (`route_id`/`correlation_id` for sigra; `provider`/`correlation_id` for
  chimeway), and asserts those keys are present via `Map.has_key?`. Because these events are declared
  `:reserved` in core (declared-not-emitted-by-core), the in-package Side-A test is what proves
  emission exists — the two facts together are the full contract. Pre-existing tests untouched.
- **threadline Side-A upgrade (Task 2):** Added (a) a catalog-iterating test over
  `Telemetry.event_names/0` asserting `:thread_id` present per emitted event (catches "declared a 4th
  event, forgot to emit"), and (b) a plug-behavior test that drives `Crosswake.Plug.Threadline.call/2`
  through its error path (passing a non-`Plug.Conn` value forces `Conn.get_req_header/2` to raise
  inside the try block), observing the previously-never-driven `[:crosswake, :threadline, :request,
  :exception]` event fire and asserting the reraise propagates via `assert_raise`. The existing
  exact-list published-contract equality tests were kept.
- **Core regression guard (Task 3):** Added `proof.telem_04.no_reserved_count_assertion` to
  `phase133_telemetry_contract_test.exs`. It reads the file's own source, filters out comment lines,
  and asserts the `length(...) >= N` reserved-event count-assertion idiom appears zero times — the
  count assertion was replaced by the Phase-136 shape assertion and must stay gone. Also added a note
  pointing to the Phase-139 anti-drift subset invariant's home (`telemetry_test.exs`), intentionally
  not duplicated here.

## Test Status

| Suite | Result |
| ----- | ------ |
| `crosswake_sigra` telemetry_test.exs | 4 tests, 0 failures |
| `crosswake_chimeway` telemetry_test.exs | 6 tests, 0 failures |
| `crosswake_threadline` telemetry_test.exs | 14 tests, 0 failures |
| core `phase133_telemetry_contract_test.exs` | 9 tests, 0 failures |

Acceptance greps: all three Side-A tests iterate `event_names()` (catalog-driven); no `map_size` /
exact-count assertions exist in any Side-A test body (the only `map_size` occurrences are in comments
explaining the prohibition).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] threadline :exception metadata assertion corrected to match the real sanitized contract**
- **Found during:** Task 2
- **Issue:** Initial assertion `metadata[:kind] == :error` failed. The plug's rescue emits
  `%{kind: :error, reason: e}`, but `Telemetry.execute/3` routes all metadata through the allowlist
  `metadata/1` guard, and `:kind`/`:reason` are not allowlisted keys — so the emitted metadata is `%{}`.
- **Fix:** Changed the assertion to `assert metadata == %{}` (with an explanatory comment), and kept
  the load-bearing proofs: the `:exception` event fires (with its `:duration` measurement) and the
  reraise propagates. This is the correct PII-safe contract, not a bug in the plug.
- **Files modified:** packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs
- **Commit:** 7dc1fc6b

## Known Stubs

None.

## Threat Flags

None — this plan only adds tests; it introduces no new network endpoints, auth paths, file access,
or schema surface.

## Self-Check: PASSED

- FOUND: packages/crosswake_sigra/test/crosswake/companions/sigra/telemetry_test.exs
- FOUND: packages/crosswake_chimeway/test/crosswake/companions/chimeway/telemetry_test.exs
- FOUND: packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs
- FOUND: test/crosswake/proof/phase133_telemetry_contract_test.exs
- FOUND commit a8f945da (Task 1: sigra + chimeway Side-A)
- FOUND commit 7dc1fc6b (Task 2: threadline Side-A + live :exception)
- FOUND commit 9674e384 (Task 3: >=24 regression guard)
