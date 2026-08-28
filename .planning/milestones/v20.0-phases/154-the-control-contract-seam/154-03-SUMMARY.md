---
phase: 154-the-control-contract-seam
plan: 03
subsystem: bridge
tags: [elixir, phoenix-liveview, bridge, control-contract-seam, denial-vocabulary, liveviewtest]

# Dependency graph
requires:
  - phase: 154-the-control-contract-seam (154-01, 154-02)
    provides: family-form capability vocabulary, fixed legacy_ids self-reference
      bug, Capability.interaction + widened @enforce_keys, manifest_schema_version
      1.1.0
provides:
  - "Crosswake.Bridge — the LiveView-facing control-contract seam: attach/1,
    on_mount/4, push/3, the reserved-event handle_event interceptor, and the
    server-armed wiring-deadline handle_info interceptor"
  - "Crosswake.Bridge.Reply — the adopter-facing typed reply struct delivered to
    handle_info/2 as {:crosswake_bridge, ref, %Reply{}}"
  - "Crosswake.Bridge.UndeclaredCapabilityError and Crosswake.Bridge.NotMountedError
    — the two named, unconditional-raise exceptions for the outbound preflight"
  - "Registry.capability_command/1 — the small family->command reverse lookup
    push/3 needs, reusing Registry's existing bijective @capability_commands map"
  - "Crosswake.Shell.Denial's 14th reason, :shell_unreachable, with a
    reason-scoped details.failing_moment default (:hook_not_wired) and the
    documented four-value failing_moment vocabulary"
  - "A wire-reply decoder in Crosswake.Bridge that flattens the doubly-nested
    wire denial and tolerates denial reason strings outside the closed
    14-reason vocabulary (resolving to :unavailable_capability, preserving the
    raw string in details.raw_reason)"
  - "test/support/bridge_live_view_case.ex — the first self-contained
    Phoenix.Endpoint + Router + LiveView test harness in core's hermetic suite,
    proving the seam via a real Phoenix.LiveViewTest round trip"
affects: [154-04, 154-05, 154-06, 154-07, 154-08]

# Tech tracking
tech-stack:
  added:
    - "lazy_html (>= 0.1.0, test-only) — required by phoenix_live_view's own
      installed runtime for Phoenix.LiveViewTest element/2 + render/1 parsing"
  patterns:
    - "Reserved-event interception via Phoenix.LiveView.attach_hook/4 on BOTH
      :handle_event (the wire reply/ack/unreachable-fact events) and
      :handle_info (the server-armed ack-deadline timer message) — both halt on
      Crosswake's own reserved messages and {:cont, socket} on everything else"
    - "Self-contained Phoenix.Endpoint test fixture via config/1+config/2
      overrides (defoverridable config: 1, config: 2) instead of Application
      env, mirroring phoenix_live_view's own test/support/endpoint.ex"
    - "exits_with/3 test helper: Process.unlink the LiveViewTest proxy pid, then
      catch the :exit a raise inside handle_event/handle_info propagates as —
      the exact pattern phoenix_live_view's own hooks_test.exs uses"

key-files:
  created:
    - lib/crosswake/bridge.ex
    - lib/crosswake/bridge/reply.ex
    - test/support/bridge_live_view_case.ex
    - test/crosswake/bridge/push_test.exs
  modified:
    - lib/crosswake/bridge/registry.ex
    - lib/crosswake/bridge/denial.ex
    - lib/crosswake/shell/denial.ex
    - test/crosswake/shell/denial_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/fixtures/proof/phase52_publish_readiness.json
    - mix.exs
    - mix.lock

key-decisions:
  - "attach/1 requires :crosswake_manifest and :crosswake_route_id already
    assigned on the socket (raising ArgumentError immediately if either is
    missing) rather than deriving them automatically — no runtime mechanism to
    resolve 'this LiveView's route id' from a bare socket exists anywhere in
    the codebase today (verified: Activation.resolve/2 and every other manifest
    consumer receives the manifest as an explicit argument). This keeps push/3's
    authorization path fully explicit and matches the project's existing
    no-hidden-magic convention; Plan 06/07's install guide documents the
    pattern for the reference host."
  - "The router file/line half of the UndeclaredCapabilityError message is
    best-effort, not authoritative: Phoenix.Router.routes/1 (router.__routes__/0)
    deliberately strips :line from its public route summary (verified by direct
    read of deps/phoenix/lib/phoenix/router.ex), so the line number is recovered
    by grepping the resolved router source file's text for the route id
    literal — mirroring doctor's own host-file-grep precedent (D-37) rather than
    inventing a new mechanism."
  - "The exception modules (NotMountedError, UndeclaredCapabilityError) are
    defined at the top level of lib/crosswake/bridge.ex, not nested inside
    defmodule Crosswake.Bridge — Elixir concatenates ALL enclosing module
    segments onto a nested defmodule's name regardless of whether the short or
    fully-qualified form is used, so nesting would have produced
    Crosswake.Bridge.Crosswake.Bridge.NotMountedError. Discovered via a failing
    acceptance-criteria grep during execution; fixed and verified against a
    real round trip."
  - "An out-of-vocabulary inbound denial reason resolves to :unavailable_capability,
    never :shell_unreachable — the latter would falsely assert no shell answered
    when one did, just with a string outside the closed vocabulary. The raw
    string survives in details.raw_reason for diagnosis."
  - "Only three of the four failing_moment values are integration-reachable via
    a full LiveViewTest round trip in this plan: :hook_not_wired (the
    ack-deadline timer), :no_transport and :transport_error (the
    crosswake:bridge_unreachable fact event, simulated via render_hook since no
    JS hook ships until Plan 06). :reply_timeout — the second, later-arriving
    timer that fires after a successful ack but before a reply — is Plan 04's
    scope (\"two timers\"); this plan proves it only at the
    Crosswake.Shell.Denial.new/1 constructor level (a unit test), matching
    D-77's scope-honesty note not to pull Plan 04 work forward."

patterns-established:
  - "Fire-and-forget push/3 calls (no ref: option) still fully resolve their
    in-flight bookkeeping (ack-deadline fires, entry is popped) but deliver
    nothing to handle_info/2 — Crosswake consumes the reply internally (D-21).
    Proven via a test-support LiveView that re-renders its own private
    in-flight-count assign after an unrelated event, since nothing else
    triggers a render for a push the adopter never asked to be told about."

requirements-completed: [CTRL-01, CTRL-02, CTRL-03]

coverage:
  - id: D1
    description: "A LiveView that calls Crosswake.Bridge.attach/1 in mount/3 and then Bridge.push/3 for a declared capability receives a correlated typed %Crosswake.Bridge.Reply{} in its own handle_info/2, proven by a real Phoenix.LiveViewTest round trip"
    requirement: "CTRL-01"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#the tracer round trip (CTRL-01, D-17, D-18, D-36)"
        status: pass
    human_judgment: false
  - id: D2
    description: "No shell (hook-not-wired ack-deadline), an unreachable-fact event (no_transport/transport_error), and a shell refusal all collapse to %Crosswake.Shell.Denial{reason: :shell_unreachable}, distinguished only by details.failing_moment; a doubly-nested wire denial decodes to a single flat struct; an out-of-vocabulary reason string neither crashes nor is laundered"
    requirement: "CTRL-02"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#the denial collapse (CTRL-02)"
        status: pass
      - kind: unit
        ref: "test/crosswake/shell/denial_test.exs#Compatibility.finding_to_denial/2 never yields :shell_unreachable (D-15)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pushing an undeclared capability family raises the named Crosswake.Bridge.UndeclaredCapabilityError unconditionally, naming the route id, the missing family, what IS declared, the LiveView module, a best-effort router file/line, and the literal fix line; an empty capabilities list and a case-mismatched family are not a wildcard; a socket that never attached raises NotMountedError"
    requirement: "CTRL-03"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#the loud preflight (CTRL-03)"
        status: pass
    human_judgment: false

# Metrics
duration: ~80min
completed: 2026-07-29
status: complete
---

# Phase 154 Plan 03: The Control-Contract Seam — Tracer, Loud Preflight, and Denial Collapse Summary

**Shipped `Crosswake.Bridge` — `push/3`, `attach/1`, `on_mount/4`, the reserved-event/wiring-deadline interceptors, the adopter-facing `Reply` struct, the 14th `:shell_unreachable` denial reason, and the tolerant wire-reply decoder — proven end-to-end by the first self-contained `Phoenix.LiveViewTest` harness in core's hermetic suite.**

## Performance

- **Duration:** ~80 min
- **Tasks:** 3
- **Files modified:** 12 (4 created, 8 modified)

## Accomplishments

- `Crosswake.Bridge.attach/1` (+ `on_mount/4` delegating to it) registers a `:handle_event` reserved-event interceptor and a `:handle_info` server-armed wiring-deadline interceptor on a LiveView socket; `push/3` mints a correlation id, authorizes through `Registry.lookup/4` (the single authorization source for both directions, D-04), and dispatches via `push_event/3`. A correlated ok/deny reply arrives at the adopter's own `handle_info/2` as `{:crosswake_bridge, ref, %Crosswake.Bridge.Reply{}}` — a typed struct, never raw wire JSON.
- Proven with a real `Phoenix.LiveViewTest` round trip against a from-scratch self-contained `Phoenix.Endpoint` + `Crosswake.Router`-based router + two test LiveViews (`test/support/bridge_live_view_case.ex`) — the first such harness anywhere in core's hermetic test suite (previously, every `Phoenix.LiveViewTest` usage in core depended on the checked-in example host via `:requires_example_host`).
- `Crosswake.Bridge.UndeclaredCapabilityError` raises unconditionally (every environment, including `:prod`) for an outbound preflight failure, with a message naming the route id, the missing family, what IS currently declared, the calling LiveView module, a best-effort router file/line (recovered via a doctor-style host-file grep, since `Phoenix.Router.routes/1` deliberately strips `:line` from its public API), and the literal capabilities line to add. `Crosswake.Bridge.NotMountedError` covers the "never attached" case. No `available?/2` or `connected?/1` predicate ships.
- `Crosswake.Shell.Denial` gains its 14th reason, `:shell_unreachable`, with a reason-scoped `details.failing_moment` default and the documented four-value vocabulary (`:no_transport | :reply_timeout | :transport_error | :hook_not_wired`) — one reason, four variants, never four reasons. `Compatibility.finding_to_denial/2` is proven (property test over every known and an unknown `Finding` axis) to never produce it.
- `Crosswake.Bridge`'s wire-reply decoder flattens the documented doubly-nested `Bridge.Denial` wire shape into a single flat `Shell.Denial`, and tolerates denial reason strings outside the closed vocabulary (resolving to `:unavailable_capability`, preserving the raw string under `details.raw_reason`) — the exact latent contract violation RESEARCH.md's D-16 warned would surface the moment replies are parsed server-side.

## Task Commits

Each task was committed as close to atomically as the interleaved, single-module implementation allowed:

1. **Tasks 1 + 2: the tracer and the loud preflight** — `7684c075` (feat)
2. **Task 3: collapse every client-detectable failure into one denial shape** — `f5c4297c` (feat)

_Note on commit granularity: Tasks 1 and 2 share one commit because `Crosswake.Bridge`'s `push/3` is a single cohesive function whose authorization-outcome branching (dispatch vs. raise) could not be meaningfully split across two commits without leaving the file in a temporarily broken state. Task 3's wire-decode tolerance was written into the same `bridge.ex` in the same pass (needed for the tracer's own deny-path tests), so its commit captures the parts that WERE cleanly separable: the `Bridge.Denial` moduledoc demotion, the extended `Shell.Denial` test coverage, the `doctor_test.exs` fixup, and the golden-fixture patch. This mirrors Plan 01/02's own documented precedent of not force-splitting a holistically-implemented change into artificial per-task diffs (154-01-SUMMARY.md, 154-02-SUMMARY.md)._

## Files Created/Modified

- `lib/crosswake/bridge.ex` (NEW) — the facade: `attach/1`, `on_mount/4`, `push/3`, the reserved-event and wiring-deadline interceptors, in-flight bookkeeping, the loud preflight, and the wire-reply decoder. `Crosswake.Bridge.NotMountedError` and `Crosswake.Bridge.UndeclaredCapabilityError` are defined at the top of the file (not nested — see Deviations).
- `lib/crosswake/bridge/reply.ex` (NEW) — `Crosswake.Bridge.Reply`, the adopter-facing typed reply struct.
- `lib/crosswake/bridge/registry.ex` — adds `capability_command/1`, the reverse lookup from a capability family to its wire command (reuses the existing bijective `@capability_commands` map; no new authorization logic).
- `lib/crosswake/bridge/denial.ex` — moduledoc demotes it to an internal wire-decode envelope (D-28).
- `lib/crosswake/shell/denial.ex` — `:shell_unreachable` as the 14th `@reasons`/`@type reason` entry, the `failing_moment` typedoc/type, and the reason-scoped details-defaulting clause.
- `test/support/bridge_live_view_case.ex` (NEW) — self-contained `Phoenix.Endpoint`, `Crosswake.Router`-based `Router`, `TracerLive`, `NotMountedLive`, and the `exits_with/3` test helper.
- `test/crosswake/bridge/push_test.exs` (NEW) — 19 tests covering the tracer round trip, the loud preflight, and the denial collapse.
- `test/crosswake/shell/denial_test.exs` — extended with `:shell_unreachable`/`failing_moment` coverage and the `finding_to_denial/2` never-yields-`:shell_unreachable` property test.
- `test/crosswake/doctor/doctor_test.exs` — the exact 13-reason `denial_reasons` assertion updated to 14 (adds `"shell_unreachable"`).
- `test/fixtures/proof/phase52_publish_readiness.json` — scoped patch (two `shell_unreachable` occurrences) matching Plan 01/02's precedent of never doing a full regeneration that would pull in unrelated drift.
- `mix.exs` / `mix.lock` — adds `{:lazy_html, ">= 0.1.0", only: :test}`.

## Decisions Made

- `attach/1` requires `:crosswake_manifest` and `:crosswake_route_id` to already be assigned on the socket rather than deriving them automatically — no such derivation mechanism exists anywhere in the codebase today (verified: every manifest consumer, e.g. `Activation.resolve/2`, receives the manifest as an explicit argument, never from a global accessor). This keeps the authorization path fully explicit, matching the project's no-hidden-magic convention.
- The router file/line in `UndeclaredCapabilityError`'s message is recovered best-effort by grepping the resolved router source file's text for the route id literal, since `Phoenix.Router.routes/1` deliberately strips `:line` from its public API (verified against `deps/phoenix/lib/phoenix/router.ex`) — mirroring doctor's own host-file-grep precedent (D-37) rather than inventing a new mechanism.
- Only `:hook_not_wired`, `:no_transport`, and `:transport_error` are integration-reachable via a full round trip in this plan; `:reply_timeout` (the second, later timer) is Plan 04's scope per D-77's scope-honesty note, and is proven only at the `Shell.Denial.new/1` constructor level here.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `Registry.capability_command/1`**
- **Found during:** Task 1 (writing `push/3`)
- **Issue:** `push/3`'s public API takes a capability FAMILY (e.g. `"haptics"`), but `Registry.lookup/4` requires the wire COMMAND (e.g. `"haptics.impact"`). `Registry`'s existing `@capability_commands` map is command→family only; no reverse lookup existed.
- **Fix:** Added `Registry.capability_command/1`, a pure reverse lookup over the same existing (bijective) map — no new authorization logic, no new map.
- **Files modified:** `lib/crosswake/bridge/registry.ex`
- **Verification:** `mix test test/crosswake/bridge/registry_test.exs` green; exercised throughout `push_test.exs`.
- **Committed in:** `7684c075`

**2. [Rule 1 - Bug] Fixed double module-name prefixing on the two exception modules**
- **Found during:** Task 2 (running the acceptance-criteria greps)
- **Issue:** `defmodule Crosswake.Bridge.NotMountedError do ... end` nested inside `defmodule Crosswake.Bridge do ... end` compiled to `Crosswake.Bridge.Crosswake.Bridge.NotMountedError` — Elixir concatenates ALL enclosing module segments onto a nested `defmodule`'s name regardless of whether the short or fully-qualified form is written. This broke every raised-exception test (`exits_with/3`'s pattern match on the exception module never matched).
- **Fix:** Moved both exception modules to the top level of `lib/crosswake/bridge.ex` (outside `defmodule Crosswake.Bridge`), with an explicit `alias` inside `Crosswake.Bridge` so internal `raise` call sites keep the bare short names.
- **Files modified:** `lib/crosswake/bridge.ex`
- **Verification:** `mix test test/crosswake/bridge/push_test.exs` — all `exits_with/3`-based tests pass; `grep -c 'defmodule Crosswake.Bridge.UndeclaredCapabilityError'`/`NotMountedError` acceptance greps both return 1.
- **Committed in:** `7684c075`

**3. [Rule 1 - Bug] `Phoenix.Router.routes/1` does not expose `:line` — fixed the router-location fallback**
- **Found during:** Task 2 (the router-location acceptance test)
- **Issue:** The original implementation assumed `Phoenix.Router.routes/1`'s returned route structs carried a `:line` field (matching the INTERNAL `Phoenix.Router.Route` struct definition). Direct verification (`deps/phoenix/lib/phoenix/router.ex`) showed the public `__routes__/0`/`routes/1` deliberately strips `:line` via `Map.take(&1, [:verb, :path, :plug, :plug_opts, :helper, :metadata])` — the field is compile-time-only, not part of the public runtime API. The message fell back to "(router location unavailable)" even when a real router was present.
- **Fix:** Recover the line number best-effort by reading the resolved router source file's text and finding the line containing the route id literal — advisory, never authoritative, matching doctor's own host-file-grep precedent (D-37).
- **Files modified:** `lib/crosswake/bridge.ex`
- **Verification:** `mix test test/crosswake/bridge/push_test.exs` — the D-10 message-content test asserts the router source filename appears in the raised message.
- **Committed in:** `7684c075`

**4. [Rule 1 - Bug] `:shell_unreachable`'s addition broke two pre-existing exact-list assertions**
- **Found during:** Task 3 (full hermetic suite run)
- **Issue:** `test/crosswake/doctor/doctor_test.exs`'s `report.bridge.denial_reasons` assertion hardcoded the exact 13-reason list; `test/fixtures/proof/phase52_publish_readiness.json`'s golden fixture embedded the same 13-string denial vocabulary in an array and a hint string. Both broke the instant `:shell_unreachable` became the 14th reason — an expected, in-scope consequence of this plan's own change, not an unrelated regression.
- **Fix:** Added `"shell_unreachable"` to `doctor_test.exs`'s expected list; scoped-patched the two exact occurrences in the golden fixture (not a full regeneration, to avoid pulling in unrelated drift, per Plan 01/02's precedent).
- **Files modified:** `test/crosswake/doctor/doctor_test.exs`, `test/fixtures/proof/phase52_publish_readiness.json`
- **Verification:** `mix test --exclude requires_example_host --exclude advisory_only` — full suite green, 1113 tests, 0 failures.
- **Committed in:** `f5c4297c`

---

**Total deviations:** 4 auto-fixed (1 blocking-issue addition, 3 bug fixes)
**Impact on plan:** All four were necessary to make the plan's own stated verification bar (`mix test --exclude requires_example_host --exclude advisory_only` green, `mix compile --warnings-as-errors` green, all acceptance-criteria greps passing) actually true. No scope creep — each fix is scoped to the specific defect found, and none touches `examples/` (`git diff --name-only | grep -c '^examples/'` returns 0, confirming D-76's PR #2a boundary held).

## Known Stubs

None. Every behavior claimed in this summary is backed by a passing automated test exercised in this session (`mix test test/crosswake/bridge/push_test.exs test/crosswake/shell/denial_test.exs` and the full hermetic suite), not a hardcoded or mocked value.

## Issues Encountered

- Building the first self-contained `Phoenix.Endpoint` + `Router` + `LiveView` test harness in core's hermetic suite required reverse-engineering the minimal working shape from `phoenix_live_view`'s own (not distributed via Hex) `test/support/endpoint.ex`/`router.ex`, since no in-repo precedent existed (every prior core `Phoenix.LiveViewTest` usage depended on the checked-in example host via `:requires_example_host`). The `config/1`+`config/2` override style (with `defoverridable config: 1, config: 2`) was the key piece not obvious from the public docs alone.
- `Phoenix.Router.routes/1`'s route structs do not carry `:line` (verified by direct source read) even though the internal, compile-time-only `Phoenix.Router.Route` struct definition documents one — a real gap between the internal representation and the public runtime API that isn't called out in the public docs.

## User Setup Required

None — no external service configuration required. `lazy_html` is a Hex package resolved automatically by `mix deps.get`.

## Next Phase Readiness

- D-76's PR #2a (the seam itself, unit-tested only) is complete and verified: `mix compile --warnings-as-errors` exits 0; `mix test test/crosswake/bridge/push_test.exs` exits 0 (19/19); the full core hermetic suite is green (1113 tests, 0 failures); `git diff --name-only | grep -c '^examples/'` returns 0.
- Plan 04 (correlation hardening: opaque `ref:`, per-mount epoch, the three-layer compare-and-delete, `resolve/2`, both timers, telemetry, the wire-denial decoder refinements, and `Crosswake.Bridge.Test`) can build directly on `Crosswake.Bridge`'s current in-flight-map shape (`%{correlation_id => %{ref:, acked:}}`) and the two existing lifecycle hooks — no rework needed.
- Plan 05 (the catalog-line guard, `CatalogGuard`) and Plan 06 (the JS hook, the iOS return leg) are unaffected by anything in this plan beyond the now-shipped `Crosswake.Bridge` facade they extend.
- No blockers for subsequent Phase 154 plans.

## Self-Check: PASSED

All files listed under "Files Created/Modified" confirmed present on disk; both task commit hashes (`7684c075`, `f5c4297c`) confirmed present in `git log --oneline --all`.

---
*Phase: 154-the-control-contract-seam*
*Completed: 2026-07-29*
