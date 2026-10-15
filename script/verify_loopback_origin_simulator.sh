#!/usr/bin/env bash
# Phase 182 (D-17.7) loopback origin Simulator harness. Phase evidence, not a CI lane.
#
# Generates a local-mode iOS shell through the declared :ios_host path (MIX_ENV=test),
# builds it for the iOS Simulator, installs and launches it with a test-owned probe
# app, and observes a WKWebView load a test-owned 127.0.0.1 page. A control relaunch
# against http://example.com/ must still fail with NSURLErrorDomain -1022 (narrowness).
#
# stdout: exactly one JSON object (also written to --evidence PATH). Diagnostics go to
# stderr. Exit 0 only for outcome passed; 3 for unavailable; 2 for blocked.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HELPERS="${ROOT_DIR}/script/loopback_origin_simulator"
XCODEBUILD="${CROSSWAKE_IOS_XCODEBUILD_BIN:-xcodebuild}"
EVIDENCE=""
SCHEME="CrosswakeShell"
CORE_TAG=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE="${2:-}"
      shift 2
      ;;
    *)
      echo "error: unsupported option $1" >&2
      exit 1
      ;;
  esac
done

OUTCOME=""
FINAL_RC=2
FAILED_RULES=()
CAUSE=""
ASSERTS=()
OBSERVATIONS=()
CANDIDATE_HEAD=""
CANDIDATE_TREE=""
CANDIDATE_CLEAN="false"
XCODE_VERSION=""
RUNTIME_NAME=""
DEVICE_NAME=""
ORIGIN=""
RUN=""
UDID=""
BUNDLE_ID=""
WE_BOOTED=0
INSTALLED=0
LISTENER_PID=""
APP_UNINSTALLED="true"
DEVICE_LEFT_AS_FOUND="true"
LISTENER_LOG=""
DATA_DIR=""

log() { echo "[loopback-sim] $*" >&2; }

assert_ok() { ASSERTS+=("$1=passed"); }
assert_bad() { ASSERTS+=("$1=failed"); }

# block RULE CAUSE: record the first failure and stop; the EXIT trap emits the evidence.
block() {
  OUTCOME="blocked"
  FINAL_RC=2
  FAILED_RULES+=("$1")
  CAUSE="$2"
  assert_bad "$1"
  log "BLOCKED $1: $2"
  exit 2
}

unavailable() {
  OUTCOME="unavailable"
  FINAL_RC=3
  FAILED_RULES+=("$1")
  CAUSE="$2"
  log "UNAVAILABLE $1: $2"
  exit 3
}

emit_json() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf '{"schema":"crosswake.phase182.simulator/1","outcome":"%s","rule_ids":["%s"]}\n' \
      "${OUTCOME:-blocked}" "${FAILED_RULES[0]:-LOOP-IOS-NO-PYTHON}"
    return 0
  fi
  local joined_asserts joined_rules joined_obs
  joined_asserts="$(printf '%s\n' "${ASSERTS[@]:-}")"
  joined_rules="$(printf '%s\n' "${FAILED_RULES[@]:-}")"
  joined_obs="$(printf '%s\n' "${OBSERVATIONS[@]:-}")"
  OUT_OUTCOME="${OUTCOME:-blocked}" OUT_CAUSE="$CAUSE" OUT_ASSERTS="$joined_asserts" \
    OUT_RULES="$joined_rules" OUT_OBS="$joined_obs" OUT_HEAD="$CANDIDATE_HEAD" \
    OUT_TREE="$CANDIDATE_TREE" OUT_CLEAN="$CANDIDATE_CLEAN" OUT_XCODE="$XCODE_VERSION" \
    OUT_RUNTIME="$RUNTIME_NAME" OUT_DEVICE="$DEVICE_NAME" OUT_ORIGIN="$ORIGIN" \
    OUT_UNINSTALLED="$APP_UNINSTALLED" OUT_LEFT="$DEVICE_LEFT_AS_FOUND" \
    python3 -I - <<'PY'
import json, os

def pairs(text):
    out = {}
    for line in text.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            out[key] = value
    return out

def lines(text):
    return [line for line in text.splitlines() if line]

e = os.environ
doc = {
    "schema": "crosswake.phase182.simulator/1",
    "outcome": e["OUT_OUTCOME"],
    "scope": "generated local_loopback shell, iOS Simulator only (not a physical device)",
    "rule_ids": lines(e["OUT_RULES"]),
    "cause": e["OUT_CAUSE"] or None,
    "candidate_head": e["OUT_HEAD"] or None,
    "candidate_tree": e["OUT_TREE"] or None,
    "candidate_clean": e["OUT_CLEAN"] == "true",
    "xcode_version": e["OUT_XCODE"] or None,
    "runtime": e["OUT_RUNTIME"] or None,
    "device_type": e["OUT_DEVICE"] or None,
    "origin": e["OUT_ORIGIN"] or None,
    "assertions": pairs(e["OUT_ASSERTS"]),
    "observations": pairs(e["OUT_OBS"]),
    "cleanup": {
        "device_left_as_found": e["OUT_LEFT"] == "true",
        "app_uninstalled": e["OUT_UNINSTALLED"] == "true",
    },
}
print(json.dumps(doc, indent=2, sort_keys=True))
PY
}

cleanup_and_emit() {
  local rc=$?
  set +e
  if [[ -z "$OUTCOME" ]]; then
    OUTCOME="blocked"
    FINAL_RC=2
    FAILED_RULES+=("LOOP-IOS-UNEXPECTED")
    CAUSE="harness stopped before completing its assertions"
  fi
  if [[ -n "$UDID" && -n "$BUNDLE_ID" && "$INSTALLED" == "1" ]]; then
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1
    if xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1; then
      APP_UNINSTALLED="true"
    else
      APP_UNINSTALLED="false"
    fi
  fi
  if [[ -n "$LISTENER_PID" ]]; then
    kill "$LISTENER_PID" >/dev/null 2>&1
    wait "$LISTENER_PID" >/dev/null 2>&1
  fi
  if [[ -n "$UDID" && "$WE_BOOTED" == "1" ]]; then
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1
    if xcrun simctl list devices 2>/dev/null | grep -F "$UDID" | grep -q "(Shutdown)"; then
      DEVICE_LEFT_AS_FOUND="true"
    else
      DEVICE_LEFT_AS_FOUND="false"
    fi
  fi
  [[ -n "$RUN" ]] && rm -rf "$RUN"
  local json
  json="$(emit_json)"
  printf '%s\n' "$json"
  if [[ -n "$EVIDENCE" ]]; then
    printf '%s\n' "$json" >"$EVIDENCE"
  fi
  if [[ "$OUTCOME" == "passed" ]]; then
    exit 0
  fi
  exit "$FINAL_RC"
}
trap cleanup_and_emit EXIT

# ---------------------------------------------------------------- step 0: binding
cd "$ROOT_DIR"
CANDIDATE_HEAD="$(git rev-parse HEAD 2>/dev/null || true)"
CANDIDATE_TREE="$(git rev-parse 'HEAD^{tree}' 2>/dev/null || true)"
if [[ -z "$(git status --porcelain 2>/dev/null)" && -n "$CANDIDATE_HEAD" ]]; then
  CANDIDATE_CLEAN="true"
else
  block "LOOP-IOS-CANDIDATE-DIRTY" "the clone has uncommitted changes; the evidence must attest a committed head"
fi

for tool in "$XCODEBUILD" xcrun python3 mix git plutil shasum; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    unavailable "LOOP-IOS-TOOLCHAIN" "a required tool is missing: $(basename "$tool")"
  fi
done

XCODE_VERSION="$("$XCODEBUILD" -version 2>/dev/null | tr '\n' ' ' | sed 's/ *$//' || true)"
[[ -n "$XCODE_VERSION" ]] || unavailable "LOOP-IOS-TOOLCHAIN" "xcodebuild did not report a version"

DEVICE_PICK="$(xcrun simctl list devices available -j 2>/dev/null | python3 -I -c '
import json, sys
data = json.load(sys.stdin)["devices"]
best = None
for runtime, devices in data.items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(p) for p in runtime.rsplit("iOS-", 1)[1].split("-") if p.isdigit())
    for device in devices:
        name = device.get("name", "")
        if not name.startswith("iPhone") or not device.get("isAvailable", True):
            continue
        rank = (name == "iPhone 17", version)
        if best is None or rank > best[0]:
            label = "iOS " + ".".join(str(p) for p in version)
            best = (rank, "%s|%s|%s|%s" % (device["udid"], device["state"], name, label))
print(best[1] if best else "")
' 2>/dev/null || true)"
[[ -n "$DEVICE_PICK" ]] || unavailable "LOOP-IOS-SIMULATOR" "no available iPhone Simulator device or iOS runtime"
IFS='|' read -r UDID DEVICE_STATE DEVICE_NAME RUNTIME_NAME <<<"$DEVICE_PICK"

RUN="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-loopback-sim.XXXXXX")"
RUN="$(cd "$RUN" && pwd -P)"
chmod 700 "$RUN"
LISTENER_LOG="$RUN/listener.log"
: >"$LISTENER_LOG"

# ---------------------------------------------------------------- step 1: listener
python3 -I "$HELPERS/listener.py" "$LISTENER_LOG" >"$RUN/listener.port" 2>"$RUN/listener.err" &
LISTENER_PID=$!
PORT=""
for _ in $(seq 1 50); do
  PORT="$(head -n1 "$RUN/listener.port" 2>/dev/null || true)"
  [[ -n "$PORT" ]] && break
  sleep 0.2
done
[[ "$PORT" =~ ^[0-9]+$ ]] || block "LOOP-IOS-LISTENER" "the loopback listener did not report a port"
[[ "$PORT" != "4790" ]] || block "LOOP-IOS-LISTENER" "the listener must not use the Phase 180 twin port"
ORIGIN="http://127.0.0.1:${PORT}"
log "listener on $ORIGIN"

# ---------------------------------------------------------------- step 2: generate
GEN="$RUN/gen"
mkdir -p "$GEN"
if ! MIX_ENV=test mix run --no-start "$HELPERS/generate.exs" "$GEN" "$PORT" >"$RUN/generate.log" 2>&1; then
  log "generation output kept at $RUN/generate.log until exit"
  cp "$RUN/generate.log" "${TMPDIR:-/tmp}/crosswake-loopback-generate.last.log" 2>/dev/null || true
  block "LOOP-IOS-GENERATE" "generation through the declared ios_host path failed"
fi
PROJ="$GEN/native/ios/crosswake_shell"
[[ -d "$PROJ/CrosswakeShell.xcodeproj" ]] || block "LOOP-IOS-GENERATE" "generated project is missing"

# ---------------------------------------------------------------- step 3: probe swap
owned_hashes() {
  (cd "$PROJ" && shasum -a 256 CrosswakeShell/Info.plist CrosswakeHostSettings.xcconfig \
    CrosswakeShell.xcodeproj/project.pbxproj Fixtures/*.json)
}
HASH_BEFORE="$(owned_hashes)"
cp "$HELPERS/ProbeApp.swift" "$PROJ/CrosswakeShell/CrosswakeShellApp.swift"
HASH_AFTER="$(owned_hashes)"
if [[ "$HASH_BEFORE" == "$HASH_AFTER" && -n "$HASH_BEFORE" ]]; then
  assert_ok "crosswake_owned_hashes_unchanged"
else
  block "LOOP-IOS-OWNED-HASH" "Crosswake-owned generated bytes changed when the probe was swapped in"
fi

# ---------------------------------------------------------------- step 4: hermetic core
CORE_CLONE="$RUN/core"
mkdir -p "$CORE_CLONE"
tar -C "$ROOT_DIR/packages/crosswake-shell-core-ios" --exclude=.build -cf - . | tar -C "$CORE_CLONE" -xf -
# SwiftPM records a fingerprint per (URL, tag) in the user-level security store, so a
# reused tag with different bytes is refused. Derive a hermetic tag in the 0.9.x band
# from the package tree and make the commit deterministic: same bytes, same revision.
git -C "$CORE_CLONE" -c init.defaultBranch=main init -q
git -C "$CORE_CLONE" -c user.email=ci@crosswake -c user.name=ci add -A
CORE_TREE="$(git -C "$CORE_CLONE" write-tree)"
CORE_TAG="0.9.$(( 16#${CORE_TREE:0:6} % 90000 + 1000 ))"
GIT_AUTHOR_DATE="2000-01-01T00:00:00Z" GIT_COMMITTER_DATE="2000-01-01T00:00:00Z" \
  git -C "$CORE_CLONE" -c user.email=ci@crosswake -c user.name=ci commit -q -m "hermetic ${CORE_TAG}"
git -C "$CORE_CLONE" tag "$CORE_TAG"
git -C "$CORE_CLONE" tag "v${CORE_TAG}"

# ---------------------------------------------------------------- step 5: build + plist
DD="$RUN/dd"
SPM="$RUN/spm"
mkdir -p "$RUN/TMPDIR" "$DD" "$SPM"
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="url.${CORE_CLONE}.insteadOf"
export GIT_CONFIG_VALUE_0="https://github.com/szTheory/crosswake-shell-core-ios.git"
if ! TMPDIR="$RUN/TMPDIR" "$XCODEBUILD" build \
  -project "$PROJ/CrosswakeShell.xcodeproj" -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DD" -clonedSourcePackagesDirPath "$SPM" \
  -packageCachePath "$RUN/pkgcache" CODE_SIGNING_ALLOWED=NO >"$RUN/build.log" 2>&1; then
  cp "$RUN/build.log" "${TMPDIR:-/tmp}/crosswake-loopback-build.last.log" 2>/dev/null || true
  block "LOOP-IOS-BUILD" "xcodebuild could not build the generated local-mode shell"
fi
unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
APP="$DD/Build/Products/Debug-iphonesimulator/${SCHEME}.app"
[[ -d "$APP" ]] || block "LOOP-IOS-BUILD" "the built app bundle is missing"

ATS_KEYS="$(plutil -extract NSAppTransportSecurity json -o - "$APP/Info.plist" 2>/dev/null |
  python3 -I -c 'import json,sys; d=json.load(sys.stdin); print(",".join(sorted(d)), d.get("NSAllowsLocalNetworking"))' 2>/dev/null || true)"
MODE_VALUE="$(plutil -extract CrosswakeOriginMode raw -o - "$APP/Info.plist" 2>/dev/null || true)"
if [[ "$ATS_KEYS" == "NSAllowsLocalNetworking True" ]]; then
  assert_ok "built_plist_ats_keys_exactly_allows_local_networking"
else
  block "LOOP-IOS-ATS-KEYS" "the built Info.plist ATS key set is not exactly NSAllowsLocalNetworking"
fi
if [[ "$MODE_VALUE" == "local_loopback" ]]; then
  assert_ok "built_plist_origin_mode_marker"
else
  block "LOOP-IOS-MARKER" "the built Info.plist origin mode marker is not local_loopback"
fi
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist" 2>/dev/null || true)"
[[ -n "$BUNDLE_ID" ]] || block "LOOP-IOS-BUILD" "the built app has no bundle identifier"

# ---------------------------------------------------------------- step 6: boot, install, launch
if [[ "$DEVICE_STATE" == "Booted" ]]; then
  WE_BOOTED=0
else
  WE_BOOTED=1
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
fi
xcrun simctl bootstatus "$UDID" -b >"$RUN/bootstatus.log" 2>&1 ||
  unavailable "LOOP-IOS-SIMULATOR" "the Simulator device did not finish booting"

xcrun simctl uninstall "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$APP" >"$RUN/install.log" 2>&1 ||
  block "LOOP-IOS-INSTALL" "the built app could not be installed in the Simulator"
INSTALLED=1

poll_until() {
  local timeout="$1"
  shift
  local end=$((SECONDS + timeout))
  while ((SECONDS < end)); do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}
listener_has() { grep -aqx -- "GET $1" "$LISTENER_LOG"; }
read_result() { cat "$DATA_DIR/tmp/result.txt" 2>/dev/null || true; }
result_is() { [[ "$(read_result)" == "$1" ]]; }

xcrun simctl launch "$UDID" "$BUNDLE_ID" >"$RUN/launch1.log" 2>&1 ||
  block "LOOP-IOS-LAUNCH" "the probe app failed to launch in the Simulator"
DATA_DIR="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data 2>/dev/null || true)"
[[ -d "$DATA_DIR" ]] || block "LOOP-IOS-LAUNCH" "the app data container could not be resolved"

if poll_until 90 listener_has "/study-session"; then assert_ok "listener_saw_entry_get"; else assert_bad "listener_saw_entry_get"; fi
if poll_until 60 listener_has "/__loaded"; then assert_ok "listener_saw_loaded_ping"; else assert_bad "listener_saw_loaded_ping"; fi
if poll_until 60 result_is "didFinish"; then assert_ok "app_reported_did_finish"; else assert_bad "app_reported_did_finish"; fi
OBSERVATIONS+=("first_launch_result=$(read_result | tr ' ' '_')")
for a in listener_saw_entry_get listener_saw_loaded_ping app_reported_did_finish; do
  printf '%s\n' "${ASSERTS[@]}" | grep -qx "$a=passed" || block "LOOP-IOS-LOOPBACK-LOAD" "the loopback page was not observed loading: $a"
done

# ---------------------------------------------------------------- step 7: narrowness control
xcrun simctl terminate "$UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
rm -f "$DATA_DIR/tmp/result.txt"
LINES_BEFORE="$(wc -l <"$LISTENER_LOG" | tr -d ' ')"
SIMCTL_CHILD_PROBE_URL="http://example.com/" xcrun simctl launch "$UDID" "$BUNDLE_ID" >"$RUN/launch2.log" 2>&1 ||
  block "LOOP-IOS-LAUNCH" "the control relaunch failed"
if poll_until 90 result_is "didFailProvisional NSURLErrorDomain -1022"; then
  assert_ok "control_example_com_refused_minus_1022"
else
  OBSERVATIONS+=("control_result=$(read_result | tr ' ' '_')")
  block "LOOP-IOS-NARROWNESS" "the http://example.com/ control was not refused with NSURLErrorDomain -1022"
fi
LINES_AFTER="$(wc -l <"$LISTENER_LOG" | tr -d ' ')"
if [[ "$LINES_BEFORE" == "$LINES_AFTER" ]]; then
  assert_ok "control_did_not_reach_listener"
else
  block "LOOP-IOS-NARROWNESS" "the control relaunch reached the loopback listener"
fi

# ---------------------------------------------------------------- step 8: final binding
if [[ "$(git -C "$ROOT_DIR" rev-parse HEAD)" != "$CANDIDATE_HEAD" ]]; then
  block "LOOP-IOS-CANDIDATE-MOVED" "the clone HEAD moved during the run"
fi
if [[ -n "$(git -C "$ROOT_DIR" status --porcelain)" ]]; then
  block "LOOP-IOS-CANDIDATE-DIRTY" "the clone became dirty during the run"
fi
OBSERVATIONS+=("ats_exception_scope=NSAllowsLocalNetworking_only")
OUTCOME="passed"
FINAL_RC=0
