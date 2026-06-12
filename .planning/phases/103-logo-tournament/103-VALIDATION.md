---
phase: 103
slug: logo-tournament
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-11
---

# Phase 103 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js structural checks (zero-dep) + `node --test` for tooling; visual checks via gallery |
| **Config file** | brandbook/tools/package.json (opentype.js 2.0.0 — Wave 0 installs) |
| **Quick run command** | `node brandbook/tools/check-candidates.mjs` (structural SVG validation: parses, no `<text>`, no full-bleed `<rect>`, viewBox present) |
| **Full suite command** | `node brandbook/tools/check-candidates.mjs && node --test brandbook/tools/*.test.mjs` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (once check script exists)
- **After every plan wave:** Run the full suite command
- **Before the LOGO-04 checkpoint:** Full suite green + manual gallery review at file://
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

> Planner fills final task IDs. Per-requirement checks:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | LOGO-01 | — | N/A | script | 7 SVG files exist in `brandbook/logo/tournament/candidates/` (A–G); each parses; each contains `<path`; `grep -L '<text' candidates/*.svg` returns all 7 | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LOGO-02 | — | N/A | structural+manual | index.html exists; contains per-candidate sections (grep candidate ids A–G); contains 16px + 24px + 256px render blocks, favicon mock, lineup grid; opens from file:// (manual) | ❌ | ⬜ pending |
| TBD | TBD | TBD | LOGO-03 | — | N/A | script | No candidate SVG contains a background `<rect>` covering the viewBox; no `<circle>`/`<rect>` wrapper shapes; lockup gap encoded ≈ one stroke width (review); no subtitle text paths in main lockups (manual) | ❌ | ⬜ pending |
| TBD | TBD | TBD | LOGO-04 | — | N/A | manual | Blocking user checkpoint: user picks direction; pick recorded in SUMMARY + STATE.md | ❌ | ⬜ pending |
| TBD | TBD | TBD | (D-06 rider) | — | N/A | manual+git | Wordmark paths for E/F/G + lockups show w/k cut edits: git history contains generated-base commit then surgical-edit commit; visual diff confirms cuts at 20° | ❌ | ⬜ pending |
| TBD | TBD | TBD | (D-07 tooling) | — | N/A | script | `node brandbook/tools/gen-wordmark.mjs` exits 0, emits per-glyph `<g>` with id="glyph-N-X" paths, uses `{flipY:false}` workaround and `variation.set({wght:600})` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `brandbook/tools/package.json` + `npm install opentype.js@2.0.0` (gitignored node_modules; lockfile committed)
- [ ] `brandbook/tools/fetch-fonts.sh` — google/fonts pinned commit `877f8918ee661764418e085766dc0b073260a3ef`, downloads `SpaceGrotesk[wght].ttf` to gitignored fonts/
- [ ] `gen-wordmark.mjs` runs and output inspected (real node counts at w apex / k arm) BEFORE cut-edit effort is estimated

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User picks logo direction | LOGO-04 | The point of the tournament | Open gallery, review 7 candidates across all contexts, pick direction or franken-combo at blocking checkpoint |
| Wordmark not typesettable in unmodified Space Grotesk | D-06 rider | Letterform judgment | Compare rendered wordmark vs raw gen-wordmark output; cuts must be visible at 100% zoom |
| 16px legibility per candidate | LOGO-02 | Optical judgment | View gallery 16px row + favicon mocks in browser |
| Optical centering / lockup x-height alignment | quality bar | Optical judgment | Review lockups at 256px; mark optical center within wordmark x-height band |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
