---
phase: 155-host-owned-fallback-components
plan: 01
subsystem: ui
tags: [phoenix-component, mix-generator, design-tokens, plug-static, playwright, focus-trap]

requires:
  - phase: 154-the-control-contract-seam
    provides: "Crosswake.Bridge.push/3, Bridge.attach/1, Bridge.Reply, the approval_live.ex haptics exemplar this plan renders alongside"
provides:
  - "mix crosswake.gen.native_controls_ui — no-clobber, stamped, two-file generator (component + stylesheet)"
  - "priv/templates/crosswake/native_controls_ui/{crosswake_fallbacks.ex.eex,crosswake_fallback.css.eex} — the library templates"
  - "--cw-overlay-scrim semantic token (8-digit hex primitive, no color-mix, no $dark)"
  - "priv/static/tokens.css — a served sibling copy of tokens.css, sibling to crosswake.esm.js, so /crosswake/tokens.css resolves through the existing single Plug.Static block"
  - "real committed generator output in examples/phoenix_host, wired additively into ApprovalLive"
  - "examples/phoenix_host/e2e/native_controls_fallback.spec.ts — the A1 absent-before/present-after browser proof"
affects: [155-02, 155-03, 155-04, 155-05, 155-06, 155-07]

tech-stack:
  added: []
  patterns:
    - "Generator no-clobber + stamp pattern (crosswake.gen.bridge_hook) combined with the multi-file ensure_file loop (crosswake.gen.offline_ui), applied to a new two-file generator"
    - "Scoped --cwfb-* alias layer over --cw-* semantic tokens, in a host-owned generated stylesheet"
    - "Zero-JS focus trap via Phoenix.Component.focus_wrap/1 + JS.focus/JS.push_focus/JS.pop_focus"

key-files:
  created:
    - lib/mix/tasks/crosswake.gen.native_controls_ui.ex
    - priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex
    - priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex
    - examples/phoenix_host/lib/crosswake_example_web/components/crosswake_fallbacks.ex
    - examples/phoenix_host/priv/static/assets/crosswake_fallback.css
    - examples/phoenix_host/e2e/native_controls_fallback.spec.ts
    - priv/static/tokens.css
    - test/mix/tasks/crosswake.gen.native_controls_ui_test.exs
    - test/crosswake/proof/phase155_native_controls_template_drift_test.exs
  modified:
    - brandbook/tokens/crosswake.tokens.json
    - brandbook/tools/compile-tokens.js
    - brandbook/tools/check-consumer-drift.mjs
    - script/check-e2e-honesty.mjs
    - lib/crosswake/install/patcher.ex
    - examples/phoenix_host/lib/crosswake_example/endpoint.ex
    - examples/phoenix_host/lib/crosswake_example/layouts.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex
    - test/mix/tasks/crosswake_install_test.exs
    - test/mix/tasks/crosswake_gen_bridge_hook_test.exs
    - guides/install.md

key-decisions:
  - "tokens.css gains a served sibling copy at priv/static/tokens.css (compile-tokens.js) — Plug.Static resolves only:-listed names relative to from:'s root, not the nested priv/static/crosswake/ packaged-mirror path, so a single /crosswake block serving both crosswake.esm.js and tokens.css requires them as siblings"
  - "crosswake_fallback.css.eex uses literal px values for spacing/type-scale/radius outside the --cwfb-* alias block, never var(--cw-*) directly, to hold D-24's fixed 15-alias-only discipline exactly (verified: grep -c 'var(--cw-' == 15)"
  - "confirm_modal demo wired to a new 'Preview the confirm fallback' trigger in ApprovalLive, not the existing 'Approve request' button — Phase 154's pinned evidence-panel.spec.ts click-target and mutation flow stay untouched (all 25 existing Playwright tests still pass)"
  - "patcher.ex's endpoint only: list uses literal 'crosswake.esm.js tokens.css' text rather than #{@hook_asset}/#{@tokens_asset} interpolation, so the line stays grep-able verbatim per the plan's acceptance check"
  - "confirm_modal's inline role=alert error text uses the full-strength --cwfb-ink alias, not a danger/status-error token — --cw-status-error is 2.44:1 as text on the dark inset surface and fails AA there (only the filled destructive BUTTON case is fixed in 155-03); the alert role plus a border-left shape cue carry the signal instead"

patterns-established:
  - "Generated CSS: everything outside the token alias block is either a --cwfb-* reference or a literal value — zero direct var(--cw-*) usage, checked by a total-count grep equality"

requirements-completed: []  # FALL-01/FALL-02/PROOF-01 are phase-level and span all 7 plans; this tracer plan (01/07) delivers the confirm-modal generator + A1 proof only. Marking deferred to the phase-closing plan.

coverage:
  - id: D1
    description: "mix crosswake.gen.native_controls_ui — no-clobber, stamped two-file generator with a full D-06 paste-ready printed block"
    requirement: "FALL-01"
    verification:
      - kind: unit
        ref: "test/mix/tasks/crosswake.gen.native_controls_ui_test.exs (7 tests: create/reuse/partial-tree/stamp/printed-output/error-path)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated confirm_modal/1 — focus-trapped Phoenix.Component, zero new JS, D-58 required-no-default title/confirm_label attrs"
    requirement: "FALL-01"
    verification:
      - kind: integration
        ref: "examples/phoenix_host/e2e/native_controls_fallback.spec.ts (A1: absent-before/present-after, role=dialog, resolved scrim)"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/evidence_panel.spec.ts + route_tour.spec.ts (25 pre-existing tests, unregressed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "--cw-overlay-scrim served through /crosswake/tokens.css from a single existing Plug.Static block"
    requirement: "PROOF-01"
    verification:
      - kind: e2e
        ref: "curl http://localhost:4700/crosswake/tokens.css (manual verification, 200 + --cw-overlay-scrim present) and native_controls_fallback.spec.ts's backdrop-not-transparent assertion"
        status: pass
    human_judgment: false
  - id: D4
    description: "Template drift guard for the two new .eex templates"
    requirement: "FALL-01"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase155_native_controls_template_drift_test.exs (2 tests, both mutation controls observed red then reverted)"
        status: pass
    human_judgment: false

duration: 130min
completed: 2026-07-30
status: complete
---

# Phase 155 Plan 01: Tracer — Generated Confirm Modal End-to-End Summary

**A real `mix crosswake.gen.native_controls_ui` generator, its two library templates, and a committed confirm-modal fallback rendering with a resolved scrim on `/saas/approvals/approval-1`, proven in a live Chromium browser.**

## Performance

- **Duration:** ~130 min
- **Tasks:** 2 completed
- **Files modified/created:** 22

## Accomplishments

- Added `--cw-overlay-scrim` (8-digit hex primitive, no `color-mix`, no dark variant) to the token system; `compile-tokens.js` gates the new `overlay` semantic group and now also writes a served sibling copy at `priv/static/tokens.css`.
- Extended the library's single `/crosswake` `Plug.Static` block to serve `tokens.css` alongside `crosswake.esm.js`; ported the same edit into the example host's endpoint and repointed its layout's stylesheet link.
- Built `mix crosswake.gen.native_controls_ui`: a no-clobber, `@template_version`-stamped generator copying a `Phoenix.Component` confirm modal (focus-trapped via `Phoenix.Component.focus_wrap/1`, zero new JavaScript) and a `--cwfb-*` scoped alias-layer stylesheet.
- Ran the generator for real against `examples/phoenix_host` and committed the real output; wired it additively into `ApprovalLive` behind its own trigger.
- Wrote a Playwright spec proving the absent-before/present-after pair with a resolved, non-transparent scrim.
- Registered both new templates and the new spec in the curated `check-consumer-drift.mjs` MANIFEST and `check-e2e-honesty.mjs` FILES arrays.
- Locked FALL-01 mechanically: a 7-test generator proof (create/reuse/partial-tree/stamp/printed-output/error-path) and a template drift guard, both mutation controls observed red then reverted.

## Task Commits

1. **Task 1: End-to-end "a generated confirm modal renders on a real route"** - `858e2064` (feat)
2. **Task 2: Lock FALL-01 mechanically — generator unit proof and template drift guard** - `801e2733` (test)

## Files Created/Modified

- `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` - the generator task
- `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex` - `confirm_modal/1` template
- `priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex` - `--cwfb-*` alias-layer stylesheet template
- `brandbook/tokens/crosswake.tokens.json` - `primitive.current.950a72` + `overlay.scrim`
- `brandbook/tools/compile-tokens.js` - `overlay` group + `priv/static/tokens.css` served copy
- `lib/crosswake/install/patcher.ex` - endpoint block now serves `tokens.css` too; added `tokens_url/0`
- `examples/phoenix_host/lib/crosswake_example/{endpoint.ex,layouts.ex}` - ported endpoint patch, repointed tokens link, added fallback stylesheet link, served `/assets`
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` - additive confirm-modal demo wiring
- `examples/phoenix_host/lib/crosswake_example_web/components/crosswake_fallbacks.ex` / `examples/phoenix_host/priv/static/assets/crosswake_fallback.css` - committed real generator output
- `examples/phoenix_host/e2e/native_controls_fallback.spec.ts` - the A1 browser proof
- `test/mix/tasks/crosswake.gen.native_controls_ui_test.exs`, `test/crosswake/proof/phase155_native_controls_template_drift_test.exs` - Task 2's proofs
- `test/mix/tasks/crosswake_install_test.exs`, `test/mix/tasks/crosswake_gen_bridge_hook_test.exs`, `guides/install.md` - consequential updates for the widened `only:` list

## Decisions Made

See `key-decisions` in frontmatter — summarized:
1. `tokens.css` now has a served sibling copy at `priv/static/tokens.css` because `Plug.Static` resolves `only:`-listed names relative to `from:`'s root, not the nested packaged-mirror path.
2. The generated stylesheet uses literal pixel values for spacing/type-scale/radius outside the 15-entry `--cwfb-*` alias block, never `var(--cw-*)` directly.
3. The confirm-modal demo has its own trigger, leaving Phase 154's pinned "Approve request" flow untouched.
4. `patcher.ex`'s `only:` line stays literal text, not interpolated, for grep-ability.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `crosswake_fallback.css.eex`'s alias layer initially leaked bare `var(--cw-*)` references outside the alias block**
- **Found during:** Task 1, self-verification against the plan's own acceptance-criteria greps
- **Issue:** Spacing/type-scale/radius declarations used `var(--cw-spacing-base)`, `var(--cw-text-scale-*)`, `var(--cw-radius-md)`, `var(--cw-focus-ring-width)` directly, in violation of D-24 ("references only `--cwfb-*` aliases... never `var(--cw-*)` in a declaration body") — the acceptance check requires the total `var(--cw-` count to equal exactly the 15 alias definitions.
- **Fix:** Rewrote the stylesheet to use literal pixel values (16px, 24px, 20px, 30px, 48px, 2px, etc.) for everything outside the 15-entry alias block, and moved the shadow's `color-mix` input from `var(--cw-text-default)` to `var(--cwfb-ink)`.
- **Files modified:** `priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex`
- **Verification:** `grep -c 'var(--cw-'` == 15 == `--cwfb-` alias definition count.
- **Committed in:** `858e2064`

**2. [Rule 1 - Bug] Explanatory CSS comments false-positived the theme-logic and D-24 greps**
- **Found during:** Task 1, self-verification
- **Issue:** A multi-line `/* ... */` comment's continuation lines (not starting with `/`, `*`, or `#`) contained the literal words "prefers-color-scheme" and "data-theme" as prose describing what the file must NOT contain, and a separate comment contained the literal text `var(--cw-*)`. The plan's acceptance greps are literal substring matches over raw file text (some filtered by comment-line prefix, some not), so both tripped false positives.
- **Fix:** Restructured every comment as a `*`-prefixed continuation (recognized by the comment filter) and reworded the two prose mentions to avoid the literal risky substrings.
- **Files modified:** `priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex`
- **Verification:** All theme-logic and `var(--cw-*)`-count greps now 0/15 as required.
- **Committed in:** `858e2064`

**3. [Rule 1 - Bug] `crosswake.esm.js` and `tokens.css` cannot both resolve through a single `/crosswake` `Plug.Static` block at their existing on-disk locations**
- **Found during:** Task 1, planning the `patcher.ex` endpoint edit
- **Issue:** `crosswake.esm.js` lives at `priv/static/crosswake.esm.js` (top-level of the `:crosswake` app's `priv/static`); the compiled `tokens.css` lives nested at `priv/static/crosswake/tokens.css`. `Plug.Static`'s `only:` matches only the FIRST path segment after stripping `at:`, then serves the FULL remaining path relative to `from:`'s root — so `/crosswake/tokens.css` with `from: :crosswake` (defaulting to that app's `priv/static` root) resolves to `priv/static/tokens.css`, which didn't exist. The plan's action text says to add `tokens.css` to the SAME block's `only:` list without introducing a third block or changing `from:`, which is only satisfiable if the served file is a sibling of `crosswake.esm.js`.
- **Fix:** `compile-tokens.js` now writes a THIRD, byte-identical copy to `priv/static/tokens.css` (sibling to `crosswake.esm.js`), in the same run as the existing `brandbook/tokens/tokens.css` and `priv/static/crosswake/tokens.css` (packaged-mirror) writes — all three come from the same `out` string in one function call, so they can never drift from each other. The existing packaged-mirror path and its `compile-tokens.test.mjs` byte-parity test are untouched.
- **Files modified:** `brandbook/tools/compile-tokens.js`
- **Verification:** `curl http://localhost:4700/crosswake/tokens.css` returns 200 with `--cw-overlay-scrim` present (manually verified against a running server); `compile-tokens.test.mjs`'s 25 existing tests still pass unchanged.
- **Committed in:** `858e2064`

**4. [Rule 1 - Bug] `patcher.ex`'s `only:` line, written as interpolated `#{@hook_asset} #{@tokens_asset}`, doesn't satisfy the plan's literal grep acceptance check**
- **Found during:** Task 1, final acceptance-criteria verification pass
- **Issue:** The acceptance criterion requires `grep -n 'only: ~w(' lib/crosswake/install/patcher.ex` to show the literal text `crosswake.esm.js` and `tokens.css` on the same line, but interpolated module-attribute references don't appear as that literal text in source.
- **Fix:** Changed that one line to literal text (`only: ~w(crosswake.esm.js tokens.css)`), keeping `@hook_asset`/`@tokens_asset` for `hook_url/0`/`tokens_url/0`.
- **Files modified:** `lib/crosswake/install/patcher.ex`
- **Verification:** Grep matches; `crosswake_install_test.exs` and `crosswake_gen_bridge_hook_test.exs` (both asserting on the rendered output string) updated and pass.
- **Committed in:** `858e2064`

**5. [Rule 1 - Bug] Two pre-existing tests asserted the OLD single-asset `only:` string and would have broken**
- **Found during:** Task 1, full `mix test` sweep after the `patcher.ex` change
- **Issue:** `test/mix/tasks/crosswake_install_test.exs` and `test/mix/tasks/crosswake_gen_bridge_hook_test.exs` both asserted `"only: ~w(crosswake.esm.js)"` (no `tokens.css`), which is now stale.
- **Fix:** Updated both assertions to the new two-asset `only:` line; also updated the matching example snippet in `guides/install.md`.
- **Files modified:** `test/mix/tasks/crosswake_install_test.exs`, `test/mix/tasks/crosswake_gen_bridge_hook_test.exs`, `guides/install.md`
- **Verification:** Both test files pass; full example-host and core Playwright suites (25/25) still pass.
- **Committed in:** `858e2064`

**6. [Rule 1 - Bug] EEx template used HEEx-style `@app_module` assign syntax, which plain `EEx.eval_file/2` doesn't support**
- **Found during:** Task 1, first generator dry run against `examples/phoenix_host`
- **Issue:** `defmodule <%= @app_module %>Web.CrosswakeFallbacks do` raised a compile error (`undefined variable "assigns"`) — plain `EEx.eval_file/2` (used by `gen.offline_ui`'s precedent) binds variables directly, not through a Phoenix `@assign` convention.
- **Fix:** Changed to `<%= app_module %>` (bare bound variable), matching `gen.offline_ui`'s own templates.
- **Files modified:** `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex`
- **Verification:** Generator runs cleanly; `mix compile --warnings-as-errors` passes in both the core lib and the example host.
- **Committed in:** `858e2064`

---

**Total deviations:** 6 auto-fixed (all Rule 1 — bugs found and fixed during self-verification against the plan's own literal acceptance criteria before any commit). No scope creep; every fix was required to make the plan's stated acceptance checks actually pass.

## Issues Encountered

- **`mix test --warnings-as-errors` (full core suite) aborts on unrelated pre-existing warnings, not on test failures.** Confirmed pre-existing and unrelated to this plan: `MIX_ENV=test mix compile --force --warnings-as-errors` is completely clean; a narrow run of every test file this plan touches or added (`crosswake_install_test.exs`, `crosswake_gen_bridge_hook_test.exs`, `crosswake.gen.offline_ui_test.exs`, `crosswake.gen.native_controls_ui_test.exs`, `phase155_native_controls_template_drift_test.exs`) passes cleanly under `--warnings-as-errors`. The full-suite run reports `1262 tests, 0 failures` both before and after this plan's changes — the abort is triggered by warnings emitted from unrelated companion/telemetry test fixtures (`Crosswake.Companions.Rulestead.validate_dependency/0 is undefined`, unused-variable/alias warnings in files this plan never touched), out of scope per the Scope Boundary rule. Not fixed; flagged here for visibility.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The generator, both templates, the served `tokens.css`, and the A1 browser proof are all real and committed — Plan 155-02 onward can build on `Crosswake.Bridge`'s D-50/D-51 fixes, contrast gates, the second `tokens.css`-serving doctor finding, `ComponentTierGuard`, the destructive tone / action menu expansion, and the full three-condition PROOF-01 lane without redoing any of this plan's plumbing.
- `--cw-status-error-fg` (the second of D-27's two semantic tokens) is intentionally NOT added by this plan — it is 155-03's job; the `--cwfb-danger-fg` alias already declares `var(--cw-status-error-fg)` in the stylesheet template and will resolve correctly once that token lands.
- `FALL-01`/`FALL-02`/`PROOF-01` checkboxes in `REQUIREMENTS.md` are deliberately left unmarked — this tracer plan is 1 of 7 plans covering those requirements; marking them complete is deferred to whichever plan actually closes out the action menu (`FALL-01`), `ComponentTierGuard` (`FALL-02`), and the three-condition browser lane (`PROOF-01`).
- No blockers for Plan 155-02.

---
*Phase: 155-host-owned-fallback-components*
*Completed: 2026-07-30*

## Self-Check: PASSED

- FOUND: `.planning/phases/155-host-owned-fallback-components/155-01-SUMMARY.md`
- FOUND: commit `858e2064` (Task 1)
- FOUND: commit `801e2733` (Task 2)
