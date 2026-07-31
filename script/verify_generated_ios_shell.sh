#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT_INPUT="${CROSSWAKE_IOS_PROJECT_ROOT:-}"
PROJECT_ROOT=""
TMPDIR_ROOT=""
DERIVED_DATA_ROOT=""
SCHEME="${CROSSWAKE_IOS_SCHEME:-CrosswakeShell}"
XCODEBUILD="${CROSSWAKE_IOS_XCODEBUILD_BIN:-xcodebuild}"
BUILD_FOR_TESTING="${CROSSWAKE_IOS_BUILD_FOR_TESTING:-1}"
LAUNCH_SIMULATOR="${CROSSWAKE_IOS_LAUNCH_SIMULATOR:-1}"
BUNDLE_ID=""
PROOF_LANE=0

if [[ "${1:-}" == "--proof-lane" ]]; then
  PROOF_LANE=1
  shift
fi

emit_proof_outcome() {
  local outcome="$1"
  local rule_id="$2"
  local scope="$3"
  printf '{"outcome":"%s","rule_id":"%s","scope":"%s"}\n' "$outcome" "$rule_id" "$scope"
}

if ! command -v "$XCODEBUILD" >/dev/null 2>&1; then
  if [[ "$PROOF_LANE" == "1" ]]; then
    emit_proof_outcome "unavailable" "PL-IOS-XCODEBUILD" "generated-proof-targets"
    exit 3
  fi
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
  TMPDIR_ROOT="$(cd "${TMPDIR_ROOT}" && pwd -P)"
  cd "${ROOT_DIR}"
  if [[ "$PROOF_LANE" == "1" ]]; then
    CROSSWAKE_PROOF_LANE_TARGET="${TMPDIR_ROOT}" mix run -e '
      root = System.fetch_env!("CROSSWAKE_PROOF_LANE_TARGET")
      Application.put_env(:crosswake, :proof_lane,
        route_id: "route-0123456789abcdef", route_path: "/study/:id",
        indexed_db_database: "proof_lane", indexed_db_store: "mutations",
        mutation_id_path: "client_mutation_id", sync_path: "/study/sync",
        evidence_path: "/_proof/evidence", router: CrosswakeWeb.Router,
        ios_shell_root: Path.join(root, "native/ios"))
      Mix.Tasks.Crosswake.Gen.ProofLane.run(["ios"])
    ' >/dev/null
    PROJECT_ROOT="${TMPDIR_ROOT}/native/ios"
  else
    mix crosswake.gen.shell ios --target "${TMPDIR_ROOT}" >/dev/null
    PROJECT_ROOT="${TMPDIR_ROOT}/native/ios/crosswake_shell"
  fi
fi

DERIVED_DATA_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-ios-derived.XXXXXX")"

if [[ "$PROOF_LANE" == "1" ]]; then
  project="${PROJECT_ROOT}/CrosswakeProofLane.xcodeproj"
  scheme="CrosswakeProofLane"
else
  project="${PROJECT_ROOT}/CrosswakeShell.xcodeproj"
  scheme="${SCHEME}"
fi

# Hermetic release-PR resolution: the checked-in host pins the remote SwiftPM
# package at the CURRENT version, which isn't tagged on the remote mirror until the
# release PR merges. When CROSSWAKE_IOS_USE_LOCAL_CORE=1, redirect the remote URL to a
# locally-tagged clone of packages/crosswake-shell-core-ios via a SwiftPM mirror
# (~/.swiftpm/configuration/mirrors.json, honored by xcodebuild) — no pbxproj edit, so
# the checked-in remote ref stays intact for the native-evidence drift guards.
if [[ "${CROSSWAKE_IOS_USE_LOCAL_CORE:-0}" == "1" ]]; then
  ios_core_remote="https://github.com/szTheory/crosswake-shell-core-ios.git"
  ios_core_version="$(sed -n 's/.*minimumVersion = \([0-9][0-9.]*\);.*/\1/p' "${project}/project.pbxproj" | head -1)"
  # Keep the throwaway clone off /var/folders — xcodebuild's package resolution can't reliably
  # read mktemp paths there (CI showed the mirror tags present yet "no versions match", i.e.
  # the redirect target was unreadable/unhonored). RUNNER_TEMP (/Users/runner/work/_temp) is
  # accessible on CI; fall back to a workspace dir locally.
  ios_core_clone="${RUNNER_TEMP:-${ROOT_DIR}/tmp}/crosswake-ios-core-hermetic"
  # The package is a regular subtree of the monorepo (not a submodule/standalone repo), so a
  # fresh CI checkout has no .git here — build a throwaway git repo from the files so SwiftPM
  # can resolve a version tag from it (git clone of a non-repo path fails: phase18 hermetic).
  rm -rf "${ios_core_clone}"
  mkdir -p "${ios_core_clone}"
  cp -R "${ROOT_DIR}/packages/crosswake-shell-core-ios/." "${ios_core_clone}/"
  rm -rf "${ios_core_clone}/.git"
  git -C "${ios_core_clone}" -c init.defaultBranch=main init -q
  git -C "${ios_core_clone}" -c user.email=ci@crosswake -c user.name=ci add -A
  git -C "${ios_core_clone}" -c user.email=ci@crosswake -c user.name=ci commit -q -m "hermetic ${ios_core_version}"
  # Lightweight tags (no -m) — most broadly recognized by SwiftPM's version resolver.
  git -C "${ios_core_clone}" tag -f "${ios_core_version}"
  git -C "${ios_core_clone}" tag -f "v${ios_core_version}"
  # Redirect at the GIT layer (insteadOf, honored by SwiftPM which shells out to git) — more
  # robust than the SwiftPM mirror config, which CI's xcodebuild ignored. Keep the SwiftPM
  # mirror too as a belt-and-suspenders second mechanism.
  git config --global "url.${ios_core_clone}.insteadOf" "${ios_core_remote}"
  mirror_dir="${HOME}/.swiftpm/configuration"
  mkdir -p "${mirror_dir}"
  cat > "${mirror_dir}/mirrors.json" <<JSON
{
  "object" : [
    {
      "mirror" : "${ios_core_clone}",
      "original" : "${ios_core_remote}"
    }
  ],
  "version" : 1
}
JSON
  echo "hermetic: redirected ${ios_core_remote} -> ${ios_core_clone} @ ${ios_core_version}"
  echo "hermetic-debug: mirror tags = [$(git -C "${ios_core_clone}" tag | tr '\n' ' ')]"
  echo "hermetic-debug: git insteadOf = $(git config --global --get "url.${ios_core_clone}.insteadOf")"
fi

# Force a clean SwiftPM package cache so resolution reads the mirror's tags fresh
# (avoids any stale "no versions" cache keyed on the original URL). Harmless for the
# non-hermetic generated-shell path. Unconditional to avoid empty-array expansion
# under `set -u` on macOS bash 3.2.
IOS_SPM_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-ios-spm.XXXXXX")"

project_check="$("$XCODEBUILD" -list -project "$project" -clonedSourcePackagesDirPath "${IOS_SPM_CACHE}" 2>&1)" || {
  if [[ "$PROOF_LANE" == "1" ]]; then
    emit_proof_outcome "unavailable" "PL-IOS-TARGET-ENUMERATION" "generated-target-graph"
    exit 3
  fi
  echo "error: generated scheme is not buildable via xcodebuild -list" >&2
  printf '%s\n' "$project_check" >&2
  exit 1
}

if [[ "$PROOF_LANE" == "1" ]]; then
  for target in CrosswakeProofLaneTests CrosswakeProofLaneUITests; do
    if ! printf '%s\n' "$project_check" | grep -q "$target"; then
      emit_proof_outcome "blocked" "PL-IOS-REQUIRED-TARGET" "generated-target-graph"
      exit 2
    fi
  done

  if ! "$XCODEBUILD" -project "$project" -scheme "$scheme" -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED_DATA_ROOT" build-for-testing >/dev/null 2>&1; then
    emit_proof_outcome "blocked" "PL-IOS-BUILD-FOR-TESTING" "generated-proof-targets"
    exit 2
  fi

  emit_proof_outcome "passed" "PL-IOS-BUILD-FOR-TESTING" "generated-proof-targets"
  exit 0
fi

if [[ "$BUILD_FOR_TESTING" != "1" ]]; then
  exit 0
fi

destinations="$("$XCODEBUILD" -project "$project" -scheme "$scheme" -showdestinations 2>&1)"

if [[ "$LAUNCH_SIMULATOR" == "1" ]] && ! printf '%s\n' "$destinations" | grep -q "platform:iOS Simulator.*name:iPhone"; then
  if command -v xcrun >/dev/null 2>&1; then
    runtime_id="$(xcrun simctl list runtimes available 2>/dev/null | awk '
      /iOS/ && /com.apple.CoreSimulator.SimRuntime.iOS/ {
        if (match($0, /com\.apple\.CoreSimulator\.SimRuntime\.iOS-[^ )]+/)) {
          print substr($0, RSTART, RLENGTH)
          exit
        }
      }
    ' || true)"

    if [[ -n "${runtime_id:-}" ]]; then
      xcrun simctl create "Crosswake CI iPhone" \
        "com.apple.CoreSimulator.SimDeviceType.iPhone-16" \
        "$runtime_id" >/dev/null 2>&1 || true
      destinations="$("$XCODEBUILD" -project "$project" -scheme "$scheme" -showdestinations 2>&1)"
    fi
  fi
fi

if [[ "$LAUNCH_SIMULATOR" == "1" ]] && ! printf '%s\n' "$destinations" | grep -q "platform:iOS Simulator.*name:iPhone"; then
  echo "No concrete iPhone simulator destination found; downloading iOS simulator platform..." >&2
  xcodebuild -downloadPlatform iOS || {
    echo "warning: iOS simulator platform download failed; retrying with currently available destinations" >&2
  }
  destinations="$("$XCODEBUILD" -project "$project" -scheme "$scheme" -showdestinations 2>&1)"
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

if [[ -z "$destination_name" && "$LAUNCH_SIMULATOR" == "1" ]]; then
  echo "error: no iPhone simulator destination found for generated shell" >&2
  printf '%s\n' "$destinations" >&2
  exit 1
fi

if [[ -z "$destination_id" && "$LAUNCH_SIMULATOR" == "1" ]]; then
  echo "error: no concrete iPhone simulator id found for generated shell" >&2
  printf '%s\n' "$destinations" >&2
  exit 1
fi

if [[ "$LAUNCH_SIMULATOR" == "1" ]] && command -v xcrun >/dev/null 2>&1; then
  xcrun simctl boot "$destination_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$destination_id" -b
  open -a Simulator --args -CurrentDeviceUDID "$destination_id" >/dev/null 2>&1 || true
fi

if [[ -n "$destination_id" ]]; then
  destination="platform=iOS Simulator,id=$destination_id"
else
  destination="generic/platform=iOS Simulator"
fi

if [[ -n "$destination_os" && -n "$destination_id" ]]; then
  destination="$destination,OS=$destination_os"
fi

app_path="${DERIVED_DATA_ROOT}/Build/Products/Debug-iphonesimulator/${scheme}.app"

# `xcodebuild test` currently relies on Apple's simulator test launcher, which can
# fail before test execution starts on hosts where pseudo-terminal setup is unavailable.
# Phase 5's proof goal is the public install path, so this lane proves the built shell
# can be produced, installed, and launched in a real simulator.
"$XCODEBUILD" \
  -project "$project" \
  -scheme "$scheme" \
  -destination "$destination" \
  -derivedDataPath "$DERIVED_DATA_ROOT" \
  build-for-testing

if [[ ! -d "$app_path" ]]; then
  echo "error: expected built iOS shell at $app_path" >&2
  exit 1
fi

if [[ "$LAUNCH_SIMULATOR" != "1" ]]; then
  exit 0
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
