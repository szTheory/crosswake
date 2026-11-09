#!/usr/bin/env bash
# Pre-release build gate for the default-generated iOS project.
#
# usage: script/verify_default_ios_generation_build.sh
#          [--source-root DIR | --project-root DIR] [--remote-version X.Y.Z]
#
# Why this exists: 0.2.12 shipped a default `mix crosswake.gen.shell ios` project that
# referenced a settings file the generator never wrote. Only the post-publish clean-room
# built that project, after Hex, Maven and the mirror were already public. This gate builds
# both default forms before anything is published.
#
# Forms:
#   local (no --remote-version)   generates with `--local` (the candidate's own Swift package).
#                                 This is what CI runs.
#   remote (--remote-version V)   generates the no-flag form (the form the post-publish
#                                 clean-room builds), rewrites ONLY the scratch copy's
#                                 `minimumVersion` to V (a version already on the public
#                                 mirror) and builds against that public core. It needs
#                                 network and is a release-time rehearsal, never run in CI.
#                                 `upToNextMajorVersion` resolves the newest 0.x tag, so V
#                                 must be the newest mirror tag or `resolved` will differ.
#
# Every PASS needs an in-run negative control: the same project with
# CrosswakeHostSettings.xcconfig deleted must fail the same build with the
# missing-base-configuration error. In remote mode PASS also needs the resolved core
# version parsed from the build log and equal to V.
#
# Nothing outside the script's own work root is written (the source root's own build
# directory is the one effect of running its generator). A project given with
# --project-root is copied and never modified.
#
# Exactly one verdict line is printed last on stdout; exit 0 PASS, 1 FAIL, 2 ERROR.
set -euo pipefail

SELF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
XCODEBUILD="${CROSSWAKE_IOS_XCODEBUILD_BIN:-xcodebuild}"
SETTINGS_FILE="CrosswakeHostSettings.xcconfig"

SOURCE_ROOT_ARG=""
PROJECT_ROOT_ARG=""
REMOTE_VERSION=""

MODE="local"
PROJECT_KIND="generated"
GENERATOR="-"
GENERATOR_DIRTY="-"
REMOTE_FROM="-"
REMOTE_MIN="-"
RESOLVED="-"
BUILD_RC="-"
BUILD_SECONDS="-"
CONTROL_RC="-"
CONTROL="skipped"
FIRST_ERROR="none"

WORK=""
SOURCE_ROOT=""
PROJECT_GIVEN=""
ERR_LOG=""

cleanup() {
  if [ -n "${WORK}" ] && [ -d "${WORK}" ]; then
    rm -rf "${WORK}"
  fi
  return 0
}
trap cleanup EXIT

# Replace a root (in the given and the `cd -P` resolved form) with a label.
scrub_root() {
  local text="$1" root="$2" label="$3" resolved=""
  if [ -z "$root" ]; then
    printf '%s' "$text"
    return 0
  fi
  if [ -d "$root" ]; then
    resolved="$(cd -P "$root" && pwd -P)"
  fi
  text="${text//"$root"/$label}"
  if [ -n "$resolved" ] && [ "$resolved" != "$root" ]; then
    text="${text//"$resolved"/$label}"
  fi
  printf '%s' "$text"
}

scrub() {
  local text="$1"
  text="$(scrub_root "$text" "$WORK" "<work>")"
  text="$(scrub_root "$text" "$PROJECT_GIVEN" "<project>")"
  text="$(scrub_root "$text" "$SOURCE_ROOT" "<source>")"
  if [ -n "${HOME:-}" ]; then
    text="${text//"$HOME"/<home>}"
  fi
  printf '%s' "$text"
}

# first `error:` line of a log, scrubbed, one line, bounded
first_error_of() {
  local log="$1" line=""
  if [ -f "$log" ]; then
    line="$(grep -m1 'error:' "$log" || true)"
  fi
  if [ -z "$line" ]; then
    printf 'none'
    return 0
  fi
  line="$(scrub "$line")"
  line="${line//$'\r'/}"
  printf '%.600s' "$line"
}

print_tail() {
  local log="$1" text=""
  if [ -f "$log" ]; then
    text="$(tail -n 40 "$log" || true)"
    scrub "$text" >&2
    printf '\n' >&2
  fi
}

# finish PASS|FAIL|ERROR [reason]
finish() {
  local kind="$1" reason="${2:-}" verdict rc
  case "$kind" in
    PASS) verdict="PASS"; rc=0 ;;
    FAIL) verdict="FAIL reason=${reason}"; rc=1 ;;
    *) verdict="ERROR reason=${reason}"; rc=2 ;;
  esac
  if [ "$kind" != "PASS" ] && [ -n "$ERR_LOG" ]; then
    FIRST_ERROR="$(first_error_of "$ERR_LOG")"
    if [ "$kind" = "FAIL" ]; then
      print_tail "$ERR_LOG"
    fi
  fi
  printf 'default-ios-build: mode=%s project=%s generator=%s generator_dirty=%s remote_from=%s remote_min=%s resolved=%s build_rc=%s build_seconds=%s control_rc=%s control=%s verdict=%s first_error=%s\n' \
    "$MODE" "$PROJECT_KIND" "$GENERATOR" "$GENERATOR_DIRTY" "$REMOTE_FROM" "$REMOTE_MIN" "$RESOLVED" \
    "$BUILD_RC" "$BUILD_SECONDS" "$CONTROL_RC" "$CONTROL" "$verdict" "$FIRST_ERROR"
  trap - EXIT
  cleanup
  exit "$rc"
}

note() {
  printf 'default-ios-build: %s\n' "$*" >&2
}

# ---- arguments ---------------------------------------------------------------------------

BAD_USAGE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --source-root)
      if [ "$#" -lt 2 ]; then BAD_USAGE=1; break; fi
      SOURCE_ROOT_ARG="$2"; shift 2 ;;
    --project-root)
      if [ "$#" -lt 2 ]; then BAD_USAGE=1; break; fi
      PROJECT_ROOT_ARG="$2"; shift 2 ;;
    --remote-version)
      if [ "$#" -lt 2 ]; then BAD_USAGE=1; break; fi
      REMOTE_VERSION="$2"; shift 2 ;;
    *) BAD_USAGE=1; break ;;
  esac
done

if [ -n "$REMOTE_VERSION" ]; then
  MODE="remote"
  REMOTE_MIN="$REMOTE_VERSION"
fi
if [ -n "$PROJECT_ROOT_ARG" ]; then
  PROJECT_KIND="given"
  PROJECT_GIVEN="$PROJECT_ROOT_ARG"
fi

if [ "$BAD_USAGE" = "1" ]; then finish ERROR bad_usage; fi
if [ -n "$REMOTE_VERSION" ] && ! [[ "$REMOTE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  finish ERROR bad_usage
fi
if [ -n "$PROJECT_ROOT_ARG" ] && [ -z "$REMOTE_VERSION" ]; then finish ERROR bad_usage; fi
if [ -n "$PROJECT_ROOT_ARG" ] && [ -n "$SOURCE_ROOT_ARG" ]; then finish ERROR bad_usage; fi

# ---- work root ---------------------------------------------------------------------------

WORK_PARENT="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
WORK="$(mktemp -d "${WORK_PARENT%/}/crosswake-default-ios-build.XXXXXX")" || finish ERROR work_root_failed
chmod 700 "$WORK"
mkdir -p "$WORK/TMPDIR"

# ---- project ------------------------------------------------------------------------------

PROJECT_DIR=""

if [ -z "$PROJECT_ROOT_ARG" ]; then
  # Generate mode.
  SOURCE_ROOT="${SOURCE_ROOT_ARG:-$SELF_ROOT}"
  if [ ! -d "$SOURCE_ROOT" ] || [ ! -f "$SOURCE_ROOT/mix.exs" ] || ! grep -q 'app: :crosswake,' "$SOURCE_ROOT/mix.exs"; then
    finish ERROR bad_source
  fi
  SOURCE_ROOT="$(cd -P "$SOURCE_ROOT" && pwd -P)"

  GENERATOR="$(git -C "$SOURCE_ROOT" rev-parse HEAD 2>/dev/null || true)"
  if ! [[ "$GENERATOR" =~ ^[0-9a-f]{40}$ ]]; then
    GENERATOR="-"
    GENERATOR_DIRTY="-"
  else
    dirty="$(git -C "$SOURCE_ROOT" status --porcelain -- lib priv 2>/dev/null || true)"
    if [ -z "$dirty" ]; then GENERATOR_DIRTY="no"; else GENERATOR_DIRTY="yes"; fi
  fi

  gen_args=(crosswake.gen.shell ios --target "$WORK/target")
  if [ -z "$REMOTE_VERSION" ]; then gen_args+=(--local); fi
  gen_rc=0
  (cd "$SOURCE_ROOT" && MIX_ENV=dev mix "${gen_args[@]}") >"$WORK/generate.log" 2>&1 || gen_rc=$?
  if [ "$gen_rc" -ne 0 ]; then
    ERR_LOG="$WORK/generate.log"
    print_tail "$WORK/generate.log"
    finish ERROR generate_failed
  fi
  PROJECT_DIR="$WORK/target/native/ios/crosswake_shell"
  CONTROL_DIR="$WORK/control/native/ios/crosswake_shell"
else
  # Given project: no-flag remote form only; build a copy.
  if [ ! -d "$PROJECT_ROOT_ARG" ] || [ ! -d "$PROJECT_ROOT_ARG/CrosswakeShell.xcodeproj" ]; then
    finish ERROR bad_project
  fi
  PROJECT_GIVEN="$(cd -P "$PROJECT_ROOT_ARG" && pwd -P)"
  if [ -e "$PROJECT_GIVEN/.crosswake/ios_host_generation.json" ] || [ -e "$PROJECT_GIVEN/../.crosswake/ios_host_generation.json" ]; then
    finish ERROR not_default_path
  fi
  if grep -q 'XCLocalSwiftPackageReference' "$PROJECT_GIVEN/CrosswakeShell.xcodeproj/project.pbxproj"; then
    finish ERROR local_copy_unsupported
  fi
  mkdir -p "$WORK/project-parent"
  cp -R "$PROJECT_GIVEN" "$WORK/project-parent/project"
  PROJECT_DIR="$WORK/project-parent/project"
  CONTROL_DIR="$WORK/control/project"
fi

PBXPROJ="$PROJECT_DIR/CrosswakeShell.xcodeproj/project.pbxproj"
if [ ! -f "$PBXPROJ" ]; then finish ERROR bad_project; fi

if [ -e "$PROJECT_DIR/.crosswake/ios_host_generation.json" ] || [ -e "$PROJECT_DIR/../.crosswake/ios_host_generation.json" ]; then
  finish ERROR not_default_path
fi

if [ -z "$REMOTE_VERSION" ]; then
  if ! grep -q 'XCLocalSwiftPackageReference' "$PBXPROJ"; then finish ERROR not_local_form; fi
else
  min_count="$(grep -c 'minimumVersion = ' "$PBXPROJ" || true)"
  if [ "$min_count" != "1" ] || ! grep -q 'XCRemoteSwiftPackageReference' "$PBXPROJ"; then
    finish ERROR not_remote_form
  fi
  REMOTE_FROM="$(sed -n 's/.*minimumVersion = \([^;]*\);.*/\1/p' "$PBXPROJ")"
  if [ -z "$REMOTE_FROM" ]; then REMOTE_FROM="-"; finish ERROR not_remote_form; fi
  # Rewrite the scratch copy only.
  sed "s/minimumVersion = [^;]*;/minimumVersion = ${REMOTE_VERSION};/" "$PBXPROJ" >"$PBXPROJ.rewritten"
  mv "$PBXPROJ.rewritten" "$PBXPROJ"
fi

if [ ! -f "$PROJECT_DIR/$SETTINGS_FILE" ]; then
  note "the project has no $SETTINGS_FILE beside its Xcode project (the build will say whether it needs it)"
fi

# ---- build --------------------------------------------------------------------------------

now() { date +%s; }

# run_build <project dir> <derived data dir> <log>; sets LAST_RC
run_build() {
  local dir="$1" derived="$2" log="$3"
  LAST_RC=0
  TMPDIR="$WORK/TMPDIR" "$XCODEBUILD" \
    -project "$dir/CrosswakeShell.xcodeproj" \
    -scheme CrosswakeShell \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived" \
    -clonedSourcePackagesDirPath "$WORK/SourcePackages" \
    CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS="$(uname -m)" build >"$log" 2>&1 || LAST_RC=$?
}

note "building the default-generated project (mode=$MODE)"
t0="$(now)"
run_build "$PROJECT_DIR" "$WORK/DerivedData" "$WORK/build.log"
t1="$(now)"
BUILD_RC="$LAST_RC"
BUILD_SECONDS="$((t1 - t0))"
ERR_LOG="$WORK/build.log"

if grep -q 'Could not resolve package dependencies' "$WORK/build.log"; then
  finish ERROR package_resolution_failed
fi
if [ "$BUILD_RC" -ne 0 ]; then
  CONTROL="skipped"
  finish FAIL build_failed
fi

if [ -n "$REMOTE_VERSION" ]; then
  resolved_lines="$(sed -n 's|.*CrosswakeShellCore: https://github\.com/szTheory/crosswake-shell-core-ios\.git @ \([^[:space:]]*\).*|\1|p' "$WORK/build.log")"
  RESOLVED="${resolved_lines%%$'\n'*}"
  RESOLVED="${RESOLVED//$'\r'/}"
  if [ -z "$RESOLVED" ]; then
    RESOLVED="-"
    finish ERROR resolved_unreadable
  fi
  if [ "$RESOLVED" != "$REMOTE_VERSION" ]; then
    finish FAIL resolved_version_mismatch
  fi
fi

# ---- negative control ---------------------------------------------------------------------

mkdir -p "$(dirname "$CONTROL_DIR")"
cp -R "$PROJECT_DIR" "$CONTROL_DIR"
rm -f "$CONTROL_DIR/$SETTINGS_FILE"
note "negative control: same build with $SETTINGS_FILE removed"
run_build "$CONTROL_DIR" "$WORK/DerivedDataControl" "$WORK/control.log"
CONTROL_RC="$LAST_RC"
ERR_LOG="$WORK/control.log"

if [ "$CONTROL_RC" -eq 0 ]; then
  CONTROL="not_detected"
  finish FAIL negative_control_passed
fi
if grep -q 'Unable to open base configuration reference file' "$WORK/control.log"; then
  CONTROL="detected"
else
  CONTROL="unexpected_error"
  finish FAIL negative_control_unexpected_error
fi

FIRST_ERROR="none"
finish PASS
