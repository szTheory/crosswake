# Phase 108: Consumer Normalization - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Rewire the **two drifted consumers** so they reference the **semantic token tier exclusively** (consumed from the already-distributed `tokens.css`), with **no duplicated flat palette, no inline font stacks, and no Tailwind utility classes**, and update the generator test to assert the new contract:

1. **Example host CSS** — `examples/phoenix_host/assets/css/app.css`
2. **The `offline_ui` generator** — both the `priv/templates/crosswake/offline_ui/*.eex` templates **and** the stale hardcoded Tailwind/esbuild theme emitted by `lib/mix/tasks/crosswake.gen.offline_ui.ex` (the legacy blue `#699cc9` / amber `#e1b982` "Next steps" block — the *actual* color source backing the templates' utility classes).
3. **Test contract** — `test/mix/tasks/crosswake.gen.offline_ui_test.exs`.

This phase is **wiring only** against the frozen v9.0 brand contract — not a redesign and not a values change. The token **source** and **distribution mechanism** were delivered in Phase 107; this phase makes the consumers actually *consume* them.

**Out of scope (other phases):**
- The drift-prevention CI gate (fail on hardcoded hex / missing `var(--cw-`) → **Phase 109** (PROOF-01).
- The byte-identical `tokens.css` parity assertion → folded into Phase 109.
- Any change to `crosswake.tokens.json`, `compile-tokens.js`, the brand book, or token *values* — all frozen.

**Requirements:** NORM-01 (example host CSS), NORM-02 (offline_ui generator), NORM-04 (generator test).

</domain>

<decisions>
## Implementation Decisions

### Offline UI styling mechanism (NORM-02) — USER DECISION
- **D-01:** The generator emits a **vendored `offline.css`** component stylesheet that expresses **both color and layout** through semantic-class rules referencing custom properties (e.g. `.cw-offline-card { background: var(--cw-surface-inset); border-radius: var(--cw-radius-lg); border: 1px solid var(--cw-border-default); }`). It is **copied into the host's `priv/static/assets/offline.css`** using the existing `ensure_file` **no-clobber** guard (never overwrite a host-customized copy), exactly mirroring the Phase 107 `tokens.css` "vendor by copy + link" mechanism. *(User chose this over inline `style=` attributes and over an inline `<style>` block — for consistency with 107, the example-host idiom, override-ability, and a single greppable target for Phase 109.)*
- **D-02:** `offline_root.html.heex.eex` links the three stylesheets in order: `tokens.css` (defines custom properties) → `app.css` (host's own) → **`offline.css`** (consumes them). The `<body>` and template markup use the new `.cw-offline-*` semantic classes — **no Tailwind classes remain** (`bg-cw-foam-50`, `text-cw-current-950`, `flex`, `min-h-screen`, `max-w-md`, `space-y-4`, `border-cw-*`, etc. all retired).
- **D-03:** `offline.css` carries **no app-specific interpolation** (no module names) — it is recommended to ship as a **static vendored file** copied verbatim (parallel to `tokens.css`), not an EEx template, keeping it greppable and diffable. *(Planner discretion on exact file form, but keep it a single namespaced file.)*

### Color → token mapping policy (NORM-01 / NORM-02) — decided by code analysis
- **D-04:** **Map onto the semantic tier wherever a semantic token captures the meaning** — this is what makes dark mode work with zero extra CSS (success criterion #1). Every color in the current consumers traces to a semantic token (the v9.0 tier was designed for them). Canonical mapping to apply:
  - body bg → `--cw-surface-default`; body text → `--cw-text-default`
  - card/panel bg → `--cw-surface-inset`; raised/badge bg → `--cw-surface-raised`
  - borders → `--cw-border-default`; muted/secondary text → `--cw-text-subtle`
  - primary button → `--cw-action-bg` / `--cw-action-hover` / `--cw-action-fg` / `--cw-action-focus-ring`
  - `.btn-success` → `--cw-status-success`; `.btn-danger` → `--cw-status-error`
  - `.badge-offline` → `--cw-runtime-offline` (exact kelp-800 match); `.badge-native` → `--cw-runtime-native` (exact brass-500 match)
  - fonts → `--cw-font-display` / `--cw-font-body` / `--cw-font-mono`; radii → `--cw-radius-*`; sizes → `--cw-text-scale-*`
- **D-05:** The **only two genuinely ambiguous cases** are the example host's `.sync-status-pending` and `.sync-status-complete`. Map to nearest: pending → `--cw-status-warning`, complete → `--cw-status-success`. **Planner's discretion** if a closer fit emerges. Prefer a semantic token over a primitive in every case so dark mode adapts; fall back to `--cw-primitive-*` **only** if no semantic token carries the meaning (none expected here).

### Required cleanup (NORM-01 / NORM-02) — not optional, not gray areas
- **D-06:** **Delete** the entire hand-authored `:root { … }` block at the top of `examples/phoenix_host/assets/css/app.css` — both the flat primitive aliases (`--cw-foam-50`, `--cw-wake-700`, `--cw-current-950`, …, which lack the `primitive.` prefix and duplicate the source) **and** the hand-declared `--cw-font-display/body/mono` font stacks. After deletion, `app.css` holds **only component rules** whose color/font/radius/size values are `var(--cw-…)` references resolved by the linked `tokens.css`. Result: zero hex, zero duplicated aliases, dark mode "free."
- **D-07:** **Retire** the stale "Next steps" instruction block in `lib/mix/tasks/crosswake.gen.offline_ui.ex` (`Mix.shell().info`): remove step 2 (the `tailwind.config.js` with legacy blue `#699cc9` / amber `#e1b982` theme) and step 3 (esbuild CSS bundling guidance — host has no bundler). Replace with honest token-link guidance: the generator vendors `tokens.css` + `offline.css` and the layout links them; the adopter only needs to mount the controller (and keep `offline.js` bundling guidance, which is real and separate). No Tailwind, no CSS build step.
- **D-08:** Hardcoded inch-by-inch values currently annotated as token comments in `app.css` (e.g. `border-radius: 14px; /* radius-lg */`, `font-size: 12px; /* text-xs */`, `10px /* radius-md */`) should be converted to the actual token references (`var(--cw-radius-lg)`, `var(--cw-text-scale-xs)`, `var(--cw-radius-md)`) — the comments reveal the intended tokens; wire them so Phase 109's gate sees real references, not literals.

### Test contract (NORM-04)
- **D-09:** Rewrite `test/mix/tasks/crosswake.gen.offline_ui_test.exs` to assert the **new** contract and **remove** the assertions that pin the retired theme. Specifically:
  - **Remove** the `outputs standard instructions` assertions for `"cw-wake-700"`, `"cw-brass-500"`, `"tailwind.config.js"`, and `"Configure esbuild to bundle offline.js"` that lock in the stale Tailwind theme. (Keep the legitimate `"get \"/offline\""` / controller / "generated successfully" assertions; keep `offline.js` bundling assertion only if D-07 keeps that guidance.)
  - **Add** assertions that the generated output contains **semantic token references** (e.g. `var(--cw-surface-default)`, `var(--cw-text-default)`, `--cw-action-bg`) and the **absence** of retired Tailwind class names (`flex`, `bg-white`, `bg-cw-foam-50`, `text-cw-current-950`, `min-h-screen`, `border-cw-`).
  - **Add** assertions that `offline.css` is vendored into `priv/static/assets/offline.css` with the same **no-clobber** semantics already tested for `tokens.css`, and that `offline_root` links it after `tokens.css`.

### Claude's Discretion
- Exact `.cw-offline-*` class names and the internal structure of `offline.css`.
- Exact form of `offline.css` (static vendored file vs. trivial EEx) — keep it a single namespaced, greppable file.
- Precise wording of the rewritten "Next steps" generator output.
- Whether the example host keeps its bespoke flashcard component CSS verbatim (only color/font/radius refs swapped) — yes, it stays a distinct surface from the generic generated `offline.css`; the two are not shared.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — NORM-01, NORM-02, NORM-04 (this phase); PROOF-01 (Phase 109, downstream awareness); NORM-03 (Phase 107, done).
- `.planning/ROADMAP.md` § "Phase 108: Consumer Normalization" — goal + 4 success criteria (the acceptance bar).
- `.planning/STATE.md` § Accumulated Context → Decisions + Blockers/Concerns — frozen-contract, wiring-only, no-new-toolchain, and the "three drifted consumers (the worst is the `.ex`-emitted theme)" warning.
- `.planning/phases/107-token-source-distribution/107-CONTEXT.md` — the distribution contract this phase wires against (D-05..D-09: vendor-by-copy + `<link>`, packaged mirror at `priv/static/crosswake/tokens.css`, link order).

### Consumers to rewire (the files this phase changes)
- `examples/phoenix_host/assets/css/app.css` — delete the `:root` flat-palette + font-stack block; swap component color/font/radius/size refs to semantic `var(--cw-…)`.
- `priv/templates/crosswake/offline_ui/offline_root.html.heex.eex` — link `offline.css` after `tokens.css`/`app.css`; retire `<body>` Tailwind classes.
- `priv/templates/crosswake/offline_ui/offline_page.html.heex.eex` — replace all Tailwind utility classes (color + layout) with `.cw-offline-*` semantic classes.
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — emit/copy `offline.css` (no-clobber, like tokens.css); retire the stale `tailwind.config.js`/esbuild "Next steps" block (~lines 56-100, the `Mix.shell().info` heredoc).
- `test/mix/tasks/crosswake.gen.offline_ui_test.exs` — rewrite per D-09.

### Token source (frozen — read for available semantic names, do NOT modify)
- `priv/static/crosswake/tokens.css` — the packaged, distributed token file; authoritative list of available `--cw-*` semantic names (`surface/text/border/action/status/runtime-*`, `font-*`, `radius-*`, `text-scale-*`) and their light/dark mappings.
- `brandbook/tokens/tokens.css` — byte-identical brand-book copy (same source).
- `brandbook/tokens/crosswake.tokens.json` — DTCG single source of truth (context only; not edited here).
- `brandbook/BRAND-SPEC.md` — token-tier rules / source-of-truth contract (context only).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `crosswake.gen.offline_ui.ex` `ensure_file/2` — existing **no-clobber** writer (returns `:reused`/`:created`, logs). Reuse verbatim for the `offline.css` copy, exactly as 107 used it for `tokens.css`.
- `get_tokens_css_path/0` — `Application.app_dir(:crosswake, "priv/static/crosswake/...")` with a dev-cwd fallback. The same pattern resolves a packaged `offline.css` source if it ships under `priv/`.
- The example host already links `/css/tokens.css` **then** `/css/app.css` in `deck_live/index.ex` and `deck_live/show.ex` (lines 15-16) — token custom properties are already defined before `app.css` is parsed, so D-06's deletion of the `:root` block is safe.

### Established Patterns
- **Vendor-by-copy + `<link>`** is the locked 107 distribution mechanism — `offline.css` follows it identically (one more vendored static file, one more `<link>`, no bundler).
- **Generated-file discipline** — vendored assets carry `/* GENERATED … do not edit */` headers; `offline.css` should match if shipped as a generated artifact.
- **Greppable/deterministic targets** — Phase 109's gate is a textual grep; keep each consumer's output a single known file with `var(--cw-` references and no bare brand hex.
- **Zero host build toolchain** — no Tailwind, no esbuild for CSS; static `<link>` only. D-07 removes the last instructions implying otherwise.

### Integration Points
- `crosswake.gen.offline_ui.ex` run → add `ensure_file(offline_css_dest, …)` alongside the existing `tokens.css` copy; add the `<link>` in `offline_root`.
- Semantic tier in `tokens.css` → consumed by both `app.css` (host) and `offline.css` (generated). Same names, two surfaces.
- Dark mode is automatic once consumers reference semantic tokens — `tokens.css` already carries the `@media (prefers-color-scheme: dark)` and `[data-theme="dark"]` overrides for the semantic tier.

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose the **vendored `offline.css`** mechanism (generated semantic-class stylesheet, copied no-clobber + linked) over inline `style=` attributes and over an inline `<style>` block — for consistency with the Phase 107 link mechanism, the example-host idiom, adopter override-ability, and a single greppable target for Phase 109.
- Profile is opinionated / `minimal_decisive`: the near-1:1 semantic mapping, dark-mode-via-semantic-tokens, deletion of the flat `:root` block, and retirement of the stale Tailwind/esbuild instructions were decided directly from code analysis (low/medium-stakes) rather than asked. Only the generator's public-contract styling mechanism was escalated.

</specifics>

<deferred>
## Deferred Ideas

- **Drift-prevention CI gate** (extend `brand-structural` to fail on bare brand hex / missing `var(--cw-` in normalized consumers) → **Phase 109** (PROOF-01). This phase must leave each consumer as a single greppable file with real token references so the gate has stable targets, but does NOT implement the gate.
- **Byte-identical parity assertion** between `brandbook/tokens/tokens.css` and `priv/static/crosswake/tokens.css` → folded into Phase 109.

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 108-Consumer Normalization*
*Context gathered: 2026-06-13*
