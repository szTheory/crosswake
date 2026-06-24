---
phase: 128-collateral-see-it-run-guide
plan: "03"
subsystem: collateral-capture
tags: [collateral, capture-harness, honest-labels, shell-script, playwright]
dependency_graph:
  requires: []
  provides: [bin/capture-collateral.sh, brandbook/collateral/see-it-run/README.md]
  affects: [COLL-01, COLL-02, brandbook/collateral/see-it-run/]
tech_stack:
  added: []
  patterns: [set-euo-pipefail, progressive-ansi, repo-root-resolution, emulator-evidence-labeling]
key_files:
  created:
    - bin/capture-collateral.sh
    - brandbook/collateral/see-it-run/README.md
  modified: []
decisions:
  - Web screenshots automated via in-repo Playwright route_tour.spec.ts (route proven before screenshot taken)
  - Native capture commands PRINTED (not executed) — human-gated per D-03
  - Playwright artifacts (library.png, offline-study-replayed.png, bridge-proof.png) renamed to collateral filenames (web-home.png, web-offline.png, web-bridge-proof.png)
  - emulator evidence label used throughout for all native rows — never "device proof"
  - Script is idempotent — re-run overwrites web PNGs safely
metrics:
  duration: "3 minutes"
  completed: "2026-06-22T21:03:42Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
status: complete
---

# Phase 128 Plan 03: Collateral Capture Harness + Honest-Label Table Summary

Shipped the collateral capture harness `bin/capture-collateral.sh` and the seven-row honest-label asset table `brandbook/collateral/see-it-run/README.md` (COLL-01/COLL-02 scaffolding).

## What Was Built

### Task 1: bin/capture-collateral.sh (commit 47c5fb0)

Bash script (280 lines, `set -euo pipefail`, `chmod +x`) that:

- **Web capture (automated):** drives `examples/phoenix_host/e2e/route_tour.spec.ts` via `npx playwright test` against `localhost:4700`. Routes are proven before the screenshot is taken (route_tour ownerMessage discipline). Renames Playwright artifacts to collateral filenames (`library.png` → `web-home.png`, `offline-study-replayed.png` → `web-offline.png`, `bridge-proof.png` → `web-bridge-proof.png`).
- **`--web-only` flag:** skips printing native instructions — suitable for headless CI.
- **Native gate (printed, not executed):** prints exact copy-paste commands for the maintainer: `xcrun simctl io booted screenshot brandbook/collateral/see-it-run/ios-simulator.png`, `adb exec-out screencap -p > brandbook/collateral/see-it-run/android-emulator.png`, ImageMagick `convert +append` montage command, and gifsicle GIF optimization. All native output uses "emulator evidence" label — never implies physical-device support.
- Shell style, ANSI gating (`NO_COLOR`/`CI`/TTY check), and repo-root resolution match `bin/see-it-run.sh`.

### Task 2: brandbook/collateral/see-it-run/README.md (commit 24f0795)

116-line honest-label table mirroring `brandbook/collateral/README.md`, containing:

- Storage rationale: `brandbook/` is Hex-excluded; raw.githubusercontent.com reference pattern documented.
- Seven-row asset table with honest labels: web rows say "Web proof", native rows say "emulator evidence — advisory, not physical device".
- Capturing/Regenerating section: automated web flow via `bin/capture-collateral.sh`, human-gated native steps with exact xcrun/adb/montage/GIF commands.
- Note that the collateral-existence Elixir test is deferred until after the real binaries land (D-19).

## Verification Results

All acceptance criteria passed:

| Check | Result |
|-------|--------|
| `bash -n bin/capture-collateral.sh` exits 0 | PASS |
| `test -x bin/capture-collateral.sh` | PASS |
| `--web-only` flag present (5 occurrences) | PASS |
| `xcrun simctl io booted screenshot` literal present | PASS |
| `adb exec-out screencap -p` literal present | PASS |
| All seven filenames referenced in script | PASS |
| `emulator evidence` present in script (8 occurrences) | PASS |
| `set -euo pipefail` present | PASS |
| README seven-row table — all seven filenames | PASS |
| README `emulator evidence` count >= 3 (actual: 4) | PASS |
| README `raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run` | PASS |
| README `capture-collateral.sh` count >= 1 (actual: 4) | PASS |
| `bin/see-it-run.sh` / proof fixtures / native wiring unmodified | PASS |

## Deviations from Plan

None — plan executed exactly as written.

The Playwright route_tour.spec.ts captures `/library` (not `/`) as the home route and
uses filenames `library.png`, `offline-study-replayed.png`, `bridge-proof.png`. The
capture script renames these to the UI-SPEC collateral filenames (`web-home.png`,
`web-offline.png`, `web-bridge-proof.png`). This mapping was already implied by the
plan's action description and is not a deviation.

## Known Stubs

The three web PNG files (`web-home.png`, `web-offline.png`, `web-bridge-proof.png`) are
not committed — they are produced at runtime by `bin/capture-collateral.sh` when the
maintainer runs the capture workflow. The native binaries (`ios-simulator.png`,
`android-emulator.png`, `three-runtime-montage.png`, `see-it-run.gif`) are human-gated
per D-03/D-19. Per the plan: "This plan ships the harness + label scaffolding. The real
PNG/GIF binaries are human-captured per the user_setup manual gate."

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. The capture script
writes only to `brandbook/collateral/see-it-run/` and does not touch proof fixtures,
`bin/see-it-run.sh`, native wiring, or the Docker backend (T-128-06 mitigation
confirmed). Native shots are never auto-executed — all native content is PRINTED
(T-128-07/T-128-08 mitigations confirmed).

## Self-Check: PASSED

- bin/capture-collateral.sh: FOUND
- brandbook/collateral/see-it-run/README.md: FOUND
- 128-03-SUMMARY.md: FOUND
- Task 1 commit 47c5fb0: FOUND
- Task 2 commit 24f0795: FOUND
