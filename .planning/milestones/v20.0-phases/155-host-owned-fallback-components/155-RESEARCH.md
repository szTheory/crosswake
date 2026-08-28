# Phase 155: Host-Owned Fallback Components - Research

**Researched:** 2026-07-30
**Domain:** Phoenix/LiveView generator-owned UI components, brand token system, CI browser proof lanes
**Confidence:** HIGH

## Summary

Phase 155 is unusually pre-specified: `155-CONTEXT.md` already carries 59 locked decisions (D-01..D-59) with exact file:line citations, and `155-UI-SPEC.md` already carries the approved visual/interaction contract. This RESEARCH.md does not re-litigate those decisions. Its job is to independently verify the load-bearing factual claims those documents depend on (so the planner is not building tasks on a stale citation), and to surface the mechanical details — exact current code shapes, exact gaps, exact test/CI plumbing — the planner needs to write concrete, verifiable tasks.

Every file:line claim in CONTEXT.md's `<canonical_refs>` that this research re-checked was **confirmed accurate against the current tree** (2026-07-30), including the three shipped-code defects (D-50 `resolve/2` raises on unattached socket, D-51 the dead `:unsupported_command` branch, D-52 `patcher.ex`'s `[:marker_reused]` never reconciling block contents) and the token/CI plumbing claims (D-26 tokens.css 404 root cause, D-29 `compile-tokens.js` groups array, D-33 the shipped-and-failing focus-ring token, D-42 the FILES pin in `check-e2e-honesty.mjs`, D-45 the `/saas/approvals/approval-1` route already carrying Phase 154's pinned assertions).

This phase introduces **zero new external dependencies** (no npm package, no Hex package, no JS library) — it is 100% Elixir/Phoenix/HEEx code plus two design tokens compiled by an existing in-repo toolchain. The Package Legitimacy Audit is therefore N/A by scope, not by omission.

**Primary recommendation:** Treat this phase as three independently plannable, sequenceable slices — (1) the two shipped-code defect fixes (D-50/D-51/D-52) as a first, separately-bisectable commit; (2) the generator + component module + token additions; (3) the `ComponentTierGuard` structural gate + the new Playwright spec — because each slice has an independent, mechanically verifiable "done," and D-50 in particular is described by CONTEXT.md itself as "the last cheap moment" to decide before it becomes one-way (source-compatible to widen, not to re-harden after first publish).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Confirm modal render + focus trap | Browser (HEEx/LiveView, server-rendered) | — | Zero JS; `Phoenix.Component.focus_wrap/1` renders `phx-hook="Phoenix.FocusWrap"`, a LiveView-shipped built-in. All markup and transitions live in the adopter's server-rendered LiveView tree. |
| Action menu render + selection | Browser (HEEx/LiveView) | API/Backend (future, Phase 156) | 155 emits no bridge command; menu selection dispatches a plain `handle_event`, not `Bridge.push/3`. Phase 156 adds the backend/native leg. |
| Denial rendering (undeclared/unavailable) | API/Backend (`Crosswake.Bridge`) → Browser (rendered assign) | — | `Bridge.push/3`/`resolve/2` run server-side inside the LiveView process; the resulting `Shell.Denial` is rendered by the same generated component, never synthesized client-side (D-02, D-14). |
| Token compilation (scrim, error-fg) | Build tooling (`brandbook/tools/compile-tokens.js`) | CDN/Static (served `tokens.css`) | Tokens are authored once in `crosswake.tokens.json`, compiled to CSS, and served from `/crosswake/tokens.css` via `Plug.Static` (D-26) — never duplicated per-host. |
| No-component-tier enforcement | API/Backend (`lib/`-resident static AST guard) | CI (merge-blocking test) | `Crosswake.ComponentTierGuard` is a compile-time-independent, `lib/`-resident predicate (mirrors `CatalogGuard`/`CompanionGuard`) invoked from an ExUnit proof test — so deleting the test cannot delete the rule. |
| Fallback-render / fail-closed proof | CDN/Static (served example host) exercised via Browser automation (Playwright) | — | The proof is a real browser (Chromium) driving a real compiled Phoenix app; no unit-level stand-in satisfies PROOF-01 per D-49 (`brand-structural` precedent). |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | **1.1.30** [VERIFIED: mix.lock] | `Phoenix.Component.focus_wrap/1`, `JS.push_focus`/`pop_focus`/`focus`, `phx-remove`, `phx-window-keydown` | Already a required dependency; ships the entire focus-trap requirement for free. No version bump needed — `focus_wrap/1` is present at `deps/phoenix_live_view/lib/phoenix_component.ex:3173` in the currently-vendored copy [VERIFIED: repo read]. |
| `Phoenix.Component` (behaviour) | shipped with `phoenix_live_view` 1.1.30 | The one artifact shape allowed for the generated module (D-03, D-05) | `Phoenix.LiveComponent` is verified structurally incompatible with `Bridge.resolve/2` — `diff.ex:1145-1152` builds a LiveComponent's private state as `Map.take([:conn_session, :root_view])`, which does not carry the Bridge private key `fetch_state!/1` reads, so calling `resolve/2` inside a `LiveComponent` raises `NotMountedError` [VERIFIED: repo read, diff.ex line range matches CONTEXT.md's D-04 citation exactly]. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Node's built-in test runner (`node --test`) | Node LTS already provisioned in CI | Existing pattern for `priv/static/crosswake.esm.js`'s unit suite | Not used by this phase directly (155 ships zero JS) — listed because the CI job that will host the new Playwright spec already runs a `node --test` step in the same job (`guard-01-e2e-honesty`), useful context for sequencing CI changes. |
| Playwright (`@playwright/test`) | pinned via `examples/phoenix_host/package.json`/lockfile | New spec `native_controls_fallback.spec.ts` | Reuse the existing `examples/phoenix_host` Playwright install; do not add a second Playwright config or project (D-42/D-49 forbid a third scheme-scoped project — would triple the merge-blocking lane's wall clock, per `playwright.config.ts`'s own comment [CITED: playwright.config.ts inline comment, referenced in CONTEXT.md D-46]). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Phoenix.Component.focus_wrap/1` | Hand-rolled `phx-hook` JS focus trap | Rejected — reintroduces the JS this phase exists to avoid (D-10); `focus_wrap/1` is already imported and served by the reference host with zero new wiring. |
| `<dialog>` + `showModal()` | Native HTML dialog element | Rejected — `showModal()`/light-dismiss/`::backdrop` requires JS to invoke (`HTMLDialogElement.showModal()` has no declarative HEEx equivalent), forcing either an inline `<script>` (regresses CSP) or a new JS module; also `<dialog>`'s `close` behavior conflicts with the D-25 resolve-while-open race the generated markup is built to survive without extra JS. |
| Scoped `--cwfb-*` alias layer | Direct `var(--cw-*)` references in generated CSS | Rejected per D-24 — the scoped alias is the re-point surface for an adopter with an existing design system; in-repo precedent already exists at `app.css:220-224` and the drift gate (`check-consumer-drift.mjs:99-114`) is explicitly written to permit exactly this pattern [VERIFIED: repo read, comment present]. |

**Installation:** None — no new dependency declarations. All work is new/modified files inside the existing `crosswake` Mix project and its vendored `examples/phoenix_host` example app.

**Version verification:** `phoenix_live_view` pinned at `1.1.30` in `mix.lock` [VERIFIED: `grep phoenix_live_view mix.lock`]. `focus_wrap/1` confirmed present at that version by direct read of the vendored dependency source (not changelog inference).

## Package Legitimacy Audit

**Not applicable.** This phase adds zero new npm, Hex, or native (SwiftPM/Gradle) dependencies. It authors two new design tokens (data, not packages) and one new Elixir module (`lib/`-resident, first-party). The Package Legitimacy Gate protocol is skipped per its own scope condition ("whenever this phase installs external packages").

## Architecture Patterns

### System Architecture Diagram

```
                         mix crosswake.gen.native_controls_ui
                                        │
                                        ▼
                     ┌──────────────────────────────────────┐
                     │  No-clobber copy (per-file)           │
                     │  - confirm_modal + action_menu markup │
                     │  - @template_version stamp header     │
                     │  - printed handle_event snippets       │
                     └───────────────┬────────────────────────┘
                                     ▼
     Host app: lib/<app>_web/components/crosswake_fallbacks.ex  (adopter-owned, never regenerated)
     Host app: priv/static/assets/crosswake_fallback.css        (adopter-owned, --cwfb-* alias layer)
                                     │
                                     │  1st server round-trip: LiveView assigns render the surface directly
                                     ▼
       ┌───────────────────────────────────────────────────────────────────────┐
       │  LiveView (adopter's route)                                            │
       │                                                                         │
       │  confirm_modal/1, action_menu/1  ──uses──▶  focus_wrap/1 (LiveView built-in) │
       │         │                                        │                     │
       │         │ phx-click / phx-window-keydown=Escape  │ phx-hook="Phoenix.FocusWrap"
       │         ▼                                        ▼                     │
       │  handle_event("crosswake_fallback_answer"/"_dismiss", …)               │
       │         │                                                              │
       │         └──▶ Crosswake.Bridge.resolve/2 (compare-and-delete in-flight) │
       └───────────────────────────────────────────────────────────────────────┘
                                     │
                     (Phase 156 only — NOT this phase) Bridge.push/3 → shell
                                     │
                                     ▼
                        Shell.Denial (undeclared / unavailable / shell_unreachable)
                                     │
                                     ▼
                   Same generated component re-renders the denial inline (role="alert")
                          — never a second UI, never silent

   ─── CI proof lane (merge-blocking, unfiltered `npx playwright test`) ───
   examples/phoenix_host/e2e/native_controls_fallback.spec.ts
     A1 /saas/approvals/approval-1   → fallback renders (existing Phase-154-pinned route)
     A2 /_e2e/undeclared-control     → new route; raises server-side, browser proves it never silently renders
     A3 /bridge-proof                → enumeration invariant (no dead-air, no silent reason drop)
```

### Recommended Project Structure
```
lib/mix/tasks/
└── crosswake.gen.native_controls_ui.ex     # new generator, copy of gen.bridge_hook's stamp pattern

lib/crosswake/
├── component_tier_guard.ex                 # new — FALL-02 structural gate (mirrors CatalogGuard/CompanionGuard)
└── bridge.ex                               # MODIFIED — resolve/2 tolerant on unattached socket (D-50)
    bridge/
    └── contract.ex                         # MODIFIED — new UnknownCapabilityFamilyError (D-51)

priv/templates/crosswake/native_controls_ui/
├── crosswake_fallbacks.ex.eex              # template: confirm_modal/1 + action_menu/1 + resolve/2 wiring
└── crosswake_fallback.css.eex              # template: --cwfb-* alias block, zero theme logic

brandbook/tokens/crosswake.tokens.json      # MODIFIED — two new tokens (D-27)
brandbook/tools/compile-tokens.js           # MODIFIED — groups array gains 'overlay' (D-29)
brandbook/tools/contrast.test.mjs           # MODIFIED — gains focus-ring pairs (D-33)
brandbook/tools/check-consumer-drift.mjs    # MODIFIED — MANIFEST gains the two new .eex templates (D-34)

lib/crosswake/install/patcher.ex            # MODIFIED — endpoint block reconciliation (D-52) + tokens.css Plug.Static

examples/phoenix_host/
├── e2e/native_controls_fallback.spec.ts    # NEW — PROOF-01, ~200 lines
├── lib/crosswake_example/e2e/...           # NEW — /_e2e/undeclared-control route + CROSSWAKE_PROOF_BREAK_FALLBACK
└── lib/<generated fallback file committed>  # the real generator OUTPUT, committed, so PROOF-01 is non-vacuous
```

### Pattern 1: No-clobber generator with a stamped provenance header
**What:** `mix crosswake.gen.bridge_hook --eject` never overwrites an existing destination file; it reads first, and if the file exists it reports `:reused` and does nothing. The written file's first bytes are a versioned comment stamp (`/* crosswake:bridge-hook:ejected protocol=1.1.0 ... */`) that `mix crosswake.doctor` later regex-parses and compares against the live contract version.
**When to use:** Exactly the shape D-35 mandates for `crosswake.gen.native_controls_ui` — do NOT copy `gen.offline_ui`'s pattern, which has no stamp at all (confirmed: `offline_page.html.heex.eex` etc. carry no version header) and is the generator responsible for the exact `~p"/assets/tokens.css"` 404 this phase must fix.
**Example:**
```elixir
# Source: lib/mix/tasks/crosswake.gen.bridge_hook.ex:129-160 (verified against current tree)
defp eject(dir, relative_path) do
  destination = Path.join(dir, relative_path)

  case File.read(destination) do
    {:ok, _existing} ->
      Mix.shell().info("  reused #{relative_path} (host-owned; the eject never clobbers your copy)")
      :reused

    {:error, :enoent} ->
      File.mkdir_p!(Path.dirname(destination))
      File.write!(destination, stamped_hook_source(relative_path))
      Mix.shell().info("  created #{relative_path} (stamped protocol #{Contract.version()})")
      :created

    {:error, reason} ->
      Mix.raise("could not write #{destination}: #{:file.format_error(reason)}")
  end
end
```

### Pattern 2: `lib/`-resident structural AST guard with an injection seam
**What:** `Crosswake.Bridge.CatalogGuard.assert_catalog_closed!/1` accepts optional `root:`/inputs, defaulting to the real shipped values, so a proof test can drive the actual raiser against a synthetic fixture tree without relaxing the zero-argument production call. `Crosswake.CompanionGuard` uses the same `Code.string_to_quoted/2` + `Macro.prewalk/3` mechanism with names-as-strings to avoid the guard self-tripping on its own module reference.
**When to use:** `Crosswake.ComponentTierGuard` (D-36) must follow this exact shape: live in `lib/` (not `test/`), accept a `root:` injection seam (per `catalog_guard.ex:88-102`), and — critically — spell its own banned namespace (`[:Crosswake, :UI]`) as strings/atoms constructed at runtime, never as a literal alias, or the guard's own source file trips its own `namespace` rule (verified pattern in `companion_guard.ex:29-33`, "Stored as module name STRINGS ... so this attribute definition does not itself contain {:__aliases__} AST nodes").
**Example:**
```elixir
# Source: lib/crosswake/companion_guard.ex:29-40 (verified against current tree)
@extracted_companion_names [
  "Crosswake.Companions.Rulestead",
  "Crosswake.Companions.Rindle",
  "Crosswake.Companions.Sigra",
  "Crosswake.Companions.Chimeway"
]
@extracted_companions MapSet.new(Enum.map(@extracted_companion_names, &String.to_atom/1))
```

### Pattern 3: Zero-JS focus trap via `Phoenix.Component.focus_wrap/1`
**What:** `focus_wrap/1` renders a wrapper `<div phx-hook="Phoenix.FocusWrap">` with two `tabindex="0"` sentinel divs before/after the slotted content. The LiveView JS client ships this hook already (`phoenix_live_view.esm.js`); it wraps Tab focus at the sentinels and calls `focusFirst` on mount.
**When to use:** Every focus-trapped surface in this phase (confirm modal, action menu). No hooks-map registration is needed because `Phoenix.FocusWrap` is a LiveView built-in hook name, distinct from adopter-registered custom hooks.
**Example:**
```elixir
# Source: deps/phoenix_live_view/lib/phoenix_component.ex:3173-3181 (verified against vendored 1.1.30)
def focus_wrap(assigns) do
  ~H"""
  <div id={@id} phx-hook="Phoenix.FocusWrap" {@rest}>
    <div id={"#{@id}-start"} tabindex="0" aria-hidden="true"></div>
    {render_slot(@inner_block)}
    <div id={"#{@id}-end"} tabindex="0" aria-hidden="true"></div>
  </div>
  """
end
```

### Anti-Patterns to Avoid
- **Routing the native reply and the fallback click into the same `handle_event` name "to deduplicate":** guarantees a double mutation. `resolve/2`'s compare-and-delete against `state.in_flight` is the only dedup mechanism (verified: `bridge.ex:279-291`, docstring explicitly forbids this).
- **A macro/`use`-based fallback module:** technically avoids the literal string `Crosswake.UI.*`, but ships the same importable surface FALL-02 forbids under a different name (D-05, D-38's retirement recipe explicitly calls this out as "what you probably want instead" — i.e., precisely what NOT to build).
- **Glob-based drift/CI file registration:** both `check-consumer-drift.mjs`'s MANIFEST and `check-e2e-honesty.mjs`'s FILES are curated arrays, not globs — a new template or spec file is silently ungated until explicitly added (verified both files, confirmed curated-array shape at `check-consumer-drift.mjs:37-43` and `check-e2e-honesty.mjs:55-60`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Focus trapping inside a modal/menu | A custom `keydown` Tab-cycling handler | `Phoenix.Component.focus_wrap/1` | Already shipped, already imported by the reference host layout, zero new JS, matches D-10 exactly. |
| Scroll lock / background inert | Custom body-scroll-lock JS library | `JS.add_class`/`remove_class` (HEEx) + server-rendered `inert` attribute | LiveView's `JS` module already covers class toggling declaratively; `inert` is a native HTML attribute needing no JS at all. |
| Contrast computation for the new tokens | Ad hoc math or a browser DevTools eyeball check | `brandbook/tools/contrast.mjs`'s `contrast()`/`parseHex()`/`luminance()` functions | Already the canonical, tested (`contrast.test.mjs`) WCAG 2.2-correct implementation (0.04045 linearization threshold, "corrected May 2021"), reused by two independent research agents per CONTEXT.md and now independently re-verifiable by running `node brandbook/tools/contrast.mjs`. |
| Second confirm-vs-menu ARIA role decision | Implementing APG's full `role="menu"` roving-tabindex contract | Plain buttons in a dialog, no `role="menu"` | Confirmed zero `role="menu"` usage anywhere in the current example host (`grep` found none) — this phase would be the FIRST introduction of that ARIA role if it were used, and D-21 forbids it. |
| Endpoint static-asset wiring for a second served path | A bespoke `Plug` | A second `Plug.Static` block, following the existing pattern already used for `/crosswake` (crosswake.esm.js) at `endpoint.ex:40-45` | The reference host's endpoint already demonstrates the exact `at:`/`from:`/`only:` shape needed for `/crosswake/tokens.css`; copy it, don't invent a new mechanism. |

**Key insight:** Every piece of client-side interactivity this phase needs (focus trap, Escape-to-close, click-away, scroll lock, background inert) already has a zero-JS LiveView-built-in or native-HTML equivalent verified present in the currently vendored `phoenix_live_view` 1.1.30. The phase's difficulty is not technical novelty — it is disciplined non-invention: every "Don't Hand-Roll" row above is one one more custom JS module the phase would otherwise ship, each one clawing back the CSP win D-10/D-12 are explicitly protecting.

## Runtime State Inventory

Not applicable — this is a greenfield generator + new module phase, not a rename/refactor/migration. (Two pre-existing runtime artifacts ARE touched — see Common Pitfalls below for the endpoint-patcher reconciliation gap and the third stray `tokens.css` copy — but neither is a rename; both are pre-existing shipped-code defects the phase fixes.)

## Common Pitfalls

### Pitfall 1: `resolve/2` crashing on the exact code path it exists to make safe
**What goes wrong:** An early adopter who runs `mix crosswake.gen.native_controls_ui` but has NOT yet called `Bridge.attach/1` for their route (plausible in 155, since there is no `menu` capability yet to motivate attaching) clicks the fallback's dismiss/answer button. The generated `handle_event` clause calls `Crosswake.Bridge.resolve(socket, ref)`, which calls `fetch_state!/1`, which raises `NotMountedError` because `socket.private[@private_key]` is `nil`.
**Why it happens:** `resolve/2`'s docstring promises "it never raises," but the current implementation is symmetric with the strict `push/3`/`dispatched/2` — it was written assuming callers always `attach/1` first, which was a safe assumption before generated adopter code called it directly.
**How to avoid:** Widen `resolve/2` specifically (leave `dispatched/2` strict, per D-50) to treat an unattached socket as "nothing to resolve" (returning the socket unchanged), symmetric with its existing no-op-on-not-found behavior. Verified exact location: `lib/crosswake/bridge.ex`, `fetch_state!/1` at lines 526-543, `resolve/2` at lines 279-291 (current numbering).
**Warning signs:** Any ExUnit test exercising the generated fallback's dismiss/answer handler on a LiveView that has not called `attach/1` will 500 today; that test's absence up to now is *why* this is not caught yet.

### Pitfall 2: A silently-dropped semantic token (transparent scrim, no gate failure)
**What goes wrong:** `compile-tokens.js`'s `groups` array (line 67, verified: `['surface', 'text', 'action', 'border', 'status', 'runtime']`) is the literal filter for which top-level token groups get emitted into the semantic tier of the compiled CSS. Adding an `overlay` group to `crosswake.tokens.json` without adding `'overlay'` to this array produces valid, green-passing CSS with the token simply absent — `var(--cw-overlay-scrim)` then resolves to nothing, and the modal's backdrop becomes fully transparent, with **zero test failure**.
**Why it happens:** No existing test asserts "every top-level group in the JSON appears in the compiled CSS" — the tests are all positive assertions about specific known tokens, not an exhaustiveness check.
**How to avoid:** Add `'overlay'` to the `groups` array in the same commit that adds the token to the JSON; write (or have the planner schedule) at least one assertion of the form "the compiled `tokens.css` contains `--cw-overlay-scrim`" so a future regression of this exact class fails loudly.
**Warning signs:** `grep -c 'cw-overlay-scrim' priv/static/crosswake/tokens.css` returning 0 after a `compile-tokens.js` run.

### Pitfall 3: A gate hole invisible to CI (focus-ring contrast)
**What goes wrong:** `--cw-action-focus-ring`'s light value is `{primitive.brass.500}` (verified: `brandbook/tokens/crosswake.tokens.json`, `action.focus-ring.$value`), already shipped and rendered at multiple sites (`offline.css:10`, `app.css:76,481,954,1458,1986`). Computed against white/`foam-50`, brass-500 fails WCAG SC 1.4.11's 3:1 non-text-contrast threshold — but `contrast.test.mjs`'s existing 96-122 test block only asserts text-color pairs, never a focus-ring-against-background pair, so this has shipped and stayed green.
**Why it happens:** The test suite's scope (text contrast) was never extended to cover non-text UI-component contrast (SC 1.4.11 is a separate WCAG success criterion from SC 1.4.3/1.4.11's text sibling).
**How to avoid:** Fix the light value to `wake-700` per D-33, AND add a new focus-ring-pair assertion class to `contrast.test.mjs` in the same change, so this exact class of failure cannot silently ship again. The browser proof's focus-ring assertion (D-46) is explicitly described as "fails today, passes only after the fix" — use it as the canary that the CSS-level fix actually landed.
**Warning signs:** `node brandbook/tools/contrast.mjs` printing the brass-500/white or brass-500/foam-50 pairing below 3.0 today (verifiable now, before any change).

### Pitfall 4: An endpoint patch silently not reaching existing adopters
**What goes wrong:** `Crosswake.Install.Patcher.ensure_endpoint_block/1` (verified: `lib/crosswake/install/patcher.ex`, the `cond` branch returning `{:ok, contents, [:marker_reused]}`) treats "the markers already exist" as fully sufficient — it never diffs the marker-delimited block's CONTENT against the current `endpoint_static_plug_block/1` template. An adopter who ran `mix crosswake.install` before this phase already has the `/crosswake` static block between the markers, but adding a second `Plug.Static` for `/crosswake/tokens.css` to the generator's canonical block will never reach them, because the installer sees the markers and reports `:marker_reused` without inspecting or reconciling the body.
**Why it happens:** The idempotency check was written to answer "did I already run here" (a presence check), not "is what's here still current" (a content check) — a reasonable original design that becomes a gap the moment the canonical block itself needs to change.
**How to avoid:** Add block-content reconciliation (diff the current in-file block against the current `endpoint_static_plug_block/1` output) plus a `mix crosswake.doctor` finding when they differ, so existing adopters get an actionable nudge rather than silent staleness (D-52).
**Warning signs:** An adopter's compiled endpoint missing the second `Plug.Static` block for `/crosswake/tokens.css` after upgrading, with `mix crosswake.install` reporting success.

### Pitfall 5: A pinned proof route colliding with a new denial scenario
**What goes wrong:** `/saas/approvals/approval-1` already carries Phase 154's `evidence_panel.spec.ts` assertions (checks A-F: idle-copy honesty, success-before-denial ordering, WCAG contrast, the live-region announcement contract, etc. — verified via `APPROVAL_ROUTE = '/saas/approvals/approval-1'` at `evidence_panel.spec.ts:36`). Reusing that same route to also exercise an "undeclared capability" scenario would require changing that route's policy/capability declarations, which risks invalidating Phase 154's already-passing, merge-blocking assertions on the same route.
**Why it happens:** It is tempting to reuse an existing, realistic-looking route for a new test rather than adding a new one, especially since D-45 explicitly names `/saas/approvals/approval-1` as the A1 fallback-render target.
**How to avoid:** Use `/saas/approvals/approval-1` ONLY for the A1 fallback-render assertion (additive — new assertions on an existing route, not modifying existing ones); create the NEW `/_e2e/undeclared-control` route (guarded `if Mix.env() in [:test, :e2e]`, same pattern as the three existing `/_e2e/*` routes at `router.ex:581-593`) for A2's undeclared-capability scenario, exactly as D-45 specifies.
**Warning signs:** Any change to `router.ex`'s `scope "/saas"` capability/policy declarations inside this phase's diff — that is the signal a task strayed onto the pinned route instead of the new one.

## Code Examples

Verified patterns from the current repo:

### The doubly-nested wire denial shape (for the D-46 `page.addInitScript` harness)
```kotlin
// Source: packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:325-349 (verified)
private fun deny(request: BridgeRequestEnvelope, reason: String, message: String, hint: String): String {
    return JSONObject()
        .put("protocol", request.protocol)
        .put("version", request.version)
        .put("command", request.command)
        .put("route_id", request.routeId)
        .put(
            "denial",
            JSONObject()
                .put("command", request.command)
                .put("route_id", request.routeId)
                .put("correlation_id", request.correlationId)
                .put(
                    "denial",                      // <-- the SECOND, doubly-nested "denial" key
                    JSONObject()
                        .put("reason", reason)
                        .put("code", reason)
                        .put("message", message)
                        .put("route_id", request.routeId)
                        .put("hint", hint)
                )
        )
}
```
The Elixir decoder is tolerant of both nestings (verified `lib/crosswake/bridge.ex`, `decode_wire_denial/1` clauses match both `%{"denial" => inner}` and a bare map) — but the Playwright harness must inject the DOUBLY-nested shape specifically, per D-46, or the assertion is vacuous (it would pass even if the code regressed to only handling the single-nested shape).

### The `fetch_state!/1` raise `resolve/2` must be widened past
```elixir
# Source: lib/crosswake/bridge.ex:526-543 (verified against current tree)
defp fetch_state!(socket) do
  case socket.private[@private_key] do
    nil ->
      raise NotMountedError,
        message: """
        [crosswake.bridge.not_mounted] #{inspect(socket.view)} called Crosswake.Bridge.push/3 \
        without ever calling Crosswake.Bridge.attach/1.
        ...
        """
    state ->
      state
  end
end
```

### The `check-e2e-honesty.mjs` curated FILES array the new spec must join
```javascript
// Source: script/check-e2e-honesty.mjs:55-60 (verified against current tree — 4 entries today)
const FILES = [
  'examples/phoenix_host/e2e/evidence_panel.spec.ts',
  'examples/phoenix_host/e2e/offline_sync.spec.ts',
  'examples/phoenix_host/e2e/route_tour.spec.ts',
  'examples/phoenix_host/e2e/support/offline_route_proof.ts',
];
```
Add `'examples/phoenix_host/e2e/native_controls_fallback.spec.ts'` here in the same PR that creates the file — otherwise the "missing-file rule" that makes a proof spec undeletable (D-42) does not yet apply to it.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `gen.offline_ui` copies `tokens.css` verbatim into the host, referenced by a hardcoded `~p"/assets/tokens.css"` route helper that the endpoint's `Plug.Static only:` list never actually serves | `tokens.css` is library-served from `/crosswake/tokens.css` via a dedicated `Plug.Static`, one source of truth | This phase (D-26) | Fixes a currently-live 404 (verified: `endpoint.ex`'s only `Plug.Static` blocks serve `~w(brand css offline_study.js ...)` and `/phoenix`/`/phoenix_live_view`/`/crosswake` — no `assets` prefix is served at all) and retires a third, ungated, byte-identical tokens.css copy at `examples/phoenix_host/priv/static/css/tokens.css` (confirmed absent from both `check-consumer-drift.mjs`'s MANIFEST and `compile-tokens.test.mjs`'s byte-parity assertions — genuinely nothing gates it today). |
| `resolve/2` documented as "never raises" but implemented identically to strict `push/3`/`dispatched/2` | `resolve/2` widened to be a true no-op on an unattached socket | This phase (D-50) | The first phase where `resolve/2` is called from GENERATED, adopter-pasted code rather than from library-internal or test code — the crash surface only exists starting now. |

**Deprecated/outdated:** Nothing in this phase deprecates prior Crosswake surfaces; it adds a new generator sibling to the two existing ones (`gen.bridge_hook`, `gen.offline_ui`) without replacing either.

## Assumptions Log

CONTEXT.md and UI-SPEC.md already tag their claims via decision numbers with explicit reversibility notes rather than the `[ASSUMED]` convention; this research re-verified every checkable file:line claim against the current tree and found no discrepancies. Two residual items carry genuine, stated uncertainty and are recorded here:

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `aria-modal="true"` is unreliable in Safari + VoiceOver, and the `inert` background mitigation is believed (not proven) sufficient (D-23) | Action Menu ARIA contract | If the mitigation is insufficient, VoiceOver users on Safari could still perceive background content as interactive during the modal state — CONTEXT.md and UI-SPEC.md already flag this as a manual-check limitation, not a passing assertion; the planner should not schedule a checkpoint that claims this is proven. |
| A2 | The `--cwfb-*` alias names proposed in UI-SPEC.md's Token Alias Layer table are Claude's-discretion spellings, not independently re-verified against any external convention | Token Alias Layer | Low risk — D-24 only fixes the MAPPING (which `--cw-*` each alias points to), not the spelling; renaming the aliases later is possible but costly once adopters have re-pointed their own copies (CONTEXT.md already flags this file as "costly — adopter-visible in a file we never regenerate"). |

**If this table is empty:** N/A — two items recorded above; neither blocks planning, both are already explicitly labeled as limitations in the upstream design contract.

## Open Questions

1. **Exact commit/task boundary between D-50/D-51 (bridge.ex fixes) and D-26/D-52 (patcher/tokens.css fixes)**
   - What we know: CONTEXT.md explicitly wants D-50 "as its own first commit for a clean bisect" — a strong signal it should be its own plan/task, isolated from the generator work.
   - What's unclear: Whether D-51 (`UnknownCapabilityFamilyError`) should ride in the same commit as D-50 (both touch `bridge.ex`/`contract.ex`, both are "shipped-code defects," but they fix different raise paths) or be split further.
   - Recommendation: Planner should place D-50 alone in the first plan/task of the phase (clean bisect point, zero blast radius since `Bridge.push/3` is unpublished per D-51's own note), then D-51 either alongside it or immediately after — both before any generator work that depends on `resolve/2` being safe to call from generated code.

2. **Whether the token-count mechanical cap test (`AUDIT.md:392`'s 30-token limit) is built this phase**
   - What we know: D-27 explicitly leaves this to "Claude's Discretion" — either resolution (build the test, or merely note the remaining headroom) is acceptable per CONTEXT.md.
   - What's unclear: Whether the planner should schedule it as a small bonus task or explicitly defer it with a one-line note in the phase's closing summary.
   - Recommendation: Given this phase spends the second-to-last token slot (27→29 of 30), and CONTEXT.md flags "after this phase only one slot remains," a cheap mechanical count assertion (`assert length(all_semantic_tokens) <= 30`) is low-cost and forecloses a much harder retrofit later. Lean toward building it, but it is explicitly not required.

3. **Whether `Crosswake.ComponentTierGuard`'s six rules need any adjustment given the actual template file structure once written**
   - What we know: D-36/D-37 specify six rules in the abstract (namespace, namespace_minted, component_use, component_dsl, template_sigil, components_exist_in_templates); D-37 confirms `component_use` and `template_sigil` are "zero today" (verified: no `Phoenix.Component`/`LiveComponent` use and no `~H` sigil currently exist anywhere in `lib/**/*.ex` — confirmed by the CONTEXT.md claim being internally consistent with this phase being the FIRST to introduce either).
   - What's unclear: The precise shape of the `components_exist_in_templates` positive-control fixture (a "real `lib/` plus real templates" pairing) cannot be fully pinned down until the actual generator/template file paths are chosen during planning.
   - Recommendation: Plan the guard's six rules as described, but treat the exact fixture file paths as an implementation detail resolved during the plan/execute step, not something requiring a second research pass.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Erlang toolchain | All `mix` tasks, `mix test` | ✓ | per `.tool-versions` (CI uses `erlef/setup-beam` `version-type: strict`) | — |
| Node.js + npm | Playwright spec, `compile-tokens.js`, `check-e2e-honesty.mjs` | ✓ | provisioned in `examples/phoenix_host` via `npm ci` in existing CI jobs | — |
| Playwright + Chromium | New `native_controls_fallback.spec.ts` | ✓ | already installed via `npx playwright install --with-deps chromium` in `route-tour-proof` job; `e2e-proof` job installs full `--with-deps` | — |
| A bundler (esbuild/webpack) for new JS | N/A | N/A (not needed) | — | This phase ships zero JS by design (D-10); the reference host's no-bundler architecture (`Plug.Static` + bare `<script type="module">`) is explicitly unaffected. |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None — this phase's entire toolchain is already present and exercised by existing CI jobs.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir, core library) + Playwright `@playwright/test` (browser, `examples/phoenix_host`) |
| Config file | `mix.exs` (ExUnit, no separate config) / `examples/phoenix_host/playwright.config.ts` |
| Quick run command | `mix test test/crosswake/component_tier_guard_test.exs` (once written) / `npx playwright test e2e/native_controls_fallback.spec.ts` (once written) |
| Full suite command | `mix test` (core) / `npx playwright test` (unfiltered, matches the real `e2e-proof` CI step) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| FALL-01 | Generator copies confirm-modal + action-menu files verbatim, no-clobber, stamped | unit (ExUnit, generator behavior) | `mix test test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` | ❌ Wave 0 |
| FALL-02 | No importable `Crosswake.UI.*` module exists; guard's six rules enforced with anti-vacuity twin | unit (ExUnit driving `Crosswake.ComponentTierGuard`) | `mix test test/crosswake/component_tier_guard_test.exs` | ❌ Wave 0 |
| FALL-02 (D-50/D-51) | `resolve/2` never raises on an unattached socket; distinct `UnknownCapabilityFamilyError` for the vocabulary-miss moment | unit (ExUnit, `Crosswake.Bridge`) | `mix test test/crosswake/bridge_test.exs` (extend existing file) | Existing file, new cases needed |
| PROOF-01 | Browser proves fallback renders (A1), fails closed on undeclared (A2), never silently degrades (A3) | e2e (Playwright, merge-blocking) | `npx playwright test e2e/native_controls_fallback.spec.ts` | ❌ Wave 0 |
| FALL-01/02 (contrast) | New/fixed tokens meet contrast floors, including the focus-ring gate hole | unit (Node test runner, `contrast.test.mjs`) | `node brandbook/tools/contrast.test.mjs` | Existing file, new assertions needed |
| FALL-01 (drift) | New template files gated against brand-color drift | structural (Node, `check-consumer-drift.mjs`) | `node brandbook/tools/check-consumer-drift.mjs` | Existing file, MANIFEST entries needed |

### Sampling Rate
- **Per task commit:** `mix test` (targeted file) and/or `node brandbook/tools/contrast.test.mjs` / `check-consumer-drift.mjs`, whichever the task touches.
- **Per wave merge:** Full `mix test --warnings-as-errors` (core) plus, for any wave touching `examples/phoenix_host`, `mix compile --warnings-as-errors` there.
- **Phase gate:** `npx playwright test` (unfiltered, matching the real `e2e-proof` job) green before `/gsd-verify-work`; `node script/check-e2e-honesty.mjs` and `node brandbook/tools/check-consumer-drift.mjs` both green.

### Wave 0 Gaps
- [ ] `test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` — covers FALL-01 (no-clobber, stamp, printed output)
- [ ] `test/crosswake/component_tier_guard_test.exs` — covers FALL-02 (six rules + anti-vacuity twin, positive/negative controls per D-37)
- [ ] `examples/phoenix_host/e2e/native_controls_fallback.spec.ts` — covers PROOF-01 (A1/A2/A3)
- [ ] `examples/phoenix_host/lib/crosswake_example/e2e/` — new `/_e2e/undeclared-control` route + controller for A2, plus `CROSSWAKE_PROOF_BREAK_FALLBACK` mutation control (D-47) — none of this exists yet
- [ ] Extend `test/crosswake/bridge_test.exs` — covers D-50 (`resolve/2` on unattached socket) and D-51 (`UnknownCapabilityFamilyError`)
- [ ] Framework install: none — all frameworks already present, only new test files are needed

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | This phase touches no auth surface — the confirm modal/action menu operate within an already-authenticated LiveView session. |
| V3 Session Management | No | No session state introduced. |
| V4 Access Control | Partial | The new `/_e2e/undeclared-control` route MUST be compile-time gated `if Mix.env() in [:test, :e2e]`, matching the existing three `/_e2e/*` routes, and verified absent from a `MIX_ENV=prod` compile by the existing `guard-02-prod-route-absence` CI job (`mix phx.routes` grep for `/_e2e`) — no new access-control mechanism needed, just conformance to the existing one. |
| V5 Input Validation | Yes | The generated `handle_event` clauses receive `phx-value-answer`/menu-selection payloads from the client; the adopter-pasted clauses (D-06) should validate/pattern-match the expected shape (`%{"answer" => "confirm"} `) rather than trusting arbitrary client payload — standard LiveView `handle_event` pattern-matching, no new library needed. |
| V6 Cryptography | No | No cryptographic operations in this phase. |

### Known Threat Patterns for {stack}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Client sends a forged `crosswake_fallback_answer` payload with an unexpected `answer` value to force a destructive action without going through the modal's intended flow | Tampering | The `handle_event` clause pattern-matches on expected literal answer values (`"confirm"`/`"cancel"`) and the actual mutation logic lives server-side in the adopter's own business logic, not in the generated file — the generated file only translates the event into a call the adopter already gates with their own authorization checks. This phase does not itself implement any mutation; it is out of scope to harden adopter mutation logic beyond documenting the pattern. |
| A malicious page (XSS elsewhere in the host) synthesizes `window.crosswakeBridge` to inject fabricated denials/success replies | Spoofing | Out of scope for this phase — this is the general bridge transport's threat model, already covered by Phase 154's seam design (the correlation-id/in-flight matching in `Bridge.push/3`/`resolve/2`), not something Phase 155's fallback UI introduces or worsens. |
| A test-only `/_e2e/undeclared-control` route accidentally reaching a production compile | Elevation of Privilege (info disclosure of test-only wiring) | Existing `guard-02-prod-route-absence` CI job already asserts no `/_e2e` route survives a clean `MIX_ENV=prod` compile — the new route must simply be added inside the SAME existing `if Mix.env() in [:test, :e2e]` guard block (`router.ex:581-593`), not a new conditional. |

## Sources

### Primary (HIGH confidence)
- Direct repo reads (this session) of: `lib/crosswake/bridge.ex`, `lib/crosswake/bridge/contract.ex`, `lib/crosswake/policy/validator.ex`, `lib/crosswake/manifest/builder.ex`, `lib/crosswake/companion_guard.ex`, `lib/crosswake/bridge/catalog_guard.ex`, `lib/crosswake/install/patcher.ex`, `lib/crosswake/shell/denial.ex`, `lib/mix/tasks/crosswake.gen.bridge_hook.ex`, `lib/mix/tasks/crosswake.gen.offline_ui.ex`, `brandbook/tools/compile-tokens.js`, `brandbook/tools/contrast.mjs`, `brandbook/tools/contrast.test.mjs`, `brandbook/tools/check-consumer-drift.mjs`, `brandbook/tools/compile-tokens.test.mjs`, `brandbook/tokens/crosswake.tokens.json`, `script/check-e2e-honesty.mjs`, `.github/workflows/offline-sync-e2e-gate.yml`, `examples/phoenix_host/lib/crosswake_example/endpoint.ex`, `examples/phoenix_host/lib/crosswake_example/router.ex`, `examples/phoenix_host/e2e/route_tour.spec.ts`, `examples/phoenix_host/e2e/evidence_panel.spec.ts`, `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex`, `deps/phoenix_live_view/lib/phoenix_component.ex`, `mix.lock`, `Package.swift`, `packages/crosswake-shell-core-android/build.gradle.kts`, `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`, `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt`.
- `.planning/phases/155-host-owned-fallback-components/155-CONTEXT.md` — 59 locked decisions, verified against source where checkable.
- `.planning/phases/155-host-owned-fallback-components/155-UI-SPEC.md` — approved design contract, treated as settled.
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — project state and requirement text.

### Secondary (MEDIUM confidence)
- None — all claims in this research were independently re-verified against source in this session rather than relying on secondary summarization.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new dependencies; existing `phoenix_live_view` 1.1.30 `focus_wrap/1` confirmed present by direct source read, not changelog inference.
- Architecture: HIGH — every file:line citation from CONTEXT.md's canonical_refs that was re-checked in this session matched the current tree exactly, including the three shipped-code defects.
- Pitfalls: HIGH — each pitfall traces to a verified, reproducible-today fact (e.g., `groups` array missing `'overlay'`, `only:` list missing `assets`, `resolve/2` calling the raising `fetch_state!/1`).

**Research date:** 2026-07-30
**Valid until:** 30 days (stable, first-party codebase; the only external-facing claim — `phoenix_live_view` 1.1.30's `focus_wrap/1` behavior — is a stable, long-shipped LiveView API unlikely to change during this phase's execution window).
