---
phase: 107-token-source-distribution
plan: "01"
subsystem: brandbook/tools
tags: [tokens, css-custom-properties, build-tool, tdd]
dependency_graph:
  requires: []
  provides: [priv/static/crosswake/tokens.css, font/dimension token emission]
  affects: [brandbook/tokens/tokens.css, priv/static/crosswake/tokens.css]
tech_stack:
  added: []
  patterns: [non-color token serialization, ROOT-anchored priv mirror write, mkdirSync recursive]
key_files:
  created:
    - priv/static/crosswake/tokens.css
  modified:
    - brandbook/tools/compile-tokens.js
    - brandbook/tools/compile-tokens.test.mjs
    - brandbook/tokens/tokens.css
decisions:
  - "Route fontFamily tokens through serializeNonColor (not props/resolveAlias) to avoid [object Array] in CSS output"
  - "NON_COLOR_GROUPS defined at module level so it is visible both in the constant scope and main()"
  - "priv mirror write placed immediately after brandbook write in main() — same out string ensures byte identity"
metrics:
  duration: "~2 minutes"
  completed: "2026-06-13"
  tasks_completed: 2
  files_changed: 4
requirements_satisfied: [TOKN-04, TOKN-05]
---

# Phase 107 Plan 01: Token Source Extension Summary

**One-liner:** Extended compile-tokens.js with fontFamily/dimension serialization helpers and a second writeFileSync to produce a byte-identical priv/static/crosswake/tokens.css package mirror from a single generator run.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Add failing tests for font/dimension emit + priv mirror parity | 6e3955c | brandbook/tools/compile-tokens.test.mjs |
| 1 (GREEN) | Add font/dimension serialization helpers and non-color :root block | 3a45b85 | brandbook/tools/compile-tokens.js, brandbook/tokens/tokens.css |
| 2 | Emit packaged priv/static/crosswake/tokens.css mirror | 07bafb4 | priv/static/crosswake/tokens.css |

## What Was Built

- `serializeNonColor(token)`: branches on `$type`. For `fontFamily`, maps each family name through a space-check and joins with `', '`; quotes multi-word names. For `dimension`, returns the raw `$value` string verbatim.
- `propsNonColor(flat, paths)`: mirrors the existing `props()` format (`--cw-` prefix, dot-to-dash, two-space indent, trailing `;`) but uses `serializeNonColor` instead of `resolveAlias`.
- `NON_COLOR_GROUPS` constant: `['font', 'text-scale', 'display-scale', 'line-height', 'spacing', 'radius', 'focus', 'tracking']`.
- Non-color `:root` block appended to `out` after the Forbidden-pairings comment, labeled `/* ─── Fonts & dimensions ─── */`. Contains all 27 non-color properties (3 fontFamily + 24 dimension), alphabetically sorted (inherited from `all.sort()`).
- `PRIV_CSS_PATH = path.join(ROOT, 'priv/static/crosswake/tokens.css')` — ROOT-anchored, not relative.
- Second write in `main()`: `fs.mkdirSync(path.dirname(PRIV_CSS_PATH), { recursive: true })` then `fs.writeFileSync(PRIV_CSS_PATH, out, 'utf8')` with the same `out` string — byte-identical by construction.
- 8 new Node tests covering font-display/body/mono quoting, three dimension values, priv existence, and byte-identical parity. All 25 tests green.

## TDD Gate Compliance

- RED commit `6e3955c`: 8 new tests fail (no implementation), 17 existing pass.
- GREEN commit `3a45b85`: all 25 tests pass.

## Verification

```
node brandbook/tools/compile-tokens.js   # exits 0, writes both files
node --test brandbook/tools/compile-tokens.test.mjs   # 25/25 pass
diff brandbook/tokens/tokens.css priv/static/crosswake/tokens.css   # exits 0
grep --cw-font-display brandbook/tokens/tokens.css   # "Space Grotesk" quoted
grep --cw-text-scale-md brandbook/tokens/tokens.css  # 16px
grep --cw-radius-lg brandbook/tokens/tokens.css       # 14px
grep object.Array brandbook/tokens/tokens.css         # no matches
```

## Success Criteria Met

- [x] TOKN-04: `tokens.css` contains `--cw-font-display`, `--cw-font-body`, `--cw-font-mono` as valid quoted font stacks
- [x] TOKN-05: `tokens.css` contains all 24 dimension tokens (`--cw-text-scale-*`, `--cw-display-scale-*`, `--cw-radius-*`, `--cw-line-height-*`, `--cw-spacing-base`, `--cw-focus-ring-width`, `--cw-tracking-tight`) as raw value strings
- [x] The packaged mirror `priv/static/crosswake/tokens.css` exists, is byte-identical to the brand book copy, and is committed for the Hex package

## Deviations from Plan

None — plan executed exactly as written. All three insertion points from PATTERNS.md were applied precisely. The TDD RED/GREEN sequence followed the prescribed order.

## Known Stubs

None — all 27 non-color token values are real data from `crosswake.tokens.json`, serialized by the generator. No placeholders.

## Threat Flags

No new threat surface introduced. Both `/* GENERATED from crosswake.tokens.json — do not edit */` headers are present on both output files (asserted by test 11 on `brandbook/tokens/tokens.css`; the priv mirror is byte-identical so the header is guaranteed). `PRIV_CSS_PATH` uses `path.join(ROOT, ...)` with a fixed subpath — no external input, no traversal.

## Self-Check: PASSED

- `brandbook/tools/compile-tokens.js` — FOUND (modified)
- `brandbook/tools/compile-tokens.test.mjs` — FOUND (modified)
- `brandbook/tokens/tokens.css` — FOUND (regenerated with font/dim block)
- `priv/static/crosswake/tokens.css` — FOUND (new packaged mirror)
- Commit `6e3955c` — FOUND (test RED)
- Commit `3a45b85` — FOUND (implementation GREEN)
- Commit `07bafb4` — FOUND (priv mirror)
