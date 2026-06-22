#!/usr/bin/env bash
set -euo pipefail

# bin/capture-collateral.sh — Crosswake See It Run collateral capture harness
#
# WEB (automated, deterministic):
#   Drives the in-repo Playwright route-proof spec against localhost:4700 to
#   capture three proven web screenshots: web-home.png, web-offline.png,
#   web-bridge-proof.png. Routes are PROVEN before the screenshot is taken,
#   per the route_tour.spec.ts ownerMessage discipline. Captured at 1x / ~900px
#   readable width (non-Retina, per D-04).
#
# NATIVE (human-gated — PRINTED, not executed):
#   Prints the exact copy-paste commands for the maintainer to capture the native
#   emulator evidence: ios-simulator.png, android-emulator.png, the three-runtime
#   montage, and the see-it-run.gif recording. These require the Phase-126 Dev
#   build booted against the local backend on the maintainer's Mac (Xcode +
#   Android SDK) and cannot be automated in CI.
#
# Usage:
#   bin/capture-collateral.sh [--web-only] [--help]
#
# Flags:
#   --web-only   Run only web capture (for headless CI); skip native instructions
#   --help, -h   Print this help and exit 0
#
# Exit codes:
#   0  = web screenshots written to brandbook/collateral/see-it-run/
#   1  = Playwright command failed or backend not reachable

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_URL="http://localhost:4700"
OUT_DIR="${ROOT_DIR}/brandbook/collateral/see-it-run"

# ---------------------------------------------------------------------------
# Flag parser
# ---------------------------------------------------------------------------
WEB_ONLY=0
SHOW_HELP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --web-only)  WEB_ONLY=1; shift ;;
    --help|-h)   SHOW_HELP=1; shift ;;
    *)
      echo "[capture-collateral] Unknown flag: $1" >&2
      echo "[capture-collateral] Run 'bin/capture-collateral.sh --help' for usage." >&2
      exit 1
      ;;
  esac
done

if [[ "$SHOW_HELP" == "1" ]]; then
  cat <<'USAGE'
[capture-collateral] bin/capture-collateral.sh — Crosswake collateral capture harness

Usage: bin/capture-collateral.sh [options]

Options:
  --web-only   Run only the automated web capture (for headless CI);
               skip printing the human-gated native capture commands
  --help, -h   Print this help and exit 0

Web capture (automated):
  Drives the in-repo Playwright spec (examples/phoenix_host/e2e/route_tour.spec.ts)
  against localhost:4700. The backend must already be running before invoking this
  script. Start it with: bin/see-it-run.sh
  Outputs:
    brandbook/collateral/see-it-run/web-home.png
    brandbook/collateral/see-it-run/web-offline.png
    brandbook/collateral/see-it-run/web-bridge-proof.png

Native capture (human-gated — PRINTED only):
  Prints exact copy-paste commands for ios-simulator.png, android-emulator.png,
  three-runtime-montage.png, and see-it-run.gif. These require the Phase-126
  Dev build and cannot be automated (needs macOS + Xcode + Android SDK).

Exit codes:
  0 = web screenshots written
  1 = backend not reachable or Playwright failed
USAGE
  exit 0
fi

# ---------------------------------------------------------------------------
# ANSI color helpers — progressive enhancement, matching see-it-run.sh style
# Color never carries meaning; plain-text is byte-identical when stripped.
# ---------------------------------------------------------------------------
BOLD="" DIM="" RESET="" ACCENT=""
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -z "${CI:-}" ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  RESET="\033[0m"
  ACCENT="\033[36m"
fi

# ---------------------------------------------------------------------------
# Pre-flight: confirm backend is reachable
# ---------------------------------------------------------------------------
if ! curl -sf "${BACKEND_URL}/" >/dev/null 2>&1; then
  echo "[capture-collateral] ERROR: ${BACKEND_URL} is not reachable." >&2
  echo "[capture-collateral] Start the backend first:" >&2
  echo "[capture-collateral]   bin/see-it-run.sh" >&2
  exit 1
fi

echo ""
printf "${BOLD}[capture-collateral] Backend reachable at ${BACKEND_URL}${RESET}\n"

# ---------------------------------------------------------------------------
# Ensure output directory exists
# ---------------------------------------------------------------------------
mkdir -p "${OUT_DIR}"

# ---------------------------------------------------------------------------
# WEB CAPTURE — deterministic, automated via in-repo Playwright
#
# Drives examples/phoenix_host/e2e/route_tour.spec.ts:
#   - Proves /, /offline, /bridge-proof routes before screenshotting
#   - Captures three web screenshots at 1x / ~900px (non-Retina, per D-04)
#   - Writes files into brandbook/collateral/see-it-run/
#
# The route_tour.spec.ts ownerMessage discipline ensures the route is proven
# (semantically correct, correct owner, correct payload) BEFORE the PNG is
# taken — web shots are evidence, not decoration.
# ---------------------------------------------------------------------------
E2E_DIR="${ROOT_DIR}/examples/phoenix_host"
PW_ARTIFACTS="${E2E_DIR}/playwright-artifacts/route-tour/screenshots"

echo ""
printf "${BOLD}[capture-collateral] Running Playwright route-proof for web screenshots ...${RESET}\n"
echo "[capture-collateral]   Spec: examples/phoenix_host/e2e/route_tour.spec.ts"
echo "[capture-collateral]   Output (route-tour artifacts): ${PW_ARTIFACTS}"
echo ""

# Run Playwright from the phoenix_host package (where playwright.config.ts lives).
# reuseExistingServer is enabled when CI is unset — the backend is already running.
(
  cd "${E2E_DIR}"
  npx playwright test e2e/route_tour.spec.ts
)

# ---------------------------------------------------------------------------
# Copy + rename the route-proof screenshots to the collateral output paths.
#
# route_tour.spec.ts captures:
#   library.png            → web-home.png           (/ — Phoenix-owned home)
#   offline-study-replayed.png → web-offline.png    (/offline — offline island)
#   bridge-proof.png       → web-bridge-proof.png   (/bridge-proof — LiveView+bridge)
#
# Note: the spec targets /library as the primary home route and renames here
# so the collateral filenames match the UI-SPEC label table (D-04).
# ---------------------------------------------------------------------------
COPY_OK=1

copy_collateral() {
  local src="${PW_ARTIFACTS}/$1"
  local dst="${OUT_DIR}/$2"
  if [ -f "${src}" ]; then
    cp "${src}" "${dst}"
    printf "${ACCENT}[capture-collateral]   wrote: brandbook/collateral/see-it-run/$2${RESET}\n"
  else
    echo "[capture-collateral] WARNING: expected screenshot not found: ${src}" >&2
    COPY_OK=0
  fi
}

echo ""
printf "${BOLD}[capture-collateral] Copying web screenshots to ${OUT_DIR} ...${RESET}\n"
copy_collateral "library.png"                        "web-home.png"
copy_collateral "offline-study-replayed.png"         "web-offline.png"
copy_collateral "bridge-proof.png"                   "web-bridge-proof.png"

if [ "$COPY_OK" -eq 0 ]; then
  echo "[capture-collateral] ERROR: one or more web screenshots were not produced by Playwright." >&2
  echo "[capture-collateral] Check Playwright output above for failures." >&2
  exit 1
fi

echo ""
printf "${BOLD}[capture-collateral] Web screenshots written (idempotent — re-run overwrites):${RESET}\n"
echo "[capture-collateral]   brandbook/collateral/see-it-run/web-home.png"
echo "[capture-collateral]   brandbook/collateral/see-it-run/web-offline.png"
echo "[capture-collateral]   brandbook/collateral/see-it-run/web-bridge-proof.png"

# ---------------------------------------------------------------------------
# NATIVE CAPTURE — HUMAN-GATED (PRINTED, not executed)
#
# The following commands must be run by the maintainer on a Mac with:
#   - Phase-126 Dev build installed on a booted iOS Simulator
#   - Phase-126 Dev build installed on a running Android Emulator
#   - Both connected to the local backend (bin/see-it-run.sh already running)
#
# Native shots are labeled "emulator evidence" — advisory, not physical device.
# They confirm the dev wiring reaches the local backend, but do NOT prove
# physical-device support, camera support, or App Store readiness.
# ---------------------------------------------------------------------------
if [[ "$WEB_ONLY" == "1" ]]; then
  echo ""
  echo "[capture-collateral] --web-only: skipping native capture instructions."
  echo ""
  exit 0
fi

echo ""
printf "${BOLD}================================================================${RESET}\n"
printf "${BOLD}  Native capture — HUMAN-GATED (emulator evidence)${RESET}\n"
printf "${BOLD}================================================================${RESET}\n"
echo ""
echo "  The following steps must be performed by the maintainer on a Mac"
echo "  with Xcode + Android SDK + the Phase-126 Dev build booted against"
echo "  the local backend (bin/see-it-run.sh running at http://localhost:4700)."
echo ""
echo "  Native screenshots are 'emulator evidence' — advisory only."
echo "  They confirm the dev wiring reaches the local backend but do NOT"
echo "  prove physical-device support."
echo ""
printf "${DIM}--------------------------------------------------------------${RESET}\n"
printf "${BOLD}  Step 1: iOS Simulator screenshot${RESET}\n"
printf "${DIM}--------------------------------------------------------------${RESET}\n"
echo ""
echo "  With the Phase-126 Dev build installed and the iOS Simulator booted:"
echo ""
printf "    xcrun simctl io booted screenshot brandbook/collateral/see-it-run/ios-simulator.png\n"
echo ""
printf "${DIM}--------------------------------------------------------------${RESET}\n"
printf "${BOLD}  Step 2: Android Emulator screenshot${RESET}\n"
printf "${DIM}--------------------------------------------------------------${RESET}\n"
echo ""
echo "  With the Phase-126 Dev build installed and an Android emulator running:"
echo ""
printf "    adb exec-out screencap -p > brandbook/collateral/see-it-run/android-emulator.png\n"
echo ""
printf "${DIM}--------------------------------------------------------------${RESET}\n"
printf "${BOLD}  Step 3: Three-runtime montage${RESET}\n"
printf "${DIM}--------------------------------------------------------------${RESET}\n"
echo ""
echo "  Compose all three screenshots side-by-side (~900px wide, each ~280px)."
echo "  Label each frame: Web (localhost:4700), iOS Simulator (emulator evidence),"
echo "  Android Emulator (emulator evidence)."
echo ""
echo "  Using ImageMagick (recommended):"
echo ""
printf "    convert +append \\\\\n"
printf "      brandbook/collateral/see-it-run/web-home.png \\\\\n"
printf "      brandbook/collateral/see-it-run/ios-simulator.png \\\\\n"
printf "      brandbook/collateral/see-it-run/android-emulator.png \\\\\n"
printf "      brandbook/collateral/see-it-run/three-runtime-montage.png\n"
echo ""
echo "  Or hand-compose in any image editor at ~900px total width."
echo ""
printf "${DIM}--------------------------------------------------------------${RESET}\n"
printf "${BOLD}  Step 4: GIF recording (see-it-run.gif)${RESET}\n"
printf "${DIM}--------------------------------------------------------------${RESET}\n"
echo ""
echo "  Record: terminal running bin/see-it-run.sh → banner output → browser auto-open"
echo "  Target: ~900px wide, 12fps, 10–15 seconds, hard cap 8MB (target < 5MB)"
echo ""
echo "  After recording, optimize with gifsicle:"
echo ""
printf "    gifsicle -O3 --output brandbook/collateral/see-it-run/see-it-run.gif \\\\\n"
printf "                          path/to/raw-recording.gif\n"
echo ""
printf "${DIM}--------------------------------------------------------------${RESET}\n"
printf "${BOLD}  Step 5: Commit the binaries${RESET}\n"
printf "${DIM}--------------------------------------------------------------${RESET}\n"
echo ""
printf "    git add brandbook/collateral/see-it-run/ios-simulator.png\n"
printf "    git add brandbook/collateral/see-it-run/android-emulator.png\n"
printf "    git add brandbook/collateral/see-it-run/three-runtime-montage.png\n"
printf "    git add brandbook/collateral/see-it-run/see-it-run.gif\n"
printf "    git commit -m 'chore: add See It Run native collateral (emulator evidence)'\n"
echo ""
printf "${BOLD}================================================================${RESET}\n"
echo ""
echo "[capture-collateral] Done. Web screenshots are ready."
echo "[capture-collateral] Native emulator evidence requires the human-gated steps above."
echo ""

exit 0
