# Crosswake Quick Start

> **New here?** Start with [guides/see_it_run.md](../guides/see_it_run.md) and
> open the showcase hub at `http://localhost:4700/`. Come back here for the full
> proof command reference.

This guide gets the checked-in Phoenix host running first, then walks through the
proof commands that show Crosswake's current route-owner architecture.
Proof routes stay one click deeper: the showcase hub is the newcomer entrypoint,
while `/offline`, `/bridge-proof`, `/native/claims`, diagnostics, and E2E routes
remain proof surfaces.

Use it from a clean checkout when you want to see what is proven today:
Phoenix-owned routes stay Phoenix-owned, `/offline` is an app-owned offline
island, `/bridge-proof` is a Phoenix-owned route with one bounded Share
affordance, and the checked-in native hosts are `checked-in public-coordinate proof`
while `--local` remains the explicit maintainer path.

## Prerequisites

- Elixir and Erlang matching the root `mix.exs`
- Node and npm for the Playwright proof in `examples/phoenix_host`
- Xcode only if you want to inspect the checked-in iOS host locally
- Android Studio, Android SDK, and Java only if you want to inspect the
  checked-in Android host locally

## First Run

### Option A: One Command (Docker)

Run from the repo root — no local Elixir, Node, or SQLite toolchain required:

```bash
bin/see-it-run.sh
```

The script boots the shared backend, prints the launch banner, and auto-opens the
browser. The app is served at `http://localhost:4700`. SQLite data is kept in a
named Docker volume and survives container restarts.

To run the Docker backend directly: `cd examples/phoenix_host && docker compose up`

### Option B: Native

Start the Phoenix example host with the local Elixir toolchain:

```bash
cd examples/phoenix_host
mix setup
PORT=4700 mix phx.server
```

Open the showcase hub at `http://localhost:4700/`.

Expected result: the Crosswake showcase hub loads with SaaS/Admin, Field Service,
and Learning/Training lanes plus route-owner labels. This smoke path proves the
Phoenix host boots with the current SQLite migrations and seed hook. It is not
the offline correctness proof.

Leave the server running for the next section.

## See The Route Owners

Visit these routes while the server is running:

```text
http://localhost:4700/
http://localhost:4700/offline
http://localhost:4700/bridge-proof
```

What to look for:

- `/` is the Phoenix-owned showcase hub for the checked-in host.
- `/offline` renders the Offline Study Island. It is a socketless
  `:offline_island` route backed by `examples/phoenix_host/priv/static/offline_study.js`.
- `/bridge-proof` renders a LiveView route that declares the bounded `share`
  capability. The button is labeled `Share`.
- The offline replay endpoint is `/study/sync`; it is used by the browser island,
  not by the bridge.

Support-truth labels stay literal in this guide: `Available today`,
`Proof-backed example`, `Demo pressure`, and `Future gap` separate shipped proof
from native-control pressure. Showcase screenshots explain the product surface;
route-tour assertions prove route-owner semantics before screenshots or other
collateral are accepted.

## Prove Offline Replay

Stop the `PORT=4700 mix phx.server` process before running this proof. Playwright
starts its own `MIX_ENV=test` Phoenix server on port `4700` from
`examples/phoenix_host/playwright.config.ts`; that test server also exposes the
gated `/_e2e` inspection route.

From `examples/phoenix_host`:

```bash
npm ci
npx playwright install chromium
npx playwright test e2e/offline_sync.spec.ts
```

This is the first required correctness proof after the smoke walkthrough. The
test drives the real app path:

1. Opens `/offline`.
2. Uses the UI to queue a review event in IndexedDB.
3. Reconnects the browser and dispatches the `online` event that triggers
   `flushOutbox`.
4. Waits for the app to post to `/study/sync`.
5. Asserts the Ecto row exists through `/_e2e/sync-state/:client_mutation_id`.
6. Confirms the accepted record was deleted from the local outbox.
7. Replays the same `client_mutation_id` and proves duplicate replay is
   idempotent.

Run the structural honesty guard after `npm ci` if you want to prove the E2E has
not drifted back to fabricated globals or test-owned mutation writes:

```bash
node ../../script/check-e2e-honesty.mjs
```

From the repo root, the same guard is:

```bash
node script/check-e2e-honesty.mjs
```

## Prove Bounded Bridge

From the repo root:

```bash
bash script/verify_bounded_bridge_proof.sh
```

This proof checks that the quick start still documents `/bridge-proof` and the
Share capability, then runs the backend bridge proof test. It proves the
semantic request/reply bridge contract for a Phoenix-owned route. It does not
make the native share sheet a required correctness gate.

## Prove Native-Owned Route Contract

From the repo root:

```bash
CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh
```

This keeps native verification hooks disabled and proves the manifest/example
host contract lane. The checked-in native hosts are already
`checked-in public-coordinate proof`; this command does not run simulator,
emulator, or physical-device evidence.

## Native Steps Are Labeled Proof

The checked-in native host paths are `checked-in public-coordinate proof`:

- `examples/ios_shell_host/CrosswakeShell.xcodeproj` | published-coordinate mode
- `examples/android_shell_host/app/build.gradle` | published-coordinate mode

What this proves: the checked-in host projects resolve the published native shell
coordinates by default.
What this does not prove: simulator, emulator, or physical-device support.
Next link: [guides/native_shell.md](../guides/native_shell.md)

Use `--local` when you want maintainer/local-dev proof against source-checkout
dependencies instead of the public default.

### iOS Local-Development Walkthrough

```bash
open examples/ios_shell_host/CrosswakeShell.xcodeproj
```

Run the project from Xcode against the Phoenix host you started with
`PORT=4700 mix phx.server`. The checked-in host path is published-coordinate
proof, but a successful simulator launch still does not prove device support.

### Android Local-Development Walkthrough

```bash
cd examples/android_shell_host
./gradlew installProdDebug
```

You need local Android tooling and a running emulator or device for that command.
The checked-in Android host path is published-coordinate proof, but the emulator
launch still does not prove physical-device support.

### Run Against the Local Backend (Dev Wiring)

These hosts are `checked-in public-coordinate proof` in `published-coordinate mode`.
The dev-wiring commands load Crosswake routes advisorily from the local backend:
a successful simulator or emulator run confirms the dev wiring reaches the local
backend, but does not prove physical-device support.

Start the shared backend first:

```bash
cd examples/phoenix_host
PORT=4700 mix phx.server
# or, from the same directory:
docker compose up
```

**iOS Simulator** (select the `Dev` scheme in Xcode):

```bash
xcodebuild \
  -project examples/ios_shell_host/CrosswakeShell.xcodeproj \
  -scheme Dev \
  -configuration Debug-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

Or open in Xcode and pick the `Dev` scheme from the scheme picker, then Run.

**Android Emulator:**

```bash
cd examples/android_shell_host
JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug
adb shell am start -n dev.crosswake.shell.dev/.MainActivity
```

You need a running Android emulator and local Android tooling (JDK 17 required).

## Troubleshooting Quick Checks

- If `mix setup` fails, run it again from `examples/phoenix_host`; it fetches
  deps, creates/migrates SQLite, and runs `priv/repo/seeds.exs`.
- If `PORT=4700 mix phx.server` says the port is in use, stop the old Phoenix or
  Playwright server and retry.
- If Playwright fails to start, confirm the Phoenix dev server is stopped before
  running `npx playwright test e2e/offline_sync.spec.ts`.
- If `node script/check-e2e-honesty.mjs` cannot find TypeScript, run
  `npm ci` from `examples/phoenix_host` first.
- If native builds fail, treat that as advisory local tooling state; the required
  contract proof is the native-skipped script above.

## What This Does Not Prove

- It does not prove broad app-wide local-first behavior or background sync.
- It does not make the bridge offline mutation authority.
- It does not prove simulator, emulator, or physical-device support.
- It does not widen checked-in host proof into simulator, emulator, or physical-device support.
- It does not turn Crosswake into a generic WebView wrapper, React Native clone,
  LiveView-to-native renderer, or plugin platform.
- It does not replace Phase 119 native evidence classification or Phase 120
  screenshots, recordings, artifact manifests, and broader troubleshooting docs.
