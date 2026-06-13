# Phase 108: Consumer Normalization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 108-Consumer Normalization
**Areas discussed:** Offline UI styling mechanism

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

## Claude's Discretion

- Exact `.cw-offline-*` class names and internal structure of `offline.css`.
- Whether `offline.css` ships as a static vendored file vs. a trivial EEx template (keep it a single namespaced greppable file).
- Mapping of the two ambiguous example-host sync states (`.sync-status-pending` → `--cw-status-warning`, `.sync-status-complete` → `--cw-status-success`) — nearest-fit, planner may refine.
- Precise wording of the rewritten generator "Next steps" output.

**Decided directly from code analysis (not asked — low/medium-stakes per opinionated/minimal_decisive profile):** semantic-tier mapping policy (D-04), dark-mode via semantic tokens, deletion of app.css's `:root` flat-palette + font-stack block (D-06), retirement of the stale `tailwind.config.js`/esbuild instructions (D-07), token-comment → token-reference conversion (D-08), and the NORM-04 test rewrite (D-09).

## Deferred Ideas

- Drift-prevention CI gate (PROOF-01) → Phase 109.
- Byte-identical `tokens.css` parity assertion → Phase 109.
