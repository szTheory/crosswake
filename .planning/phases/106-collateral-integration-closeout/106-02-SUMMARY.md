---
phase: 106-collateral-integration-closeout
plan: "02"
subsystem: brand-integration
tags: [readme, mix-exs, ci, collateral, brand]
dependency_graph:
  requires: ["106-01"]
  provides: [readme-header-wired, exdoc-logo, hex-exclude-patterns, brandbook-verify-ci, collateral-readme]
  affects: [README.md, mix.exs, .github/workflows/brandbook-verify.yml, brandbook/collateral/README.md]
tech_stack:
  added: []
  patterns: [picture-dark-mode-header, hex-exclude-patterns, advisory-ci-lane]
key_files:
  modified: [README.md, mix.exs]
  created: [.github/workflows/brandbook-verify.yml, brandbook/collateral/README.md]
decisions:
  - "Used absolute raw.githubusercontent.com URLs for <picture> header to support both GitHub and hexdocs renderers"
  - "exclude_patterns belt-and-suspenders alongside existing :files allowlist (not replacing it)"
  - "Advisory CI lane paths-filtered to brandbook/** only; not added to required status checks"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-12T21:59:49Z"
  tasks_completed: 2
  files_changed: 4
---

# Phase 106 Plan 02: Brand Integration & Advisory CI Summary

Wire v9.0 brand into repo surfaces and stand up advisory brandbook CI lane.

## Results

| Check | Result |
|-------|--------|
| README header wired | Yes — <picture> block with dark/light absolute raw.githubusercontent.com URLs |
| mix compile | Green |
| hex tarball brandbook paths | 0 |
| CI lane created | Yes — .github/workflows/brandbook-verify.yml |
| Final committed brandbook bytes | 677,056 (677KB / 1,048,576 limit) |

## What Was Done

**Task 1 (a211838):** Prepended `<picture>` header to README.md above the `# Crosswake` H1; existing content untouched. Added `logo: "brandbook/logo/crosswake-mark.svg"` to `docs()` and `exclude_patterns: ["brandbook"]` to `package()` in mix.exs.

**Task 2 (d29480b):** Created advisory `brandbook-verify.yml` CI lane (paths: brandbook/**, permissions: contents: read, SHA-pinned actions, three jobs: size budget using Linux `stat -c%s`, SVG structural validation, token round-trip). Created `brandbook/collateral/README.md` documenting assets and manual GitHub social-preview upload step.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- README.md: `<picture>` header present, both absolute raw URLs, dark media query
- mix.exs: `logo:` and `exclude_patterns` present
- mix compile: exit 0
- hex tarball brandbook count: 0
- brandbook-verify.yml: exists, advisory, paths-filtered, Linux stat form
- brandbook/collateral/README.md: exists, documents social preview
- Brandbook size: 677KB <= 1MB
