# Phase 127: Launch Orchestration + Banner - Context

**Gathered:** 2026-06-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a single friendly entrypoint — `bin/see-it-run.sh` (with an optional
`mix crosswake.demo` alias) — that a newcomer runs from the repo root to:
1. **Boot or reuse** the Phase-125 Dockerized shared backend on port **4700**
   (or reuse an already-running server, native or container),
2. Print a **plain-ASCII, brand-voiced banner** listing the served URL, the key
   route owners, the exact next command per runtime (web / iOS sim / Android
   emulator), and an honest **"What's proven / What needs a native build"** block,
3. **Advisorily launch** the iOS simulator / Android emulator when the toolchain
   is present, and print **calm guidance** (never a stack trace or silent skip)
   when it is absent.

**Requirements:** LAUNCH-01, LAUNCH-02 (see REQUIREMENTS.md — locked).

**Core contract:** the **web path is the success contract** (backend up + banner
printed → exit 0); everything native is **best-effort advisory** and never fails
the run. Native runs are "advisory native" evidence only (sim/emulator ≠ device).

**NOT in this phase:** three-runtime screenshots, screen recording, the full
`guides/see_it_run.md` (gameplan-at-top, JTBD sections), README/QUICK_START
routing to that guide, and `test/crosswake/guides/see_it_run_test.exs` → all
**Phase 128**. Also out: Dockerizing the Android emulator (REQUIREMENTS "Out of
Scope"); a `--backend-url`/port override (port 4700 locked by Phase 125).

**Method:** all four gray areas (banner anatomy + drift-guard, backend boot
orchestration, sim/emulator launch depth, failure & guidance posture) were
researched by four parallel subagents covering Elixir/Phoenix/Mix idiom, POSIX
shell + DevOps/SRE practice, JTBD/UX/brand voice, and cross-ecosystem lessons
(Vite, Supabase CLI, Expo, React Native, Flutter, Capacitor, Rails `bin/setup`,
`gh`, cargo, `flutter doctor`, Stripe/Netlify/fly CLIs). Synthesized into the one
coherent, mutually-reinforcing set below. Confidence: high on all four. The one
cross-area conflict (banner-in-Mix-task vs banner-in-shell) was resolved in
favor of the shell script (see D-01/D-02/D-21).
</domain>

<decisions>
## Implementation Decisions

### Architecture & entrypoint boundary (resolves the one cross-area conflict)
- **D-01 (single source of truth = the shell script):** `bin/see-it-run.sh` is
  the **canonical entrypoint and runs with ZERO Elixir** — the Docker-only
  newcomer (no `mix`) is the primary audience. `mix crosswake.demo` is a **thin
  optional alias** (LAUNCH-01: "with an optional `mix crosswake.demo` alias")
  that `System.cmd`s into `bin/see-it-run.sh`, passing flags through and
  streaming output; it carries a `# logic lives in bin/see-it-run.sh` comment and
  adds no banner/boot logic. **Rejected** making the Mix task canonical: it can't
  run without Elixir, failing the Docker-only path.
- **D-02 (banner lives in the shell script):** The banner is emitted by the shell
  script (`printf`/heredoc), NOT by Elixir. **Plain-ASCII structure carries all
  meaning** (LAUNCH-01 "plain-ASCII"); dividers are `-`/`=` only (no Unicode
  box-drawing — Windows/locale-safe). Optional minimal ANSI (bold/dim, at most one
  accent) is **progressive enhancement** gated on
  `[ -t 1 ] && -z "${NO_COLOR:-}" && -z "${CI:-}"`; color never carries meaning.
- **D-03 (shell conventions):** `set -euo pipefail` — confirmed the repo's
  `script/*.sh` all use the full **pipefail** variant (corrects the earlier
  "`set -eu`" assumption). Every expected-non-zero probe (`command -v`, `curl`,
  `grep -q`, `docker compose ps`) is guarded with `|| true` or wrapped in `if`.
  Use the `[crosswake]` log/guidance prefix (BRAND-SPEC §4). `bin/see-it-run.sh`
  is `chmod +x` like the existing `script/*.sh`.

### Banner anatomy (LAUNCH-01)
- **D-04 (section order — payoff first, caveat before native):**
  (1) one-line header ("Crosswake demo backend is running"); (2) **served URL**
  (the payoff); (3) **key route owners**; (4) **"What's proven / What needs a
  native build"** block — placed **before** the native commands so the reader
  meets the caveat before attempting `xcodebuild`/`gradlew`; (5) **per-runtime
  next commands** (web / iOS sim / Android emulator), each reproduced **verbatim**
  so the reader needn't leave the terminal; (6) footer: the matching
  `docker compose … down` stop command, a `… logs -f` tip, and a pointer to
  `guides/see_it_run.md` (Phase 128). Keep the banner ≈ ≤30 visible lines.
- **D-05 (minimal honest route set):** Surface exactly **`/`, `/offline`,
  `/bridge-proof`** — the three QUICK_START "See The Route Owners" already
  drift-tested. **Do NOT** dump the other router scopes (`/saas`, `/sigra`,
  `/commerce`, `/gating`, `/media`, `/decks`, `/study` — example-app guts) and
  **do NOT** surface `/native/claims` (it is auth-gated → a newcomer hits a
  redirect, not the route). Label each by route-owner/runtime
  (Phoenix-owned / app-owned offline island / LiveView + bounded Share).
- **D-06 (proven-vs-needs-build content):** *Proven now (no extra toolchain):*
  backend boots from Docker or native `mix phx.server`; the 3 web routes are
  reachable in any browser; offline replay (Playwright) and bounded-bridge
  (`script/verify_bounded_bridge_proof.sh`) proofs are runnable. *Advisory native
  (needs Xcode / Android SDK):* a successful sim/emulator run confirms the dev
  wiring reaches the local backend **but does not prove physical-device support**
  — reuse the exact "advisory native" sentence from QUICK_START (Phase 126 D-16).

### Backend boot orchestration (LAUNCH-01 "boots OR uses already-running")
- **D-07 (detached boot, banner after ready):** `docker compose -f
  examples/phoenix_host/docker-compose.yml up -d` (**detached**) → wait for
  readiness → **then** print the banner. Never print a URL before it serves
  (first boot is ~60–90 s of `deps.get/deps.compile/compile/ecto/seed`). Show
  dot-progress while waiting ("Waiting for backend on http://localhost:4700 …").
  **Rejected** foreground `docker compose up`: the banner drowns under a wall of
  compile logs (the most-cited first-run footgun).
- **D-08 (readiness probe — script-side curl):** Loop `curl -sf
  http://localhost:4700/ >/dev/null` with a 2 s sleep and a **hard ~120 s cap**;
  on timeout exit 1 printing the `docker compose … logs` command. **No** compose
  `healthcheck:` stanza and **no** new `/healthz` route (out of scope; curl on `/`
  is sufficient and universally available). Handles both slow-first-boot and
  fast-restart.
- **D-09 (reuse detection — probe :4700 first):** Probe `curl -sf` on :4700
  **before** any boot. If something already serves it → skip boot, print
  "Port 4700 is already serving — reusing it", go straight to banner (this
  transparently covers a hand-started native `mix phx.server` too). If not
  serving, inspect `docker compose ps` to distinguish first-boot vs
  crashed/exited container and message accordingly before `up -d`.
- **D-10 (compose invocation hygiene):** Always invoke compose from repo root via
  `-f examples/phoenix_host/docker-compose.yml` (don't mutate the user's CWD;
  compose resolves `build.context ../..` and `env_file .env` relative to the
  compose-file dir, which is correct). The footer's `down`/`logs -f` tips use the
  same `-f` path so copy-paste works from the repo root.

### Docker-absent / native posture
- **D-11 (Docker absent = fatal + calm guidance, no silent path-switch):**
  `command -v docker` failing OR `docker info` failing (daemon down) = **FATAL
  exit 1** with calm guidance that points to the native path
  (`cd examples/phoenix_host && PORT=4700 mix phx.server`) and the Docker install
  URL. **Do NOT** auto-switch to a native boot (different semantics, no readiness
  gate — silent path-switching is surprising); the D-09 reuse probe still lets a
  hand-started native server be reused. Intercept Docker's opaque "Cannot connect
  to the Docker daemon" stderr and replace it with the `[crosswake]` message.

### Sim/emulator advisory launch (LAUNCH-02)
- **D-12 (launch depth — tiered):** **Default** (toolchain present): **boot the
  simulator/emulator device** (satisfies ROADMAP criterion 3 "advisorily launches
  the simulator/emulator") and **print** the Phase-126 Dev build/install commands.
  **`--build` flag** opts into the full slow path: iOS `xcodebuild -scheme Dev
  -configuration Debug-Dev … build`; Android `JAVA_HOME=/opt/homebrew/opt/openjdk@17
  ./gradlew installDevDebug` + `adb shell am start -n
  dev.crosswake.shell.dev/.MainActivity`. The default avoids the 2–8 min build and
  license-hang footguns (React Native's #1 first-run failure); `--build` is the
  maintainer/full-proof path. **Rejected** print-only (that's LAUNCH-01) and
  always-full-build-by-default (slow/failure-prone for a first run).
- **D-13 (toolchain detection — minimal `command -v`):** Mirror
  `script/verify_generated_ios_shell.sh` / `verify_generated_android_shell.sh`.
  iOS (macOS only): `xcrun` && `xcodebuild` present. Android: `adb` present &&
  `examples/android_shell_host/gradlew` exists &&
  `${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}/bin/java`
  executable. No slow tool invocations in the probe.
- **D-14 (opt-in model):** Auto-launch **when detected** by default; `--web-only`
  escape hatch; `--ios` / `--android` to force one platform. **Auto-suppress**
  native launch when `CI` is set OR not a TTY (`! [ -t 1 ]`) — prevents the
  RN/Gradle license-prompt CI hang. The banner always prints regardless of path.
- **D-15 (device selection):** iOS — reuse the `simctl list` / first-booted-iPhone
  discovery from `verify_generated_ios_shell.sh`; if none booted, `xcrun simctl
  boot <first-available>` + `open -a Simulator`. Android — check `adb devices` for
  a running emulator; if none, print calm guidance (how to start one in Android
  Studio / `emulator @<avd>`) and **skip** — do **NOT** auto-create or auto-boot an
  AVD (too slow/risky for first-run). `iPhone 16` in docs is a placeholder; prefer
  dynamic discovery with a named fallback.
- **D-16 (sequencing — non-blocking):** backend-confirmed → **banner** → native
  launches (best-effort, each wrapped so a failure never propagates). Native runs
  **after** the banner so the URL is always visible first even if Xcode/Gradle is
  slow or absent.

### Failure & guidance posture (LAUNCH-02 criterion 3)
- **D-17 (web = success / native = advisory; two exit codes only):** Exit **0** =
  backend serving + banner printed (native skipped/failed does NOT change it);
  exit **1** = backend could not boot (Docker absent/daemon down, port 4700 held
  by a **foreign** process, or `compose up` fails). No tiered exit codes.
- **D-18 (calm-guidance microcopy — 4-line `[crosswake]` pattern):** Per missing
  prereq: *what's wrong* → *why it matters* (one calm line) → *exact remediation
  command/URL* → *reassurance* (web path still works / this is optional). Never a
  raw stack trace or silent skip. The JDK-17 note
  (`JAVA_HOME=/opt/homebrew/opt/openjdk@17`) sits **adjacent** to the Android
  remediation. Mirror `mix crosswake.doctor`'s calm tone but implement checks
  **inline in shell** — scopes don't overlap (doctor checks library/route-policy
  health; see-it-run checks system toolchain). Do **NOT** call or extend doctor.
- **D-19 (web auto-open — default on, CI/TTY-safe):** Auto-open
  `http://localhost:4700/` when `[ -t 1 ]` && `CI` unset && `NO_OPEN` unset
  (`open` on macOS / `xdg-open` on Linux, both `|| true` — never fatal). `--no-open`
  flag + `NO_OPEN=1` opt-out. The URL is **always** printed in the banner
  regardless. ("See It Run" → instant gratification, but never hijacks CI.)
- **D-20 (idempotent + clean interrupts):** Re-running when already up is
  fast/calm/error-free (D-09). `trap 'echo "[crosswake] Interrupted."; exit 0'
  INT TERM`; because compose is detached, Ctrl-C leaves the backend running — the
  trap says so and prints the `down` command (no orphaned-foreground surprise).

### Single-source-of-truth drift guard (honesty culture — guard the banner NOW)
- **D-21 (banner drift test in Phase 127, reading the shell file as text):** Add
  `test/crosswake/guides/see_it_run_banner_test.exs`
  (`Crosswake.Guides.SeeItRunBannerTest`), mirroring
  `quick_start_adoption_drift_test.exs` — which already drift-tests a **non-Elixir
  text file** (QUICK_START.md) by reading it as a string. So banner-in-shell is
  **fully drift-testable without any Elixir runtime dependency**. Read
  `bin/see-it-run.sh` as text and assert: PORT **derived from**
  `examples/phoenix_host/config/runtime.exs` via the existing
  `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` regex appears in the banner; the
  three route paths appear; the iOS/Android/`adb` command literals appear; the
  posture words (`advisory`, `simulator`, `emulator`, and a "proven"/"native
  build" phrase) appear. Include **synthetic anti-vacuity** regression cases
  (wrong port / missing route must fail) — the house idiom from
  `native_evidence_drift_test.exs` / `contract_drift_test.exs`. Phase 128's
  `see_it_run_test.exs` then scopes to the **guide markdown only** — no
  banner-string duplication across the two test files.

### Claude's Discretion (planner/researcher to settle)
- Exact `bin/see-it-run.sh` flag-parser shape and `--help` text; whether `--all`
  is an explicit alias for "both platforms".
- Exact ANSI palette (if any) — must degrade to byte-identical plain text; brand
  accent optional, never load-bearing.
- Exact curl-loop cap (120 s suggested) and dot cadence; whether to add a one-line
  "first boot compiles deps (~1–2 min)" notice during the wait.
- Exact iOS destination discovery vs a named fallback device; confirm `--build`
  does NOT auto-boot an AVD on Android (recommended: it does not).
- Whether `mix crosswake.demo` forwards `--web-only`/`--build`/`--no-open`
  (recommended: yes, pure pass-through).
- Exact `bin/` location (repo-root `bin/see-it-run.sh` per LAUNCH-01) and
  `chmod +x`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` §"LAUNCH" — LAUNCH-01, LAUNCH-02 (locked requirement text).
- `.planning/ROADMAP.md` §"Phase 127" — goal + 3 success criteria (the acceptance bar);
  §"Phase 128" — what is explicitly deferred (do not poach screenshots/recording/guide).
- `.planning/phases/125-containerized-shared-backend-port-convention/125-CONTEXT.md` —
  port 4700, runtime.exs port source, compose/entrypoint structure, "proof fixtures sacred".
- `.planning/phases/126-additive-native-dev-wiring/126-CONTEXT.md` — the exact Dev-variant
  launch commands this script invokes; "advisory native" voice (D-16); proof-posture guard.

### Backend boot surface (Phase 125 — invoke, don't mutate)
- `examples/phoenix_host/docker-compose.yml` — `up -d` target; ports 4700:4700; BIND_ALL,
  DATABASE_PATH; build.context `../..`, env_file `.env` (resolve via `-f` from repo root).
- `examples/phoenix_host/entrypoint.sh` — what runs on first boot (slow: deps/compile/ecto/seed).
- `examples/phoenix_host/config/runtime.exs` — **canonical PORT source** for the banner drift test.

### Native launch surface (Phase 126 — invoke advisorily)
- `examples/QUICK_START.md` §"Run Against the Local Backend (Dev Wiring)" — verbatim iOS
  (`-scheme Dev -configuration Debug-Dev`) + Android (`installDevDebug` + `adb … am start
  -n dev.crosswake.shell.dev/.MainActivity`, JDK-17) commands the banner reproduces.
- `examples/ios_shell_host/CrosswakeShell.xcodeproj` — iOS Dev scheme target (Phase 126).
- `examples/android_shell_host/` — `dev` flavor, `gradlew`, package `dev.crosswake.shell.dev`.

### Repo shell + Mix idiom (mirror these)
- `script/verify_generated_ios_shell.sh` — `command -v xcodebuild` detection + `simctl`
  boot / `open -a Simulator` pattern to reuse for D-13/D-15 (iOS).
- `script/verify_generated_android_shell.sh` — JAVA_HOME-17 fallback + `adb`/`emulator`
  pattern to reuse for D-13/D-15 (Android); `… || true` idempotent-cleanup idiom.
- `script/*.sh` generally — `set -euo pipefail` house convention (D-03).
- `lib/mix/tasks/crosswake.contract.gen.ex` — `use Mix.Task`/`@shortdoc`/`OptionParser`/
  `Mix.shell().info` idiom for the thin `mix crosswake.demo` task (D-01).
- `lib/mix/tasks/crosswake.doctor.ex` — calm preflight/guidance tone to mirror (NOT call) (D-18).

### Drift-test culture (mirror exactly — D-21)
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` — reads a non-Elixir text
  file, derives PORT via regex, `require_contains`, `wrong_port_failures` — the template.
- `test/crosswake/guides/native_evidence_drift_test.exs`,
  `test/crosswake/guides/contract_drift_test.exs` — synthetic anti-vacuity regression idiom.
- `test/crosswake/guides/port_registry_test.exs` — minimal source-derived guard example.

### Route truth (banner route set — D-05)
- `examples/phoenix_host/lib/crosswake_example/router.ex` — `/`, `/offline`, `/bridge-proof`
  (surface these); `/native`, `/saas`, `/commerce`, … (do NOT surface).

### Vision / voice
- `brandbook/BRAND-SPEC.md` — **CANONICAL** brand voice/tone + `[crosswake]` CLI prefix
  (newer than, and supersedes, `prompts/crosswake-brand-book.md` for any conflict).
- `prompts/crosswake-elixir-oss-dna.md` — "install truth is product truth", honesty/no-drift culture.
- `docs/PORT-REGISTRY.md` — why 4700; COMPOSE_PROJECT_NAME caveat; foreign-process-on-4700 context (D-11).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `script/verify_generated_ios_shell.sh` / `verify_generated_android_shell.sh` — toolchain
  `command -v` detection, `simctl boot`/`open -a Simulator`, JAVA_HOME-17 fallback, and
  `|| true` idempotent patterns to lift directly into `bin/see-it-run.sh` (D-13/D-15).
- `quick_start_adoption_drift_test.exs` — proven "read a text file, derive port via regex,
  assert + synthetic-failure" idiom; the banner drift test (D-21) copies it nearly verbatim.
- `examples/phoenix_host/docker-compose.yml` + `entrypoint.sh` — boot is already one command;
  this phase wraps it with detach + readiness-poll + banner, no compose change needed (D-07/D-08).
- `lib/mix/tasks/crosswake.*.ex` — Mix.Task idiom for the thin `mix crosswake.demo` alias (D-01).

### Established Patterns
- **Web path is the proof; native is advisory** — exit 0 unless the backend itself fails (D-17);
  native sim/emulator runs are "advisory native" evidence, never device proof (D-06/D-12).
- **Every port/route/command claim is source-derived + drift-tested** — never hardcode a fact
  the source owns; the banner is guarded the same way the guides are (D-21).
- **Proof fixtures are sacred** — this launcher only *runs* things; it mutates no proof artifact.
- **`set -euo pipefail` + guarded probes + `[crosswake]` prefix** — house shell convention (D-03).

### Integration Points
- Reads PORT from `config/runtime.exs` (drift test) and the compose port mapping (boot).
- Invokes Phase-126 Dev-variant commands (iOS scheme / Android flavor) advisorily (D-12).
- Readiness handshake (`curl` on :4700) gates both the banner and any native launch (D-08/D-16).
- `mix crosswake.demo` → `System.cmd` → `bin/see-it-run.sh` (single source of truth) (D-01).
</code_context>

<specifics>
## Specific Ideas

- The maintainer asked for one coherent, one-shot recommendation set (not sequential
  one-by-one questions) — delivered via four parallel research subagents (banner anatomy +
  drift-guard, backend boot orchestration, sim/emulator launch depth, failure & guidance
  posture), each weighing pros/cons/tradeoffs, Elixir/Phoenix/shell idiom, DX/JTBD/brand
  voice, and cross-ecosystem lessons, synthesized into D-01..D-21.
- Cross-ecosystem lessons applied: Supabase CLI's "boot detached → poll → print a URL
  table when ready" (D-07/D-08); Vite/CRA payoff-first banner + NO_COLOR discipline
  (D-04/D-02); Expo/Flutter device-picker + graceful "no devices" message and React
  Native's license-prompt CI-hang footgun (D-12/D-14); `flutter doctor`/cargo/`gh` calm,
  actionable, never-stack-trace guidance (D-18); the docker-compose-foreground
  "banner lost under the log wall" footgun → detached + poll (D-07).
- "See It Run" milestone intent → instant gratification (auto-open the browser) balanced
  with CI/TTY safety (D-19); the banner must be visible before any slow native step (D-16).

### The one cross-area conflict, resolved
- **Banner-in-Mix-task (Elixir, easily testable) vs banner-in-shell (Docker-only-friendly):**
  resolved to **shell** (D-01/D-02). The honesty requirement is preserved because the existing
  drift test already asserts on a non-Elixir text file — so `bin/see-it-run.sh` is drift-tested
  by reading it as text (D-21). No compromise: Docker-only-runnable AND guarded now.
</specifics>

<deferred>
## Deferred Ideas

- Three-runtime screenshots + screen recording, the full `guides/see_it_run.md`, README/
  QUICK_START routing to that guide, and `test/crosswake/guides/see_it_run_test.exs`
  → **Phase 128** (its guide test scopes to the markdown; the banner string is guarded
  here in Phase 127 by D-21 — no duplication).
- `bin/see-it-run.sh --backend-url <url>` / port override — deferred; 4700/localhost/10.0.2.2
  are hardcoded (port locked by Phase 125).
- Auto-creating/booting an Android AVD when none exists — out (too slow/risky for first-run);
  print guidance instead (D-15).
- Dockerizing the Android emulator — explicitly OUT OF SCOPE (REQUIREMENTS "Out of Scope").
- Adding a Phoenix `/healthz` route or compose `healthcheck:` — not needed; script-side curl
  on `/` is sufficient (D-08). Revisit only if compose moves into CI.

None beyond the above — discussion stayed within phase scope.
</deferred>

---

*Phase: 127-launch-orchestration-banner*
*Context gathered: 2026-06-22*
