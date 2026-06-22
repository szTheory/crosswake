# See It Run

> Boot Crosswake once. See web, iOS simulator, and Android emulator connect to the
> same backend — advisorily, without claiming device support. Works from Docker with
> no local Elixir toolchain.
>
> ```bash
> bin/see-it-run.sh
> ```
>
> The banner prints your next steps.
>
> See [examples/QUICK_START.md](../examples/QUICK_START.md) for the full proof command reference.

## What You'll See

> Advisory native collateral. A successful simulator or emulator run confirms the
> dev wiring reaches the local backend, but does not prove physical-device support.
> This is `emulator evidence` per the
> [support-truth label legend](support_matrix.md#support-truth-label-legend).

Three runtimes, one shared backend:

<img
  src="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/three-runtime-montage.png"
  alt="Three-runtime Crosswake comparison: web (localhost:4700), iOS Simulator (emulator evidence — advisory native, not a physical device), Android Emulator (emulator evidence — advisory native, not a physical device)"
  width="900"
/>

*Advisory native evidence — simulator/emulator, not a physical device.*

<img
  src="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/see-it-run.gif"
  alt="Screen recording: bin/see-it-run.sh boots the backend, prints the banner, and opens the browser — emulator evidence of all three runtimes connecting"
  width="900"
/>

## Run It Now (Zero Toolchain)

**JTBD-A:** See the web app running in under a minute — no Elixir, no Node, no
SQLite toolchain required.

Boot the shared backend with one command:

```bash
bin/see-it-run.sh
```

Or start the Docker backend directly:

```bash
cd examples/phoenix_host
docker compose up
```

Open `http://localhost:4700/` in your browser. The page loads the Crosswake Phoenix
Host and links to the route owners.

If you have Elixir installed locally, `mix crosswake.demo` does the same thing.

For the full first-run walkthrough including offline replay proof, see
[examples/QUICK_START.md](../examples/QUICK_START.md) — Option A: One Command (Docker).

## Browse the Route Owners

Visit these routes while the backend is running at `http://localhost:4700`:

| Route | Owner | What you see |
|-------|-------|-------------|
| `/` | Phoenix-owned | Crosswake Phoenix Host home — links to route owner examples |
| `/offline` | App-owned offline island | Offline Study Island — app-owned IndexedDB outbox and Phoenix/Ecto replay |
| `/bridge-proof` | Phoenix-owned LiveView | Bridge Proof — bounded `share` capability with a Share button |

```text
http://localhost:4700/
http://localhost:4700/offline
http://localhost:4700/bridge-proof
```

For the Playwright offline replay proof and script commands, see
[examples/QUICK_START.md](../examples/QUICK_START.md) — See The Route Owners.

## Compare All Three Runtimes (Web, iOS, Android)

> Advisory native collateral. The iOS Simulator and Android Emulator runs confirm
> the dev wiring reaches the shared backend. They are `emulator evidence` — advisory
> platform evidence, not physical-device support.

| Runtime | Status | Label |
|---------|--------|-------|
| Web (localhost:4700) | Proven | Phoenix-owned LiveView routes fully operational |
| iOS Simulator | Advisory | emulator evidence — sim connects to shared backend |
| Android Emulator | Advisory | emulator evidence — emulator connects to shared backend |

The three runtimes connect to the same shared backend started by `bin/see-it-run.sh`.
"Web" is proven; native is advisory emulator evidence per the
[support-truth label legend](support_matrix.md#support-truth-label-legend).

## Wire a Native Runtime to the Local Backend

> Advisory native collateral. The dev wiring commands load Crosswake routes from
> the local backend.

The checked-in native shell hosts at `examples/ios_shell_host` and
`examples/android_shell_host` are `checked-in public-coordinate proof` in
`published-coordinate mode`. The dev-wiring step connects the simulator or emulator
to the Phoenix host you already booted with `bin/see-it-run.sh`.

A successful simulator or emulator run confirms the dev wiring reaches the local
backend, but does not prove physical-device support. This is `emulator evidence`
per the [support-truth label legend](support_matrix.md#support-truth-label-legend).

For the exact `xcodebuild` and `gradlew` dev-wiring commands, see
[examples/QUICK_START.md](../examples/QUICK_START.md) — Run Against the Local Backend (Dev Wiring).

## What This Proves (And What It Doesn't)

What `bin/see-it-run.sh` proves:

- The Phoenix-owned web routes (`/`, `/offline`, `/bridge-proof`) are live and
  serving correctly at `http://localhost:4700`. This is proven.
- The Docker backend starts cleanly and accepts connections. This is proven.
- The iOS Simulator and Android Emulator reach the shared backend via dev wiring.
  This is `emulator evidence` — advisory, not a proven native build.

What it does not prove:

- Physical-device support. The iOS and Android runs are emulator evidence only;
  they confirm the dev wiring path, not broad device support.
- Offline replay correctness. The offline proof requires the Playwright spec in
  [examples/QUICK_START.md](../examples/QUICK_START.md).
- Any claim of simulator or emulator support beyond the advisory label.

"Proven" is reserved for the web path. Native is always labeled `emulator evidence`.

## Go Deeper

- Full proof command reference: [examples/QUICK_START.md](../examples/QUICK_START.md)
- Installing the library in your own Phoenix app: [install.md](install.md)
- Route ownership and the policy model: [route_policy.md](route_policy.md)
- Choosing the right runtime for your audience: [adopter_profiles.md](adopter_profiles.md)
