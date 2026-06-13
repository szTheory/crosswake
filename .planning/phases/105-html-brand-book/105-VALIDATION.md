---
phase: 105
slug: html-brand-book
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 105 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing zero-dep validators + Playwright render-verify (mandatory) |
| **Quick run command** | `node brandbook/tools/check-production.mjs && xmllint --noout brandbook/index.html 2>/dev/null || node -e "require('fs').readFileSync('brandbook/index.html','utf8')"` |
| **Full suite command** | quick + `node --test brandbook/tools/*.test.mjs` + render-verify at 1200w AND 390w with screenshots READ |
| **Estimated runtime** | ~15s |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | BOOK-01 | — | N/A | script+visual | index.html + assets/brandbook.{css,js} exist; no framework imports (grep -L react/vue/jquery); Google Fonts link present; fonts fallback stacks present; opens via render-verify from file:// with zero console errors (Playwright page.on('console') check) | ❌ | ⬜ pending |
| TBD | TBD | TBD | BOOK-02 | — | N/A | structural+visual | grep section ids: hero, essence, logo-system, color, typography, tokens, motifs, voice, ui-specimens, asset-index (all 10); contrast badges computed by JS (grep contrast function in brandbook.js); misuse examples present; screenshots at 1200w + 390w READ by executor | ❌ | ⬜ pending |
| TBD | TBD | TBD | BOOK-03 | — | N/A | structural | brandbook/BRAND-SPEC.md exists; contains Stone 600 #756D63, ratified colorway table, state-mapping table, "v1.0"; prompts/crosswake-brand-book.md UNTOUCHED (git diff --exit-code prompts/) | ❌ | ⬜ pending |
| TBD | TBD | TBD | (D-09 size) | — | N/A | script | tournament/index.html replaced by ≤2KB README; committed brandbook total ≤ 800KB after this phase (leaves ≥200KB for 106) | ❌ | ⬜ pending |

## Wave 0 Requirements
Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Page reads as professional brand book | BOOK-01/02 | Editorial/visual judgment | Executor + orchestrator inspect full-page screenshots; check section rhythm, spacing, hero impact |

## Validation Sign-Off
- [ ] All tasks verified; latency < 15s
- [ ] `nyquist_compliant: true` set

**Approval:** pending
