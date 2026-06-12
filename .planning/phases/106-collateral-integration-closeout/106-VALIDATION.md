---
phase: 106
slug: collateral-integration-closeout
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-12
---

# Phase 106 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing validators + Playwright export/verify + mix |
| **Quick run command** | `node brandbook/tools/check-production.mjs && node brandbook/tools/check-candidates.mjs` |
| **Full suite command** | quick + `node --test brandbook/tools/*.test.mjs` + `mix compile --warnings-as-errors 2>/dev/null || mix compile` + `mix hex.build` tarball check |
| **Estimated runtime** | ~60s (mix involved) |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | COLL-01 | — | N/A | script+visual | collateral/: readme-header.svg + readme-header-dark.svg + social-card.svg + social-card.png + favicon-32.png + apple-touch-icon.png all exist; PNG dims via `magick identify` (1200x630, 32x32, 180x180); social-card.png < 153600 bytes; screenshots READ | ❌ | ⬜ pending |
| TBD | TBD | TBD | COLL-02 | — | N/A | structural | README.md starts with <picture> block; both srcset/src use https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/ absolute URLs; prefers-color-scheme media on source | ❌ | ⬜ pending |
| TBD | TBD | TBD | COLL-03 | — | N/A | script | mix.exs docs() contains logo:; package() contains exclude_patterns; `mix hex.build` succeeds and `tar -tf` of the tarball contains NO brandbook/ paths; `mix docs` or at minimum `mix compile` passes | ❌ | ⬜ pending |
| TBD | TBD | TBD | COLL-04 | — | N/A | script | .github/workflows/brandbook-verify.yml exists, advisory (no required contexts), paths filter brandbook/**; runs size+SVG+token jobs; committed brandbook ≤ 1048576 bytes total | ❌ | ⬜ pending |

## Wave 0 Requirements
Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README header looks right on GitHub light+dark | COLL-02 | GitHub renders remotely post-push | After push: view repo in both themes |
| GitHub social preview upload | — | Settings UI only | Documented step in collateral README |

## Validation Sign-Off
- [ ] All tasks verified
- [ ] `nyquist_compliant: true` set

**Approval:** pending
