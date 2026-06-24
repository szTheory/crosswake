# Phase 127: Launch Orchestration + Banner - Pattern Map

**Mapped:** 2026-06-22
**Files analyzed:** 3 new files
**Analogs found:** 3 / 3 (every new file has a strong in-repo analog)

All three new files copy existing repo patterns directly. No file falls back to RESEARCH.md-only patterns. The banner *content* is novel (no banner-printing analog exists), but its emission idiom (`printf`/heredoc under `set -euo pipefail`) and its drift-guard are both copied from existing code.

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `bin/see-it-run.sh` | utility (POSIX shell launcher/orchestrator) | request-response (probe → boot → poll → banner → advisory launch) | `script/verify_generated_ios_shell.sh` + `script/verify_generated_android_shell.sh` | role-match (toolchain-detect + sim/emulator launch); novel banner/boot-poll content |
| `lib/mix/tasks/crosswake.demo.ex` | mix task (thin alias) | request-response (System.cmd passthrough) | `lib/mix/tasks/crosswake.contract.gen.ex` + `lib/mix/tasks/crosswake.doctor.ex` | exact (Mix.Task scaffold); demo's body is a `System.cmd` shim, simpler than both |
| `test/crosswake/guides/see_it_run_banner_test.exs` | test (source-derived drift guard) | transform (read text file → regex-derive facts → assert + synthetic anti-vacuity) | `test/crosswake/guides/quick_start_adoption_drift_test.exs` | exact (same non-Elixir-text-file drift idiom; same PORT regex) |

## Pattern Assignments

---

### `bin/see-it-run.sh` (utility, request-response orchestrator)

**Primary analogs:** `script/verify_generated_ios_shell.sh`, `script/verify_generated_android_shell.sh`
**Note:** `bin/` does not exist yet — the plan must `mkdir -p bin` and `chmod +x bin/see-it-run.sh` (mirrors the executable bit on every `script/*.sh`). All `script/*.sh` are bash; this file is bash (`#!/usr/bin/env bash`) so the `BASH_SOURCE`/`[[ ]]`/array idioms below are available.

**Header + house shell convention (D-03)** — `script/verify_generated_ios_shell.sh:1-4`:
```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```
Repo-wide convention: every `script/*.sh` uses `set -euo pipefail` (confirmed via grep across `script/`). Compute `ROOT_DIR` from `BASH_SOURCE` so the script works from any CWD — required for D-10 (always invoke compose via `-f examples/phoenix_host/docker-compose.yml` from repo root without `cd`-ing the user).

**Toolchain detection — minimal `command -v`, no slow invocations (D-13)** — `script/verify_generated_ios_shell.sh:14-17` and `:52`:
```bash
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is required for iOS shell verification" >&2
  exit 1
fi
# ... later, guarded use:
if command -v xcrun >/dev/null 2>&1; then
```
Copy this `command -v <tool> >/dev/null 2>&1` shape for the iOS (`xcrun`, `xcodebuild`) and Android (`adb`) probes. NOTE for D-11/D-18: the analog *exits 1* when the tool is absent because the verifier *requires* it. In see-it-run, missing **native** tooling is advisory (calm guidance, never fatal — wrap in `if`, do not exit); only missing **Docker** (`command -v docker` / `docker info`) is fatal exit 1.

**iOS simulator boot + open Simulator.app (D-15)** — `script/verify_generated_ios_shell.sh:127-131`:
```bash
if [[ "$LAUNCH_SIMULATOR" == "1" ]] && command -v xcrun >/dev/null 2>&1; then
  xcrun simctl boot "$destination_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$destination_id" -b
  open -a Simulator --args -CurrentDeviceUDID "$destination_id" >/dev/null 2>&1 || true
fi
```
The `|| true` on `simctl boot` and `open -a Simulator` is the idempotent idiom — booting an already-booted device must not abort the script under `set -e`. Reuse the `simctl boot` + `open -a Simulator` pair for D-15; for first-booted-iPhone discovery copy the `xcodebuild -showdestinations` + `awk name:/id:/OS:` extraction at `:79-113` (or the simpler `simctl list` path the plan chooses — D-15 leaves exact discovery to discretion).

**Android JDK-17 fallback + `adb` (D-13/D-15/D-18)** — `script/verify_generated_android_shell.sh:41-47` and `:38`:
```bash
homebrew_java_home() {
  local prefix="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

  if jdk_works "${prefix}"; then
    printf '%s\n' "${prefix}"
  fi
}
# jdk_works:
[[ -x "${java_home}/bin/java" ]] && "${java_home}/bin/java" -version >/dev/null 2>&1
```
Copy the `/opt/homebrew/opt/openjdk@17/...` path literal and the `[[ -x .../bin/java ]]` executable check for the D-13 Android JDK probe. Per D-18 the JDK-17 remediation note (`JAVA_HOME=/opt/homebrew/opt/openjdk@17`) sits *adjacent* to the Android guidance. Do NOT copy this analog's `install_jdk_if_needed` / `install_android_tools_if_needed` / `sdkmanager --licenses` provisioning (lines 49-139) or `create_avd_if_needed` (141-154) — D-15 explicitly forbids auto-creating/booting an AVD; see-it-run only *detects* and prints guidance.

**`|| true` idempotent-probe idiom (D-03)** — pervasive in both analogs (`script/verify_generated_android_shell.sh:149,181,200-202`; ios `:65,128,130,172,182`):
```bash
adb kill-server >/dev/null 2>&1 || true
avdmanager delete avd -n "${AVD_NAME}" >/dev/null 2>&1 || true
```
Every expected-non-zero probe (`curl`, `docker compose ps`, `grep -q`, `simctl boot`, `open`/`xdg-open`, `adb devices`) must be `|| true` or wrapped in `if` so `set -e` never aborts on an expected non-zero. This is the load-bearing convention for D-08 (curl readiness loop), D-09 (reuse probe), D-19 (auto-open), D-16 (best-effort native).

**Cleanup/interrupt trap (D-20)** — `script/verify_generated_ios_shell.sh:19-23`, android `:216`:
```bash
cleanup() { ... }
trap cleanup EXIT
```
D-20 wants `trap 'echo "[crosswake] Interrupted."; exit 0' INT TERM` (NOT the analog's EXIT-cleanup — compose is detached so Ctrl-C must *leave the backend running* and print the `down` command). Same `trap` mechanism, different signals/handler.

**Boot surface to invoke (D-07/D-08/D-09/D-10) — DO NOT MUTATE these files:**
- `examples/phoenix_host/docker-compose.yml:13-14` — ports `"4700:4700"`; line `6-8` `build.context ../..`. Invoke detached: `docker compose -f examples/phoenix_host/docker-compose.yml up -d`. `down`/`logs -f` footer tips use the same `-f` path.
- `examples/phoenix_host/entrypoint.sh:8-16` — the slow first-boot work (`mix deps.get`/`deps.compile`/`compile`/`ecto.create`/`ecto.migrate`/`run priv/repo/seeds.exs`/`exec mix phx.server`) — this is *why* D-07 waits before printing the banner and D-08 caps the poll at ~120 s.
- Readiness probe (D-08): `curl -sf http://localhost:4700/ >/dev/null` in a loop with `sleep 2` and a hard cap; on timeout exit 1 printing the `docker compose -f … logs` command. No new `/healthz` route, no compose `healthcheck:`.

**Banner content sources (D-04/D-05/D-06)** — novel `printf`/heredoc, but every fact is source-derived:
- Port `4700` from `examples/phoenix_host/config/runtime.exs:12` (`String.to_integer(System.get_env("PORT") || "4700")`). The banner string is guarded by the drift test below.
- Route set (D-05) from `examples/phoenix_host/lib/crosswake_example/router.ex` — surface exactly `/` (`:120`, home/Phoenix-owned), `/offline` (`:122`, app-owned offline island), `/bridge-proof` (`:131`, LiveView + bounded Share). Do NOT surface `/native/claims` (auth-gated via `live_session :selective_native` `on_mount require_authenticated_member` at `:266-267` → newcomer gets a redirect) or the `/saas`,`/sigra`,`/commerce`,`/gating`,`/media`,`/decks` example-app guts.
- Native next-commands reproduced verbatim from `examples/QUICK_START.md:191-208` (iOS `-scheme Dev -configuration Debug-Dev`; Android `JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug` + `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`).
- "advisory native" sentence (D-06) reuse from `examples/QUICK_START.md:177-180`: *"a successful simulator or emulator run confirms the dev wiring reaches the local backend, but does not prove physical-device support."*

---

### `lib/mix/tasks/crosswake.demo.ex` (mix task, thin System.cmd alias)

**Analog:** `lib/mix/tasks/crosswake.contract.gen.ex` (scaffold) + `lib/mix/tasks/crosswake.doctor.ex` (OptionParser/passthrough tone)

**Mix.Task scaffold (D-01)** — `lib/mix/tasks/crosswake.contract.gen.ex:1-6,57-59`:
```elixir
defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task

  @shortdoc "Regenerates all derived non-Elixir contract surfaces from the canonical bridge version"

  @moduledoc """
  ...
  """

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} = OptionParser.parse(args, strict: [dev: :boolean])
```
Copy: `use Mix.Task`, `@shortdoc`, `@moduledoc`, `@impl Mix.Task def run(args)`. For `Mix.Tasks.Crosswake.Demo`, the `@moduledoc` MUST carry the `# logic lives in bin/see-it-run.sh` note (D-01) and the body adds NO banner/boot logic.

**Calm guidance tone (D-18)** — `lib/mix/tasks/crosswake.doctor.ex:8-13`:
```elixir
@shortdoc "Diagnose Crosswake install, policy, manifest, and support truth"

@moduledoc """
Runs host-truth-first diagnostics over installer state, route-policy compilation,
manifest validity, and support-matrix consistency.
"""
```
Mirror doctor's calm, declarative `@shortdoc`/`@moduledoc` voice. D-18 is explicit: mirror the *tone* but DO NOT call or extend `Crosswake.Doctor` — scopes don't overlap (doctor checks library/route-policy health; see-it-run checks system toolchain, inline in shell).

**Body = System.cmd passthrough (D-01)** — no existing task shells out, so this is the one novel bit. The recommended shape (D-01 + discretion item "pure pass-through"):
```elixir
@impl Mix.Task
def run(args) do
  # logic lives in bin/see-it-run.sh — this task is a thin alias only
  script = Path.join(:code.priv_dir(:crosswake) ... or repo-root-derived path, "bin/see-it-run.sh")
  {_out, status} = System.cmd("bin/see-it-run.sh", args, into: IO.stream(:stdio, :line))
  if status != 0, do: exit({:shutdown, status})
end
```
Forward `args` verbatim (`--web-only`/`--build`/`--no-open` pass straight through — recommended in discretion). Stream output (the analog uses `Mix.shell().info` for its own output, but demo must *stream* the shell's live output — use `into: IO.stream/2`). Note `Mix.Tasks` `run/1` receives raw argv; unlike contract.gen there is no need to `OptionParser.parse` — pass `args` through untouched so the shell owns flag parsing.

---

### `test/crosswake/guides/see_it_run_banner_test.exs` (test, source-derived drift guard)

**Analog:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` — reads a non-Elixir text file and drift-tests it. This is the template; copy it nearly verbatim, retargeting the read from `examples/QUICK_START.md` to `bin/see-it-run.sh`.

**Module + read-the-file-as-text (D-21)** — `quick_start_adoption_drift_test.exs:1-7,37-38`:
```elixir
defmodule Crosswake.Guides.QuickStartAdoptionDriftTest do
  use ExUnit.Case, async: true

  @phoenix_config_path "examples/phoenix_host/config/runtime.exs"
  # ...
  scan_quick_start({@quick_start_path, File.read!(@quick_start_path)})
```
New module: `Crosswake.Guides.SeeItRunBannerTest`. Add `@banner_script_path "bin/see-it-run.sh"` and read it with `File.read!/1` — the proof that banner-in-shell is drift-testable with ZERO Elixir runtime dependency (D-21).

**PORT derived from source (the exact regex D-21 names)** — `quick_start_adoption_drift_test.exs:134-138,430-435`:
```elixir
defp phoenix_host_port do
  @phoenix_config_path
  |> File.read!()
  |> source_port!(~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/, @phoenix_config_path)
end

defp source_port!(contents, regex, path) do
  case Regex.run(regex, contents) do
    [_match, port] -> port
    _ -> raise "could not derive port from #{path}"
  end
end
```
Copy `phoenix_host_port/0` and `source_port!/3` verbatim. Assert `http://localhost:#{port}` and the dot-port appear in the banner string — NEVER hardcode `4700`.

**`require_contains` assertion helper** — `quick_start_adoption_drift_test.exs:588-594` + usage `:197-211`:
```elixir
defp require_contains(path, contents, needle, category, detail) do
  if String.contains?(contents, needle) do
    []
  else
    [failure(path, category, detail: detail)]
  end
end
# usage:
require_contains(path, contents, "/offline", :missing_route, "document the offline route"),
require_contains(path, contents, "/bridge-proof", :missing_route, "document the bounded bridge proof route"),
```
Copy `require_contains/5`, `require_regex/5` (`:596-602`), `failure/3` (`:388-396`), `format_failures/1`, `assert_no_drift_failures/1` (`:418-421`), `assert_failure_category/2` (`:423-426`). D-21 required-presence assertions on the banner string:
- the three route paths: `/`, `/offline`, `/bridge-proof`
- iOS command literals: `-scheme Dev`, `Debug-Dev` (and/or the full `xcodebuild` line)
- Android command literals: `installDevDebug`, `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`, `JAVA_HOME=/opt/homebrew/opt/openjdk@17`
- posture words: `advisory`, `simulator`, `emulator`, and a "proven"/"native build" phrase
- derived `http://localhost:#{port}`

**Synthetic anti-vacuity regression idiom (D-21)** — `quick_start_adoption_drift_test.exs:44-80` (the `String.replace` + `assert_failure_category` shape), reinforced by `native_evidence_drift_test.exs:51-77`:
```elixir
# quick_start_adoption_drift_test.exs:51-61 — wrong-port synthetic:
assert_failure_category(
  scan_quick_start(
    {"synthetic/quick_start_wrong_port.md", String.replace(quick_start, port, "4000")}
  ),
  :wrong_port
)
```
```elixir
# native_evidence_drift_test.exs:54-64 — replace-a-known-good-token-and-assert-it-fails:
stale_gav_failures =
  scan_surface(
    "...path...",
    String.replace(current_build_gradle, "<good token>", "<stale token>")
  )
assert Enum.any?(stale_gav_failures, &(&1.category == :stale_android_coordinate))
```
Build a `scan_banner({path, contents})` mirroring `scan_quick_start/1`, then add synthetic cases that MUST fail: (a) read `bin/see-it-run.sh`, `String.replace(banner, port, "4000")` → expect `:wrong_port`; (b) `String.replace(banner, "/bridge-proof", "/nope")` → expect a missing-route failure. This proves the assertions aren't vacuous.

**Scope boundary (D-21):** This test guards the **banner string only**. Phase 128's `see_it_run_test.exs` scopes to the **guide markdown** — no banner-string duplication across the two files.

---

## Shared Patterns

### `set -euo pipefail` + guarded probes + `[crosswake]` prefix (D-03)
**Source:** every `script/*.sh` (e.g. `script/verify_generated_ios_shell.sh:2`); prefix at `brandbook/BRAND-SPEC.md:154` (`- CLI/log prefix: \`[crosswake]\``).
**Apply to:** `bin/see-it-run.sh` — strict mode at the top, every expected-non-zero probe `|| true`-guarded or `if`-wrapped, all human-facing log/guidance lines prefixed `[crosswake]`.

### `|| true` idempotent best-effort (D-08/D-09/D-16/D-19/D-20)
**Source:** `script/verify_generated_android_shell.sh:149,181,200-202`; `script/verify_generated_ios_shell.sh:128,130,172,182`.
**Apply to:** every advisory step in `bin/see-it-run.sh` (readiness curl, reuse probe, `docker compose ps`, `simctl boot`, `open`/`xdg-open` auto-open, `adb devices`) so native/optional failures never flip the exit code off the web-success contract (D-17: exit 0 = backend up + banner; exit 1 = backend boot failed only).

### Source-derived facts, never hardcoded (D-21)
**Source:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` (PORT via regex against `runtime.exs`); route truth from `router.ex`.
**Apply to:** both the banner (which reproduces the facts) and `see_it_run_banner_test.exs` (which guards them). The PORT regex `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` against `examples/phoenix_host/config/runtime.exs:12` is the single canonical PORT source.

### Mix.Task scaffold + calm declarative voice (D-01/D-18)
**Source:** `lib/mix/tasks/crosswake.contract.gen.ex:1-6,57-59` (scaffold); `lib/mix/tasks/crosswake.doctor.ex:8-13` (tone).
**Apply to:** `crosswake.demo.ex` — `use Mix.Task` + `@shortdoc` + `@moduledoc` + `@impl Mix.Task def run/1`, calm voice, thin `System.cmd` body, `# logic lives in bin/see-it-run.sh`.

## No Analog Found

No new file lacks an analog. Two *sub-behaviors* are novel (and the planner should source them from CONTEXT.md decisions + RESEARCH.md, not from a copied file):

| Behavior | Owning File | Why no analog | Source instead |
|----------|-------------|---------------|----------------|
| Banner emission (`printf`/heredoc, payoff-first layout) | `bin/see-it-run.sh` | No banner-printing script exists in repo | D-02/D-04 layout; Vite/Supabase cross-ecosystem lessons in CONTEXT `<specifics>` |
| `docker compose up -d` detached + curl readiness-poll loop | `bin/see-it-run.sh` | No script orchestrates a detached compose boot + poll today | D-07/D-08/D-09; boot surface files (compose/entrypoint/runtime.exs) are the *invocation targets*, not pattern donors |
| `System.cmd` shell-out from a Mix task | `crosswake.demo.ex` | No existing Mix task shells out to a script | D-01 (pure pass-through, `into: IO.stream`) |

## Metadata

**Analog search scope:** `script/*.sh`, `lib/mix/tasks/crosswake.*.ex`, `test/crosswake/guides/*drift_test.exs`, `examples/phoenix_host/` (boot surface + router + runtime config), `examples/QUICK_START.md`, `brandbook/BRAND-SPEC.md`.
**Files scanned:** 11 read in full/targeted + grep confirmations (`bin/` absent, `set -euo pipefail` repo-wide, `[crosswake]` prefix, gradlew path).
**Pattern extraction date:** 2026-06-22
