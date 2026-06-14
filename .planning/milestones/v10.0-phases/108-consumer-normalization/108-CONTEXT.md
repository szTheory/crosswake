# Phase 108: Consumer Normalization - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Rewire the **drifted brand-color consumers** so they reference the **semantic token tier exclusively** (consumed from the already-distributed `tokens.css`), with **no duplicated flat palette, no inline font stacks, no Tailwind utility classes, and no primitive-tier references** — then update the generator test to assert the new contract.

**In scope (confirmed via discussion + deep research):**
1. **Generator** — the `priv/templates/crosswake/offline_ui/*.eex` templates **and** the stale hardcoded Tailwind/esbuild theme emitted by `lib/mix/tasks/crosswake.gen.offline_ui.ex` (legacy blue `#699cc9` / amber `#e1b982` "Next steps" block — the *actual* color source behind the templates).
2. **A new vendored `offline.css`** the generator emits + copies (no-clobber) into the host and links — the component styling layer for the offline page.
3. **Example host — the REAL served consumers** (research correction; see D-12): `examples/phoenix_host/priv/static/css/app.css` (the file DeckLive actually renders), reconciliation of the unserved `assets/css/app.css` duplicate, and the example host's own offline page `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` (inline Tailwind-hex `<style>` block → semantic tokens).
4. **Test contract** — `test/mix/tasks/crosswake.gen.offline_ui_test.exs`.

This phase is **wiring only** against the frozen v9.0 brand contract — not a redesign, not a values change, no new tokens. The token **source** and **distribution mechanism** were delivered in Phase 107; this phase makes the consumers actually *consume* them, correctly and accessibly.

**Out of scope (other phases / deferred — see `<deferred>`):**
- The drift-prevention CI gate (fail on bare brand hex / `--cw-primitive-*` / missing `var(--cw-` in normalized consumers) → **Phase 109** (PROOF-01).
- `examples/phoenix_host/.../saas_portal/step_up_challenge_live.ex` (dead Tailwind utilities) and `examples/phoenix_host/priv/static/offline_study.js` (innerHTML hardcoded hex) → noted follow-up.
- Any change to `crosswake.tokens.json`, `compile-tokens.js`, `mix.exs` `files:`, the brand book, or token *values/names* — all frozen. **Adding new semantic tokens is forbidden** (brand book hard cap: 30 semantic tokens, 27 used; component-tier tokens explicitly prohibited).
- Dynamic sync-state UI, sync counts, retry actions, conflict disclosure, staleness timestamps — offline-page UX features beyond a faithful token restyle.

**Requirements:** NORM-01 (example host consumes semantic tier, renders light+dark), NORM-02 (offline_ui generator token-backed, no Tailwind), NORM-04 (generator test asserts the new contract).

</domain>

<decisions>
## Implementation Decisions

### Offline UI styling mechanism (NORM-02) — USER DECISION, research-VALIDATED
- **D-01:** The generator emits a **vendored `offline.css`** component stylesheet that expresses **both color and layout** through semantic-class rules referencing custom properties (`.cw-offline-card { background: var(--cw-surface-inset); border-radius: var(--cw-radius-lg); border: 1px solid var(--cw-border-default); }`). Copied into the host's `priv/static/assets/offline.css` via the existing `ensure_file` **no-clobber** guard, mirroring the Phase 107 `tokens.css` "vendor by copy + link" mechanism. *Research confirms this is the idiomatic, correct choice:* it matches the `mix phx.gen.auth` host-owned-editable-file model, the `guides/tokens.md` distribution contract, and avoids the Tailwind lock-in footgun that excludes no-build hosts (petal_components / salad_ui / backpex). It is strictly better than `ash_admin`'s inline-`<style>`-re-sent-every-render and than `live_dashboard`'s un-overridable embedded CSS — the offline page is brand-facing and host-customizable.
- **D-02:** `offline_root.html.heex.eex` links three stylesheets in order: `tokens.css` (defines custom properties) → `app.css` (host's own) → **`offline.css`** (consumes them). Markup uses `.cw-offline-*` semantic classes — **no Tailwind classes remain** (`bg-cw-foam-50`, `text-cw-current-950`, `flex`, `min-h-screen`, `max-w-md`, `space-y-4`, `border-cw-*`, `border-gray-200`, `text-gray-500`, etc. all retired).
- **D-03:** `offline.css` carries no app-specific interpolation — ship as a **static vendored file** copied verbatim (parallel to `tokens.css`), greppable/diffable, with the `/* GENERATED … do not edit */` header convention. It **consumes** semantic tokens only; it **must not redefine** any `--cw-*` value. Dark mode flows automatically because the semantic tokens it references already flip in `tokens.css`.

### Token mapping policy (NORM-01 / NORM-02) — REVISED by brand-contract research
- **D-04:** **Semantic-tier ONLY.** `brandbook/AUDIT.md §7` + `BRAND-SPEC.md §7` make this absolute: *"Primitive tokens: internal, never referenced in component CSS. Only semantic tokens cross the library boundary."* Every color/font/radius/size value in every consumer maps to a semantic token — **`--cw-primitive-*` references are forbidden** in consumer CSS (this supersedes the earlier "primitive fallback" idea). Canonical mapping to apply:
  - body bg → `--cw-surface-default`; body text → `--cw-text-default`
  - card/panel bg → `--cw-surface-inset`; raised/badge bg → `--cw-surface-raised`
  - borders → `--cw-border-default` (or `--cw-border-strong` for accent borders); muted/secondary text → **`--cw-text-muted`** (see D-05)
  - primary button → `--cw-action-bg` / `--cw-action-hover` / `--cw-action-fg` / `--cw-action-focus-ring`
  - offline/native badges → `--cw-runtime-offline` (exact kelp-800) / `--cw-runtime-native` (exact brass-500)
  - fonts → `--cw-font-display` / `--cw-font-body` / `--cw-font-mono`; radii → `--cw-radius-*`; sizes → `--cw-text-scale-*`; spacing → multiples of `--cw-spacing-base`; display tracking → `--cw-tracking-tight`
- **D-05:** **Use `--cw-text-muted` (resolves to stone-600), NOT `--cw-text-subtle` (stone-500), for normal-size secondary text.** Stone-500 on foam-50 fails WCAG AA at 4.09:1 (the token file flags it as a forbidden pairing); stone-600 is the v9.0 remediation and passes (4.53:1 light / 12.25:1 dark). Applies to `#status`, `.card-back`, session-item subtitles, and the offline page's secondary text.
- **D-06:** **Status colors as button backgrounds carry a contrast footgun — render-verify required.** `.btn-success`/`.btn-danger` backgrounds → `--cw-status-success`/`--cw-status-error`, but `--cw-status-success` flips to `wake-500` (#4E9A8E) in dark mode where **white text fails AA (~2.9:1)**. So: button foreground = **`--cw-text-inverse`** (theme-aware), NOT hardcoded white; executor **MUST browser-render and visually check both light AND dark** (per the project's render-verify rule). If a solid fill fails contrast in either mode, switch that button to an **outlined treatment** (status color as border + text on `--cw-surface-*`). **`--cw-status-warning` is never a fill behind light text.** Sync-status indicators (`.sync-status-pending`/`-complete`) use status tokens as **`color:`** only (pending → `--cw-status-warning`, complete → `--cw-status-success`), on a neutral surface, not as backgrounds. We **cannot** add `--cw-action-danger-bg`/etc. (tokens frozen, hard-capped).

### Accessibility & correctness — folded into the template rewrite (brand book + UX research)
- **D-07:** Add to the consumer/offline CSS (the templates are being rewritten anyway, so this is in-scope, not creep):
  - `:root { color-scheme: light dark; }` — so browser chrome/scrollbars/form controls track the theme.
  - A `:focus-visible { outline: var(--cw-focus-ring-width) solid var(--cw-action-focus-ring); outline-offset: 2px; }` rule — **`outline`, not `box-shadow`-only** (box-shadow is invisible in Windows Forced-Colors mode).
  - **Status not by color alone** (WCAG 1.4.1; brand book §8 *"pair status colors with text labels and icons"*): the offline status card must carry a non-color cue (e.g., a thick `border-left` shape cue) in addition to its text.
- **D-08:** Upgrade the offline page markup semantics during the rewrite: `role="status"` on the status card (must exist in initial DOM for WCAG 4.1.3 / future JS updates); session list as `<ul role="list">/<li>`; the "Status" label as a heading (`<h2>`). Keep the page structure otherwise unchanged (no redesign).
- **D-09:** **Keep the existing microcopy** — "Available offline" / "Pending server confirmation" / "Draft only" already match the prescribed status vocabulary in `BRAND-SPEC.md §15` and the honesty principles in `guides/offline.md` (no false reassurance). An HTML comment may flag the placeholder copy as proto-copy for adopters. Copy embellishments (e.g. "— will sync when reconnected") are **deferred**.
- **D-10:** **No `var()` fallbacks** (neither `var(--cw-x, #hex)` nor `var(--cw-x, 14px)`). `tokens.css` is contractually guaranteed to load before consumers (D-02 link order), so fallbacks are unnecessary, and a hex fallback would both mask drift and risk tripping / weakening Phase 109's grep. Convert token-intent comments to real references (`border-radius: 14px; /* radius-lg */` → `border-radius: var(--cw-radius-lg);`; `font-size: 12px; /* text-xs */` → `font-size: var(--cw-text-scale-xs);`).

### Generator DX & cleanup (NORM-02) — research-informed
- **D-11:** **Retire** the stale "Next steps" block in `crosswake.gen.offline_ui.ex` (`Mix.shell().info`): remove step 2 (the `tailwind.config.js` legacy blue/amber theme) and step 3 (esbuild CSS bundling — host has no bundler). Replace with honest, concise guidance modeled on `mix phx.gen.auth`: the generator vendored `tokens.css` + `offline.css`; the layout links them in order; state explicitly that these are **host-owned and editable**, and that re-running won't update them (no-clobber) — to pick up upstream token changes, delete and re-run. Keep the legitimate router-mount step and the `offline.js` bundling guidance (real, separate from CSS). **No Tailwind, no CSS build step.** Keep the existing `ensure_file` no-clobber (already tested). *Igniter and `Mix.Generator.create_file/3` + `--force` are noted as future DX, not adopted now.*

### Example-host scope correction (NORM-01) — USER DECISION (Option A)
- **D-12:** Research found the ROADMAP-named `examples/phoenix_host/assets/css/app.css` **is not served** — Phoenix serves `priv/static/`, there is **no asset build pipeline**, and DeckLive (`deck_live/index.ex`, `show.ex`) links `/css/app.css` = **`examples/phoenix_host/priv/static/css/app.css`** (a *different*, hand-written, divergent file). Therefore this phase:
  - Normalizes the **SERVED** `priv/static/css/app.css` (the real consumer DeckLive renders) onto semantic tokens — this is what makes dark mode actually visible on the demo.
  - **Reconciles the duplicate:** make one file canonical so it can't re-drift. **Recommended:** delete the unserved `assets/css/app.css` after confirming no served path references it (or, if it carries unique flashcard-island rules that are actually used, fold them into the served file). Planner/researcher must verify references before deleting.
  - Normalizes the example host's own offline page `controllers/offline_html/index.html.heex` — its inline `<style>` block of all-Tailwind-system hex (#3b82f6 / #10b981 / #ef4444, `system-ui`, `0.5rem`) → semantic tokens (link `tokens.css` or use `var(--cw-*)`), so the example genuinely demonstrates token consumption in both themes.
  - The example host CSS keeps its bespoke component rules (flashcard, cards, buttons, badges) — only the color/font/radius/size **values** become semantic `var(--cw-…)`, and the hand-authored flat `:root` palette + font-stack blocks are **deleted** (zero hex, zero flat aliases, zero primitives).

### Phase release gate (project render-verify rule)
- **D-13:** This phase is **not done** until the example host and a generated offline page are **browser-rendered and visually inspected in BOTH light and dark mode** (system + `[data-theme]` toggle), confirming: correct colors, working dark mode, AA contrast on text and status buttons (D-06), visible focus rings, no hover/focus weirdness, no layout shift. Verification must LOOK at the rendered output, not just grep for `var(--cw-`.

### Claude's Discretion
- Exact `.cw-offline-*` class names and internal structure of `offline.css`.
- Exact form of `offline.css` (static vendored file vs. trivial EEx) — single namespaced greppable file.
- Whether `.btn-success`/`.btn-danger` end up solid-fill (with `--cw-text-inverse`) or outlined — decide by render-verify per D-06.
- Precise wording of the rewritten generator "Next steps" output.
- Exact duplicate-reconciliation (delete `assets/css/app.css` vs. fold) after verifying references.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — NORM-01, NORM-02, NORM-04 (this phase); PROOF-01 (Phase 109, downstream).
- `.planning/ROADMAP.md` § "Phase 108: Consumer Normalization" — goal + 4 success criteria (acceptance bar). Note: success-criterion #1 names `assets/css/app.css`; D-12 corrects this to the served file + reconciliation.
- `.planning/STATE.md` § Accumulated Context — frozen-contract, wiring-only, no-new-toolchain, "three drifted consumers / worst is the `.ex`-emitted theme" warning.
- `.planning/phases/107-token-source-distribution/107-CONTEXT.md` — the distribution contract this phase wires against (vendor-by-copy + `<link>`, packaged mirror, link order).

### Brand contract — NORMATIVE (read for rules; do NOT modify; tokens frozen)
- `brandbook/AUDIT.md` §7 (Architecture Overview, two-tier rule, theming model D-08, runtime tier, spacing/radius/focus), §13 (Do-not: component tokens), Appendix A (WCAG matrix).
- `brandbook/BRAND-SPEC.md` §7 (token spec, primitive-internal rule), §8 (semantic color mapping, Stone-600 remediation, color-not-alone), §9 (font tokens), §13 (radius scale), §15 (status-label microcopy), §18 (reduced-motion), §21/§23 (WCAG do/don't).
- `guides/tokens.md` — distribution mechanism, consumer expectations, link order, no-hand-edit, byte-parity, no-toolchain (the binding DX contract delivered in 107).

### Offline UX / honesty vocabulary (for the offline page)
- `guides/offline.md` — supported shapes + exact state vocabulary (`cached read-only`, `stale`, `saved locally`, `queued for replay`, `replay failed`, `conflict requires attention`), support boundary.
- `guides/user_flows.md` — personas / JTBD / honest degraded-path messaging.

### Consumers to rewire (the files this phase changes)
- `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` — link `offline.css` after `tokens.css`/`app.css`; retire `<body>` Tailwind classes; add `color-scheme`/focus rule home (in offline.css).
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` — replace ALL Tailwind classes (color + layout) with `.cw-offline-*`; add a11y markup (D-08).
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — emit/copy `offline.css` (no-clobber); retire the stale `tailwind.config.js`/esbuild "Next steps" heredoc (~lines 62-101).
- (NEW vendored) `priv/static/crosswake/offline.css` (or equivalent) — the generated component stylesheet source.
- `examples/phoenix_host/priv/static/css/app.css` — **the SERVED file**; normalize onto semantic tokens (D-12).
- `examples/phoenix_host/assets/css/app.css` — the unserved duplicate; reconcile (delete or fold) per D-12.
- `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex` — inline Tailwind-hex `<style>` → semantic tokens.
- `examples/phoenix_host/lib/crosswake_example/flashcards/deck_live/index.ex` & `show.ex` — link order reference (lines 15-16); confirm they pick up the normalized served CSS.
- `test/mix/tasks/crosswake.gen.offline_ui_test.exs` — rewrite per the NORM-04 notes below.

### Token source (frozen — read for available semantic names, do NOT modify)
- `priv/static/crosswake/tokens.css` — authoritative semantic `--cw-*` names + light/dark mappings; carries forbidden-pairing comments (stone-500/wake-500/mist-200 on foam-50).
- `brandbook/tokens/tokens.css` (byte-identical), `brandbook/tokens/crosswake.tokens.json` (DTCG source).

### CI (context for Phase 109; do not extend here)
- `.github/workflows/brandbook-verify.yml` — `brand-structural` (required) currently triggers only on `brandbook/**`; Phase 109 extends it to `examples/**` + `priv/templates/**` and adds the consumer drift greps.

### NORM-04 test rewrite contract
- **Remove** the `outputs standard instructions` assertions that pin retired content: `"cw-wake-700"`, `"cw-brass-500"`, `"tailwind.config.js"`, `"Configure esbuild to bundle offline.js"`. Keep neutral ones (`"get \"/offline\""`, controller name, "generated successfully").
- **Add**: generated output contains semantic token refs (`var(--cw-surface-default)`, `var(--cw-text-default)`, `--cw-action-bg`); contains **no** Tailwind classes (`flex`, `bg-white`, `bg-cw-foam-50`, `text-cw-current-950`, `min-h-screen`, `border-cw-`, `border-gray-`) and **no** `--cw-primitive-` references; `offline.css` vendored to `priv/static/assets/offline.css` with no-clobber (mirror the existing tokens.css no-clobber test); `offline_root` links `offline.css` after `tokens.css`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `crosswake.gen.offline_ui.ex` `ensure_file/2` — tested no-clobber writer (`:reused`/`:created`). Reuse verbatim for the `offline.css` copy.
- `get_tokens_css_path/0` — `Application.app_dir(:crosswake, "priv/static/crosswake/...")` with dev-cwd fallback; same pattern resolves a packaged `offline.css`.
- DeckLive already links `/css/tokens.css` then `/css/app.css` (lines 15-16) — custom properties defined before `app.css`, so deleting the served file's flat `:root` block is safe.

### Established Patterns
- **Vendor-by-copy + `<link>`** (107) — `offline.css` follows it identically. **Two-tier tokens, semantic-only at the boundary** (brand book, hard rule). **No build toolchain** (static `<link>` only). **Greppable/deterministic** targets for Phase 109.
- Generated assets carry `/* GENERATED … do not edit */`. Host-owned generated code is editable; library-owned token values are not.

### Integration Points / Landmines
- **Served-vs-source `app.css`** (D-12): the file that renders is `priv/static/css/app.css`, NOT `assets/css/app.css`. Normalizing the wrong one = zero visible effect. No pipeline copies between them.
- The example host's offline page (`index.html.heex`) is a **second** offline surface distinct from the generator templates — both must be normalized.
- Dark mode is automatic once consumers use semantic tokens (`tokens.css` carries `@media (prefers-color-scheme: dark) :root:not([data-theme])` + `[data-theme="dark"]`).
- Status tokens flip in dark mode (success→wake-500) — the D-06 contrast footgun. `--cw-runtime-native` and `--cw-status-error` do NOT flip; success/warning/offline DO.

</code_context>

<specifics>
## Specific Ideas

- User chose the **vendored `offline.css`** mechanism (research-validated as idiomatic vs. inline styles / inline `<style>`).
- User chose **Option A** for example-host scope: normalize the real served consumers + reconcile the duplicate + the example offline page; defer `step_up_challenge_live.ex` + `offline_study.js`.
- Deep research (5 parallel subagents: Phoenix-lib asset/DX idioms, design-token/dark-mode CSS, offline UI/UX+a11y, internal prompts/brand/guides, codebase grounding) drove the brand-contract corrections (semantic-only, text-muted not text-subtle, status-button contrast, color-scheme/focus/role=status, no var fallbacks) and the served-vs-source discovery. Profile is opinionated/`minimal_decisive`: only the two genuinely high-impact decisions (styling mechanism, example-host scope) were escalated.

</specifics>

<deferred>
## Deferred Ideas

- **Drift-prevention CI gate** (extend `brand-structural` to fail on bare brand hex / `--cw-primitive-*` / missing `var(--cw-` in normalized consumers; trigger on `examples/**` + `priv/templates/**`; byte-parity diff of the two `tokens.css`) → **Phase 109** (PROOF-01). This phase leaves each consumer as a single greppable file with semantic refs so the gate has stable targets.
- **`step_up_challenge_live.ex`** (dead `bg-[#2563EB]` Tailwind utilities that won't render without a pipeline) and **`offline_study.js`** (hardcoded hex `#9A4D35`/`#fee2e2`/`#ef4444` via innerHTML) → noted follow-up; a different class of fix than CSS-token normalization.
- **Offline-page UX features** (dynamic sync-state updates, pending-count, retry/reconnect action, per-item sync-failed state, staleness timestamps, sync animation + `prefers-reduced-motion`) → future phase; not a token restyle.
- **Microcopy embellishments** (e.g. "Pending server confirmation — will sync when reconnected") → future, optional.
- **Generator DX upgrades** — Igniter adoption (when the generator needs to patch `router.ex`/`config.exs`; use optional-dep pattern) and `Mix.Generator.create_file/3` + `--force` for the standard conflict protocol → future DX, not this phase.
- **Shadow-opacity token** — `box-shadow: ... rgba(9,20,26,0.06)` has no token; leave as-is (no brand-hex; an rgba of current-950). Note for a future token addition if drift gate flags it.

</deferred>

---

*Phase: 108-Consumer Normalization*
*Context gathered: 2026-06-13*
