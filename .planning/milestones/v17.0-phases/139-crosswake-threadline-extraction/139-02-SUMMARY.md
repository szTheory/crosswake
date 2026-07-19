---
phase: 139-crosswake-threadline-extraction
plan: "02"
subsystem: crosswake_threadline
status: complete
tags: [extraction, test-migration, anti-drift, clean-room-proof, dx-wins, pii-floor, telemetry, brand-voice]
dependency_graph:
  requires: [139-01-PLAN]
  provides: [threadline-package-test-lane, anti-drift-pii-floor-test, clean-room-proof, gen-audit-hardening, dx-wins]
  affects:
    - packages/crosswake_threadline/test/
    - packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex
    - packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex
    - packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex
    - packages/crosswake_threadline/lib/crosswake/audit/ledger.ex
    - test/crosswake/telemetry_test.exs
    - test/crosswake/proof/phase133_telemetry_contract_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
    - guides/companion_compatibility.md
    - mix.exs
tech_stack:
  added:
    - NO_COLOR env detection (no-color.org standard, ASCII tree fallback in mix crosswake.threadline)
    - try/rescue crash-isolation pattern in generated telemetry handler (ledger.ex.eex)
    - on_conflict: :nothing + conflict_target: :idempotency_key for idempotent replay
  patterns:
    - anti-drift PII-floor subset test (core_baseline ⊆ union(companion forbidden_metadata_keys), non-vacuous)
    - vacuity-safe clean-room proof (module-shipment canaries + real dep list check, async: true)
    - frozen-literal support matrix assertion (post-extraction, no live module call in core test)
    - brand-voice microcopy (brandbook §6: calm, specific, actionable, verb-first)
key_files:
  created:
    - packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs
    - packages/crosswake_threadline/test/crosswake/threadline/id_test.exs
    - packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs
    - packages/crosswake_threadline/test/crosswake/plug/threadline_test.exs
    - packages/crosswake_threadline/test/crosswake/live/threadline_test.exs
    - packages/crosswake_threadline/test/crosswake/audit/ledger_test.exs
    - packages/crosswake_threadline/test/crosswake/proof/phase91_threadline_contract_closeout_test.exs
    - packages/crosswake_threadline/test/crosswake/proof/phase92_server_propagation_closeout_test.exs
    - packages/crosswake_threadline/test/crosswake/proof/phase96_threadline_docs_contract_test.exs
    - packages/crosswake_threadline/test/mix/tasks/crosswake.gen.audit_test.exs
    - packages/crosswake_threadline/test/mix/tasks/crosswake.threadline_test.exs
  modified:
    - packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex (try/rescue, on_conflict, advisory moduledoc, attach/2)
    - packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex (NO_COLOR, empty-result guard, posture microcopy)
    - packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex (Next-steps assertions verified; skipping verb confirmed)
    - packages/crosswake_threadline/lib/crosswake/audit/ledger.ex (HMAC ArgumentError names both paths)
    - test/crosswake/telemetry_test.exs (anti-drift D-5 test + baseline-count assertion, stub companions)
    - test/crosswake/proof/phase133_telemetry_contract_test.exs (TELEM-04 rewritten to avoid circular dep)
    - test/crosswake/support_matrix/support_matrix_test.exs (frozen-literal assertions, removed live module calls)
    - guides/companion_compatibility.md (crosswake_threadline row added)
    - mix.exs (circular-dep fix: removed {:crosswake_threadline, path:...})
  deleted:
    - test/crosswake/threadline/id_test.exs
    - test/crosswake/threadline/telemetry_test.exs
    - test/crosswake/plug/threadline_test.exs
    - test/crosswake/live/threadline_test.exs
    - test/crosswake/audit/ledger_test.exs
    - test/mix/tasks/crosswake.gen.audit_test.exs
    - test/mix/tasks/crosswake.threadline_test.exs
    - test/crosswake/proof/phase91_threadline_contract_closeout_test.exs
    - test/crosswake/proof/phase92_server_propagation_closeout_test.exs
    - test/crosswake/proof/phase96_threadline_docs_contract_test.exs
decisions:
  - "circular-dep fix: removed {:crosswake_threadline, path: 'packages/crosswake_threadline', only: :test} from core mix.exs — crosswake_threadline->crosswake path dep created MixProject double-load error; rewrite phase133 TELEM-04 to emit threadline events via :telemetry.execute directly (proves catalog correctness without circular dep)"
  - "support_matrix_test: replaced live Crosswake.Threadline.Telemetry.* calls with frozen-literal assertions against the expected 20/4/3 key counts (SITE 1 freeze is the source of truth post-extraction)"
  - "anti-drift test uses two stub companions (StubThreadlineDomainCompanion with 20 keys + StubChimewayDomainCompanion) so union covers all 11 baseline keys non-vacuously"
  - "clean-room proof async: true — threadline NOT a :companions registrant, no Application.put_env, no process-global mutation; 4 canaries: event_names/0 == 3, Plug.init/1 header_name, actor_ref/2 64-hex, real dep list refutes sigra+chimeway"
  - "ledger.ex.eex template: added attach/2 convenience function + handle_event/4 with try/rescue+Logger.error+:ok (never reraises); on_conflict: :nothing in both handle_event and record_in_multi; advisory @moduledoc for row_hash/prev_hash"
  - "DX wins in 3 separate commits: NO_COLOR ASCII glyphs (Commit A), empty-result guard with filter context (Commit B), posture microcopy brand-voice (Commit C)"
  - "companion_compatibility.md: added crosswake_threadline row to satisfy phase132_compat_matrix_drift_test"
metrics:
  duration: "~55 min"
  completed: "2026-07-02"
  tasks_completed: 5
  tasks_total: 5
  files_created: 12
  files_modified: 9
  files_deleted: 10
---

# Phase 139 Plan 02: Test Migration + Hardening + DX Summary

10 threadline test files moved to the package lane, anti-drift PII-floor test added to core, gen.audit template hardened with try/rescue crash-isolation + on_conflict replay idempotency, vacuity-safe clean-room proof created, and 4 brand-voice DX wins landed as isolated commits.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Move threadline tests to package lane + anti-drift PII-floor test | afee444a | 16 files (10 test moves, 6 core modifications) |
| 2 | Harden generated audit ledger template | c666afbe | ledger.ex.eex |
| 3 | Add vacuity-safe clean-room proof (async: true) | 107e9622 | phase139_threadline_cleanroom_test.exs |
| 4A | NO_COLOR/ASCII tree fallback | 8d581f26 | crosswake.threadline.ex |
| 4B | Empty-result guard | 81250d73 | crosswake.threadline.ex |
| 4C | Posture microcopy rewrites | 1f6d7b7c | crosswake.threadline.ex |
| 5A | Gen.audit test assertions (Next-steps + skipping) | cca8a40f | gen.audit_test.exs, ledger_test.exs |
| 5B | HMAC ArgumentError names both resolution paths | 244cf00e | ledger.ex |

## What Was Built

**Task 1 — Test migration + anti-drift D-5:**

- Moved 10 test files from `test/` to `packages/crosswake_threadline/test/` verbatim (id, telemetry, plug, live, audit/ledger, gen.audit, crosswake.threadline, phase91/92/96 proof tests)
- path fix in phase96: `"guides/threadline.md"` → `"../../guides/threadline.md"` (sigra-package pattern)
- Deleted all 10 from core
- Added anti-drift test to `test/crosswake/telemetry_test.exs`:
  - `StubThreadlineDomainCompanion` (20 keys) + `StubChimewayDomainCompanion` (covers :token)
  - `core_baseline ⊆ union(companion forbidden_metadata_keys)` — fails loudly if floor key loses provenance
  - Baseline count assertion: exactly 11 atoms post-Phase-139
- Fixed circular-dep bug (Rule 1): removed `{:crosswake_threadline, path:..., only: :test}` from core `mix.exs` — caused `MixProject` double-load error because crosswake_threadline→crosswake path dep is circular; rewrote phase133 TELEM-04 to use `:telemetry.execute` directly
- Fixed support_matrix_test: 3 tests that called live `Crosswake.Threadline.Telemetry.*` module (no longer in core) replaced with frozen-literal count assertions (20/4/3 keys)
- Added `crosswake_threadline` row to `guides/companion_compatibility.md` (phase132 drift test required it)
- Core suite: 910 tests, 0 failures

**Task 2 — Hardened gen.audit template:**

- Advisory `@moduledoc`: `row_hash`/`prev_hash` are **advisory** fingerprints, NOT tamper-evidence; `idempotency_key` UNIQUE index is the real integrity guarantee
- `handle_event/4` telemetry handler with `try/rescue` crash-isolation: write failures log via `Logger.error` and return `:ok` — NEVER reraise (reraising auto-detaches the handler → silent audit blackout)
- `on_conflict: :nothing, conflict_target: :idempotency_key` in both `handle_event/4` (direct insert) and `record_in_multi/3` (Ecto.Multi) for idempotent replay
- `attach/2` convenience function to subscribe to `@threadline_events`
- Package gen.audit tests: 5 tests, 0 failures (then 8 after Task 5 extensions)

**Task 3 — Vacuity-safe clean-room proof:**

- `use ExUnit.Case, async: true` (threadline NOT a `:companions` registrant — no `Application.put_env`, safe)
- No setup block, no companion-behaviour assertions
- 4 tests: `event_names/0 == 3`, `Plug.Threadline.init([])` header_name, `actor_ref/2` → 64-char hex, real dep list refutes `:crosswake_sigra` + `:crosswake_chimeway` (non-vacuous: dep list non-empty guard)
- 4 tests, 0 failures

**Task 4 (3 commits) — DX wins:**

- Commit A: `ascii_mode?/0` detects `NO_COLOR` env (any non-nil value per no-color.org); `glyph/1` helper selects `+--`/`\--`/`|   ` (ASCII) or `└──`/`├──`/`│   ` (Unicode); applied throughout `render_durable/1`
- Commit B: `render_durable/2` overload for empty events → "No events found for thread_id=..." with filter context; non-empty path unchanged
- Commit C: ephemeral posture → "Posture: Ephemeral — no audit ledger configured." + config-key guidance + gen.audit CTA; durable posture → "Posture: Durable — querying audit ledger" (both code paths)
- threadline task tests: 11 tests, 0 failures

**Task 5 (2 commits) — Brand-voice microcopy:**

- Commit A: gen.audit_test assertions for Next-steps (mix crosswake.threadline CTA, mix ecto.create note, skipping verb) + ledger_test assertion for HMAC error message (RED until 5B)
- Commit B: HMAC `ArgumentError` now names both the `:secret` keyword option AND the `:audit_hmac_secret` application-env key — stays a hard raise (fail-loud, DoS mitigation T-139-17)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Circular path dep caused MixProject double-load (core broke)**
- **Found during:** Task 1 — `mix test` from repo root failed: `(Mix) Trying to load Crosswake.MixProject from "mix.exs" but another project with the same name was already defined`
- **Root cause:** 139-01 added `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` to core `mix.exs`. crosswake_threadline declares `{:crosswake, path: "../.."}` — Mix cannot resolve this circular path dep; even `mix deps.clean` failed.
- **Fix:** Removed the `{:crosswake_threadline, path:...}` dep from core `mix.exs`. Rewrote phase133 TELEM-04 (both Side A and Side B) to emit the 3 threadline events via `:telemetry.execute` directly — proves the events/0 catalog entries are correct without needing Plug.Threadline compiled in core. Plug.Threadline behavior is separately proven in phase92_server_propagation_closeout_test.exs in the package lane.
- **Files modified:** `mix.exs`, `test/crosswake/proof/phase133_telemetry_contract_test.exs`
- **Committed in:** `afee444a`

**2. [Rule 1 - Bug] support_matrix_test called Crosswake.Threadline.Telemetry.* (module no longer in core)**
- **Found during:** Task 1 post-circular-dep fix — 3 support_matrix tests failed with `UndefinedFunctionError` (module not available in core test lane)
- **Fix:** Replaced the 3 live-module-call tests with frozen-literal count assertions against the values expected from the SITE 1 freeze in `@audit_ledger_support_truth_static`. The frozen literal IS the source of truth post-extraction; the package lane's own drift tests maintain parity.
- **Files modified:** `test/crosswake/support_matrix/support_matrix_test.exs`
- **Committed in:** `afee444a`

**3. [Rule 2 - Missing Critical] crosswake_threadline missing from companion_compatibility.md**
- **Found during:** Task 1 core test run — phase132_compat_matrix_drift_test failed: `crosswake_threadline is declared as a package but has no row in the compat matrix`
- **Fix:** Added `crosswake_threadline` row to `guides/companion_compatibility.md` (same pattern as chimeway in 138-01)
- **Files modified:** `guides/companion_compatibility.md`
- **Committed in:** `afee444a`

## Verification Results

| Gate | Result |
|------|--------|
| `mix test --exclude requires_example_host test/crosswake/telemetry_test.exs` | PASS (7 tests, 0 failures) |
| `mix test --exclude requires_example_host --exclude engine_present` (core) | PASS (910 tests, 0 failures) |
| `cd packages/crosswake_threadline && mix test` | PASS (96 tests, 0 failures) |
| `grep -q "rescue"` in ledger.ex.eex | PASS |
| `grep -q "on_conflict"` in ledger.ex.eex | PASS |
| `grep -q "NO_COLOR"` in crosswake.threadline.ex | PASS |
| `grep -q "No events found"` in crosswake.threadline.ex | PASS |
| `grep -q "querying audit ledger"` in crosswake.threadline.ex | PASS |
| `grep -q "crosswake.threadline"` in crosswake.gen.audit.ex | PASS |
| `grep -q "skipping"` in crosswake.gen.audit.ex | PASS |
| `grep -q "audit_hmac_secret"` in ledger.ex | PASS |
| `grep -q "async: true"` in phase139_threadline_cleanroom_test.exs | PASS |
| No threadline tests remain in core `test/` | PASS (`test/crosswake/threadline/` deleted) |

## Known Stubs

None — all moved tests are real assertions; all DX changes are wired to real behavior.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced in this plan.

## Self-Check: PASSED

All created files exist on disk. All commits verified in git log.
