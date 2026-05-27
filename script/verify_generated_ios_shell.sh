#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT_INPUT="${CROSSWAKE_IOS_PROJECT_ROOT:-}"
PROJECT_ROOT=""
TMPDIR_ROOT=""
DERIVED_DATA_ROOT=""
SCHEME="${CROSSWAKE_IOS_SCHEME:-CrosswakeShell}"
BUNDLE_ID=""

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is required for iOS shell verification" >&2
  exit 1
fi

cleanup() {
  [[ -n "${TMPDIR_ROOT}" ]] && rm -rf "${TMPDIR_ROOT}"
  [[ -n "${DERIVED_DATA_ROOT}" ]] && rm -rf "${DERIVED_DATA_ROOT}"
}
trap cleanup EXIT

if [[ -n "${PROJECT_ROOT_INPUT}" ]]; then
  PROJECT_ROOT="$(cd "${ROOT_DIR}" && cd "${PROJECT_ROOT_INPUT}" && pwd)"
else
  TMPDIR_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-ios-shell.XXXXXX")"
  cd "${ROOT_DIR}"
  mix crosswake.gen.shell ios --target "${TMPDIR_ROOT}" >/dev/null
  PROJECT_ROOT="${TMPDIR_ROOT}/native/ios/crosswake_shell"
fi

DERIVED_DATA_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-ios-derived.XXXXXX")"

project="${PROJECT_ROOT}/CrosswakeShell.xcodeproj"
scheme="${SCHEME}"

project_check="$(xcodebuild -list -project "$project" 2>&1)" || {
  echo "error: generated scheme is not buildable via xcodebuild -list" >&2
  printf '%s\n' "$project_check" >&2
  exit 1
}

destinations="$(xcodebuild -project "$project" -scheme "$scheme" -showdestinations 2>&1)"

if ! printf '%s\n' "$destinations" | grep -q "platform:iOS Simulator.*name:iPhone"; then
  echo "No concrete iPhone simulator destination found; downloading iOS simulator platform..." >&2
  xcodebuild -downloadPlatform iOS || {
    echo "warning: iOS simulator platform download failed; retrying with currently available destinations" >&2
  }
  destinations="$(xcodebuild -project "$project" -scheme "$scheme" -showdestinations 2>&1)"
fi

destination_name="$(printf '%s\n' "$destinations" | awk '
  /platform:iOS Simulator/ && /name:iPhone/ {
    line = $0
    if (match(line, /name:[^,}]+/)) {
      name = substr(line, RSTART + 5, RLENGTH - 5)
      gsub(/^ +| +$/, "", name)
      print name
      exit
    }
  }
')"

destination_os="$(printf '%s\n' "$destinations" | awk '
  /platform:iOS Simulator/ && /name:iPhone/ {
    line = $0
    if (match(line, /OS:[^,}]+/)) {
      os = substr(line, RSTART + 3, RLENGTH - 3)
      gsub(/^ +| +$/, "", os)
      print os
      exit
    }
  }
')"

destination_id="$(printf '%s\n' "$destinations" | awk '
  /platform:iOS Simulator/ && /name:iPhone/ {
    line = $0
    if (match(line, /id:[^,}]+/)) {
      id = substr(line, RSTART + 3, RLENGTH - 3)
      gsub(/^ +| +$/, "", id)
      print id
      exit
    }
  }
')"

if [[ -z "$destination_name" ]]; then
  echo "error: no iPhone simulator destination found for generated shell" >&2
  printf '%s\n' "$destinations" >&2
  exit 1
fi

if [[ -z "$destination_id" ]]; then
  echo "error: no concrete iPhone simulator id found for generated shell" >&2
  printf '%s\n' "$destinations" >&2
  exit 1
fi

if command -v xcrun >/dev/null 2>&1; then
  xcrun simctl boot "$destination_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$destination_id" -b
  open -a Simulator --args -CurrentDeviceUDID "$destination_id" >/dev/null 2>&1 || true
fi

destination="platform=iOS Simulator,id=$destination_id"

if [[ -n "$destination_os" ]]; then
  destination="$destination,OS=$destination_os"
fi

app_path="${DERIVED_DATA_ROOT}/Build/Products/Debug-iphonesimulator/${scheme}.app"

# `xcodebuild test` currently relies on Apple's simulator test launcher, which can
# fail before test execution starts on hosts where pseudo-terminal setup is unavailable.
# Phase 5's proof goal is the public install path, so this lane proves the built shell
# can be produced, installed, and launched in a real simulator.
xcodebuild \
  -project "$project" \
  -scheme "$scheme" \
  -destination "$destination" \
  -derivedDataPath "$DERIVED_DATA_ROOT" \
  build-for-testing

if [[ ! -d "$app_path" ]]; then
  echo "error: expected built iOS shell at $app_path" >&2
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${app_path}/Info.plist" 2>/dev/null || true)"

if [[ -z "$BUNDLE_ID" ]]; then
  echo "error: could not resolve bundle identifier for built iOS shell" >&2
  exit 1
fi

xcrun simctl uninstall "$destination_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$destination_id" "$app_path"
launch_output="$(xcrun simctl launch "$destination_id" "$BUNDLE_ID" 2>&1)" || {
  echo "error: built iOS shell failed to launch in simulator" >&2
  printf '%s\n' "$launch_output" >&2
  exit 1
}

printf '%s\n' "$launch_output"
sleep 2
xcrun simctl terminate "$destination_id" "$BUNDLE_ID" >/dev/null 2>&1 || true
