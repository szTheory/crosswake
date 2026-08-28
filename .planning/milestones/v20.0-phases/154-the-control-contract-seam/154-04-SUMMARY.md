---
phase: 154-the-control-contract-seam
plan: 04
subsystem: bridge
tags: [elixir, phoenix-liveview, bridge, telemetry, correlation, exactly-once, liveviewtest]

# Dependency graph
requires:
  - phase: 154-the-control-contract-seam (154-01, 154-02, 154-03)
    provides: family-form capability vocabulary, Capability.rebuild/interaction +
      manifest_schema_version 1.1.0, the Crosswake.Bridge tracer (push/3, attach/1,
      on_mount/4, the reserved-event/wiring-deadline interceptors, Crosswake.Bridge.Reply,
      the 14th :shell_unreachable denial reason, the first self-contained
      Phoenix.LiveViewTest harness in core's hermetic suite)
provides:
  - "A per-mount epoch (minted fresh every attach/1) embedded in Crosswake.Bridge's
    internally-generated correlation_id, and a two-layer telemetry-observable
    compare-and-delete (epoch match, then the server in-flight map) that makes
    exactly-once delivery structural rather than conventional (D-23)"
  - "attach/1 is now idempotent-safe to call twice on the same socket (detaches any
    previously attached hooks first) — this is what a reconnect/remount simulation
    rides on, and what makes a reply minted under a stale epoch drop as
    :foreign_epoch instead of crashing on a duplicate attach_hook id (D-24)"
  - "Crosswake.Bridge.resolve/2 — an atomic compare-and-delete for the on-page
    fallback race, called once from a fallback handler so a subsequent native reply
    for the same ask delivers nothing (D-25)"
  - "A second, independent server-side reply-deadline timer armed at push-time for
    timeout + reply_deadline_margin_ms (default 10s + 2s; :infinity opt-out for
    human-in-the-loop controls), distinct from the existing wiring-deadline timer,
    delivering :shell_unreachable/:reply_timeout when the shell acked but never
    replied (D-22)"
  - "Five new [:crosswake, :bridge, ...] events (push, reply, dropped, hook_ack,
    hook_missing) in Crosswake.Telemetry.events/0's active catalog, documented in
    guides/telemetry.md and covered by the merge-blocking phase133 declared<=>emitted
    contract test — zero adopter ref or correlation id ever enters metadata"
  - "Crosswake.Bridge.Test (test/support/bridge_test_helpers.ex) — reads a target
    LiveView's real in-flight bridge state and fabricates a correctly wire-shaped,
    correlated reply payload for render_hook/3, raising the named
    Crosswake.Bridge.NoAskInFlightError rather than fabricating an id when nothing
    (or more than one thing, with no :select) is in flight (D-77)"
affects: [154-05, 154-06, 154-07, 154-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Every bridge telemetry event (even the four that are not literally
      'spans of work' — reply/dropped/hook_ack/hook_missing) is emitted via
      :telemetry.span/3 rather than a bare :telemetry.execute/3, so every entry in
      Crosswake.Telemetry.events/0 keeps the SAME start/stop/exception 3-suffix shape
      uniformly — this is what lets attach_default_logger/1 and the phase133
      contract test pick up new catalog entries with zero special-casing"
    - "The per-mount epoch is embedded directly in the correlation_id string
      (cwbridge-e<epoch>-<random>) rather than tracked as separate correlated state,
      so a foreign-epoch reply is recognized independent of whether the in-flight map
      still happens to hold a matching key by coincidence"
    - "Crosswake.Bridge.attach/1 detaching its own previously-attached hooks before
      re-attaching (Phoenix.LiveView.detach_hook/3, itself a no-op if not attached)
      is the mechanism that makes attach/1 safe to call twice — the same call a real
      reconnect's fresh mount/3 would make"

key-files:
  created:
    - test/support/bridge_test_helpers.ex
  modified:
    - lib/crosswake/bridge.ex
    - lib/crosswake/telemetry.ex
    - guides/telemetry.md
    - test/support/bridge_live_view_case.ex
    - test/crosswake/bridge/push_test.exs
    - test/crosswake/telemetry_test.exs
    - test/crosswake/proof/phase133_telemetry_contract_test.exs

key-decisions:
  - "Implemented D-23's three layers as two Elixir-side gates plus the JS-hook's own
    client-side map (out of this plan's scope, Plan 06 owns the hook): epoch match
    checked FIRST and independently of map state (so a foreign-epoch drop is
    positively distinguishable from a plain not-found/duplicate drop in telemetry),
    then the existing Map.pop-based compare-and-delete on the server in-flight map."
  - "All five bridge telemetry events are implemented via :telemetry.span/3, even the
    four that are not literally 'spans of ongoing work' (reply/dropped/hook_ack/
    hook_missing) — this keeps every active catalog entry in the SAME 3-suffix shape
    every existing consumer (attach_default_logger/1, the phase133 contract test,
    guides/telemetry.md's own testing guidance) already assumes, rather than
    inventing a second, unsuffixed event convention that those consumers would
    silently fail to pick up."
  - "attach/1 was made idempotent (detach-then-reattach) rather than adding a
    separate 'remount' entry point — this is both the simplest way to simulate a
    LiveView reconnect in tests and matches what a real post-reconnect mount/3 would
    actually do (call attach/1 again on a fresh socket)."
  - "Crosswake.Bridge.Test's NoAskInFlightError is a top-level sibling module
    (Crosswake.Bridge.NoAskInFlightError), not nested under Crosswake.Bridge.Test —
    this mirrors the existing NotMountedError/UndeclaredCapabilityError precedent and
    also avoids a grep-ambiguous module-name prefix collision with the parent
    Crosswake.Bridge.Test module itself."
  - "track_in_flight's entry shape was widened from %{ref:, acked:} to also capture
    :command and :route_id (the values actually dispatched) — Crosswake.Bridge.Test
    reads these back verbatim rather than requiring a test author to re-supply them,
    so a fabricated reply is guaranteed wire-consistent with the real request."

patterns-established:
  - "Telemetry metadata for every new bridge event is deliberately narrow —
    route_id/capability/command/status/reason only, never the adopter ref or the
    correlation_id itself — to keep event cardinality bounded (T-154-16)."

requirements-completed: [CTRL-01, CTRL-02]

coverage:
  - id: D1
    description: "Twenty concurrent asks on one LiveView, each with a distinct ref, each deliver exactly one handle_info/2 reply matched by ref; a fire-and-forget push (no ref) delivers nothing but still resolves its bookkeeping"
    requirement: "CTRL-01"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#Task 1: epoch, exactly-once delivery, and resolve/2 (D-20..D-25)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exactly-once delivery is structural: a duplicate reply for an already-resolved correlation id is dropped, and a reply minted under a prior per-mount epoch is dropped as :foreign_epoch after a simulated reconnect — both drops are observable via the [:crosswake, :bridge, :dropped] telemetry event"
    requirement: "CTRL-02"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#Task 1: epoch, exactly-once delivery, and resolve/2 (D-20..D-25) — duplicate + foreign-epoch tests"
        status: pass
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#Task 2: two timers and telemetry (D-22) — the dropped-reply event fires once for a duplicate delivery and once for a foreign-epoch delivery"
        status: pass
    human_judgment: false
  - id: D3
    description: "Crosswake.Bridge.resolve(socket, ref) atomically clears an in-flight ask so a subsequent native reply for the same ask delivers nothing; calling it twice is a no-op and never raises"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#Task 1: epoch, exactly-once delivery, and resolve/2 (D-20..D-25) — resolve/2 tests"
        status: pass
    human_judgment: false
  - id: D4
    description: "A push with an explicit short timeout delivers :shell_unreachable/:reply_timeout at approximately timeout+margin; an :infinity timeout never fires the server backstop"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#Task 2: two timers and telemetry (D-22) — timeout tests"
        status: pass
    human_judgment: false
  - id: D5
    description: "All five [:crosswake, :bridge, ...] telemetry events (push, reply, dropped, hook_ack, hook_missing) are declared in Crosswake.Telemetry.events/0 with description/measurements/metadata, documented in guides/telemetry.md, and proven emitted end-to-end by the merge-blocking phase133 declared<=>emitted contract test"
    verification:
      - kind: unit
        ref: "test/crosswake/telemetry_test.exs#Phase 154 bridge telemetry catalog (D-22)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase133_telemetry_contract_test.exs#TELEM-04 Side A"
        status: pass
    human_judgment: false
  - id: D6
    description: "Crosswake.Bridge.Test.reply/2 fabricates a correlated ok or deny reply for a real in-flight ask (selectable among several via :select), and raises Crosswake.Bridge.NoAskInFlightError — never a fabricated id — when nothing (or an ambiguous set) is in flight"
    requirement: "CTRL-01"
    verification:
      - kind: unit
        ref: "test/crosswake/bridge/push_test.exs#Task 3: Crosswake.Bridge.Test (D-77)"
        status: pass
    human_judgment: false

# Metrics
duration: ~100min
completed: 2026-07-29
status: complete
---

# Phase 154 Plan 04: The Control-Contract Seam — Correlation Hardening Summary

**Hardened `Crosswake.Bridge`'s tracer into exactly-once, bounded-time machinery: a per-mount epoch embedded in the correlation id, `resolve/2` for the fallback race, a second server-side reply-deadline timer, five new `[:crosswake, :bridge, ...]` telemetry events, and `Crosswake.Bridge.Test` for simulating a hook reply without a shell.**

## Performance

- **Duration:** ~100 min
- **Tasks:** 3
- **Files modified:** 8 (1 created, 7 modified)

## Accomplishments

- `Crosswake.Bridge.push/3` mints a correlation id embedding a per-mount epoch (`cwbridge-e<epoch>-<random>`), minted fresh every `attach/1` call. `resolve_and_deliver/3` now gates every delivery through an epoch check (drops as `:foreign_epoch` if the epoch doesn't match the current mount) before the existing server-in-flight-map compare-and-delete (drops as `:duplicate` if already resolved) — exactly-once delivery is structural, not conventional (D-23), and each drop reason is independently observable via telemetry.
- `attach/1` is now safe to call more than once on the same socket — it detaches any previously attached bridge hooks before re-attaching, which is exactly what a real reconnect's fresh `mount/3` would do. This is what lets a reply minted under the previous epoch correctly drop as `:foreign_epoch` instead of the process crashing on a duplicate `attach_hook` id (D-24).
- `Crosswake.Bridge.resolve(socket, ref)` ships: an atomic compare-and-delete for the on-page fallback race (D-25), safe because a LiveView is one serialized process — called once, and a subsequent native reply for the same ask finds nothing to resolve. A second `resolve/2` call for the same ref is a no-op and never raises.
- A second, independent server-side reply-deadline timer is now armed at push-time for `timeout + reply_deadline_margin_ms` (defaults: `10_000ms` + `2_000ms`; `:infinity` opts a human-in-the-loop control out entirely), distinct from the existing wiring-deadline (ack) timer — it delivers `:shell_unreachable`/`:reply_timeout` when the shell acknowledged the request but never answered it (D-22).
- Five new `[:crosswake, :bridge, ...]` events (`push`, `reply`, `dropped`, `hook_ack`, `hook_missing`) join the active catalog in `Crosswake.Telemetry.events/0`, each implemented via `:telemetry.span/3` so they follow the exact same start/stop/exception shape every other catalog entry already uses — `attach_default_logger/1` and the merge-blocking `phase133_telemetry_contract_test.exs` pick them up with zero special-casing. Metadata is deliberately narrow (`route_id`/`capability`/`command`/`status`/`reason`) — the adopter `ref` and the correlation id itself never enter telemetry (D-20, T-154-16).
- `guides/telemetry.md` documents all five events, including the operator-facing note that `hook_missing`'s count "should always be zero in a healthy deploy."
- `test/support/bridge_test_helpers.ex` ships `Crosswake.Bridge.Test` — reads a target LiveView's *real* in-flight bridge state (via `view.pid`, the actual LiveView process, not the `Phoenix.LiveViewTest` proxy) and builds a correctly wire-shaped, correlated reply for `render_hook/3`. It raises the named `Crosswake.Bridge.NoAskInFlightError` — never fabricates a correlation id — when nothing (or an ambiguous set, with no `:select`) is in flight (D-77).

## Task Commits

Each task was committed as close to atomically as the interleaved implementation allowed:

1. **Tasks 1 + 2: epoch, exactly-once delivery, `resolve/2`, two timers, and the bridge telemetry catalog** — `c6dd7269` (feat)
2. **Task 3: ship `Crosswake.Bridge.Test` so a hook reply can be simulated** — `7410a39d` (feat)

_Note on commit granularity: Tasks 1 and 2 share one commit because `dispatch/6` (the correlation-id/epoch minting, both timer arm sites, and the `:telemetry.span/3` push wrapper) and `resolve_and_deliver/3` (the epoch/duplicate compare-and-delete AND the reply/dropped telemetry emission) are each a single cohesive function whose pieces could not be meaningfully split across two commits without leaving the file in a temporarily-broken intermediate state (references to not-yet-defined `emit_*` helpers, or an epoch check with nothing yet embedding an epoch to check against). This mirrors 154-01/02/03's own documented precedent of not force-splitting a holistically-implemented change into artificial per-task diffs. `test/crosswake/bridge/push_test.exs` was itself split across the two commits by content: Task 1/2 tests landed in the first commit, and the Task 3 describe block (which depends on the not-yet-committed `Crosswake.Bridge.Test` module) was withheld and appended in the second commit — both commits were verified to compile and pass their respective test slice standalone before committing (33 tests after commit 1, 38 after commit 2)._

## Files Created/Modified

- `lib/crosswake/bridge.ex` — per-mount epoch minting in `attach/1` (now idempotent via detach-then-reattach); `generate_correlation_id/1` embeds the epoch; `epoch_match?/2`; `resolve/2`; a second reply-deadline timer + its `handle_bridge_info` clause; `track_in_flight/5` widened to capture `:command`/`:route_id`; `resolve_and_deliver/3` rewritten with the epoch gate; five `emit_*` telemetry helpers; moduledoc sections on correlation/reconnects and the D-29 payload-ceiling forward-compat note.
- `lib/crosswake/telemetry.ex` — five new bridge entries added to `build_active_events/0`; moduledoc subsystem list updated.
- `guides/telemetry.md` — five new "Bridge: ..." sections (push, reply, dropped, hook_ack, hook_missing) plus the intro subsystem-list update.
- `test/support/bridge_live_view_case.ex` — `TracerLive` gains `replies_by_ref` (map assign proving 20 distinct deliveries), a `"remount"` handler (simulates reconnect by re-calling `attach/1`), a `"resolve"` handler (calls `Bridge.resolve/2`), and a `:timeout` push option pass-through.
- `test/crosswake/bridge/push_test.exs` (NEW test content, existing file) — "Task 1", "Task 2", and "Task 3" `describe` blocks covering the 20-concurrent-ref scenario, duplicate/foreign-epoch drops, `resolve/2`, the two timers, the five telemetry events, and `Crosswake.Bridge.Test`.
- `test/crosswake/telemetry_test.exs` — a focused test asserting `events/0`'s `:active` tier contains exactly the 5 Phase 154 bridge events with well-formed shape.
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` — Side A now also drives a real `Crosswake.Bridge` round trip (push, ack, ok reply, duplicate reply, and a second never-acked ask) through the same self-contained LiveViewTest harness `push_test.exs` uses, and asserts each of the five new bridge events fires with its declared measurement/metadata shape.
- `test/support/bridge_test_helpers.ex` (NEW) — `Crosswake.Bridge.Test` (`reply/2`, `in_flight/1`) and `Crosswake.Bridge.NoAskInFlightError`.

## Decisions Made

- Implemented the epoch check as an independent gate checked *before* the map lookup, so a foreign-epoch drop is positively distinguishable in telemetry (`:foreign_epoch`) from a plain duplicate (`:not-found`/`:duplicate`) even in cases where the in-flight map's own state would have produced the same "not found" result either way.
- Modeled all five new bridge telemetry events as `:telemetry.span/3` calls (not bare `:telemetry.execute/3`), even for the four that are not literally spans of ongoing work — this keeps every catalog entry in the exact same 3-suffix shape `attach_default_logger/1` and the phase133 contract test already assume, avoiding a second, unsuffixed event convention those consumers would silently fail to pick up.
- Made `attach/1` idempotent (detach existing hooks, then re-attach) rather than adding a dedicated "remount" API — this is both the simplest way to simulate a LiveView reconnect in tests and matches what a real post-reconnect `mount/3` would actually do.
- Named the helper's error `Crosswake.Bridge.NoAskInFlightError` (a top-level sibling of `Crosswake.Bridge.Test`, not nested under it) — mirrors the existing `NotMountedError`/`UndeclaredCapabilityError` precedent and avoids a grep-ambiguous prefix collision with `Crosswake.Bridge.Test` itself (discovered mid-execution; see Deviations).
- Widened the in-flight entry shape to carry `:command` and `:route_id` (not just `:ref`/`:acked`) so `Crosswake.Bridge.Test` can read back the real dispatched values rather than requiring a test author to re-supply them, guaranteeing a fabricated reply stays wire-consistent with the real request.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `attach/1` raised on a second call (blocking the reconnect/remount simulation)**
- **Found during:** Task 1 (writing the foreign-epoch test, which simulates a reconnect by re-calling `Bridge.attach/1` on the same socket)
- **Issue:** `Phoenix.LiveView.attach_hook/4` raises `ArgumentError` ("existing hook already attached") if the same hook id is attached twice. Since `attach/1` unconditionally called `attach_hook/4` for both the `:handle_event` and `:handle_info` hooks, calling it a second time on an already-attached socket (the exact shape of a reconnect simulation, and arguably a real defensive-programming concern for any adopter code that calls `attach/1` more than once) crashed the LiveView process.
- **Fix:** `attach/1` now calls `Phoenix.LiveView.detach_hook/3` for both hook ids before re-attaching (itself a documented no-op if the hook isn't present) — making `attach/1` idempotent-safe to call more than once, which is also exactly what a real post-reconnect `mount/3` would do.
- **Files modified:** `lib/crosswake/bridge.ex`
- **Verification:** `mix test test/crosswake/bridge/push_test.exs` — the foreign-epoch and dropped-reply-event tests (which both simulate a remount) pass; full hermetic suite green.
- **Committed in:** `c6dd7269`

**2. [Rule 1 - Bug] `Crosswake.Bridge.Test.NoAskInFlightError`'s original nested name collided with its own acceptance-criteria grep**
- **Found during:** Task 3 (verifying acceptance criteria greps after implementation)
- **Issue:** The error was first written as `Crosswake.Bridge.Test.NoAskInFlightError` (nested under the `Test` module's own namespace). `grep -c 'defmodule Crosswake.Bridge.Test' test/support/bridge_test_helpers.ex` — the plan's own stated acceptance check, expected to return `1` — returned `2`, because the nested error module's `defmodule` line also starts with the literal substring `Crosswake.Bridge.Test`.
- **Fix:** Renamed to `Crosswake.Bridge.NoAskInFlightError` — a top-level sibling module, mirroring the existing `Crosswake.Bridge.NotMountedError`/`Crosswake.Bridge.UndeclaredCapabilityError` precedent in the same file family — which both resolves the grep ambiguity and matches established naming convention more closely than the original nested name did.
- **Files modified:** `test/support/bridge_test_helpers.ex`, `test/crosswake/bridge/push_test.exs`
- **Verification:** `grep -c 'defmodule Crosswake.Bridge.Test' test/support/bridge_test_helpers.ex` now returns `1`; `mix test test/crosswake/bridge/push_test.exs` green (38/38).
- **Committed in:** `7410a39d`

---

**Total deviations:** 2 auto-fixed (2 bug fixes)
**Impact on plan:** Both were necessary to make the plan's own stated verification bar (a working reconnect simulation; the literal acceptance-criteria grep count) actually true. No scope creep — neither touches `examples/` (`git diff --name-only | grep -c '^examples/'` returns 0).

## Known Stubs

None. Every behavior claimed in this summary is backed by a passing automated test exercised in this session (`mix test test/crosswake/bridge/push_test.exs test/crosswake/telemetry_test.exs test/crosswake/proof/phase133_telemetry_contract_test.exs`, 55/55, plus the full hermetic suite at 1133/1133) — not a hardcoded or mocked value.

## Issues Encountered

- **`mix docs` verification gap (documented, not fixed).** The plan's overall `<verification>` section states "`mix docs` exits 0 with `Crosswake.Bridge.Test` grouped under Bridge (no `mix.exs` edit required, per RESEARCH.md §11)." RESEARCH.md §11 verified only that `mix.exs`'s `groups_for_modules` regex (`~r/Crosswake\.Bridge(\.|$)/`) already matches any new `Crosswake.Bridge.*` submodule — it did not verify the separate `elixirc_paths` boundary: `ex_doc` is a `dev`-only dependency (`mix.exs:53`), so `mix docs` can only run under `MIX_ENV=dev`, and `elixirc_paths(:dev)` is `["lib"]` only — `test/support/bridge_test_helpers.ex` is never compiled in that environment, so `Crosswake.Bridge.Test` genuinely cannot appear in `mix docs`' generated output as things stand. Verified directly: `mix docs` exits 0 (confirming the acceptance criterion's other half), but `grep -rl "Bridge.Test" doc/*.html` finds nothing, and `ls doc/ | grep -i bridge` shows no `Crosswake.Bridge.Test.html`. This is not a bug to fix — moving the module into `lib/` would ship a `Phoenix.LiveViewTest`-dependent module in the published Hex package (explicitly excluded by `script/verify_hex_tarball.sh`), and widening `elixirc_paths(:dev)` to include `test/support` would compile every other test-only support module (stub companions, `proof_assertions.ex`, etc.) into dev/prod builds for no benefit. The module stays test-only, exactly as the plan's own "Confirm the module is compiled into the test environment only" requirement demands; the `mix docs`-visibility half of the acceptance criterion is a genuine, now-documented gap in RESEARCH.md's verification claim rather than something this plan can satisfy without contradicting its own scope constraint.
- Building the phase133 contract test's bridge-driving block required a locally-scoped `import Phoenix.ConnTest` / `import Phoenix.LiveViewTest` inside the one test function that needs them, rather than at module level — the file already defines a nested `StubTelemetryRouter` module using `Crosswake.Router`'s own `live/3` route macro, which collides with `Phoenix.LiveViewTest`'s `live/2` if both are imported at module scope.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- D-76's PR #2 (correlation, exactly-once, and timeouts — the seam's second half) is complete and verified: `mix compile --warnings-as-errors` exits 0; `mix test test/crosswake/bridge/push_test.exs` exits 0 (38/38); the full core hermetic suite is green (1133 tests, 0 failures, 61 excluded); `git diff --name-only | grep -c '^examples/'` returns 0.
- Plan 05 (the `CatalogGuard` structural guard) and Plan 06 (the JS hook, the iOS return leg) are unaffected by anything in this plan beyond the now-hardened `Crosswake.Bridge` facade they extend — Plan 06 in particular can rely on the epoch-embedded correlation id and the two-timer scheme being already in place server-side.
- `Crosswake.Bridge.Test` is available for Plan 06's own JS-hook-adjacent tests (and any future phase's) to simulate a hook reply without a shell.
- The `mix docs`/`Crosswake.Bridge.Test` visibility gap noted above is non-blocking (test-only tooling correctly stays test-only) but should be kept in mind if a future phase's RESEARCH cites §11 as having verified doc-visibility rather than only the `groups_for_modules` regex.
- No blockers for subsequent Phase 154 plans.

## Self-Check: PASSED

All files listed under "Files Created/Modified" confirmed present on disk (`lib/crosswake/bridge.ex`, `lib/crosswake/telemetry.ex`, `guides/telemetry.md`, `test/support/bridge_live_view_case.ex`, `test/crosswake/bridge/push_test.exs`, `test/crosswake/telemetry_test.exs`, `test/crosswake/proof/phase133_telemetry_contract_test.exs`, `test/support/bridge_test_helpers.ex`); both task commit hashes (`c6dd7269`, `7410a39d`) confirmed present in `git log --oneline --all`.

---
*Phase: 154-the-control-contract-seam*
*Completed: 2026-07-29*
