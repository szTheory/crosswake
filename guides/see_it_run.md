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
> See [examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md) for the full proof command reference.

## What You'll See

> Advisory native collateral. A successful simulator or emulator run confirms the
> dev wiring reaches the local backend, but does not prove physical-device support.
> This is `emulator evidence` per the
> [support-truth label legend](support_matrix.md#support-truth-label-legend).

One shared backend, starting at the showcase hub:

<img
  src="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/web-home.png"
  alt="Crosswake showcase hub at localhost:4700 — the SaaS/Admin, Field Service, and Learning/Training lanes with route-owner and support-truth labels"
  width="900"
/>

Then watch `bin/see-it-run.sh` boot the shared backend and open the browser:

<img
  src="https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/see-it-run.gif"
  alt="Screen recording: bin/see-it-run.sh boots the shared backend, prints the banner, and opens the browser at localhost:4700"
  width="900"
/>

The web runtime is proven; iOS Simulator and Android Emulator connect to the same
backend as advisory `emulator evidence` — compared side by side in the
[Compare All Three Runtimes](#compare-all-three-runtimes-web-ios-android) table below.

Showcase screenshots explain the product surface; route-tour assertions prove
route-owner semantics before screenshots are written.

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

Open `http://localhost:4700/` in your browser. This is the showcase hub: a
product-shaped first screen for the SaaS/Admin, Field Service, and
Learning/Training lanes, with route-owner and support labels visible before you
inspect proof routes.

If you have Elixir installed locally, `mix crosswake.demo` does the same thing.

For the full first-run walkthrough including offline replay proof, see
[examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md) — Option A: One Command (Docker).

To visibly rehearse the checked-in offline study route in iPhone Simulator, run:

```bash
bin/crosswake-ios-rehearsal
```

It is advisory Simulator evidence only. The real-phone handoff and its one-command
promotion flow are documented in [Physical iPhone handoff](physical_iphone_handoff.md).

## Browse the Route Owners

Visit these routes while the backend is running at `http://localhost:4700`:

| Route | Owner | What you see |
|-------|-------|-------------|
| `/` | Phoenix-owned showcase | Showcase hub — three domain lanes with route-owner labels |
| `/offline` | App-owned offline island | Offline Study Island — app-owned IndexedDB outbox and Phoenix/Ecto replay |
| `/bridge-proof` | Phoenix-owned LiveView | Bridge Proof — bounded `share` capability with a Share button |

Proof routes stay one click deeper and are secondary to the showcase-first path.
Use them after the hub explains the product shape.

Support-truth labels stay literal here: `Available today`,
`Proof-backed example`, `Demo pressure`, and `Future gap` distinguish shipped
proof from native-control pressure.

```text
http://localhost:4700/
http://localhost:4700/offline
http://localhost:4700/bridge-proof
```

For the Playwright offline replay proof and script commands, see
[examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md) — See The Route Owners.

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
[examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md) — Run Against the Local Backend (Dev Wiring).

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
  [examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md).
- Any claim of simulator or emulator support beyond the advisory label.

"Proven" is reserved for the web path. Native is always labeled `emulator evidence`.

## Run the Reference Twin (Simulator)

The bounded reference twin drives one offline study island on an iOS Simulator against a local
Phoenix backend and writes a twin-only receipt. The shipped command is:

```bash
MIX_ENV=test mix crosswake.proof_lane.verify_twin ios \
  --candidate <prepared candidate record> --run-root <new private directory> \
  --identity <identity file>
```

Prerequisites: a prepared candidate record (a private, mode 0600 JSON file naming the candidate
path, expected head and tree, the declared loopback origin, and resource and fixture digests; this
is a file, not the candidate directory), a free loopback origin port, an Xcode Simulator runtime,
and an identity file. Every run needs a new run root; a run root that already holds a receipt is
refused so a first result is never overwritten. The candidate tree must be clean at the recorded head; a dirty tree is refused. Changes hidden by index flags (assume-unchanged or skip-worktree) or by git settings still count, a candidate whose git configuration can hide changes (a worktree redirect, a filter, or .git/info/attributes) or that is not the repository's top-level directory is refused, and git 2.41 or newer is required. Untracked files that a .gitignore ignores are not counted; this is a known limit of the check, not something it detects.

Before a run, check whether it would be allowed with the read-only preflight:

```bash
MIX_ENV=test mix crosswake.proof_lane.twin_preflight ios \
  --candidate <prepared candidate record> --run-root <new private directory> \
  --identity <identity file>
```

The preflight prints four lines (result allowed or blocked, first cause, `report: none written; no run root was created or consumed`, and one next action) and exits `0` when allowed and `2` when blocked. It writes no receipt and never creates or consumes a run root, so the same run root can be used for the real run. Allowed means the source, the identity digests and the run root pass and the origin port is free at that moment, while the backend build and the live journey are checked only by the real run, which repeats every check. Dirty counts are findings, not distinct files (a file can be both changed and flagged). Because the check ignores global git configuration, `safe.directory` entries do not apply, a filesystem without file modes reports changes, and repositories that rely on LFS or end-of-line filters are refused.

Exit codes: `0` complete pass, `1` observed failure, `2` missing prerequisite or missing
observation. The command prints four lines: result, first cause, local report path and one next
action.

What the receipt proves: a virtual twin on a simulator with synthetic test authority, run by a
trusted local runner. What it does not prove: a physical iPhone, a signed device, a physical
speaker, first adopter evidence, or cryptographic certification of the run.

## Go Deeper

- Full proof command reference: [examples/QUICK_START.md](https://github.com/szTheory/crosswake/blob/main/examples/QUICK_START.md)
- Installing the library in your own Phoenix app: [install.md](install.md)
- Route ownership and the policy model: [route_policy.md](route_policy.md)
- Choosing the right runtime for your audience: [adopter_profiles.md](adopter_profiles.md)
