---
phase: 39-route-policy-gating-dsl-and-manifest-binding
plan: 01
subsystem: policy
tags: [elixir, nimble-options, dsl, route-policy, gating, compile-time-validation]

requires:
  - phase: 38-companion-seam-contract
    provides: Crosswake.Companion behaviour with route_gated?/2 callback signature that reads RouteEntry.t() with gated_by field

provides:
  - validate_flag_key/1 in Policy.Schema — snake_case atom-identifier validator via regex (D-01/D-04)
  - validate_on_unavailable/1 in Policy.Schema — :deny/:fallback_phoenix/nil validator (D-05b)
  - gated_by + on_unavailable entries in @schema NimbleOptions definition (no default: :deny leak, D-05d/Pitfall 2)
  - gated_by: atom() | nil and on_unavailable: :deny | {:fallback_phoenix, atom()} | nil fields on Policy.Route struct
  - validate_gating_posture/1 cross-key validator — on_unavailable without gated_by rejected at compile time (D-05c)
  - validate_gating_posture/1 applies :deny default when gated_by is set but on_unavailable is nil (D-05d)
  - Hermetic proof test phase39_route_policy_gating_test.exs — 26 GATE-01 cases, untagged, picked up by phase34-proof.yml

affects:
  - 39-02 (manifest binding — extends same proof file with GATE-02 manifest round-trip cases)
  - 40-routegate-wiring (reads RouteEntry.gated_by to dispatch to companion route_gated?/2)
  - 41-rulestead-gating-doctor (flags unknown route_id references in {:fallback_phoenix, route_id})

tech-stack:
  added: []
  patterns:
    - "NimbleOptions custom validator with snake_case atom regex: is_atom and not in [true,false,nil] + Regex.match? + {:ok, atom} return (D-04 — atom not string)"
    - "Cross-key validation in Route.new/1 with-chain via validate_gating_posture/1 mirroring validate_offline_contracts/1 pattern"
    - "TDD: proof test scaffolded before implementation; RED verified (compile error on missing functions), GREEN verified (26/26 pass)"

key-files:
  created:
    - test/crosswake/proof/phase39_route_policy_gating_test.exs
  modified:
    - lib/crosswake/policy/schema.ex
    - lib/crosswake/policy/route.ex

key-decisions:
  - "validate_flag_key returns {:ok, atom} not {:ok, String.t()} — D-04: atom is the native contract type passed to route_gated?/2 in Phase 40, unlike validate_identifier/1 which string-converts"
  - "No default: :deny in @schema entry — D-05d/Pitfall 2: default would leak onto non-gated routes; :deny default applied only by validate_gating_posture/1 when gated_by is set"
  - "validate_gating_posture/1 placed after validate_offline_contracts in with-chain — cross-key constraints run in order, gating posture checked before entry/commerce/pack validations"

patterns-established:
  - "Atom-identifier DSL key pattern: validate_flag_key/1 is the canonical atom-identifier validator; future atom DSL keys (companion IDs, kill-switch IDs) should follow this shape"
  - "Cross-key gating posture validation: on_unavailable requires gated_by — fail-closed by default, fail-open only via explicit {:fallback_phoenix, route_id}"

requirements-completed: [GATE-01]

duration: 15min
completed: 2026-05-30
---

# Phase 39 Plan 01: Route-Policy Gating DSL And Manifest Binding Summary

**`gated_by: :atom` and `on_unavailable` compile-time-validated DSL keys added to Policy.Schema + Policy.Route with cross-key enforcement and a hermetic 26-test GATE-01 proof**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-30T07:30:00Z
- **Completed:** 2026-05-30T07:45:00Z
- **Tasks:** 3
- **Files modified:** 3 (2 source, 1 test)

## Accomplishments

- Added `validate_flag_key/1` to `Policy.Schema`: snake_case atom regex validator that returns `{:ok, atom}` (not string), rejecting booleans/nil/strings/integers/quoted atoms with dots/hyphens/CamelCase
- Added `validate_on_unavailable/1` to `Policy.Schema`: accepts nil/:deny/{:fallback_phoenix, valid_atom}, delegates route_id validation to `validate_flag_key/1`
- Extended `Policy.Route` struct with `:gated_by` and `:on_unavailable` fields plus `validate_gating_posture/1` cross-key validator enforcing D-05c (on_unavailable requires gated_by) and D-05d (:deny default when gated_by set)
- Created hermetic `phase39_route_policy_gating_test.exs` (26 tests, async: true, untagged) — all GATE-01 cases pass; full hermetic suite 344 tests, 0 failures

## Task Commits

1. **Task 1: Add gated_by + on_unavailable validators and schema entries to Policy.Schema** - `7d69aa3` (feat)
2. **Task 2: Add gated_by + on_unavailable fields and cross-key validation to Policy.Route** - `11ef19b` (feat)
3. **Task 3: Create hermetic GATE-01 proof test** - `04cb364` (feat)

## Files Created/Modified

- `lib/crosswake/policy/schema.ex` — Added validate_flag_key/1, validate_on_unavailable/1, gated_by/on_unavailable schema entries, @type validated_options fields
- `lib/crosswake/policy/route.ex` — Added :gated_by/:on_unavailable to defstruct and @type t, validate_gating_posture/1 and bang variant, wired into new/1 and new!/1
- `test/crosswake/proof/phase39_route_policy_gating_test.exs` — New: hermetic GATE-01 proof, 26 tests, untagged, async: true

## Decisions Made

- `validate_flag_key` returns `{:ok, atom}` not `{:ok, String.t()}` (D-04): atom is the native contract type for `route_gated?/2` dispatch in Phase 40; unlike `validate_identifier/1` which string-converts
- No `default: :deny` in `@schema` entry (D-05d/Pitfall 2): default would leak onto non-gated routes; `:deny` default applied only in `validate_gating_posture/1` when `gated_by != nil`
- `async: true` on proof test: no `Application.put_env` writes in GATE-01 cases (unlike Phase 38 SC#2/SC#4 which write `:companions` key); safe per PATTERNS note. Plan 02 may revisit if manifest cases require env writes.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

Worktree had no `deps` or `_build` directory; created symlinks to the main project's `deps` and `_build` (both gitignored) to enable `mix compile` and `mix test` within the worktree. This is a standard worktree workflow issue, not a plan deviation.

## Threat Model Coverage

Per plan threat register:
- **T-39-01 (Tampering):** Mitigated — `validate_flag_key/1` enforces snake_case atom regex; quoted/kebab/dot atoms and non-atoms rejected before reaching RouteEntry
- **T-39-03 (EoP):** Mitigated — `validate_gating_posture/1` rejects `on_unavailable` without `gated_by` at compile time

T-39-02 accepted per plan (shape-only validation; cross-validation deferred to Phase 41 doctor).

## Next Phase Readiness

- Plan 02: Extend `RouteEntry` and `Manifest.Types.to_map/1` with `gated_by`/`on_unavailable` fields (GATE-02 manifest binding), append manifest round-trip cases to the same proof file
- Phase 40: `RouteGate` reads `route_entry.gated_by` and dispatches to `route_gated?/2` — struct field now present
- Phase 41 doctor: `{:fallback_phoenix, route_id}` cross-validation against declared routes — deferred as planned

---
*Phase: 39-route-policy-gating-dsl-and-manifest-binding*
*Completed: 2026-05-30*
