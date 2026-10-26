# Crosswake See It Run Collateral

Screenshots and recording for the Crosswake "See It Run" first-run experience —
showing the three runtimes (web, iOS Simulator, Android Emulator) connected to
the same shared backend.

## Storage rationale

This subdirectory lives under `brandbook/collateral/` which is excluded from the
Hex tarball (`mix.exs` `exclude_patterns: ["brandbook"]`). Binary assets here do
not ship to downstream `mix deps.get` consumers.

Images are referenced from docs and README via absolute raw URLs:

```
https://raw.githubusercontent.com/szTheory/crosswake/main/brandbook/collateral/see-it-run/<filename>
```

This is the same pattern already used for `readme-header.svg` and
`readme-header-dark.svg` in the parent collateral directory.

## Assets

| File | Type | Label |
|------|------|-------|
| `web-home.png` | Screenshot | Web proof — localhost:4700/ |
| `web-offline.png` | Screenshot | Web proof — localhost:4700/offline |
| `web-bridge-proof.png` | Screenshot | Web proof — localhost:4700/bridge-proof |
| `ios-simulator.png` | Screenshot | emulator evidence — iOS Simulator (advisory, not physical device) |
| `android-emulator.png` | Screenshot | emulator evidence — Android Emulator (advisory, not physical device) |
| `three-runtime-montage.png` | Composite | emulator evidence — three-runtime comparison (advisory, not physical device) |
| `see-it-run.gif` | Recording | Demo — terminal → banner → web browser |

**Honest-label discipline:** the three web rows (`web-*.png`) carry "Web proof" —
they are produced by the in-repo Playwright route-proof spec, which asserts route
semantics before taking the screenshot. The three native/montage rows carry
"emulator evidence" — a simulator or emulator run confirms the dev wiring reaches
the local backend, but does not prove physical-device support, camera support, or
App Store readiness.

## Capturing / Regenerating

### Web screenshots (automated)

The three web screenshots are captured automatically by the in-repo Playwright
route-proof spec via `bin/capture-collateral.sh`. The backend must be running
first:

```bash
# 1. Start the backend (Docker — no local Elixir toolchain required)
bin/see-it-run.sh

# 2. Capture the three web screenshots
bin/capture-collateral.sh
```

This writes `web-home.png`, `web-offline.png`, and `web-bridge-proof.png` to
`brandbook/collateral/see-it-run/`. Re-running overwrites — the script is
idempotent.

For headless or CI use, pass `--web-only` to skip the native capture instructions:

```bash
bin/capture-collateral.sh --web-only
```

### GIF (CI-automated) and native screenshots (manual dispatch)

Two workflows split the capture:

- [`.github/workflows/see-it-run-collateral.yml`](../../../.github/workflows/see-it-run-collateral.yml)
  captures the three web screenshots and `see-it-run.gif` on `ubuntu-latest` and
  lands them on `main` via an auto-PR (`peter-evans/create-pull-request`, branch
  `collateral/auto-refresh`). It runs weekly, on manual `workflow_dispatch`, and
  whenever the shells, the launcher, the demo routes, the tape, or the workflow
  itself change. It has no native job and does not capture `ios-simulator.png`,
  `android-emulator.png`, or `three-runtime-montage.png`.
- [`.github/workflows/see-it-run-native.yml`](../../../.github/workflows/see-it-run-native.yml)
  is **manual `workflow_dispatch` only**. A `macos-latest` job boots the shared
  backend on `:4700`, builds the Dev variants, and screenshots the loaded route via
  `script/capture-native-collateral.mjs` (simulator/emulator evidence, advisory,
  not physical device). It uploads `ios-simulator.png`, `android-emulator.png`, and
  the evidence manifest as workflow artifacts (14-day retention), plus a two-runtime
  `native-montage.png` (iOS + Android, ImageMagick `+append`). It does not open a PR
  and does not commit anything: a maintainer downloads the artifacts if they want
  to check them in. The job can fail by design while the known capture gaps noted
  in the workflow remain.

The three-runtime montage (`three-runtime-montage.png`) is no longer produced
automatically; the native workflow emits only the two-runtime `native-montage.png`.
The GIF is a deterministic `vhs` terminal cast of `bin/see-it-run.sh`
(`see-it-run.tape` in this directory), optimized with `gifsicle -O3` to stay under
the size budget below. Merging the web/GIF auto-PR keeps the README + ExDoc guide
images resolving on `main`.

#### Manual fallback (maintainer Mac)

`bin/capture-collateral.sh` prints the exact native commands for a local capture
if you do not want to dispatch the native workflow:

```bash
xcrun simctl io booted screenshot brandbook/collateral/see-it-run/ios-simulator.png
adb exec-out screencap -p > brandbook/collateral/see-it-run/android-emulator.png
convert +append \
  brandbook/collateral/see-it-run/web-home.png \
  brandbook/collateral/see-it-run/ios-simulator.png \
  brandbook/collateral/see-it-run/android-emulator.png \
  brandbook/collateral/see-it-run/three-runtime-montage.png
vhs brandbook/collateral/see-it-run/see-it-run.tape
gifsicle -O3 --colors 128 \
  -o brandbook/collateral/see-it-run/see-it-run.gif \
  brandbook/collateral/see-it-run/see-it-run.gif
```

### Drift guards

Two guards keep the assets honest and present:

- **`test/crosswake/guides/see_it_run_collateral_test.exs`** — existence +
  non-empty for all seven assets. Excluded from the default suite (tag
  `:collateral_binaries`); run it directly with
  `CROSSWAKE_INCLUDE_COLLATERAL=1 mix test test/crosswake/guides/see_it_run_collateral_test.exs`.
- **`.github/workflows/collateral-guard.yml`** — runs that test plus
  `script/check-collateral-size.sh` (≤1 MB budget) on every PR via
  `script/collateral-guard.sh`. Web assets are enforced now; the native assets and
  three-runtime montage are not produced by any automatic lane, so they are
  enforced only once a maintainer checks them in from a native-workflow run.
