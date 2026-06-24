---
phase: 127-launch-orchestration-banner
verified: 2026-06-22T18:30:00Z
status: passed
score: 10/10
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 127: Launch Orchestration + Banner — Verification Report

**Phase Goal:** A newcomer can run one command that boots the shared backend, reads a human-voiced banner telling them exactly what is running and what to do next, and optionally watches their sim/emulator launch automatically
**Verified:** 2026-06-22T18:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `bin/see-it-run.sh` with Docker present and port 4700 free boots the detached compose backend, waits for curl readiness, then prints the banner and exits 0 (D-07/D-08/D-17) | VERIFIED | Line 122: `(cd "${ROOT_DIR}" && docker compose -f examples/phoenix_host/docker-compose.yml up -d)`; readiness loop lines 128–144 (60×sleep 2); `print_banner` called line 211; `exit 0` line 349 |
| 2 | Running `bin/see-it-run.sh` when port 4700 already serves skips boot, prints 'reusing it', prints the banner, exits 0 (D-09) | VERIFIED | Line 91: `if curl -sf "${BACKEND_URL}/" ...`; line 92: `echo "[crosswake] Port 4700 is already serving — reusing it."` — reuse probe is first; banner still called; exit 0 at end |
| 3 | Running `bin/see-it-run.sh` with Docker absent or daemon down prints calm [crosswake] guidance pointing at the native path and exits 1 — never a raw Docker stack trace, never a silent native path-switch (D-11/D-17) | VERIFIED | Lines 95–101: `command -v docker` check with 4-line guidance + `exit 1`; lines 103–109: `docker info` check with 4-line guidance + `exit 1`; both include `cd examples/phoenix_host && PORT=4700 mix phx.server`; `docker info >/dev/null 2>&1` suppresses stderr |
| 4 | The banner surfaces exactly the routes /, /offline, /bridge-proof and never /native/claims or the example-app scopes (D-05) | VERIFIED | Lines 158–160: `"    /              Phoenix-owned home\n"`, `"    /offline       app-owned offline island\n"`, `"    /bridge-proof  LiveView + bounded Share\n"`; grep for `/native/claims`, `/saas`, `/sigra`, `/commerce`, `/gating`, `/media`, `/decks` in banner section returns clean |
| 5 | The banner reproduces the verbatim Phase-126 iOS and Android dev-wiring commands and the 'advisory native' sentence, with the proven/needs-build block placed before the native commands (D-04/D-06) | VERIFIED | Lines 163–174: proven block (`"What is proven now"`, `"Advisory native"`, `"it is not a proven native build"`); iOS commands lines 185–190: `-scheme Dev`, `Debug-Dev`; Android commands lines 195–196: `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug`, `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`; proven block (line 163) precedes native commands (line 187) |
| 6 | Native sim/emulator launch is best-effort: a missing or failing toolchain prints calm guidance and never changes the exit code off the web-success contract (D-12/D-16/D-17) | VERIFIED | Lines 281–288 (iOS absent): 4-line `[crosswake]` guidance, no exit; lines 334–340 (Android absent): 4-line guidance, no exit; all native steps `|| true`-guarded; exit 0 is the only terminal exit after banner |
| 7 | Native auto-launch is suppressed when CI is set or stdout is not a TTY; --web-only/--ios/--android/--build/--no-open/--help flags are honored (D-12/D-14/D-19) | VERIFIED | Line 230: `if [ "$WEB_ONLY" -eq 1 ] || [ -n "${CI:-}" ] || ! [ -t 1 ]; then return 0; fi`; all 7 flags parsed lines 30–36; `--help` confirmed exit 0 with behavioral spot-check; unknown flag confirmed exit 1 |
| 8 | `mix crosswake.demo` shells out to `bin/see-it-run.sh`, streams live output, forwards args verbatim, and propagates the script's exit status (D-01) | VERIFIED | `System.cmd(script_path, args, into: IO.stream(:stdio, :line))` line 39; no `OptionParser.parse`; `exit({:shutdown, status})` line 42; module body contains zero banner/boot/docker/curl logic |
| 9 | The banner drift test reads `bin/see-it-run.sh` as text, derives PORT from `runtime.exs` via the documented regex, and asserts the derived URL, three routes, verbatim native literals, and posture words (D-21) | VERIFIED | `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` line 189; no hardcoded `4700` anywhere in test; main test asserts all required literals; `mix test` passes 5/0 |
| 10 | The drift test's synthetic anti-vacuity cases FAIL when the port is corrupted or a route is removed — proving the assertions are not vacuous (D-21) | VERIFIED | Three anti-vacuity tests present: wrong-port (`localhost:4700` → `localhost:4000`, asserts `:wrong_port`); missing-route (`/bridge-proof` → `/nope`, asserts `:missing_route`); missing-posture (`advisory` → `optional`, asserts `:missing_native_label`); all pass in 5/0 test run |

**Score:** 10/10 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/see-it-run.sh` | Canonical one-command launcher: probe -> boot/reuse -> readiness poll -> banner -> advisory native launch; min 150 lines; `set -euo pipefail` | VERIFIED | 349 lines, executable, `set -euo pipefail` line 2, all orchestration present |
| `lib/mix/tasks/crosswake.demo.ex` | Thin `Mix.Task` alias; `use Mix.Task`; no banner/boot logic | VERIFIED | 45 lines; `use Mix.Task`; pure `System.cmd` passthrough; `# logic lives in bin/see-it-run.sh` in `@moduledoc` |
| `test/crosswake/guides/see_it_run_banner_test.exs` | Source-derived drift guard; module `Crosswake.Guides.SeeItRunBannerTest` | VERIFIED | 237 lines; correct module name; PORT regex-derived; 5 tests pass |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `bin/see-it-run.sh` | `examples/phoenix_host/docker-compose.yml` | `docker compose -f examples/phoenix_host/docker-compose.yml up -d` (detached boot, D-07/D-10) | VERIFIED | Line 122 — always run from `ROOT_DIR` so `build.context` resolves |
| `bin/see-it-run.sh` | `http://localhost:4700/` | `curl -sf` readiness poll gating the banner (D-08) | VERIFIED | Lines 91 (reuse probe) and 129 (readiness loop) |
| `lib/mix/tasks/crosswake.demo.ex` | `bin/see-it-run.sh` | `System.cmd` into canonical script, args forwarded verbatim (D-01) | VERIFIED | Lines 33–36 resolve script via `__DIR__`/`Path.expand`; line 39 invokes it |
| `test/crosswake/guides/see_it_run_banner_test.exs` | `examples/phoenix_host/config/runtime.exs` | PORT derived via `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` regex (D-21) | VERIFIED | Lines 185–192; port string used as `"http://localhost:#{port}"` in assertions |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase produces a shell script, a Mix task passthrough, and a test file. No component renders dynamic data from a database source.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `--help` exits 0 and lists flags + exit codes | `CI=1 bash bin/see-it-run.sh --help; echo "EXIT:$?"` | Full usage printed; EXIT:0 | PASS |
| Unknown flag exits 1 with `[crosswake]` hint | `CI=1 bash bin/see-it-run.sh --unknown-flag; echo "EXIT:$?"` | `[crosswake] Unknown flag` printed; EXIT:1 | PASS |
| Script parses clean (no syntax errors) | `bash -n bin/see-it-run.sh` | SYNTAX OK | PASS |
| Drift test passes 5/0 | `mix test test/crosswake/guides/see_it_run_banner_test.exs` | 5 tests, 0 failures (0.02s) | PASS |
| Compile clean | `mix compile --warnings-as-errors` | Clean — no warnings | PASS |

---

### Probe Execution

No phase-declared probes. Step skipped.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| LAUNCH-01 | 127-01-PLAN.md, 127-02-PLAN.md | Single entrypoint `bin/see-it-run.sh` + optional `mix crosswake.demo` alias; brand-voiced banner with URLs/routes/next-commands/proven-needs-build block | SATISFIED | `bin/see-it-run.sh` 349-line complete implementation; `mix crosswake.demo` thin alias; banner verified with all required elements |
| LAUNCH-02 | 127-01-PLAN.md | Advisory sim/emulator boot when toolchain present; calm 4-line guidance when absent; never opaque failure | SATISFIED | `maybe_launch_native()` function: iOS/Android toolchain detection, `|| true` guards, calm guidance blocks lines 281–340, no AVD creation, no exit-code change |

Both requirements mapped to Phase 127 in REQUIREMENTS.md traceability table; both marked complete.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/mix/tasks/crosswake.demo.ex` | 4, 8, 12–13 | `"banner"`, `"docker"`, `"curl"` appear in `@shortdoc`/`@moduledoc` strings | Info | These are documentation strings, not implementation logic. The `run/1` body contains only `System.cmd` and exit propagation — confirmed clean |

No TBD/FIXME/XXX/TODO/PLACEHOLDER markers found in any modified file. No unreferenced debt markers. No Unicode box-drawing characters. No `eval` usage. No AVD creation (`avdmanager`, `sdkmanager --licenses` absent). No `--backend-url` or port override accepted. No `healthcheck:` stanza or `/healthz` route added. Proof fixtures (`docker-compose.yml`, `entrypoint.sh`, `runtime.exs`) unmodified per commit stat — all three commits touch only their declared files.

---

### Human Verification Required

None. All automated checks pass with sufficient evidence. Native advisory launch (iOS sim boot, Android emulator detection) is best-effort and explicitly documented as advisory — the phase goal does not require these paths to succeed on the verifier's machine, only that failure is calm and non-fatal, which is verified by code inspection and the `|| true` / guard pattern throughout.

---

### Gaps Summary

No gaps. All 10 must-have truths verified, all 3 artifacts confirmed substantive and wired, all 4 key links confirmed, both LAUNCH-01 and LAUNCH-02 satisfied, all prohibitions upheld.

---

## Prohibition Audit

| Prohibition | Status | Evidence |
|-------------|--------|----------|
| MUST NOT add compose `healthcheck:` stanza or `/healthz` route | UPHELD | `docker-compose.yml` grep clean; no route file touched |
| MUST NOT auto-switch to native boot when Docker is absent | UPHELD | Lines 95–101, 103–109: Docker absent/down = `exit 1`, no path-switch |
| MUST NOT auto-create or auto-boot an Android AVD | UPHELD | No `avdmanager`, `sdkmanager`, `create avd`, or `emulator @` start call anywhere in script |
| MUST NOT accept `--backend-url` or port override | UPHELD | Flag parser handles only 7 declared flags; unknown flags exit 1; `BACKEND_URL` is a hardcoded literal |
| MUST NOT mutate `docker-compose.yml`, `entrypoint.sh`, `runtime.exs`, or proof fixtures | UPHELD | Commits touch only `bin/see-it-run.sh`, `lib/mix/tasks/crosswake.demo.ex`, `test/crosswake/guides/see_it_run_banner_test.exs` |
| MUST NOT use Unicode box-drawing in the banner | UPHELD | Python byte scan clean; only `=` and `-` dividers used |
| MUST NOT let color carry meaning; ANSI gated on `[ -t 1 ] && -z NO_COLOR && -z CI` | UPHELD | Lines 79–84: ANSI vars initialized to empty strings, set only inside the gate; color never carries meaning (plain-text is byte-identical) |
| Mix.Tasks.Crosswake.Demo MUST NOT contain banner/boot/printf orchestration logic | UPHELD | `run/1` body: only `__DIR__` path resolution, `System.cmd`, and exit propagation |
| Drift test MUST NOT hardcode 4700 | UPHELD | `grep '4700' test/crosswake/guides/see_it_run_banner_test.exs` returns empty |
| Drift test MUST NOT assert anything about `guides/see_it_run.md` | UPHELD | No reference to Phase 128 guide markdown found |

---

_Verified: 2026-06-22T18:30:00Z_
_Verifier: Claude (gsd-verifier)_
