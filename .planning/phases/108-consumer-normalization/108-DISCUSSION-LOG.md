# Phase 108: Consumer Normalization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 108-Consumer Normalization
**Areas discussed:** Offline UI styling mechanism; Example-host normalization scope (after deep research)

---

## Offline UI styling mechanism (NORM-02)

How the generated offline UI should express styling once Tailwind utility classes (color **and** layout) are removed, given the host carries no Tailwind/bundler.

| Option | Description | Selected |
|--------|-------------|----------|
| Vendored `offline.css` | Generator emits a semantic-class stylesheet (`.cw-offline-*` → `var(--cw-…)`) covering color + layout, copied no-clobber into host `priv/static/assets/offline.css`, linked after `tokens.css`. Mirrors 107 vendor-by-copy+link; matches example-host idiom; override-able; single greppable target for Phase 109. | ✓ |
| Inline `style=` attributes | Each element carries `style="…: var(--cw-…)"` directly in HEEx; no extra file, but verbose (layout inline), repeated strings, hard to override. | |
| Inline `<style>` block in layout | Generator writes a `<style>` block of semantic classes into `offline_root.html.heex`; self-contained but not vendored-by-copy, not separately override-able, diverges from 107 link mechanism. | |

**User's choice:** Vendored `offline.css` (recommended).
**Notes:** Chosen for consistency with the Phase 107 link mechanism, the example-host idiom (tokens.css + app.css + classes), adopter override-ability, and giving Phase 109's grep gate a single stable target. Success criterion #2 explicitly permits either inline token styles or a host-owned CSS class — this lands on the host-owned-class shape.

---

## Deep research round (5 parallel subagents)

After the mechanism decision, the user requested deep multi-lens research. Five parallel subagents ran: (1) Phoenix/Elixir library asset-distribution + generator DX idioms; (2) design-token consumption + dark-mode CSS best practice; (3) offline-first UI/UX + accessibility + microcopy; (4) internal `prompts/`/brand-book/guides digest; (5) codebase ground-truth inventory. Findings drove the CONTEXT refinements (D-04..D-13) and surfaced a scope correction.

**Validated:** vendored `offline.css` is idiomatic (matches `mix phx.gen.auth` host-owned model + `guides/tokens.md`; avoids Tailwind lock-in; better than ash_admin inline-style / live_dashboard embedded CSS).

**Corrected (decided directly, brand-contract or low-stakes):**
- Two-tier rule is absolute — primitives FORBIDDEN in consumer CSS (earlier "primitive fallback" idea dropped).
- `--cw-text-muted` (stone-600, AA-pass) for normal secondary text, not `--cw-text-subtle` (stone-500, AA-fail).
- Status-color button backgrounds flip in dark mode (success→wake-500, white text fails AA) → foreground `--cw-text-inverse`, render-verify both themes, outline fallback; cannot add action-tier status tokens (frozen).
- Add `color-scheme: light dark`, `:focus-visible` outline (not box-shadow), status-not-by-color-alone, `role="status"`, semantic `<ul>/<li>`/`<h2>`.
- No `var()` fallbacks. Keep existing microcopy (matches BRAND-SPEC §15). Igniter deferred.

## Example-host normalization scope (post-research)

Research found the ROADMAP-named `examples/phoenix_host/assets/css/app.css` is NOT served (no build pipeline; DeckLive renders `priv/static/css/app.css`), plus a second inline-Tailwind-hex offline page in the example host.

| Option | Description | Selected |
|--------|-------------|----------|
| Real consumers + offline page | Normalize served `priv/static/css/app.css`; reconcile the unserved duplicate; normalize the example offline `index.html.heex`. Defer `step_up_challenge_live.ex` + `offline_study.js`. | ✓ |
| Literal roadmap scope only | Normalize only `assets/css/app.css` (the unserved file) + generator + test. | |
| Maximal: all host brand surfaces | Also rework `step_up_challenge_live.ex` (dead Tailwind) + `offline_study.js` (innerHTML hex). | |

**User's choice:** Real consumers + offline page (recommended).
**Notes:** Makes NORM-01 genuinely true (dark mode visible on the demo), gives Phase 109's gate meaningful targets, and keeps the broken-rendering LiveView/JS surfaces as a separate noted follow-up.

## Claude's Discretion

- Exact `.cw-offline-*` class names and internal structure of `offline.css`.
- Whether `offline.css` ships as a static vendored file vs. a trivial EEx template (keep it a single namespaced greppable file).
- Mapping of the two ambiguous example-host sync states (`.sync-status-pending` → `--cw-status-warning`, `.sync-status-complete` → `--cw-status-success`) — nearest-fit, planner may refine.
- Precise wording of the rewritten generator "Next steps" output.

**Decided directly from code analysis (not asked — low/medium-stakes per opinionated/minimal_decisive profile):** semantic-tier mapping policy (D-04), dark-mode via semantic tokens, deletion of app.css's `:root` flat-palette + font-stack block (D-06), retirement of the stale `tailwind.config.js`/esbuild instructions (D-07), token-comment → token-reference conversion (D-08), and the NORM-04 test rewrite (D-09).

## Deferred Ideas

- Drift-prevention CI gate (PROOF-01) → Phase 109.
- Byte-identical `tokens.css` parity assertion → Phase 109.
