---
phase: 104
slug: logo-refinement-production-suite
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 104 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing zero-dep Node checks + Playwright render-verify loop (mandatory per D-05) |
| **Config file** | none new |
| **Quick run command** | `node brandbook/tools/check-candidates.mjs && node brandbook/tools/check-production.mjs` (check-production added this phase, pointing at brandbook/logo/) |
| **Full suite command** | quick + `node --test brandbook/tools/*.test.mjs` + Playwright screenshot of refinement.html / suite QA page, INSPECTED by the executing agent |
| **Estimated runtime** | ~10 seconds (scripted) + render loop |

## Sampling Rate

- After every task commit: quick command
- Before any user presentation: render-verify loop (screenshot → inspect) — BLOCKING
- Before phase close: full suite green + visual inspection of all 8 production files at 100% and 16px

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | LOGO-05 | — | N/A | script+visual | refinement.html exists; contains 3 variant ids + 4 colorway swatches each; screenshot inspected; user sign-off recorded | ❌ | ⬜ pending |
| TBD | TBD | TBD | LOGO-06 | — | N/A | script+visual | 8 files in brandbook/logo/ (mark, mark-mono, lockup-horizontal, lockup-horizontal-dark, lockup-stacked, lockup-subtitle, typemark, favicon.svg); all parse; no `<text>`; favicon viewBox="0 0 16 16"; subtitle ONLY in lockup-subtitle; dark variants use #F7F1E6, light use #09141A literal fills; screenshots inspected | ❌ | ⬜ pending |
| TBD | TBD | TBD | LOGO-07 | — | N/A | script | `node brandbook/tools/gen-wordmark.mjs` exits 0 and regenerated base matches committed wordmark-base.svg (diff clean); regen workflow documented in header comments | ❌ | ⬜ pending |
| TBD | TBD | TBD | (D-12 size) | — | N/A | script | `git ls-files brandbook/ \| xargs stat -f%z \| awk '{s+=$1} END {exit s>1048576}'` passes | ❌ | ⬜ pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements (tools from 102/103; Playwright from examples/phoenix_host).

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| User signs off a micro-variant | LOGO-05 | Taste gate | Open brandbook/logo/refinement.html, compare V1/V2/V3 across 4 colorways, pick at blocking checkpoint |
| Favicon legible at 16px real size | LOGO-06 | Optical | Render favicon.svg at literal 16px in tab mock; inspect screenshot |
| Optical centering / lockup balance | quality | Optical | Inspect production lockup screenshots at 100% |

## Validation Sign-Off

- [ ] All tasks have automated verify or visual-loop equivalent
- [ ] No 3 consecutive tasks without verification
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
