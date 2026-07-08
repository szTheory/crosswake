#!/usr/bin/env bash
# verify_companion_cleanroom.sh — Post-publish clean-room resolvability + doctor proof (PROOF-01).
#
# Usage:
#   bash script/verify_companion_cleanroom.sh [PACKAGE [VERSION [ENGINE_PACKAGE [ENGINE_MODULE]]]]
#
# Arguments:
#   PACKAGE        Hex package name (default: crosswake_rulestead)
#   VERSION        Hex version to verify — REQUIRED (e.g. 0.1.0)
#   ENGINE_PACKAGE Optional engine Hex package override. Defaults come from PACKAGE profile:
#                  rulestead/rindle are engine-present, sigra/chimeway are no-engine,
#                  and threadline is an observer. Pass empty string or "none" to force no-engine.
#   ENGINE_MODULE  Engine top-level Elixir module atom; required only when overriding ENGINE_PACKAGE.
#
# What this script does (D-17, SC#3):
#   1. Reads the exact Hex release metadata for PACKAGE/VERSION and derives
#      requirements.crosswake.requirement as the core floor.
#   2. Creates a throwaway Phoenix host app OUTSIDE the monorepo in $RUNNER_TEMP.
#   3. Installs the published duo (no-engine) or trio (engine):
#      crosswake + PACKAGE == VERSION [+ ENGINE_PACKAGE].
#   4. Compiles the throwaway app with --warnings-as-errors.
#   5. Writes a minimal Phoenix router stub (required by mix crosswake.doctor --router).
#   6. Writes an inline ExUnit smoke test asserting the public seam of the companion.
#   7. Runs mix test test/smoke_test.exs (D-18 — public-seam only, no MockFlagSource).
#   8. Registers companion config in config/runtime.exs (no engine registration in no-engine mode).
#   9. Runs mix crosswake.doctor --router CleanRoomHost.Router and asserts exit 0 (D-19/D-20).
#
# Parameterized for rindle reuse (D-16):
#   bash script/verify_companion_cleanroom.sh crosswake_rindle 0.1.0 rindle Rindle
#
# No-engine mode (no engine dep — validate_dependency/0 returns :ok unconditionally):
#   bash script/verify_companion_cleanroom.sh crosswake_sigra 0.1.0
#   bash script/verify_companion_cleanroom.sh crosswake_sigra 0.1.0 none
#   bash script/verify_companion_cleanroom.sh crosswake_sigra 0.1.0 "" ""
#   bash script/verify_companion_cleanroom.sh crosswake_chimeway 0.1.0
#   (chimeway defaults enabled?(%{}) to true — the smoke test emits assert, not refute)
#
# Non-companion no-engine mode (crosswake_threadline is NOT a Crosswake.Companion implementor):
#   bash script/verify_companion_cleanroom.sh crosswake_threadline 0.1.0
#   threadline has no enabled?/1, companion_id/0, or validate_dependency/0 — those functions do not
#   exist and would raise UndefinedFunctionError. The threadline lane suppresses the companion-behaviour
#   assertions entirely and substitutes three module-shipment canaries (Telemetry/Plug/Ledger).
#   Installs crosswake + crosswake_threadline with NEITHER sibling — zero-sibling-dep mode.
#
# NOTE: Full end-to-end execution is CI-only / post-publish (PROOF-01 irreversible).
# This script requires a live published crosswake_PACKAGE on Hex.pm — it cannot run
# locally before the Phase 131 publish job cuts the first release.
#
# Failure messages lead with [crosswake] (BRAND-SPEC §6): name what happened + what to do next.

set -euo pipefail

# ---------------------------------------------------------------------------
# Parameters (D-16)
# ---------------------------------------------------------------------------

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

PACKAGE="${1:-crosswake_rulestead}"
VERSION="${2:-}"
_RAW_ENGINE_PKG="${3-__crosswake_default__}"
_RAW_ENGINE_MOD="${4-}"

CORE_REQUIREMENT=""
PACKAGE_REQUIREMENT=""
SELECTED_CORE_VERSION=""
PROFILE=""
NO_ENGINE=""
ENGINE_PACKAGE=""
ENGINE_MODULE=""

log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  local next_action="${2:-Stop and inspect the package, version, release metadata, and clean-room lockfile before retrying.}"

  echo "[crosswake] FAIL: ${message}"
  log "package=${PACKAGE:-unknown} version=${VERSION:-unknown} core_floor=${CORE_REQUIREMENT:-unknown} selected_core=${SELECTED_CORE_VERSION:-unknown} state=failed"
  log "What to do next: ${next_action}"
  exit 1
}

package_config() {
  case "$PACKAGE" in
    crosswake_rulestead)
      PROFILE="engine-present"
      NO_ENGINE=0
      ENGINE_PACKAGE="rulestead"
      ENGINE_MODULE="Rulestead"
      ;;
    crosswake_rindle)
      PROFILE="engine-present"
      NO_ENGINE=0
      ENGINE_PACKAGE="rindle"
      ENGINE_MODULE="Rindle"
      ;;
    crosswake_sigra)
      PROFILE="no-engine-companion"
      NO_ENGINE=1
      ENGINE_PACKAGE=""
      ENGINE_MODULE=""
      ;;
    crosswake_chimeway)
      PROFILE="no-engine-companion"
      NO_ENGINE=1
      ENGINE_PACKAGE=""
      ENGINE_MODULE=""
      ;;
    crosswake_threadline)
      PROFILE="threadline-observer"
      NO_ENGINE=1
      ENGINE_PACKAGE=""
      ENGINE_MODULE=""
      ;;
    *)
      fail "unknown Hex package '${PACKAGE:-<empty>}'." "Choose one of: crosswake_rulestead, crosswake_rindle, crosswake_sigra, crosswake_chimeway, crosswake_threadline."
      ;;
  esac
}

validate_inputs() {
  if [ -z "${VERSION:-}" ]; then
    fail "VERSION required as \$2 (e.g. 0.1.0)." "Pass the exact Release Please component version output for ${PACKAGE}."
  fi

  if ! printf "%s" "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z._-]+)?$'; then
    fail "VERSION '${VERSION:-<empty>}' does not look like a valid semver string." "Pass the exact Release Please component version output for ${PACKAGE}."
  fi

  if [ "$_RAW_ENGINE_PKG" != "__crosswake_default__" ]; then
    if [ -z "$_RAW_ENGINE_PKG" ] || [ "$_RAW_ENGINE_PKG" = "none" ]; then
      NO_ENGINE=1
      ENGINE_PACKAGE=""
      ENGINE_MODULE=""
    else
      case "${_RAW_ENGINE_PKG}:${_RAW_ENGINE_MOD:-}" in
        rulestead:Rulestead | rindle:Rindle)
          ;;
        *)
          fail "unsupported engine override '${_RAW_ENGINE_PKG}:${_RAW_ENGINE_MOD:-}'." "Use the built-in package profile, 'none', or an allowlisted engine/module pair."
          ;;
      esac

      NO_ENGINE=0
      ENGINE_PACKAGE="$_RAW_ENGINE_PKG"
      ENGINE_MODULE="${_RAW_ENGINE_MOD:-}"
    fi
  fi
}

fetch_hex_release_metadata() {
  local body_file="$1"
  local url="https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}"
  local code

  code=$(curl -sS -o "$body_file" -w "%{http_code}" "$url" || true)

  case "$code" in
    200)
      ok "package=${PACKAGE} version=${VERSION} state=hex-metadata-found proof=continue"
      ;;
    404)
      fail "Hex.pm returned 404 for ${PACKAGE} ${VERSION}; clean-room proof runs only after publish." "Confirm the Release Please version output and Hex package URL: ${url}"
      ;;
    *)
      fail "Hex.pm release metadata returned HTTP ${code} for ${PACKAGE} ${VERSION}." "Retry after confirming Hex.pm status; do not claim clean-room proof until metadata is readable."
      ;;
  esac
}

parse_core_requirement_from_release() {
  local body_file="$1"
  local parsed

  if ! parsed=$(python3 - "$body_file" "$VERSION" <<'PYEOF'
import json
import sys

body_path = sys.argv[1]
expected_version = sys.argv[2]

try:
    with open(body_path, "r", encoding="utf-8") as handle:
        payload = json.load(handle)
except Exception as exc:
    print(f"malformed JSON: {exc}", file=sys.stderr)
    sys.exit(2)

version = payload.get("version")
if version != expected_version:
    print(f"version mismatch: expected {expected_version}, got {version!r}", file=sys.stderr)
    sys.exit(3)

if payload.get("retirement") or payload.get("retired"):
    print("release is retired or unusable", file=sys.stderr)
    sys.exit(4)

requirements = payload.get("requirements")
if not isinstance(requirements, dict):
    print("missing requirements object", file=sys.stderr)
    sys.exit(5)

crosswake = requirements.get("crosswake")
if not isinstance(crosswake, dict):
    print("missing requirements.crosswake object", file=sys.stderr)
    sys.exit(6)

requirement = crosswake.get("requirement")
if not isinstance(requirement, str) or not requirement.strip():
    print("missing requirements.crosswake.requirement", file=sys.stderr)
    sys.exit(7)

print(requirement.strip())
PYEOF
  ); then
    fail "Hex.pm metadata for ${PACKAGE} ${VERSION} is malformed or unusable." "Inspect https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}; required field: requirements.crosswake.requirement."
  fi

  CORE_REQUIREMENT="$parsed"
  PACKAGE_REQUIREMENT="== ${VERSION}"
  ok "package=${PACKAGE} version=${VERSION} core_floor=${CORE_REQUIREMENT} state=metadata-ready proof=continue"
}

lock_version_for() {
  local package="$1"

  PACKAGE_FOR_LOCK="$package" elixir -e '
lock_path = "mix.lock"
unless File.exists?(lock_path), do: System.halt(2)
{lock, _binding} = Code.eval_file(lock_path)
package = System.fetch_env!("PACKAGE_FOR_LOCK") |> String.to_atom()

case Map.fetch(lock, package) do
  {:ok, tuple} when is_tuple(tuple) and tuple_size(tuple) >= 3 ->
    version = elem(tuple, 2)
    if is_binary(version), do: IO.puts(version), else: System.halt(3)

  _ ->
    System.halt(4)
end
'
}

assert_absent_lock_deps() {
  local dep

  for dep in "$@"; do
    if LOCK_DEP="$dep" elixir -e '
lock_path = "mix.lock"
unless File.exists?(lock_path), do: System.halt(2)
{lock, _binding} = Code.eval_file(lock_path)
dep = System.fetch_env!("LOCK_DEP") |> String.to_atom()
if Map.has_key?(lock, dep), do: System.halt(1), else: :ok
'; then
      ok "package=${PACKAGE} version=${VERSION} absent_dep=${dep} state=absence-verified"
    else
      fail "mix.lock unexpectedly selected ${dep} for ${PACKAGE} ${VERSION}." "Inspect clean-room mix.lock; ${dep} must stay absent for this package profile."
    fi
  done
}

assert_lockfile_postconditions() {
  local selected_package

  if ! selected_package=$(lock_version_for "$PACKAGE"); then
    fail "mix.lock does not contain ${PACKAGE} after mix deps.get." "Inspect ${CLEAN_ROOM_DIR}/mix.lock before retrying."
  fi

  if [ "$selected_package" != "$VERSION" ]; then
    fail "mix.lock selected ${PACKAGE} ${selected_package}, expected ${VERSION}." "The companion dependency must stay pinned as == ${VERSION}."
  fi

  if ! SELECTED_CORE_VERSION=$(lock_version_for "crosswake"); then
    fail "mix.lock does not contain crosswake after mix deps.get." "Inspect ${CLEAN_ROOM_DIR}/mix.lock before retrying."
  fi

  if ! CORE_REQUIREMENT="$CORE_REQUIREMENT" SELECTED_CORE_VERSION="$SELECTED_CORE_VERSION" elixir -e '
requirement = Version.parse_requirement!(System.fetch_env!("CORE_REQUIREMENT"))
version = Version.parse!(System.fetch_env!("SELECTED_CORE_VERSION"))
unless Version.match?(version, requirement), do: System.halt(1)
'; then
    fail "mix.lock selected crosswake ${SELECTED_CORE_VERSION}, which does not satisfy ${CORE_REQUIREMENT}." "Inspect the Hex metadata floor and clean-room resolver output before retrying."
  fi

  case "$PACKAGE" in
    crosswake_chimeway)
      assert_absent_lock_deps crosswake_sigra
      ;;
    crosswake_threadline)
      assert_absent_lock_deps crosswake_sigra crosswake_chimeway
      ;;
  esac

  ok "package=${PACKAGE} version=${VERSION} core_floor=${CORE_REQUIREMENT} selected_core=${SELECTED_CORE_VERSION} state=lockfile-verified proof=continue"
}

package_config
validate_inputs

METADATA_FILE=$(mktemp "${TMPDIR:-/tmp}/crosswake-cleanroom-release.XXXXXX.json")
trap 'rm -f "$METADATA_FILE"' EXIT

fetch_hex_release_metadata "$METADATA_FILE"
parse_core_requirement_from_release "$METADATA_FILE"

if [ "$NO_ENGINE" = "1" ]; then
  log "verify_companion_cleanroom: package=${PACKAGE} version=${VERSION} profile=${PROFILE} core_floor=${CORE_REQUIREMENT}"
else
  log "verify_companion_cleanroom: package=${PACKAGE} version=${VERSION} profile=${PROFILE} engine_package=${ENGINE_PACKAGE} engine_module=${ENGINE_MODULE} core_floor=${CORE_REQUIREMENT}"
fi
log "clean-room deps: crosswake ${CORE_REQUIREMENT}; ${PACKAGE} ${PACKAGE_REQUIREMENT}"

# ---------------------------------------------------------------------------
# Step 1: Hex release metadata has already been fetched and parsed.
# ---------------------------------------------------------------------------

ok "Step 1: package=${PACKAGE} version=${VERSION} core_floor=${CORE_REQUIREMENT} state=hex-release-authority"

# ---------------------------------------------------------------------------
# Step 2: Create throwaway Phoenix host OUTSIDE the monorepo (D-17)
# ---------------------------------------------------------------------------

# Underscores, not hyphens: the basename becomes the `mix new` app name, which must be a
# valid Elixir atom (hyphens error: "Application name must start with a lowercase ASCII letter").
CLEAN_ROOM_DIR="${RUNNER_TEMP:-/tmp}/clean_room_${PACKAGE}"

echo "[crosswake] Step 2: creating throwaway Phoenix host at ${CLEAN_ROOM_DIR}..."

rm -rf "$CLEAN_ROOM_DIR"

# mix new in the PARENT of CLEAN_ROOM_DIR, naming the subdirectory.
# Create ONLY the parent — `mix new "$APP_NAME"` creates the leaf dir itself; pre-creating
# it makes mix prompt "directory already exists? [Yn]", which EOFs to abort under `bash -e`.
PARENT_DIR=$(dirname "$CLEAN_ROOM_DIR")
APP_NAME=$(basename "$CLEAN_ROOM_DIR")
mkdir -p "$PARENT_DIR"
cd "$PARENT_DIR"
mix new "$APP_NAME" --sup

cd "$CLEAN_ROOM_DIR"

# Patch mix.exs to add Phoenix + companion deps (and engine dep if not in no-engine mode).
# No-engine mode (NO_ENGINE=1): duo — crosswake + PACKAGE only (sigra has no engine dep).
# Engine mode (NO_ENGINE=0): trio — crosswake + PACKAGE + ENGINE_PACKAGE.
if [ "$NO_ENGINE" = "1" ]; then
python3 - <<PYEOF
import re

with open("mix.exs", "r") as f:
    content = f.read()

deps_block = '''  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:crosswake, "${CORE_REQUIREMENT}"},
      {:${PACKAGE}, "${PACKAGE_REQUIREMENT}"}
    ]
  end'''

content = re.sub(
    r'defp deps do\s*\[.*?\]\s*end',
    deps_block,
    content,
    flags=re.DOTALL
)

with open("mix.exs", "w") as f:
    f.write(content)

print("[crosswake] mix.exs deps patched (no-engine: duo — crosswake + ${PACKAGE})")
PYEOF
else
python3 - <<PYEOF
import re

with open("mix.exs", "r") as f:
    content = f.read()

deps_block = '''  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.2"},
      {:crosswake, "${CORE_REQUIREMENT}"},
      {:${PACKAGE}, "${PACKAGE_REQUIREMENT}"},
      {:${ENGINE_PACKAGE}, "~> 0.1"}
    ]
  end'''

content = re.sub(
    r'defp deps do\s*\[.*?\]\s*end',
    deps_block,
    content,
    flags=re.DOTALL
)

with open("mix.exs", "w") as f:
    f.write(content)

print("[crosswake] mix.exs deps patched (engine: trio — crosswake + ${PACKAGE} + ${ENGINE_PACKAGE})")
PYEOF
fi

echo "[crosswake] Step 2 OK: throwaway app created at ${CLEAN_ROOM_DIR}"

# ---------------------------------------------------------------------------
# Step 3: deps.get + compile --warnings-as-errors (D-17)
# ---------------------------------------------------------------------------

echo "[crosswake] Step 3: mix deps.get..."
mix deps.get
assert_lockfile_postconditions

echo "[crosswake] Step 3: mix compile --warnings-as-errors..."
mix compile --warnings-as-errors

echo "[crosswake] Step 3 OK: compiled clean"

# ---------------------------------------------------------------------------
# Step 4: Write minimal Phoenix router stub (D-17, Open Question 1 default)
# required by mix crosswake.doctor --router CleanRoomHost.Router
# ---------------------------------------------------------------------------

echo "[crosswake] Step 4: writing minimal Phoenix router stub..."

mkdir -p lib/clean_room_host

cat > lib/clean_room_host/router.ex <<'ROUTEREOF'
defmodule CleanRoomHost.Router do
  use Phoenix.Router
  # minimal router stub — no routes required for doctor smoke (Open Question 1)
end
ROUTEREOF

# Compile setup only; the doctor command below is the router loadability proof.
mix compile

echo "[crosswake] Step 4 OK: router stub compiled"

# ---------------------------------------------------------------------------
# Step 5: Write and run inline ExUnit smoke test (D-18)
# Public-seam only — MockFlagSource is NOT in the tarball (test/ excluded per D-24).
# Assertions: validate_dependency() == :ok (engine present), companion_id(), enabled?/1.
# ---------------------------------------------------------------------------

echo "[crosswake] Step 5: writing inline smoke test..."

# The companion module name is the standard Crosswake companion namespace:
# crosswake_rulestead -> Crosswake.Companions.Rulestead
# crosswake_rindle    -> Crosswake.Companions.Rindle
# Derive from PACKAGE by stripping the crosswake_ prefix and capitalizing.
COMPANION_SUFFIX=$(echo "$PACKAGE" | sed 's/^crosswake_//')
COMPANION_MODULE_SUFFIX=$(echo "$COMPANION_SUFFIX" | python3 -c "import sys; s=sys.stdin.read().strip(); print(s[0].upper() + s[1:])")
COMPANION_MODULE="Crosswake.Companions.${COMPANION_MODULE_SUFFIX}"

if [ "$NO_ENGINE" = "1" ]; then
# No-engine smoke test: validate_dependency/0 is unconditionally :ok (no engine gate).
#
# enabled?(%{}) assertion is PACKAGE-AWARE:
#   - crosswake_chimeway: assert enabled?(%{}) — chimeway defaults enabled? to true
#   - all other no-engine companions (e.g. sigra): refute enabled?(%{}) — default false
# Emitting exactly one form per package keeps the test non-contradictory.
#
# NOTE: crosswake_threadline is NOT a Crosswake.Companion implementor — it has no
# enabled?/1, companion_id/0, or validate_dependency/0. Those assertions are SUPPRESSED
# for threadline (emitting them would raise UndefinedFunctionError). Instead, three
# module-shipment canaries prove real threadline machinery shipped with both siblings absent:
# (1) Telemetry.event_names/0 == 3, (2) Plug.Threadline.init/1 header_name, (3) Ledger.actor_ref/2 hex.
if [ "$PACKAGE" = "crosswake_threadline" ]; then
cat > test/smoke_test.exs <<SMOKEEOF
# Inline clean-room smoke test — generated by verify_companion_cleanroom.sh (D-18)
# Tests public seam only: module-shipment canaries for threadline sub-modules.
# crosswake_threadline is NOT a Crosswake.Companion implementor — it is a pure-OTP
# audit/correlation observer wired via Plug and LiveView on_mount, not the :companions registry.
# The companion-behaviour assertions (enabled?/1, companion_id/0, validate_dependency/0) are
# SUPPRESSED here because threadline has none of these functions.
# Installs: crosswake + crosswake_threadline only (zero-sibling-dep mode — no crosswake_sigra,
# no crosswake_chimeway). Both siblings deliberately absent (THREAD-02, T-139-18).

ExUnit.start()

defmodule CleanRoom.SmokeTest do
  use ExUnit.Case

  # Canary 1: Telemetry sub-module shipped in the tarball and exports exactly 3 request-span events.
  # A missing or short list means Crosswake.Threadline.Telemetry was excluded from the tarball.
  test "Threadline.Telemetry.event_names/0 returns 3 request-span events (canary: Telemetry shipped)" do
    events = Crosswake.Threadline.Telemetry.event_names()
    assert is_list(events) and length(events) == 3,
           "[crosswake] Crosswake.Threadline.Telemetry.event_names/0 should return 3 events — " <>
             "the Crosswake.Threadline.Telemetry module may be missing from the tarball"
  end

  # Canary 2: Plug sub-module shipped and init/1 returns expected opts with header_name.
  # Proves Crosswake.Plug.Threadline compiled and the NimbleOptions schema is valid.
  test "Plug.Threadline.init/1 returns opts with header_name (canary: Plug shipped)" do
    opts = Crosswake.Plug.Threadline.init([])
    assert Keyword.get(opts, :header_name) == "x-crosswake-thread-id",
           "[crosswake] Crosswake.Plug.Threadline.init/1 should return opts with header_name: " <>
             "'x-crosswake-thread-id' — the Crosswake.Plug.Threadline module may be missing from the tarball"
  end

  # Canary 3: Audit.Ledger.actor_ref/2 returns a 64-char hex binary (HMAC-SHA256 lower hex).
  # Proves Crosswake.Audit.Ledger compiled and the :crypto HMAC helper works.
  test "Audit.Ledger.actor_ref/2 returns a 64-char lowercase hex binary (canary: Ledger shipped)" do
    result = Crosswake.Audit.Ledger.actor_ref("test-user-id", secret: "test-secret")
    assert is_binary(result) and byte_size(result) == 64 and result == String.downcase(result),
           "[crosswake] Crosswake.Audit.Ledger.actor_ref/2 should return a 64-char lowercase hex string — " <>
             "the Crosswake.Audit.Ledger module may be missing from the tarball"
  end

  # Zero-sibling-dep invariant: neither sigra nor chimeway is in the installed deps (THREAD-02).
  test "crosswake_sigra and crosswake_chimeway are NOT installed (zero-sibling-dep mode)" do
    deps = Mix.Project.config()[:deps] || []
    dep_names = Enum.map(deps, fn
      {name, _} -> name
      {name, _, _} -> name
      dep when is_atom(dep) -> dep
      _ -> nil
    end)
    assert :crosswake_sigra not in dep_names,
           "[crosswake] crosswake_sigra must not be installed in the threadline clean-room — " <>
             "zero-sibling-dep invariant violated (THREAD-02)"
    assert :crosswake_chimeway not in dep_names,
           "[crosswake] crosswake_chimeway must not be installed in the threadline clean-room — " <>
             "zero-sibling-dep invariant violated (THREAD-02)"
    assert dep_names != [], "[crosswake] dep_names must be non-empty (non-vacuity guard)"
  end
end
SMOKEEOF
elif [ "$PACKAGE" = "crosswake_chimeway" ]; then
cat > test/smoke_test.exs <<SMOKEEOF
# Inline clean-room smoke test — generated by verify_companion_cleanroom.sh (D-18)
# Tests public seam only: no MockFlagSource, no internal modules.
# Companion: ${COMPANION_MODULE}
# No-engine mode: validate_dependency/0 returns :ok unconditionally (pure-Elixir notification companion).
# chimeway: enabled?(%{}) defaults to true (notification companion — enabled by default).

ExUnit.start()

defmodule CleanRoom.SmokeTest do
  use ExUnit.Case

  alias ${COMPANION_MODULE}

  test "validate_dependency/0 returns :ok (no engine dep — pure-Elixir notification companion)" do
    assert ${COMPANION_MODULE_SUFFIX}.validate_dependency() == :ok
  end

  test "companion_id/0 returns :${COMPANION_SUFFIX}" do
    assert ${COMPANION_MODULE_SUFFIX}.companion_id() == :${COMPANION_SUFFIX}
  end

  # chimeway-specific: enabled?(%{}) defaults to TRUE (no :enabled key required).
  # chimeway is a notification companion — enabled by default. asserting true here
  # (not refute) is the chimeway-correct form (RESEARCH Pitfall 1, CHIME-02).
  test "enabled?/1 defaults to true (chimeway enabled by default — no :enabled key required)" do
    assert ${COMPANION_MODULE_SUFFIX}.enabled?(%{})
  end

  test "enabled?/1 respects config — true when enabled: true" do
    assert ${COMPANION_MODULE_SUFFIX}.enabled?(%{enabled: true})
  end

  # Telemetry canary: proves Chimeway.Telemetry sub-module shipped in the tarball (CHIME-02).
  # A missing or short event_names list means the Telemetry module was excluded from the tarball.
  # This is the vacuity-safe proof that real notification machinery runs with the companion absent.
  test "Chimeway.Telemetry.event_names/0 returns 10 notification events (canary: Telemetry shipped)" do
    events = Crosswake.Companions.Chimeway.Telemetry.event_names()
    assert is_list(events) and length(events) == 10,
           "[crosswake] Chimeway.Telemetry.event_names/0 should return 10 events — " <>
             "the Crosswake.Companions.Chimeway.Telemetry module may be missing from the tarball"
  end
end
SMOKEEOF
else
# Default companion no-engine path: emit the standard companion-behaviour assertions.
# SUPPRESS for crosswake_threadline — it is NOT a Crosswake.Companion implementor and has
# no enabled?/1, companion_id/0, or validate_dependency/0 (handled by the branch above).
if [ "$PACKAGE" != "crosswake_threadline" ]; then
cat > test/smoke_test.exs <<SMOKEEOF
# Inline clean-room smoke test — generated by verify_companion_cleanroom.sh (D-18)
# Tests public seam only: no MockFlagSource, no internal modules.
# Companion: ${COMPANION_MODULE}
# No-engine mode: validate_dependency/0 returns :ok unconditionally (pure-Elixir companion).

ExUnit.start()

defmodule CleanRoom.SmokeTest do
  use ExUnit.Case

  alias ${COMPANION_MODULE}

  test "validate_dependency/0 returns :ok (no engine dep — pure-Elixir companion)" do
    assert ${COMPANION_MODULE_SUFFIX}.validate_dependency() == :ok
  end

  test "companion_id/0 returns :${COMPANION_SUFFIX}" do
    assert ${COMPANION_MODULE_SUFFIX}.companion_id() == :${COMPANION_SUFFIX}
  end

  test "enabled?/1 respects config — false when no :enabled key" do
    refute ${COMPANION_MODULE_SUFFIX}.enabled?(%{})
  end

  test "enabled?/1 respects config — true when enabled: true" do
    assert ${COMPANION_MODULE_SUFFIX}.enabled?(%{enabled: true})
  end
end
SMOKEEOF
fi  # end PACKAGE != "crosswake_threadline" suppress guard
fi
else
cat > test/smoke_test.exs <<SMOKEEOF
# Inline clean-room smoke test — generated by verify_companion_cleanroom.sh (D-18)
# Tests public seam only: no MockFlagSource, no internal modules.
# Companion: ${COMPANION_MODULE}
# Engine: ${ENGINE_MODULE} (installed as {:${ENGINE_PACKAGE}, "~> 0.1"})

ExUnit.start()

defmodule CleanRoom.SmokeTest do
  use ExUnit.Case

  alias ${COMPANION_MODULE}

  test "validate_dependency/0 returns :ok when engine (${ENGINE_MODULE}) is installed" do
    # Engine is explicitly in deps — Code.ensure_loaded?(${ENGINE_MODULE}) must be true
    assert ${COMPANION_MODULE_SUFFIX}.validate_dependency() == :ok
  end

  test "companion_id/0 returns :${COMPANION_SUFFIX}" do
    assert ${COMPANION_MODULE_SUFFIX}.companion_id() == :${COMPANION_SUFFIX}
  end

  test "enabled?/1 respects config — false when no :enabled key" do
    refute ${COMPANION_MODULE_SUFFIX}.enabled?(%{})
  end

  test "enabled?/1 respects config — true when enabled: true" do
    assert ${COMPANION_MODULE_SUFFIX}.enabled?(%{enabled: true})
  end
$(if [ "$PACKAGE" = "crosswake_rindle" ]; then cat <<'CANARYEOF'

  # rindle-only Contracts canary (D-18): confirms the Contracts sub-module shipped in
  # the tarball. rindle owns Crosswake.Companions.Rindle.Contracts (unlike rulestead,
  # which had no sub-module to verify). Single canary, not a full Contracts suite (D-17).
  test "Rindle.Contracts.media_state_vocabulary/0 returns a non-empty list (canary: Contracts shipped)" do
    vocab = Crosswake.Companions.Rindle.Contracts.media_state_vocabulary()

    assert is_list(vocab) and vocab != [],
           "[crosswake] Rindle.Contracts.media_state_vocabulary/0 returned empty — " <>
             "the Crosswake.Companions.Rindle.Contracts module may be missing from the tarball"
  end
CANARYEOF
fi)
end
SMOKEEOF
fi

echo "[crosswake] Step 5: running smoke test..."
mix test test/smoke_test.exs

echo "[crosswake] Step 5 OK: inline smoke test passed"

# ---------------------------------------------------------------------------
# Step 6: Register companion + engine in config/runtime.exs (D-17)
# ---------------------------------------------------------------------------

echo "[crosswake] Step 6: writing runtime config for ${PACKAGE} (${PROFILE})..."

mkdir -p config

if [ "$PACKAGE" = "crosswake_threadline" ]; then
# crosswake_threadline is NOT a Crosswake.Companion implementor — it is wired via
# Plug/LiveView on_mount, not the :companions registry. Do NOT register it under :companions
# (doing so would cause doctor to emit companion.dependency_missing since threadline has
# no validate_dependency/0). No runtime config is needed for the module-shipment canaries.
mkdir -p config
cat >> config/runtime.exs <<CONFIGEOF

import Config
# Clean-room: crosswake_threadline — pure-OTP audit/correlation observer, NOT in :companions.
# No :companions registration — threadline is wired via Crosswake.Plug.Threadline (Plug) and
# Crosswake.Live.Threadline (on_mount), not the companion registry.
CONFIGEOF
elif [ "$NO_ENGINE" = "1" ]; then
# No-engine mode: register companion only — no engine config line (sigra needs no engine).
cat >> config/runtime.exs <<CONFIGEOF

import Config
# Clean-room: register ${COMPANION_MODULE} (no-engine mode — pure-Elixir auth, no engine dep)
config :crosswake, :companions, [${COMPANION_MODULE}]
config :crosswake, :${COMPANION_SUFFIX}, enabled: true
CONFIGEOF
else
# Engine mode: register companion + engine config.
cat >> config/runtime.exs <<CONFIGEOF

import Config
# Clean-room: register ${COMPANION_MODULE} with engine ${ENGINE_MODULE} enabled
config :crosswake, :companions, [${COMPANION_MODULE}]
config :crosswake, :${COMPANION_SUFFIX}, enabled: true
CONFIGEOF
fi

if [ "$PACKAGE" = "crosswake_threadline" ]; then
  ok "Step 6: package=${PACKAGE} version=${VERSION} profile=${PROFILE} state=observer-not-registered"
else
  ok "Step 6: package=${PACKAGE} version=${VERSION} profile=${PROFILE} state=companion-registered"
fi

# ---------------------------------------------------------------------------
# Step 7: Run mix crosswake.doctor --router and assert exit 0 (D-19/D-20)
# ---------------------------------------------------------------------------

echo "[crosswake] Step 7: running mix crosswake.doctor --router CleanRoomHost.Router..."

# Compile setup only after runtime config changes; mix crosswake.doctor is the proof.
mix compile

mix crosswake.doctor --router CleanRoomHost.Router

ok "Step 7: package=${PACKAGE} version=${VERSION} core_floor=${CORE_REQUIREMENT} selected_core=${SELECTED_CORE_VERSION} profile=${PROFILE} state=doctor-green"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

ok "verify_companion_cleanroom: package=${PACKAGE} version=${VERSION} core_floor=${CORE_REQUIREMENT} selected_core=${SELECTED_CORE_VERSION} profile=${PROFILE} state=passed"
log "Next safe command: elixir script/check_release_workflow_integrity.exs"
