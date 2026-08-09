---
phase: 154-the-control-contract-seam
plan: 01
subsystem: api
tags: [elixir, manifest, doctor, capability-vocabulary, route-policy, playwright]

# Dependency graph
requires:
  - phase: 154-the-control-contract-seam (CONTEXT/RESEARCH/PATTERNS)
    provides: D-57..D-63, D-76 vocabulary-flip decisions and the verified
      self-referential legacy_ids bug mechanism
provides:
  - family-form capability vocabulary (`"haptics"`) taught in the reference
    host's route policy and in the guides, with the legacy dotted command
    id (`"haptics.impact"`) still accepted forever via `legacy_ids`
  - a fixed `Manifest.Builder.compatibility_capability_attrs/2` that no
    longer produces a self-referential `legacy_ids` entry for any
    compatibility-path capability
  - a doctor advisory (`capability.legacy_capability_id`) naming any route
    still declaring a legacy capability id, at :warning severity, wired
    into the existing findings accumulation chain
affects: [154-02, 154-03, 154-04, 154-05, 154-06, 154-07, 154-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doctor findings: new capability.legacy_capability_id advisory folded
      into the existing findings ++ ... accumulation chain (same shape as
      native_rebuild_findings/2 / check/6)"

key-files:
  created: []
  modified:
    - lib/crosswake/manifest/builder.ex
    - lib/crosswake/doctor/doctor.ex
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - examples/ios_shell_host/Fixtures/crosswake_manifest.json
    - examples/android_shell_host/app/src/main/assets/crosswake_manifest.json
    - guides/route_policy.md
    - guides/capabilities.md
    - guides/bridge.md
    - test/crosswake/manifest/builder_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/doctor/formatter_test.exs
    - gen_manifest.exs

key-decisions:
  - "D-61/D-62: reference host's approval route flips capabilities: [\"haptics.impact\"] to capabilities: [\"haptics\"] — route policy declares families, the bridge dispatches commands"
  - "D-60: compatibility_capability_attrs/2 drops legacy_ids before returning the constructed compatibility-path capability, fixing the self-referential bug universally (not haptics-specific)"
  - "D-58/D-59/D-63: doctor's new capability.legacy_capability_id advisory is the only honest deprecation surface — compile-time warning is mechanically impossible here"
  - "Scoped manual patch of the two committed manifest fixtures instead of a full gen_manifest.exs regeneration, because the checked-in fixtures were ~2 months stale relative to the router (missing dozens of routes from Phases 149-152) — a full regen would have produced a ~500-line diff of unrelated drift"

patterns-established:
  - "Doctor advisory findings that can never change doctor's exit code: severity fixed at :warning, folded into the same accumulation chain as existing findings, no new aggregation mechanism"

requirements-completed: [CTRL-03]

coverage:
  - id: D1
    description: "Reference host's approval route declares the family capability id \"haptics\"; both \"haptics\" and legacy \"haptics.impact\" still authorize the haptics.impact command"
    requirement: "CTRL-03"
    verification:
      - kind: unit
        ref: "test/crosswake/manifest/builder_test.exs#haptics vocabulary flip (D-57, D-58, D-60, D-61)"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts (npx playwright test route_tour.spec.ts)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The built manifest carries exactly one haptics capability-registry entry, and no capability's id appears in its own legacy_ids (universal invariant)"
    verification:
      - kind: unit
        ref: "test/crosswake/manifest/builder_test.exs#the built manifest carries exactly one haptics capability-registry entry when only the family id is declared (D-60)"
        status: pass
      - kind: unit
        ref: "test/crosswake/manifest/builder_test.exs#no capability in the built manifest lists its own id inside its own legacy_ids (D-60, universal invariant)"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix crosswake.doctor emits an advisory (never error) finding naming each route declaring a legacy capability id and the family id to use instead"
    verification:
      - kind: unit
        ref: "test/crosswake/doctor/doctor_test.exs#legacy capability id doctor advisory (D-58, D-59, D-63)"
        status: pass
      - kind: unit
        ref: "test/crosswake/doctor/formatter_test.exs#renders the capability.legacy_capability_id advisory without a fall-through (Phase 154, D-58/D-59)"
        status: pass
    human_judgment: false
  - id: D4
    description: "guides/route_policy.md, guides/capabilities.md, and guides/bridge.md teach the family id as route-policy vocabulary and state the wire command keeps its dotted form"
    verification:
      - kind: unit
        ref: "test/crosswake/guides/ (mix test test/crosswake/guides/ test/crosswake/proof/phase69_docs_contract_parity_test.exs)"
        status: pass
    human_judgment: false

# Metrics
duration: 25min
completed: 2026-07-29
status: complete
---

# Phase 154 Plan 01: The Control-Contract Seam — Vocabulary Flip Summary

**Flipped the published haptics capability vocabulary from the dotted command form to the family form, fixed a self-referential `legacy_ids` manifest bug, added doctor's legacy-id advisory, and updated three guides — D-76's PR #1 (no behavior change).**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- The reference host's approval route now declares `capabilities: ["haptics"]` (family form); the legacy `capabilities: ["haptics.impact"]` form still authorizes the `haptics.impact` command indefinitely via `legacy_ids` — no behavior change, per D-57/D-63.
- Fixed the self-referential `legacy_ids` bug in `Manifest.Builder.compatibility_capability_attrs/2` universally (not just for haptics) — a constructed compatibility-path capability no longer carries its own id inside its own `legacy_ids` list.
- Added `mix crosswake.doctor`'s `capability.legacy_capability_id` advisory: names every route still declaring a legacy capability id, alongside the family id to use instead, at `:warning` severity — never `:error`, so it can never fail doctor's exit code.
- `guides/route_policy.md`, `guides/capabilities.md`, and `guides/bridge.md` now teach the family-for-policy / command-for-wire distinction explicitly, plus the permanent legacy-acceptance and doctor-advisory framing.
- The coupled Playwright assertion at `route_tour.spec.ts:168` was updated in the same change as the router edit — confirmed the merge-blocking browser lane stays green (`npx playwright test route_tour.spec.ts`, 4/4 passed).

## Task Commits

Each task was committed atomically:

1. **Task 1: Flip the published vocabulary to the family form and fix the duplicate manifest entry** - `94151bd5` (feat)
2. **Task 2: Add the doctor legacy-capability-id advisory** - `ad9001d7` (feat)
3. **Task 3: Teach the family/command distinction in the guides** - `4409d441` (docs)

_Note: this plan's tasks were not TDD-gated per-task (`tdd="true"` at the task level meant "add regression coverage alongside the fix," which was folded into each task's single commit rather than split into separate RED/GREEN commits)._

## Files Created/Modified
- `lib/crosswake/manifest/builder.ex` - `compatibility_capability_attrs/2` drops `legacy_ids` before returning the constructed compatibility-path capability
- `lib/crosswake/doctor/doctor.ex` - adds `legacy_capability_id_findings/1`, folded into the existing findings accumulation chain
- `examples/phoenix_host/lib/crosswake_example/router.ex` - approval route capability flips to `["haptics"]`
- `examples/phoenix_host/e2e/route_tour.spec.ts` - router-source assertion flips to `capabilities: ["haptics"]`; wire-command assertions (196-201) untouched
- `examples/ios_shell_host/Fixtures/crosswake_manifest.json`, `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` - duplicate `haptics.impact` capability-registry entry removed, `camera` compatibility entry's self-referential `legacy_ids` cleared, `saas-approval` route capability flipped
- `guides/route_policy.md`, `guides/capabilities.md`, `guides/bridge.md` - family/command distinction taught explicitly, plus permanent legacy-acceptance and doctor-advisory framing
- `test/crosswake/manifest/builder_test.exs` - 5 new tests: both authorization forms, single-haptics-entry invariant, universal no-self-reference invariant, unknown-id compatibility path
- `test/crosswake/doctor/doctor_test.exs` - 4 new tests plus two router fixtures (`LegacyCapabilityRouter`, `FamilyOnlyCapabilityRouter`)
- `test/crosswake/doctor/formatter_test.exs` - 1 new test proving the new finding code renders without a fall-through
- `gen_manifest.exs` - fixed to match `Crosswake.Manifest.compile/1`'s current return shape (see Deviations)

## Decisions Made
- Applied the `legacy_ids`-drop fix universally in `compatibility_capability_attrs/2` rather than special-casing haptics, per the plan's `must_haves` ("assert this universally over the whole registry, not just haptics").
- Manually patched the two committed manifest fixtures with a scoped, narrow diff instead of running a full `gen_manifest.exs` regeneration, once regeneration was confirmed to pull in ~2 months of unrelated router drift (see Deviations below). The resulting diff is byte-identical to what a scoped regeneration of only the affected keys would produce.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed `gen_manifest.exs`'s stale API usage**
- **Found during:** Task 1 (regenerating the committed manifest fixtures)
- **Issue:** `gen_manifest.exs` pattern-matched `{:ok, %{json: json}} = Crosswake.Manifest.compile(...)`, but `Crosswake.Manifest.compile/1`'s current return shape is `{:ok, %{manifest: manifest, warnings: warnings}}` (the JSON rendering was split into a separate `Crosswake.Manifest.render/1` function at some point after this script was last touched, per `git log` — May 20, 2026). The script could not run at all, with or without our Phase 154 changes.
- **Fix:** Changed the script to call `Crosswake.Manifest.render(manifest)` explicitly after matching the current `compile/1` return shape.
- **Files modified:** `gen_manifest.exs`
- **Verification:** Ran the fixed script successfully via `MIX_ENV=test mix run -e 'Crosswake.TestSupport.ExampleHost.load!(); Code.require_file("gen_manifest.exs")'`; confirmed it writes valid JSON to both manifest paths.
- **Committed in:** `94151bd5` (Task 1 commit)

**2. [Rule 1 - Bug, scope-bounded] Manual scoped patch instead of full manifest regeneration**
- **Found during:** Task 1 (regenerating the committed manifest fixtures)
- **Issue:** Running the (now-fixed) `gen_manifest.exs` against the current router produced an ~850-line diff across the two manifest fixtures — the committed fixtures were roughly two months stale relative to the router (missing dozens of routes added across Phases 149-152: `bridge-proof`, `decks-*`, `fieldserv-*`, `learnloop_daily_pack`, etc.), plus a fresh `generated_at` timestamp. Committing that full diff under this plan's commit would have buried the Phase 154 change (duplicate haptics entry removal + router capability flip) inside unrelated, out-of-scope drift catch-up, violating the scope-boundary rule ("only auto-fix issues directly caused by the current task's changes").
- **Fix:** Reverted the full regeneration and applied a narrow, scripted patch instead, touching only: (1) removed the duplicate `"haptics.impact"` capability-registry entry, (2) cleared the self-referential `legacy_ids` on the pre-existing `"camera"` compatibility entry (same bug class, same fix, already present in the stale fixture before this plan touched it), and (3) flipped the `saas-approval` route's `capabilities` literal to `["haptics"]`. This is byte-identical to what a full regeneration would have produced for those specific keys.
- **Files modified:** `examples/ios_shell_host/Fixtures/crosswake_manifest.json`, `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json`
- **Verification:** `diff` confirms the two fixture files remain byte-identical to each other after the patch; `python3 -c "import json; json.load(...)"` confirms both remain valid JSON; `git diff --stat` shows a 27-line diff (not ~850); all acceptance-criteria greps pass (`"haptics.impact": {` count is 0 in both files).
- **Committed in:** `94151bd5` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking-issue fix, 1 scope-bounded bug fix)
**Impact on plan:** Both were necessary to complete Task 1's stated action ("regenerate both committed manifest fixtures") without either leaving the fixtures broken or burying the plan's actual change inside unrelated drift. No scope creep — the unrelated ~2-months-stale drift itself is out of scope and was left untouched, not fixed.

## Issues Encountered
- `mix run -e '<expr>' <file>.exs` does not run both the `-e` expression and the file — Elixir's script runner treats the trailing positional as an argument to the eval, not a second thing to require. Worked around by using `Code.require_file/1` inside the `-e` expression itself.
- `test/support/example_host.ex`'s `load!/0` requires `examples/phoenix_host`'s dev-env code to already be compiled (`_build/dev/lib/*/ebin`), and itself is only compiled under `MIX_ENV=test` (it lives in `test/support/`) — the working invocation is `MIX_ENV=test mix run -e 'Crosswake.TestSupport.ExampleHost.load!(); Code.require_file("gen_manifest.exs")'` from the repo root.
- `Crosswake.Router`'s route policy validator requires `security:` whenever `capabilities` (or offline/pack/sync policy) is declared — the first draft of the new doctor test's router fixtures omitted it and failed manifest compilation with a clear error naming the missing field; added `security: :standard` to both fixtures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- D-76 PR #1 (vocabulary flip) is complete and verified: core hermetic suite green (1071 tests, 0 failures) and the merge-blocking Playwright route tour green (4/4).
- Plan 02 (per its own scope note in Task 3) owns `guides/capability_map.md` and `guides/support_matrix.md` — confirmed neither was touched here (`git diff --name-only` excludes both).
- No blockers for subsequent Phase 154 plans (the seam itself, `Bridge.push/3`, HRDN-01 migration) — this plan's scope was deliberately isolated to the vocabulary/docs/manifest layer per D-76's PR sequencing.

## Self-Check: PASSED

All 13 files listed under "Files Created/Modified" confirmed present on disk; all 3 task commit hashes (`94151bd5`, `ad9001d7`, `4409d441`) confirmed present in `git log --oneline --all`.

---
*Phase: 154-the-control-contract-seam*
*Completed: 2026-07-29*
