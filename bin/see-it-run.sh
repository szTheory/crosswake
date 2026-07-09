#!/usr/bin/env bash
set -euo pipefail

# Crosswake "See It Run" launcher — one command to boot the demo backend,
# print a plain-ASCII brand-voiced banner, and advisorily launch the iOS
# simulator / Android emulator when the toolchain is present.
#
# Exit codes (D-17):
#   0 = backend serving + banner printed (native outcomes never change this)
#   1 = backend boot failure (Docker absent/daemon down, readiness timeout)
#
# Usage: bin/see-it-run.sh [--web-only] [--ios] [--android] [--all] [--build] [--no-open] [--help]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_URL="http://localhost:4700"
JAVA_HOME_17="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home}"

# ---------------------------------------------------------------------------
# Flag parser (D-12/D-14/D-19)
# ---------------------------------------------------------------------------
WEB_ONLY=0
IOS_ONLY=0
ANDROID_ONLY=0
DO_BUILD=0
NO_OPEN=0
SHOW_HELP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --web-only)   WEB_ONLY=1; shift ;;
    --ios)        IOS_ONLY=1; shift ;;
    --android)    ANDROID_ONLY=1; shift ;;
    --all)        IOS_ONLY=0; ANDROID_ONLY=0; shift ;;  # default: both platforms
    --build)      DO_BUILD=1; shift ;;
    --no-open)    NO_OPEN=1; shift ;;
    --help|-h)    SHOW_HELP=1; shift ;;
    *)
      echo "[crosswake] Unknown flag: $1" >&2
      echo "[crosswake] Run 'bin/see-it-run.sh --help' for usage." >&2
      exit 1
      ;;
  esac
done

if [[ "$SHOW_HELP" == "1" ]]; then
  cat <<'USAGE'
[crosswake] bin/see-it-run.sh — Crosswake one-command launcher

Usage: bin/see-it-run.sh [options]

Options:
  --web-only    Skip all native platform launch (web only)
  --ios         Force iOS simulator launch (skip Android)
  --android     Force Android emulator launch (skip iOS)
  --all         Launch both iOS and Android (default when toolchains present)
  --build       Opt into full slow build path (xcodebuild / gradlew installDevDebug)
  --no-open     Skip auto-opening http://localhost:4700 in the browser
  --help, -h    Print this help and exit 0

Exit codes:
  0 = backend serving + banner printed
  1 = backend boot failure (Docker absent, daemon down, or readiness timeout)

Native outcomes never change the exit code.
USAGE
  exit 0
fi

# ---------------------------------------------------------------------------
# Interrupt trap (D-20) — compose is detached; Ctrl-C leaves backend running
# ---------------------------------------------------------------------------
trap 'echo ""; echo "[crosswake] Interrupted. The backend is still running (it was started detached)."; echo "[crosswake] To stop it: docker compose -f examples/phoenix_host/docker-compose.yml down"; exit 0' INT TERM

# ---------------------------------------------------------------------------
# ANSI color helpers — progressive enhancement (D-02)
# Color never carries meaning; plain-text is byte-identical when stripped.
# ---------------------------------------------------------------------------
BOLD="" DIM="" RESET="" ACCENT=""
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ -z "${CI:-}" ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  RESET="\033[0m"
  ACCENT="\033[36m"  # cyan — single accent, no meaning
fi

# ---------------------------------------------------------------------------
# Task 1: Backend boot/reuse orchestration with curl readiness poll
# ---------------------------------------------------------------------------

# D-09 — Reuse probe FIRST: if something is already serving :4700, skip boot
if curl -sf "${BACKEND_URL}/" >/dev/null 2>&1; then
  echo "[crosswake] Port 4700 is already serving — reusing it."
else
  # D-11 — Check Docker is present and daemon is running
  if ! command -v docker >/dev/null 2>&1; then
    echo "[crosswake] Docker is not installed on this machine."
    echo "[crosswake] The Docker backend is required to boot the Crosswake demo without Elixir."
    echo "[crosswake] Install Docker Desktop: https://docs.docker.com/get-docker/"
    echo "[crosswake] Or start the backend natively: cd examples/phoenix_host && PORT=4700 mix phx.server"
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    echo "[crosswake] Docker is installed but the Docker daemon is not running."
    echo "[crosswake] The Crosswake demo backend runs as a Docker container."
    echo "[crosswake] Start Docker Desktop, wait for it to say 'Docker Desktop is running', then retry."
    echo "[crosswake] Or start the backend natively: cd examples/phoenix_host && PORT=4700 mix phx.server"
    exit 1
  fi

  # D-09 — Inspect compose ps to distinguish first-boot vs crashed container
  compose_ps="$(cd "${ROOT_DIR}" && docker compose -f examples/phoenix_host/docker-compose.yml ps --format json 2>/dev/null || true)"
  if echo "${compose_ps}" | grep -qi '"State":"exited"' 2>/dev/null || \
     echo "${compose_ps}" | grep -qi '"State":"dead"' 2>/dev/null; then
    echo "[crosswake] Previous container exited. Restarting ..."
  elif [ -z "${compose_ps}" ] || echo "${compose_ps}" | grep -q '^\[\]$' 2>/dev/null || \
       ! echo "${compose_ps}" | grep -q '"State"' 2>/dev/null; then
    echo "[crosswake] First boot — compiling deps and migrating DB (~1-2 min). Hang tight ..."
  fi

  # D-07 — Detached boot (always from repo root so build.context resolves correctly)
  (cd "${ROOT_DIR}" && docker compose -f examples/phoenix_host/docker-compose.yml up -d)

  echo "[crosswake] Waiting for backend on ${BACKEND_URL} ..."

  # D-08 — Readiness poll: loop curl with 2s sleep, hard cap ~120s (60 iterations)
  READY=0
  for i in $(seq 1 60); do
    if curl -sf "${BACKEND_URL}/" >/dev/null 2>&1; then
      READY=1
      break
    fi
    printf "."
    sleep 2
  done
  echo ""  # newline after dots

  if [ "$READY" -eq 0 ]; then
    echo "[crosswake] Backend did not become ready within ~120 seconds."
    echo "[crosswake] Check the container logs for errors:"
    echo "[crosswake]   docker compose -f examples/phoenix_host/docker-compose.yml logs"
    echo "[crosswake] If this is a first boot, deps compilation may need more time. Retry once logs show 'Access CrosswakeExample.Endpoint'."
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Task 2: Plain-ASCII brand-voiced banner (D-02/D-04/D-05/D-06)
# ---------------------------------------------------------------------------
print_banner() {
  printf "${BOLD}================================================================${RESET}\n"
  printf "${BOLD}  Crosswake showcase backend is running${RESET}\n"
  printf "${BOLD}================================================================${RESET}\n"
  printf "\n"
  printf "  Open the showcase hub:\n"
  printf "    ${ACCENT}${BOLD}http://localhost:4700/${RESET}\n"
  printf "\n"
  printf "  The root route is the product-shaped showcase for Crosswake:\n"
  printf "    /              showcase hub (LiveView, cached read-only)\n"
  printf "\n"
  printf "  Proof routes stay one click deeper (secondary):\n"
  printf "    /offline       app-owned offline island\n"
  printf "    /bridge-proof  LiveView + bounded Share\n"
  printf "    /native/claims native-pressure route list\n"
  printf "\n"
  printf '%s\n' "----------------------------------------------------------------"
  printf "  What is proven now (no extra toolchain required)\n"
  printf '%s\n' "----------------------------------------------------------------"
  printf "\n"
  printf "  - Backend boots from Docker (this script) or native mix phx.server\n"
  printf "  - Showcase and proof routes reachable in any browser\n"
  printf "  - Route-tour assertions prove route-owner semantics; screenshots are collateral\n"
  printf "  - Offline replay proof: npx playwright test (examples/phoenix_host/e2e/)\n"
  printf "  - Bounded bridge proof: script/verify_bounded_bridge_proof.sh\n"
  printf "\n"
  printf "  Advisory native (needs Xcode / Android SDK):\n"
  printf "  A successful simulator or emulator run confirms the dev wiring reaches\n"
  printf "  the local backend, but does not prove physical-device support.\n"
  printf "  Native sim/emulator evidence is advisory; it is not a proven native build.\n"
  printf "\n"
  printf "================================================================\n"
  printf "  Per-runtime next commands\n"
  printf "================================================================\n"
  printf "\n"
  printf "  Web:\n"
  printf "    open %s\n" "${BACKEND_URL}"
  printf "\n"
  printf "  iOS Simulator (select 'Dev' scheme in Xcode, or run):\n"
  printf "\n"
  printf "    xcodebuild \\\\\n"
  printf "      -project examples/ios_shell_host/CrosswakeShell.xcodeproj \\\\\n"
  printf "      -scheme Dev \\\\\n"
  printf "      -configuration Debug-Dev \\\\\n"
  printf "      -destination 'platform=iOS Simulator,name=iPhone 16' \\\\\n"
  printf "      build\n"
  printf "\n"
  printf "  Android Emulator:\n"
  printf "\n"
  printf "    cd examples/android_shell_host\n"
  printf "    JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug\n"
  printf "    adb shell am start -n dev.crosswake.shell.dev/.MainActivity\n"
  printf "\n"
  printf '%s\n' "----------------------------------------------------------------"
  printf "  Stop the backend when done:\n"
  printf "\n"
  printf "    docker compose -f examples/phoenix_host/docker-compose.yml down\n"
  printf "\n"
  printf "  Follow live logs:\n"
  printf "\n"
  printf "    docker compose -f examples/phoenix_host/docker-compose.yml logs -f\n"
  printf "\n"
  printf "  Full guide: guides/see_it_run.md\n"
  printf '%s\n' "----------------------------------------------------------------"
}

print_banner

# ---------------------------------------------------------------------------
# Task 3: Web auto-open (D-19)
# ---------------------------------------------------------------------------
if [ "$NO_OPEN" -eq 0 ] && [ -t 1 ] && [ -z "${CI:-}" ] && [ -z "${NO_OPEN:-}" ]; then
  if command -v open >/dev/null 2>&1; then
    open "${BACKEND_URL}/" || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${BACKEND_URL}/" || true
  fi
fi

# ---------------------------------------------------------------------------
# Task 3: Advisory native launch (D-12/D-14/D-15/D-16)
# Suppressed when: --web-only, CI set, stdout not a TTY
# ---------------------------------------------------------------------------
maybe_launch_native() {
  # Suppress all native when --web-only, CI, or not a TTY (D-14)
  if [ "$WEB_ONLY" -eq 1 ] || [ -n "${CI:-}" ] || ! [ -t 1 ]; then
    return 0
  fi

  # Determine which platforms to attempt
  local do_ios=1
  local do_android=1
  if [ "$IOS_ONLY" -eq 1 ]; then
    do_android=0
  elif [ "$ANDROID_ONLY" -eq 1 ]; then
    do_ios=0
  fi

  # --- iOS advisory launch (macOS only, D-13/D-15) ---
  if [ "$do_ios" -eq 1 ]; then
    if command -v xcrun >/dev/null 2>&1 && command -v xcodebuild >/dev/null 2>&1; then
      echo ""
      echo "[crosswake] iOS toolchain detected. Booting simulator ..."

      # Discover first available iPhone simulator via simctl list
      local sim_udid=""
      sim_udid="$(xcrun simctl list devices available 2>/dev/null | \
        grep -E 'iPhone' | \
        grep -E '\(([0-9A-F-]{36})\)' | \
        head -1 | \
        grep -oE '[0-9A-F-]{36}' || true)"

      if [ -n "${sim_udid}" ]; then
        xcrun simctl boot "${sim_udid}" >/dev/null 2>&1 || true
        open -a Simulator --args -CurrentDeviceUDID "${sim_udid}" >/dev/null 2>&1 || true
        echo "[crosswake] iOS Simulator booted. To build and install the Dev variant:"
      else
        echo "[crosswake] No available iPhone simulator found. To build and install the Dev variant:"
      fi

      if [ "$DO_BUILD" -eq 1 ]; then
        echo "[crosswake] Running full Dev build (this may take a few minutes) ..."
        xcodebuild \
          -project "${ROOT_DIR}/examples/ios_shell_host/CrosswakeShell.xcodeproj" \
          -scheme Dev \
          -configuration Debug-Dev \
          -destination 'platform=iOS Simulator,name=iPhone 16' \
          build || true
      else
        printf "    xcodebuild \\\\\n"
        printf "      -project examples/ios_shell_host/CrosswakeShell.xcodeproj \\\\\n"
        printf "      -scheme Dev \\\\\n"
        printf "      -configuration Debug-Dev \\\\\n"
        printf "      -destination 'platform=iOS Simulator,name=iPhone 16' \\\\\n"
        printf "      build\n"
      fi
    else
      # Calm 4-line guidance when Xcode toolchain absent (D-18)
      echo ""
      echo "[crosswake] Xcode toolchain (xcrun / xcodebuild) not found on this machine."
      echo "[crosswake] iOS simulator launch is advisory and requires Xcode installed from the Mac App Store."
      echo "[crosswake] Install Xcode: https://developer.apple.com/xcode/ then run 'xcode-select --install'."
      echo "[crosswake] The web backend is running and fully usable without iOS tooling."
    fi
  fi

  # --- Android advisory launch (D-13/D-15) ---
  if [ "$do_android" -eq 1 ]; then
    local java_exec="${JAVA_HOME_17}/bin/java"
    local gradlew="${ROOT_DIR}/examples/android_shell_host/gradlew"

    if command -v adb >/dev/null 2>&1 && \
       [ -f "${gradlew}" ] && \
       [[ -x "${java_exec}" ]]; then

      echo ""
      echo "[crosswake] Android toolchain detected. Checking for running emulator ..."

      # Check for running emulator
      local emulator_running=0
      if adb devices 2>/dev/null | grep -q "emulator"; then
        emulator_running=1
      fi

      if [ "$emulator_running" -eq 1 ]; then
        echo "[crosswake] Android emulator detected."

        if [ "$DO_BUILD" -eq 1 ]; then
          echo "[crosswake] Running full Dev install (this may take a few minutes) ..."
          (
            cd "${ROOT_DIR}/examples/android_shell_host"
            JAVA_HOME="/opt/homebrew/opt/openjdk@17" ./gradlew installDevDebug || true
          )
          adb shell am start -n dev.crosswake.shell.dev/.MainActivity || true
        else
          echo "[crosswake] To install and launch the Dev variant:"
          printf "    cd examples/android_shell_host\n"
          printf "    JAVA_HOME=/opt/homebrew/opt/openjdk@17 ./gradlew installDevDebug\n"
          printf "    adb shell am start -n dev.crosswake.shell.dev/.MainActivity\n"
        fi
      else
        # No emulator running — print calm guidance (D-15/D-18), no AVD creation
        echo ""
        echo "[crosswake] No running Android emulator found (adb devices shows none)."
        echo "[crosswake] An Android emulator is needed to install and run the Dev variant."
        echo "[crosswake] Start an emulator in Android Studio (AVD Manager) or run: emulator @<your-avd-name>"
        echo "[crosswake]   JAVA_HOME=/opt/homebrew/opt/openjdk@17 must be set. The web backend works without Android tooling."
      fi
    else
      # Calm 4-line guidance when Android toolchain absent (D-18)
      echo ""
      echo "[crosswake] Android toolchain (adb / gradlew / JDK 17) not found or not configured."
      echo "[crosswake] Android emulator launch is advisory and requires adb, Android SDK, and JDK 17."
      echo "[crosswake] Install Android Studio: https://developer.android.com/studio — set JAVA_HOME=/opt/homebrew/opt/openjdk@17"
      echo "[crosswake] The web backend is running and fully usable without Android tooling."
    fi
  fi
}

maybe_launch_native

# ---------------------------------------------------------------------------
# Success (D-17: exit 0 = backend serving + banner printed)
# ---------------------------------------------------------------------------
exit 0
