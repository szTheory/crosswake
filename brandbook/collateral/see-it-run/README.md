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

### Native screenshots and recording (human-gated)

The native screenshots (`ios-simulator.png`, `android-emulator.png`) and the
recording (`see-it-run.gif`) require the Phase-126 Dev build booted against the
local backend on the maintainer's Mac (Xcode + Android SDK). They cannot be
automated in CI.

After running `bin/capture-collateral.sh` (which prints the exact commands), the
maintainer copies:

**iOS Simulator:**

```bash
xcrun simctl io booted screenshot brandbook/collateral/see-it-run/ios-simulator.png
```

**Android Emulator:**

```bash
adb exec-out screencap -p > brandbook/collateral/see-it-run/android-emulator.png
```

**Three-runtime montage** (ImageMagick):

```bash
convert +append \
  brandbook/collateral/see-it-run/web-home.png \
  brandbook/collateral/see-it-run/ios-simulator.png \
  brandbook/collateral/see-it-run/android-emulator.png \
  brandbook/collateral/see-it-run/three-runtime-montage.png
```

**GIF recording** — record terminal → banner → browser auto-open (~900px wide,
12fps, 10–15s), then optimize:

```bash
gifsicle -O3 --output brandbook/collateral/see-it-run/see-it-run.gif path/to/raw-recording.gif
```

Hard cap: 8MB (target < 5MB).

### Deferred collateral-existence test

The Elixir test that guards binary existence
(`test/crosswake/guides/see_it_run_collateral_test.exs`) is added AFTER the real
binaries land (per D-19 in the phase context). It is not present in this
scaffolding phase — adding it before the PNGs exist would cause false CI failures.

Once the maintainer has committed the real binaries (per the human-gated steps
above), the collateral-existence test can be created to drift-guard them.
