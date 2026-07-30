---
phase: 155-host-owned-fallback-components
plan: 02
subsystem: api
tags: [phoenix-liveview, exceptions, error-handling, bridge]

requires:
  - phase: 154-the-control-contract-seam
    provides: "Crosswake.Bridge.push/3, resolve/2, dispatched/2, the two top-level error modules, and the strict fetch_state!/1 raiser this plan widens/splits"
provides:
  - "Crosswake.Bridge.resolve/2 is a true no-op on an unattached socket (D-50) — safe to call from generated fallback code before any capability motivates attach/1"
  - "Crosswake.Bridge.UnknownCapabilityFamilyError — a distinct, correctly-worded raise for a capability family outside the bridge's closed vocabulary (D-51), separate from UndeclaredCapabilityError"
  - "Crosswake.Bridge.Registry.known_capability_families/0 — the vocabulary the new raiser lists"
affects: [155-03, 155-04, 155-05, 155-06, 155-07]

tech-stack:
  added: []
  patterns:
    - "Tolerant sibling of a strict fetch_state!/1 (maybe_fetch_state/1) added beside it rather than modifying the strict raiser, so the widening is provably scoped to one caller"
    - "Two-moment raise split: a private raiser per undeclared-capability moment, each a distinct exception module, so an error reporter groups them separately and moment C's remediation cannot regress into moment B's harmful advice"

key-files:
  created: []
  modified:
    - lib/crosswake/bridge.ex
    - lib/crosswake/bridge/registry.ex
    - test/crosswake/bridge/push_test.exs
    - test/support/bridge_live_view_case.ex

key-decisions:
  - "The plan's assumed test file test/crosswake/bridge_test.exs does not exist and never has; the real, established Bridge test file is test/crosswake/bridge/push_test.exs (Phase 154's CTRL-01/02/03 suite). Extended that file instead of creating a new one — one Bridge test file, not two competing conventions."
  - "D-51's acceptance criteria describe assert_raise directly against Bridge.push/3; a bare %Phoenix.LiveView.Socket{} built outside a live process cannot satisfy attach/1's call to Phoenix.LiveView.attach_hook/4 (it requires socket.private[:lifecycle], only initialized by real LiveView mount machinery — verified by KeyError :lifecycle not found when attempted). Used the file's established BridgeCase.exits_with/3 LiveView-process pattern instead, which is functionally equivalent (same raise, same exception type, same message assertions) without requiring a same-process raise."
  - "known_capability_families/0 added to Crosswake.Bridge.Registry (not duplicated in bridge.ex) so the new raiser's 'currently-known families' list and any future caller share one source of truth: Map.values(@capability_commands)."
  - "Two pre-existing push_test.exs tests (family 'camera' and family 'Haptics') were unknowingly exercising the exact collapsed-moment bug D-51 fixes — both families are outside the known vocabulary entirely, so post-fix they route to the new UnknownCapabilityFamilyError, not UndeclaredCapabilityError as originally asserted. Updated the first to use 'share' (a genuinely known-but-undeclared family) to preserve its original intent of testing moment B's rich message; updated the second's expected exception type to match its true moment-C nature."
  - "FALL-02 is NOT marked complete by this plan despite being named in the plan's requirements frontmatter — this plan only fixes two bridge.ex defects (D-50/D-51); FALL-02's actual substance (fallback rendering, focus trap, contrast gates, no importable Crosswake.UI.* tier) ships in later 155-0N plans, consistent with 155-01's SUMMARY precedent of deferring FALL-01/FALL-02/PROOF-01 to whichever plan actually closes each out."

requirements-completed: []  # FALL-02 deliberately deferred — see key-decisions above; this plan is prerequisite bridge-hardening work, not the fallback-rendering/contrast/focus-trap/ComponentTierGuard substance FALL-02 requires.

coverage:
  - id: D1
    description: "Crosswake.Bridge.resolve/2 returns the socket unchanged and raises nothing on a socket that never called attach/1 (D-50); push/3 and dispatched/2 stay strict as two negative controls"
    requirement: "FALL-02"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs describe \"resolve/2 on an unattached socket (D-50)\" (6 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A capability family outside the bridge's closed vocabulary raises the distinct Crosswake.Bridge.UnknownCapabilityFamilyError (bracketed id, no capabilities: remediation), while a known-but-undeclared family still raises UndeclaredCapabilityError with its capabilities: fix line intact (D-51)"
    requirement: "FALL-02"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs describe \"unknown capability family (D-51)\" (3 tests)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-30
status: complete
---

# Phase 155 Plan 02: The Two Shipped-Code Bridge Defects (D-50, D-51) Summary

**`Crosswake.Bridge.resolve/2` is now a true no-op on an unattached socket, and the vocabulary-miss raise is split into a distinct `Crosswake.Bridge.UnknownCapabilityFamilyError` with harmless remediation, each landed as its own bisectable commit.**

## Performance

- **Duration:** ~20 min
- **Tasks:** 2 completed
- **Files modified:** 4

## Accomplishments

- Added `Crosswake.Bridge.maybe_fetch_state/1` (the tolerant sibling of `fetch_state!/1`) and rerouted `resolve/2` through it — a socket that never called `attach/1` now returns unchanged with no raise, making the function's own "it never raises" docstring promise literally true. `push/3` and `dispatched/2` remain strict, proven by two dedicated negative-control tests.
- Ran the mutation control by hand: temporarily reverting `resolve/2`'s first line back to `fetch_state!/1` made the new unattached-socket test fail with `Crosswake.Bridge.NotMountedError` (observed red); reverting the mutation restored all 46 tests green.
- Added the top-level `Crosswake.Bridge.UnknownCapabilityFamilyError` and a private `raise_unknown_capability_family!/2`, rerouted `push/3`'s vocabulary-miss branch to it, and deleted the now-unreachable `{:error, :unsupported_command}` case arm (proven unreachable: `capability_command/1` only ever returns commands already known to `command_supported?/1`).
- Added `Crosswake.Bridge.Registry.known_capability_families/0` as the single source of truth the new error message lists.
- Extended `test/crosswake/bridge/push_test.exs` with both defects' coverage and fixed two pre-existing tests that were unknowingly exercising the exact bug being fixed.

## Task Commits

1. **Task 1: D-50 — widen resolve/2 to a true no-op on an unattached socket** - `bc90b25b` (fix)
2. **Task 2: D-51 — a distinct UnknownCapabilityFamilyError for the vocabulary-miss moment** - `3385de55` (fix)

## Files Created/Modified

- `lib/crosswake/bridge.ex` - `maybe_fetch_state/1`, widened `resolve/2`, new top-level `UnknownCapabilityFamilyError`, `raise_unknown_capability_family!/2`, `push/3`'s rerouted vocabulary-miss branch, deleted dead `:unsupported_command` arm, updated docstrings
- `lib/crosswake/bridge/registry.ex` - `known_capability_families/0`
- `test/crosswake/bridge/push_test.exs` - D-50 describe block (6 tests), D-51 describe block (3 tests), fixed two pre-existing tests ("camera" → "share", "Haptics" → expects `UnknownCapabilityFamilyError`), and unrelated warnings-as-errors cleanup (see Deviations)
- `test/support/bridge_live_view_case.ex` - `NotMountedLive` gained `"resolve"` and `"read_dispatched"` `handle_event` clauses so the unattached-socket fixture can exercise D-50's six behaviors

## Decisions Made

See `key-decisions` in frontmatter — summarized:
1. Extended the real `test/crosswake/bridge/push_test.exs` instead of creating the plan-assumed (nonexistent) `test/crosswake/bridge_test.exs`.
2. Used the file's established `BridgeCase.exits_with/3` LiveView-process pattern for D-51's raise assertions instead of literal `assert_raise` against a bare socket, because `Bridge.attach/1` requires real LiveView mount machinery (`socket.private[:lifecycle]`) that a directly-constructed `%Phoenix.LiveView.Socket{}` does not have.
3. `known_capability_families/0` lives in `Registry`, not duplicated in `bridge.ex`.
4. Fixed two pre-existing tests whose fixture families ("camera", "Haptics") were, unbeknownst to their original authors, outside the known vocabulary entirely — this plan's fix changes their raised exception type from the old collapsed `UndeclaredCapabilityError` to the new `UnknownCapabilityFamilyError`.
5. FALL-02 intentionally left unmarked in `requirements-completed` — see below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The plan's target test file `test/crosswake/bridge_test.exs` does not exist**
- **Found during:** Task 1, initial file read
- **Issue:** The plan's frontmatter (`files_modified`), `<read_first>`, and acceptance-criteria greps all reference `test/crosswake/bridge_test.exs`. That path has never existed in this repo (`git log --all` returns nothing for it). The real, established Bridge test suite (Phase 154's CTRL-01/02/03 coverage) lives at `test/crosswake/bridge/push_test.exs`, built on the `test/support/bridge_live_view_case.ex` / `bridge_test_helpers.ex` harness.
- **Fix:** Extended `test/crosswake/bridge/push_test.exs` instead of creating a second, competing Bridge test file. Adjusted the acceptance-criteria greps accordingly (ran them against `push_test.exs`, not the nonexistent path) — all Task 1 and Task 2 mechanical greps pass against the real file.
- **Files modified:** `test/crosswake/bridge/push_test.exs`, `test/support/bridge_live_view_case.ex`
- **Verification:** `mix test test/crosswake/bridge/push_test.exs --warnings-as-errors` — 49 tests, 0 failures.
- **Committed in:** `bc90b25b`, `3385de55`

**2. [Rule 3 - Blocking] Constructing a bare `%Phoenix.LiveView.Socket{}` for `assert_raise`-style D-51 tests fails with `KeyError: key :lifecycle not found`**
- **Found during:** Task 2, first attempt at direct-socket tests
- **Issue:** D-51's acceptance criteria describe `assert_raise Crosswake.Bridge.UnknownCapabilityFamilyError` / `assert_raise Crosswake.Bridge.UndeclaredCapabilityError` directly against `Bridge.push/3`. Building a socket via `%Phoenix.LiveView.Socket{}` + `Phoenix.Component.assign/2` + `Bridge.attach/1` outside a real `Phoenix.LiveViewTest` process fails inside `attach/1`'s call to `Phoenix.LiveView.attach_hook/4`, which requires `socket.private[:lifecycle]` — a key only initialized by real LiveView mount/channel machinery, not present on a hand-built struct (`%{live_temp: %{}}` has no `:lifecycle` key).
- **Fix:** Used the file's established `BridgeCase.exits_with/3` pattern (mount a real `TracerLive` via `Phoenix.LiveViewTest.live/2`, `render_click` to trigger `push/3` inside `handle_event/3`, catch the process `:exit`) — functionally equivalent (same exception type, same message content asserted) without requiring a same-process raise.
- **Files modified:** `test/crosswake/bridge/push_test.exs`
- **Verification:** All three D-51 tests pass; message content, bracketed id, and remediation-line presence/absence asserted exactly as specified.
- **Committed in:** `3385de55`

**3. [Rule 1 - Bug] Two pre-existing `push_test.exs` tests were exercising the exact collapsed-moment bug D-51 fixes**
- **Found during:** Task 2, running the full narrow suite after the fix
- **Issue:** `"pushing a capability the route never declared raises UndeclaredCapabilityError..."` used family `"camera"`, and `"a capability id differing only by case does not authorize and raises..."` used family `"Haptics"` (capital). Neither string is a value in `Registry`'s known-family vocabulary — both were, before this fix, silently routed through the same collapsed raiser as genuinely-known-but-undeclared families, so their pre-fix assertions (`UndeclaredCapabilityError`, fix-line remediation) happened to pass for the wrong reason. Post-fix, both now correctly hit moment C and raise `UnknownCapabilityFamilyError`, breaking the original assertions.
- **Fix:** Changed the first test's family to `"share"` (genuinely known, genuinely undeclared on the `bridge-tracer` route) to preserve its original intent of exercising moment B's rich remediation message. Changed the second test's expected exception to `Crosswake.Bridge.UnknownCapabilityFamilyError` and added a `refute` that its message carries no `capabilities:` remediation, since the test's real subject (case-sensitive exact-string matching) is enforced at the vocabulary-lookup stage, not the per-route declaration stage.
- **Files modified:** `test/crosswake/bridge/push_test.exs`
- **Verification:** Both updated tests pass; `mix test test/crosswake/bridge/push_test.exs --warnings-as-errors` — 49 tests, 0 failures.
- **Committed in:** `3385de55`

**4. [Rule 3 - Blocking] Recompiling `push_test.exs` surfaced three pre-existing, unrelated `--warnings-as-errors` failures**
- **Found during:** Task 1, first `--warnings-as-errors` run after editing the file
- **Issue:** Editing the file forced a fresh compile, surfacing three warnings that were latent (present before this plan's changes, masked by stale `.beam` caching from a prior non-`--warnings-as-errors` compile): an unused `alias Crosswake.Bridge` (never referenced bare — every usage in the file is fully qualified), unused default arguments on `dispatch!/2` (`dispatch!/1` was never called), and an unused `correlation_id` binding in the D-22 telemetry describe block.
- **Fix:** Removed the unused alias, dropped the unused default value from `dispatch!/2` (making `params` required — it was always passed explicitly at every call site), and prefixed the unused binding with `_`.
- **Files modified:** `test/crosswake/bridge/push_test.exs`
- **Verification:** `mix test test/crosswake/bridge/push_test.exs --warnings-as-errors` exits 0.
- **Committed in:** `bc90b25b`

---

**Total deviations:** 4 auto-fixed (2 Rule 3 - blocking, 1 Rule 1 - bug, 1 Rule 3 - blocking). No scope creep — all four were required to make the plan's own required verification command (`mix test ... --warnings-as-errors` exiting 0) actually pass against the real codebase.

## Issues Encountered

- **`mix test --warnings-as-errors` (full core suite) aborts on unrelated pre-existing warnings, not on test failures.** Consistent with the known pre-existing issue flagged for this executor and with 155-01's own SUMMARY: `mix test --warnings-as-errors` reports `1271 tests, 0 failures` and then aborts due to two warnings in files this plan never touched (`test/crosswake/offline/proof_lane_test.exs:37`, an unused `support` variable; `test/crosswake/proof/phase43_rulestead_advisory_test.exs:45`, a comparison-between-distinct-types warning). Both are pre-existing, out of scope per the Scope Boundary rule. Narrow, targeted runs (`mix test test/crosswake/bridge/`, `mix test test/crosswake/bridge/push_test.exs --warnings-as-errors`) are clean: 125 tests / 49 tests, 0 failures, 0 warnings.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Crosswake.Bridge.resolve/2` is now safe to call from generated adopter code before any capability motivates calling `attach/1` — the load-bearing precondition Phase 155's action-menu fallback (a later plan) needs before it can wire `resolve/2` into its `handle_event` clauses per D-25.
- The two undeclared-capability moments are now distinct, correctly-worded raises; a future error reporter groups them separately and the vocabulary-miss remediation can never regress into suggesting a route declaration that `Crosswake.Policy.Validator` would reject.
- `crosswake_fallbacks.ex.eex` (the 155-01 confirm-modal template) deliberately makes zero `Bridge` calls at all (D-07) — it does not yet call `resolve/2`, so this plan's fix has no template to wire into yet. That wiring is expected in the action-menu plan (155-05/06/07 per the phase pattern map), which is the actual caller D-50's docstring update anticipates.
- FALL-02 remains unmarked complete — its substance (fallback rendering, focus trap, contrast gates, `ComponentTierGuard`) ships in later plans.
- No blockers for Plan 155-03.

---
*Phase: 155-host-owned-fallback-components*
*Completed: 2026-07-30*

## Self-Check: PASSED

- FOUND: `.planning/phases/155-host-owned-fallback-components/155-02-SUMMARY.md`
- FOUND: commit `bc90b25b` (Task 1)
- FOUND: commit `3385de55` (Task 2)
