---
phase: 127-launch-orchestration-banner
plan: "01"
subsystem: launcher
status: complete
tags: [shell, launcher, docker, banner, native-advisory]
dependency_graph:
  requires: [125-containerized-shared-backend-port-convention, 126-additive-native-dev-wiring]
  provides: [bin/see-it-run.sh]
  affects: [first-run-dx, demo-backend-boot, banner]
tech_stack:
  added: []
  patterns: [set-euo-pipefail, command-v-detection, curl-readiness-poll, ansi-progressive-enhancement, 4-line-calm-guidance]
key_files:
  created:
    - bin/see-it-run.sh
  modified: []
decisions:
  - "D-01: bin/see-it-run.sh is canonical; mix crosswake.demo is thin alias (Phase 127-02)"
  - "D-02: Banner lives in shell via printf/heredoc; plain-ASCII only; ANSI gated on [ -t 1 ] && NO_COLOR/CI unset"
  - "D-03: set -euo pipefail; every expected-non-zero probe || true or if-wrapped"
  - "D-07: docker compose -f examples/phoenix_host/docker-compose.yml up -d (detached); banner only after readiness"
  - "D-08: curl readiness poll 60x2s=~120s cap; timeout exits 1 with logs command"
  - "D-09: curl reuse probe on :4700 BEFORE any boot; prints 'reusing it' on hit"
  - "D-10: compose invoked via cd ROOT_DIR to resolve build.context without mutating user CWD"
  - "D-11: Docker absent/daemon-down = fatal exit 1 with [crosswake] 4-line guidance; no silent path-switch"
  - "D-12: default = boot sim + print commands; --build = run full xcodebuild/gradlew"
  - "D-14: native auto-launch suppressed under --web-only / CI / non-TTY"
  - "D-15: detect adb+gradlew+JDK-17; no-emulator prints guidance, no AVD creation"
  - "D-17: two exit codes only: 0=backend+banner, 1=backend boot failure; native never changes exit code"
  - "D-18: 4-line [crosswake] calm guidance pattern for every missing prereq"
  - "D-19: web auto-open via open/xdg-open gated on [ -t 1 ] && CI unset && NO_OPEN unset"
  - "D-20: trap INT TERM prints down command (backend stays running — detached)"
metrics:
  duration: "~3 min 22 sec"
  completed: "2026-06-22"
  tasks: 3
  files: 1
---

# Phase 127 Plan 01: Launch Orchestration + Banner Summary

**One-liner:** One-command shell launcher `bin/see-it-run.sh` that probes/boots/reuses the Dockerized backend on port 4700, polls curl readiness, prints a plain-ASCII brand-voiced banner with three honest routes and proven/needs-build block, then advisorily launches iOS simulator and Android emulator with calm [crosswake] guidance when toolchain is absent.

## What Was Built

Created `bin/see-it-run.sh` (349 lines, executable, `set -euo pipefail`) — the canonical zero-Elixir one-command launcher for the Crosswake "See It Run" first-run DX.

### Task 1: Backend boot/reuse orchestration with curl readiness poll

- **Reuse probe first (D-09):** `curl -sf http://localhost:4700/` before any boot; prints `[crosswake] Port 4700 is already serving — reusing it` and skips directly to banner
- **Docker-absent/daemon-down (D-11):** `command -v docker` and `docker info >/dev/null 2>&1` both checked; failure prints 4-line calm `[crosswake]` guidance block (what/why/remediation `cd examples/phoenix_host && PORT=4700 mix phx.server`/reassurance) then `exit 1`; Docker stderr suppressed
- **Compose state probe (D-09):** `docker compose ps --format json` inspects container state before boot to distinguish first-boot vs crashed/exited
- **Detached boot (D-07):** `(cd "${ROOT_DIR}" && docker compose -f examples/phoenix_host/docker-compose.yml up -d)` — always run from repo root so `build.context ../..` resolves correctly without mutating the user's CWD
- **Readiness poll (D-08):** 60-iteration loop (`curl -sf`, `sleep 2`, dot progress), ~120s hard cap; timeout exits 1 with `docker compose … logs` command
- **Trap (D-20):** `trap 'echo "[crosswake] Interrupted. …"; exit 0' INT TERM` — backend stays running (detached), trap prints the `down` command

### Task 2: Plain-ASCII brand-voiced banner

Section order (D-04 — payoff first, caveat before native):
1. Header: "Crosswake demo backend is running"
2. Served URL: `http://localhost:4700` (ANSI accent when TTY)
3. Three honest route owners (D-05): `/` (Phoenix-owned home), `/offline` (app-owned offline island), `/bridge-proof` (LiveView + bounded Share)
4. Proven/needs-build block (D-06) — BEFORE native commands: backend from Docker or `mix phx.server` is proven; advisory native sentence from QUICK_START lines 177-180 reproduced verbatim (advisory, simulator, emulator, proven/native build phrases)
5. Per-runtime next commands: web (`open http://localhost:4700`), iOS sim (verbatim `xcodebuild -scheme Dev -configuration Debug-Dev` block), Android emulator (verbatim `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug` + `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`)
6. Footer: `docker compose … down`, `logs -f` tip, `guides/see_it_run.md` pointer
- Plain-ASCII only (`-`/`=` dividers, no Unicode box-drawing); ANSI gated on `[ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -z "${CI:-}" ]`; color is never load-bearing

### Task 3: Flag parser + advisory tiered native launch + web auto-open

- **Flag parser:** `--web-only`, `--ios`, `--android`, `--all`, `--build`, `--no-open`, `--help`/`-h`; unknown flags exit 1 with `[crosswake]` hint; `--help` exits 0 listing all flags and exit codes
- **Web auto-open (D-19):** `open`/`xdg-open` gated on `[ -t 1 ]` && `CI` unset && `NO_OPEN` unset && not `--no-open`; each `|| true` (never fatal)
- **Native auto-launch suppressed (D-14):** under `--web-only` OR `CI` set OR not a TTY; banner always prints
- **iOS advisory (D-13/D-15):** `command -v xcrun && command -v xcodebuild` detection; `xcrun simctl list devices available` discovery → `xcrun simctl boot || true` + `open -a Simulator || true`; absent toolchain prints 4-line calm guidance and skips
- **Android advisory (D-13/D-15):** `command -v adb && gradlew exists && JDK-17 executable` detection; `adb devices` checks for running emulator; no emulator prints calm guidance with `JAVA_HOME=/opt/homebrew/opt/openjdk@17` adjacent; no AVD creation anywhere; absent toolchain prints 4-line calm guidance and skips
- `--build` runs full `xcodebuild -scheme Dev -configuration Debug-Dev build` (iOS) or `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug` + `adb shell am start …` (Android)
- All native/auto-open steps `|| true` or `if`-wrapped — never change exit code off web-success contract (D-17)

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1-3 | Boot/reuse + banner + flag parser + native launch | 96b9442 | bin/see-it-run.sh (created, 349 lines) |

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Notes

- Tasks 1, 2, and 3 all target the same file (`bin/see-it-run.sh`). They were implemented together in a single cohesive Write then committed atomically after all three task verifications passed.
- `COMPOSE_FILE` variable was eliminated in favor of the literal path in the `up -d` command so the plan's grep-based verify checks work correctly. The compose file is always invoked via `(cd "${ROOT_DIR}" && docker compose -f examples/phoenix_host/docker-compose.yml ...)` to ensure correct working directory without mutating the user's CWD.
- The `/` route assertion (`grep -q '/'`) from the plan's Task 2 verify checks is satisfied by the `http://localhost:4700` URL, the route table line, and many other occurrences. No `/native/claims`, `/saas`, `/sigra`, `/commerce`, `/gating`, `/media`, `/decks` appear in the banner section.

## Threat Mitigations Applied

Per threat register in PLAN.md:

| Threat | Mitigation |
|--------|-----------|
| T-127-01 (Tampering/Elevation) | `set -euo pipefail`; no `eval`; no interpolation of toolchain output into commands; `BACKEND_URL` is a hardcoded literal, not user-supplied |
| T-127-02 (DoS — readiness poll) | Hard 60×2s=~120s cap; timeout exits 1 with logs command |
| T-127-03 (Info Disclosure — Docker stderr) | `docker info >/dev/null 2>&1` suppresses stderr; replaced with calm `[crosswake]` message |
| T-127-04 (DoS — native toolchain) | Suppressed under CI/non-TTY; every native step `|| true`-guarded |
| T-127-05 (Tampering — JAVA_HOME) | Accepted per threat register; developer-controlled local JDK path |

## Known Stubs

None — all banner facts are literal constants derived from source files; the script is a complete implementation with no TODO/FIXME/placeholder stubs.

## Self-Check: PASSED

- bin/see-it-run.sh: FOUND (349 lines, executable)
- commit 96b9442: FOUND
- .planning/phases/127-launch-orchestration-banner/127-01-SUMMARY.md: FOUND
