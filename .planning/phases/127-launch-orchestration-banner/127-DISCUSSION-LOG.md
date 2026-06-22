# Phase 127: Launch Orchestration + Banner - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-22
**Phase:** 127-launch-orchestration-banner
**Areas discussed:** Banner anatomy + drift-guard, Backend boot orchestration, Sim/emulator launch depth, Failure & guidance posture

The maintainer selected **all four** gray areas and requested a single coherent,
research-backed recommendation set ("one-shot a perfect set of recommendations so I
don't have to think") rather than sequential questions. Four parallel research
subagents (Sonnet) investigated pros/cons/tradeoffs, Elixir/Phoenix/shell idiom,
DX/JTBD/brand voice, and cross-ecosystem lessons; results were synthesized into
D-01..D-21 in CONTEXT.md. Decisions below record the option chosen per sub-area.

---

## Banner anatomy + drift-guard

| Option | Description | Selected |
|--------|-------------|----------|
| Banner in Mix task (Elixir, easily testable), drift-guard now | Single Elixir source; needs `mix` to print | |
| Banner in shell heredoc, defer all tests to Phase 128 | Docker-only-friendly but unguarded until P128 | |
| **Banner in shell script, drift-guard NOW (read script as text)** | Docker-only-friendly AND guarded — existing drift test already asserts on a non-Elixir file | ✓ |
| Payoff-first ordering, caveat before native commands, minimal 3-route set | URL→routes→proven/needs-build→commands→footer; `/`,`/offline`,`/bridge-proof` only | ✓ |

**User's choice:** Shell script is the single source; banner drift-guarded in Phase 127 (D-01/D-02/D-04/D-05/D-06/D-21).
**Notes:** Resolved the one cross-area conflict (banner-in-Mix vs banner-in-shell) in favor of shell — the Docker-only newcomer (no Elixir) is the primary audience, and `quick_start_adoption_drift_test.exs` proves a non-Elixir text file is fully drift-testable.

---

## Backend boot orchestration

| Option | Description | Selected |
|--------|-------------|----------|
| `docker compose up` foreground | Banner drowns under compile-log wall | |
| **`docker compose up -d` detached → curl-poll :4700 → then banner** | Banner appears only after backend serves | ✓ |
| Compose healthcheck / new `/healthz` route | Extra scope; not needed | |
| **Probe :4700 first to reuse already-running (covers native too)** | Honest "already serving — reusing it" fast path | ✓ |
| Shell canonical, `mix crosswake.demo` thin `System.cmd` wrapper | Works without Elixir; alias for Elixir users | ✓ |

**User's choice:** Detached boot + script-side curl readiness poll (120 s cap) + probe-first reuse + shell↔mix boundary with shell canonical (D-07/D-08/D-09/D-10).
**Notes:** Docker-absent/daemon-down = fatal exit 1 with calm guidance to the native path; no silent path-switching (D-11).

---

## Sim/emulator launch depth

| Option | Description | Selected |
|--------|-------------|----------|
| Print commands only | That's LAUNCH-01, not LAUNCH-02 | |
| Full build+install+run by default | 2–8 min, license-hang/failure-prone for first run | |
| **Tiered: boot device by default + print build cmds; `--build` for full** | Fast/safe default, full path opt-in | ✓ |
| Auto-when-detected + `--web-only`/`--ios`/`--android`, CI/non-TTY auto-suppress | No CI hang; banner always prints | ✓ |
| Reuse `verify_generated_*_shell.sh` detection/boot; don't auto-create AVD | iOS simctl boot; Android guidance if no emulator | ✓ |

**User's choice:** Tiered launch depth, auto-when-detected opt-in with CI safety, reuse existing repo detection patterns (D-12/D-13/D-14/D-15/D-16).
**Notes:** Native launch is sequenced after the banner and is always non-fatal/best-effort.

---

## Failure & guidance posture

| Option | Description | Selected |
|--------|-------------|----------|
| All-or-nothing exit on any failure | Hostile to web-only newcomer | |
| **Web=success / native=advisory; exit 0 unless backend fails; exit 1 only fatal** | Two codes only | ✓ |
| **4-line `[crosswake]` calm-guidance microcopy (what/why/fix/reassurance)** | Never a stack trace or silent skip | ✓ |
| **Web auto-open default ON, gated TTY && !CI && !NO_OPEN (`--no-open` opt-out)** | "See It Run" gratification, CI-safe | ✓ |
| Mirror `crosswake.doctor` tone inline (don't call it); trap INT/TERM clean | Scopes don't overlap; idempotent re-run | ✓ |

**User's choice:** Web-success/native-advisory taxonomy, two exit codes, calm 4-line guidance, default-on CI-safe auto-open, idempotent + clean interrupts (D-17/D-18/D-19/D-20).
**Notes:** Confirmed all repo `script/*.sh` use `set -euo pipefail` (full pipefail variant) — adopted (D-03). JDK-17 note sits adjacent to the Android remediation.

---

## Claude's Discretion

- Exact flag-parser shape / `--help` text; whether `--all` aliases "both platforms".
- Exact ANSI palette (must degrade to byte-identical plain text).
- Exact curl-loop cap/cadence; optional "first boot compiles deps (~1–2 min)" notice.
- iOS destination discovery vs named fallback; `--build` should not auto-boot an AVD.
- Whether `mix crosswake.demo` forwards `--web-only`/`--build`/`--no-open` (recommend yes).
- `bin/see-it-run.sh` location (repo root) + `chmod +x`.

## Deferred Ideas

- Phase 128: screenshots, screen recording, `guides/see_it_run.md`, README/QUICK_START
  routing, `see_it_run_test.exs` (guide-markdown scope; banner string guarded here).
- `--backend-url`/port override — deferred (port locked by Phase 125).
- Auto-creating/booting an Android AVD — out (guidance instead).
- Dockerizing the Android emulator — out of scope (REQUIREMENTS).
- Phoenix `/healthz` route or compose `healthcheck:` — not needed; script-side curl suffices.
