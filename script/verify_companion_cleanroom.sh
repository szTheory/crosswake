#!/usr/bin/env bash
# verify_companion_cleanroom.sh — Post-publish clean-room resolvability + doctor proof (PROOF-01).
#
# Usage:
#   bash script/verify_companion_cleanroom.sh [PACKAGE [VERSION [ENGINE_PACKAGE [ENGINE_MODULE]]]]
#
# Arguments:
#   PACKAGE        Hex package name (default: crosswake_rulestead)
#   VERSION        Hex version to verify — REQUIRED (e.g. 0.1.0)
#   ENGINE_PACKAGE Engine Hex package name (default: rulestead); pass empty string or "none" to
#                  activate no-engine mode (sigra has no engine dep — pure-Elixir auth machinery).
#   ENGINE_MODULE  Engine top-level Elixir module atom (default: Rulestead); ignored in no-engine mode.
#
# What this script does (D-17, SC#3):
#   1. Polls Hex.pm propagation until VERSION is listed for PACKAGE.
#   2. Creates a throwaway Phoenix host app OUTSIDE the monorepo in $RUNNER_TEMP.
#   3. Installs the published duo (no-engine) or trio (engine): crosswake + PACKAGE [+ ENGINE_PACKAGE].
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
# NOTE: Full end-to-end execution is CI-only / post-publish (PROOF-01 irreversible).
# This script requires a live published crosswake_PACKAGE on Hex.pm — it cannot run
# locally before the Phase 131 publish job cuts the first release.
#
# Failure messages lead with [crosswake] (BRAND-SPEC §6): name what happened + what to do next.

set -euo pipefail

# ---------------------------------------------------------------------------
# Parameters (D-16)
# ---------------------------------------------------------------------------

PACKAGE="${1:-crosswake_rulestead}"
VERSION="${2:?}" # required: VERSION?: pass a semver string as \$2 (e.g. bash script/verify_companion_cleanroom.sh crosswake_rulestead 0.1.0)
if [ -z "${VERSION:-}" ]; then
  echo "[crosswake] FAIL: VERSION required as \$2 (e.g. 0.1.0)"
  exit 1
fi

# No-engine mode: activated when $3/$4 are omitted, empty, or the sentinel "none".
# Sigra has no engine dep — pure-Elixir auth machinery, validate_dependency/0 is always :ok.
# The default engine path (rulestead/Rulestead) is preserved for back-compat.
_RAW_ENGINE_PKG="${3:-}"
_RAW_ENGINE_MOD="${4:-}"
if [ -z "$_RAW_ENGINE_PKG" ] || [ "$_RAW_ENGINE_PKG" = "none" ]; then
  NO_ENGINE=1
  ENGINE_PACKAGE=""
  ENGINE_MODULE=""
else
  NO_ENGINE=0
  ENGINE_PACKAGE="${_RAW_ENGINE_PKG:-rulestead}"
  ENGINE_MODULE="${_RAW_ENGINE_MOD:-Rulestead}"
fi

# ---------------------------------------------------------------------------
# Security: validate $VERSION looks like a semver string before using it in
# curl URL construction (T-131-07 injection prevention).
# ---------------------------------------------------------------------------

if ! echo "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][a-zA-Z0-9._-]+)?$'; then
  echo "[crosswake] FAIL: VERSION '${VERSION}' does not look like a valid semver (e.g. 0.1.0)."
  echo "[crosswake] What to do next: pass a valid semver string as \$2."
  exit 1
fi

if [ "$NO_ENGINE" = "1" ]; then
  echo "[crosswake] verify_companion_cleanroom: PACKAGE=${PACKAGE} VERSION=${VERSION} (no-engine mode)"
else
  echo "[crosswake] verify_companion_cleanroom: PACKAGE=${PACKAGE} VERSION=${VERSION} ENGINE_PACKAGE=${ENGINE_PACKAGE} ENGINE_MODULE=${ENGINE_MODULE}"
fi

# ---------------------------------------------------------------------------
# Step 1: Poll Hex.pm propagation (mirror of publish-hex job poll, MAX_ATTEMPTS=36/DELAY=10)
# ---------------------------------------------------------------------------

MAX_ATTEMPTS=36
DELAY=10

echo "[crosswake] Step 1: polling Hex.pm for ${PACKAGE} ${VERSION} (up to $((MAX_ATTEMPTS * DELAY))s)..."

HEX_FOUND=false
for i in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -fsS "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}" | grep -q '"version"'; then
    echo "[crosswake] Hex.pm lists ${PACKAGE} ${VERSION}"
    HEX_FOUND=true
    break
  fi
  echo "[crosswake] waiting for Hex propagation... (${i}/${MAX_ATTEMPTS})"
  sleep "$DELAY"
done

if [ "$HEX_FOUND" = "false" ]; then
  echo "[crosswake] FAIL: timed out waiting for https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}"
  echo "[crosswake] What happened: Hex.pm propagation did not complete within $((MAX_ATTEMPTS * DELAY)) seconds."
  echo "[crosswake] What to do next: check Hex.pm status page; if the package is broken, run: mix hex.retire ${PACKAGE} ${VERSION} invalid"
  exit 1
fi

echo "[crosswake] Step 1 OK: ${PACKAGE} ${VERSION} is live on Hex.pm"

# ---------------------------------------------------------------------------
# Step 2: Create throwaway Phoenix host OUTSIDE the monorepo (D-17)
# ---------------------------------------------------------------------------

CLEAN_ROOM_DIR="${RUNNER_TEMP:-/tmp}/clean-room-${PACKAGE}"

echo "[crosswake] Step 2: creating throwaway Phoenix host at ${CLEAN_ROOM_DIR}..."

rm -rf "$CLEAN_ROOM_DIR"
mkdir -p "$CLEAN_ROOM_DIR"

# mix new in the PARENT of CLEAN_ROOM_DIR, naming the subdirectory
PARENT_DIR=$(dirname "$CLEAN_ROOM_DIR")
APP_NAME=$(basename "$CLEAN_ROOM_DIR")
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
      {:crosswake, "~> 0.1"},
      {:"${PACKAGE}", "~> 0.1"}
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
      {:crosswake, "~> 0.1"},
      {:"${PACKAGE}", "~> 0.1"},
      {:"${ENGINE_PACKAGE}", "~> 0.1"}
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

# Recompile so the router module is loaded before the doctor smoke
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
if [ "$PACKAGE" = "crosswake_chimeway" ]; then
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

echo "[crosswake] Step 6: registering companion in config/runtime.exs..."

mkdir -p config

if [ "$NO_ENGINE" = "1" ]; then
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

echo "[crosswake] Step 6 OK: companion registered"

# ---------------------------------------------------------------------------
# Step 7: Run mix crosswake.doctor --router and assert exit 0 (D-19/D-20)
# ---------------------------------------------------------------------------

echo "[crosswake] Step 7: running mix crosswake.doctor --router CleanRoomHost.Router..."

# Recompile to pick up config/runtime.exs changes
mix compile

mix crosswake.doctor --router CleanRoomHost.Router

echo "[crosswake] Step 7 OK: doctor exited 0 — companion registered, engine present, router accepted"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo "[crosswake] verify_companion_cleanroom: ${PACKAGE} ${VERSION} PASSED"
echo "[crosswake] Clean-room proof: published trio installed, smoke test green, doctor exit 0 (PROOF-01 SC#3)"
