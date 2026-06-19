# Crosswake Quick Start

This guide gets the checked-in Phoenix host running first, then walks through the
proof commands that show Crosswake's current route-owner architecture.

Use it from a clean checkout when you want to see what is proven today:
Phoenix-owned routes stay Phoenix-owned, `/offline` is an app-owned offline
island, `/bridge-proof` is a Phoenix-owned route with one bounded Share
affordance, and native UI steps remain advisory/local-development until Phase
119 classifies checked-in native evidence.

## Prerequisites

- Elixir and Erlang matching the root `mix.exs`
- Node and npm for the Playwright proof in `examples/phoenix_host`
- Xcode only if you want the advisory iOS local-development walkthrough
- Android Studio, Android SDK, and Java only if you want the advisory Android
  local-development walkthrough

## First Run

Start the Phoenix example host:

```bash
cd examples/phoenix_host
mix setup
PORT=4002 mix phx.server
```

Open `http://localhost:4002/`.

Expected result: the Crosswake Phoenix Host page loads and links to the route
owner examples. This smoke path proves the Phoenix host boots with the current
SQLite migrations and seed hook. It is not the offline correctness proof.

Leave the server running for the next section.

## See The Route Owners

Visit these routes while the server is running:

```text
http://localhost:4002/
http://localhost:4002/offline
http://localhost:4002/bridge-proof
```

What to look for:

- `/` is the Phoenix-owned starting point for the checked-in host.
- `/offline` renders the Offline Study Island. It is a socketless
  `:offline_island` route backed by `examples/phoenix_host/priv/static/offline_study.js`.
- `/bridge-proof` renders a LiveView route that declares the bounded `share`
  capability. The button is labeled `Share`.
- The offline replay endpoint is `/study/sync`; it is used by the browser island,
  not by a bridge-owned mutation queue.

## Prove Offline Replay

Stop the `PORT=4002 mix phx.server` process before running this proof. Playwright
starts its own `MIX_ENV=test` Phoenix server on port `4002` from
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
host contract lane. It is useful before Phase 119 because the checked-in native
hosts are not yet classified as published-coordinate proof.

## Native Steps Are Advisory

The checked-in native hosts are local-development proof surfaces in this phase.
Use these steps only when you want to inspect the local host projects manually.
They are advisory evidence, not merge-blocking proof, not generated
public-coordinate proof, and not physical-device support.

### iOS Local-Development Walkthrough

```bash
open examples/ios_shell_host/CrosswakeShell.xcodeproj
```

Run the project from Xcode against the Phoenix host you started with
`PORT=4002 mix phx.server`. This project currently uses a local Swift package
reference, so do not read a successful simulator launch as published-coordinate
proof.

### Android Local-Development Walkthrough

```bash
cd examples/android_shell_host
./gradlew installDebug
```

You need local Android tooling and a running emulator or device for that command.
The checked-in Android host currently remains a local-development proof surface
until Phase 119 reconciles native evidence labels.

## Troubleshooting Quick Checks

- If `mix setup` fails, run it again from `examples/phoenix_host`; it fetches
  deps, creates/migrates SQLite, and runs `priv/repo/seeds.exs`.
- If `PORT=4002 mix phx.server` says the port is in use, stop the old Phoenix or
  Playwright server and retry.
- If Playwright fails to start, confirm the Phoenix dev server is stopped before
  running `npx playwright test e2e/offline_sync.spec.ts`.
- If `node script/check-e2e-honesty.mjs` cannot find TypeScript, run
  `npm ci` from `examples/phoenix_host` first.
- If native builds fail, treat that as advisory local tooling state for Phase
  118; the required contract proof is the native-skipped script above.

## What This Does Not Prove

- It does not prove broad app-wide local-first behavior or background sync.
- It does not make the bridge offline mutation authority.
- It does not prove simulator, emulator, or physical-device support.
- It does not classify checked-in iOS/Android hosts as published-coordinate
  adopter proof.
- It does not turn Crosswake into a generic WebView wrapper, React Native clone,
  LiveView-to-native renderer, or plugin platform.
- It does not replace Phase 119 native evidence classification or Phase 120
  screenshots, recordings, artifact manifests, and broader troubleshooting docs.
