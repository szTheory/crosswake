---
phase: 39-route-policy-gating-dsl-and-manifest-binding
plan: 02
subsystem: manifest
tags: [elixir, manifest, serialization, route-policy, gating]

requires:
  - phase: 39-01
    provides: Policy.Route gated_by/on_unavailable fields + GATE-01 proof test scaffolding

provides:
  - gated_by and on_unavailable fields on RouteEntry struct (Manifest.Types)
  - new_route_entry/1 pass-through of gated_by/on_unavailable via Keyword.get
  - to_map/1 for RouteEntry: gated_by atom->string + serialize_on_unavailable/1 with nil-omission scoped to those two keys
  - serialize_on_unavailable/1 private function: nil->nil, :deny->"deny", {:fallback_phoenix, id}->"fallback_phoenix:<id>"
  - Builder.route_entries/3 pass-through of route.gated_by and route.on_unavailable (closes Pitfall 4)
  - GATE-02 proof cases: SC#2 manifest round-trip, SC#3 binding-vs-value split, fallback_phoenix reversibility, non-gated boundary

affects:
  - Phase 40: RouteGate reads RouteEntry.gated_by to dispatch to companion route_gated?/2
  - Phase 41 doctor: {:fallback_phoenix, route_id} cross-validation against declared routes

tech-stack:
  added: []
  patterns:
    - "Scoped nil-omission in to_map: reject only new optional keys (not blanket) to preserve existing nil-valued fields like cache_contract"
    - "serialize_on_unavailable/1 private helper: pattern-match on nil/:deny/{:fallback_phoenix, id} for reversible serialization"
    - "Pitfall 4 closure: Builder.route_entries/3 must explicitly pass route.gated_by and route.on_unavailable or they are silently nil in compiled RouteEntry"

key-files:
  created: []
  modified:
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - test/crosswake/proof/phase39_route_policy_gating_test.exs

decisions:
  - "Nil-omission scoped to gated_by/on_unavailable only — existing RouteEntry to_map does not blanket-reject nils (cache_contract etc. can legitimately be nil); scoping prevents accidental behavior change"
  - "serialize_on_unavailable lives as a private defp in Types — keeps serialization logic co-located with the to_map clause that calls it"
  - "async: true retained — Manifest.compile writes no Application env (confirmed by grep); no async: false needed for GATE-02 cases"

metrics:
  duration: 10min
  completed: 2026-05-30
---

# Phase 39 Plan 02: Manifest Binding For Route Policy Gating Summary

**RouteEntry extended with gated_by/on_unavailable fields, Builder pass-through wired, GATE-02 proof asserting binding-vs-value split and nil-omission — 32 hermetic tests passing**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-30T08:00:00Z
- **Completed:** 2026-05-30T08:10:00Z
- **Tasks:** 3
- **Files modified:** 3 (2 source, 1 test)

## Accomplishments

- Extended `RouteEntry` struct with `:gated_by` (atom | nil) and `:on_unavailable` (:deny | {:fallback_phoenix, atom()} | nil) — no `@enforce_keys`, default nil, D-07 enforced (no flag-value field)
- Added `gated_by/on_unavailable` pass-through in `new_route_entry/1` via `Keyword.get`
- Extended `to_map(%RouteEntry{})` with `"gated_by" => atom && Atom.to_string` and `"on_unavailable" => serialize_on_unavailable(...)`, nil-omission scoped to those two keys only
- Added private `serialize_on_unavailable/1`: nil→nil, :deny→"deny", {:fallback_phoenix, id}→"fallback_phoenix:<id>"
- Added `gated_by: route.gated_by` and `on_unavailable: route.on_unavailable` to `Builder.route_entries/3` `new_route_entry` call, closing Pitfall 4
- Appended 6 GATE-02 proof cases to existing test file: SC#2 round-trip, SC#3 binding-vs-value split (refuting :gated_by_value/:gate_enabled/:flag_state), fallback_phoenix reversibility, non-gated boundary
- Full hermetic suite: 350 tests, 0 failures (38 excluded `:requires_example_host`)

## Task Commits

1. **Task 1: Extend RouteEntry struct, new_route_entry/1, and to_map/1** - `f6a9941` (feat)
2. **Task 2: Pass gated_by + on_unavailable through Builder.route_entries/3** - `ce5ed9b` (feat)
3. **Task 3: Complete the Phase 39 proof with GATE-02 cases** - `badad4b` (feat)

## Files Created/Modified

- `lib/crosswake/manifest/types.ex` — RouteEntry defstruct + @type t extended; new_route_entry/1 updated; to_map/1 extended with gated_by/on_unavailable + scoped nil-omission; serialize_on_unavailable/1 added
- `lib/crosswake/manifest/builder.ex` — route_entries/3 new_route_entry call extended with gated_by/on_unavailable pass-through
- `test/crosswake/proof/phase39_route_policy_gating_test.exs` — Alias Manifest/Types added; GatedRouter/FallbackRouter/NonGatedRouter inline fixtures added; 6 GATE-02 describe blocks appended (32 total tests)

## Decisions Made

- Nil-omission scoped to `gated_by`/`on_unavailable` only — the existing `to_map/1` for `RouteEntry` does not blanket-reject nils; scoping prevents silent regression on fields like `cache_contract` that may legitimately be nil-valued maps
- `serialize_on_unavailable/1` lives as a private `defp` in `Manifest.Types` — serialization logic co-located with the `to_map` clause that calls it; clean pattern-match on the three valid shapes
- `async: true` retained — `Manifest.compile/1` writes no `Application.put_env` (confirmed); safe for concurrent test execution

## Deviations from Plan

None — plan executed exactly as written.

## Threat Model Coverage

- **T-39-04 (Tampering/Repudiation):** Mitigated — `RouteEntry` has only `gated_by` (key) and `on_unavailable` (posture), no `gated_by_value`/`gate_enabled`/`flag_state`; SC#3 proof test asserts absence of those keys, so an accidental future field addition fails CI
- **T-39-05 (Information disclosure):** Mitigated — only flag key (atom→string) and declared posture serialized; non-gated routes omit both keys entirely (no empty/null leakage)
- **T-39-SC (Tampering — supply chain):** Accepted per plan — zero new package installs

## Known Stubs

None — all RouteEntry gating fields are real data from the compiled Policy.Route struct; no placeholder values.

## Self-Check: PASSED

- `lib/crosswake/manifest/types.ex` contains `serialize_on_unavailable` — FOUND
- `lib/crosswake/manifest/builder.ex` contains `gated_by: route.gated_by` — FOUND
- `test/crosswake/proof/phase39_route_policy_gating_test.exs` contains `gated_by_value` (in refute assertions) — FOUND
- Commits f6a9941, ce5ed9b, badad4b — all present in git log
- `mix test test/crosswake/proof/phase39_route_policy_gating_test.exs` — 32 tests, 0 failures
- `mix test --exclude requires_example_host` — 350 tests, 0 failures
