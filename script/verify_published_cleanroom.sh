#!/usr/bin/env bash
# verify_published_cleanroom.sh <X.Y.Z>
#
# Fail-closed clean-room proof (REL-06) that a published Crosswake version is
# consumable from nothing but the public registries. Three legs, all required:
#
#   hex    resolve crosswake == <version> from hex.pm into a fresh mix project,
#          require the mix.lock outer checksum to equal the registry checksum,
#          compile, and require Application.spec(:crosswake, :vsn) == <version>
#   maven  download the .pom, .module and .aar of
#          io.github.sztheory:crosswake-shell-core-android:<version> from Maven
#          Central, check each against its published .sha256, and require the
#          pom <version> to match and <packaging> to be aar
#   ios    find refs/tags/v<version> on the SwiftPM mirror, clone it shallowly,
#          and `swift build` it
#
# Exit codes: 0 every leg passed; 1 any leg failed; 2 usage error or a refused
# override. A missing tool is a FAIL for that leg (tool_unavailable), never a
# skip. No credential is used and every registry is read unauthenticated.
# No repository clone is needed: the work happens in a throwaway directory this
# script creates and removes, and nothing is read from beside the script.
#
# Toolchain selectors (not verdict overrides): when the caller sets both
# CLEANROOM_ELIXIR_VERSION and CLEANROOM_ERLANG_VERSION, the hex leg writes
# them into a version file inside its own throwaway project so asdf shims
# resolve; otherwise it uses whatever `mix` PATH finds.
#
# Selftest overrides (honored only with CLEANROOM_SELFTEST=1; without it any
# override exits 2): CLEANROOM_LEGS, CLEANROOM_MAVEN_BASE, CLEANROOM_HEX_API.
# With the flag set the run announces itself and ends `result SELFTEST`,
# never `result PASS`.
#
# Output contract (parsed by later phases):
#   cleanroom: leg <leg> PASS <version> <detail>
#   cleanroom: FAIL <leg> <reason>
#   cleanroom: result PASS|FAIL|SELFTEST legs <list> version <version>

set -uo pipefail

DEFAULT_LEGS="hex,maven,ios"
MAVEN_DEFAULT_BASE="https://repo1.maven.org/maven2"
HEX_DEFAULT_API="https://hex.pm/api"
MIRROR_URL="https://github.com/szTheory/crosswake-shell-core-ios.git"

usage() {
  echo "cleanroom: usage verify_published_cleanroom.sh <X.Y.Z>"
  exit 2
}

[ "$#" -eq 1 ] || usage
VERSION="$1"
case "$VERSION" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) usage ;;
esac
if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  usage
fi

SELFTEST="${CLEANROOM_SELFTEST:-}"
LEGS="${CLEANROOM_LEGS:-$DEFAULT_LEGS}"
MAVEN_BASE="${CLEANROOM_MAVEN_BASE:-$MAVEN_DEFAULT_BASE}"
HEX_API="${CLEANROOM_HEX_API:-$HEX_DEFAULT_API}"

if [ "$SELFTEST" != "1" ]; then
  if [ "$LEGS" != "$DEFAULT_LEGS" ] || [ -n "${CLEANROOM_MAVEN_BASE:-}" ] || [ -n "${CLEANROOM_HEX_API:-}" ]; then
    echo "cleanroom: override refused (set CLEANROOM_SELFTEST=1 to use selftest overrides)"
    exit 2
  fi
else
  echo "cleanroom: selftest overrides active"
fi

FAILED=0
LEGS_RUN=""

# Never prompt for credentials; every registry is read anonymously.
export GIT_TERMINAL_PROMPT=0

WORK=""
cleanup() { [ -n "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

fail() { # leg reason
  echo "cleanroom: FAIL $1 $2"
  FAILED=1
}

need_tools() { # leg tool...
  local leg="$1" t
  shift
  for t in "$@"; do
    if ! command -v "$t" >/dev/null 2>&1; then
      fail "$leg" tool_unavailable
      return 1
    fi
  done
  return 0
}

sha256_of() { # file -> hex digest
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    sha256sum "$1" | cut -d' ' -f1
  fi
}

# fetch <url> <dest>: 0 ok, 3 not published (404 / missing file), 4 other failure.
fetch() {
  local url="$1" dest="$2" code rc
  code=$(curl -sS -L -o "$dest" -w '%{http_code}' "$url" 2>/dev/null)
  rc=$?
  case "$url" in
    file://*)
      [ "$rc" -eq 0 ] && [ -f "$dest" ] && return 0
      return 3
      ;;
  esac
  [ "$rc" -eq 0 ] || return 4
  case "$code" in
    200) return 0 ;;
    404) return 3 ;;
    *) return 4 ;;
  esac
}

mk_work() {
  if [ -z "$WORK" ]; then
    WORK=$(mktemp -d "${TMPDIR:-${RUNNER_TEMP:-/tmp}}/crosswake-cleanroom.XXXXXX") || return 1
  fi
}

leg_maven() {
  need_tools maven curl cut grep mktemp || return
  if [ -z "$(command -v shasum 2>/dev/null)$(command -v sha256sum 2>/dev/null)" ]; then
    fail maven tool_unavailable
    return
  fi
  mk_work || { fail maven tool_unavailable; return; }
  local dir="$WORK/maven"
  mkdir -p "$dir"
  local art="crosswake-shell-core-android"
  local url_base="$MAVEN_BASE/io/github/sztheory/$art/$VERSION"
  local ext name rc published actual aar_sha=""
  for ext in pom module aar; do
    name="$art-$VERSION.$ext"
    fetch "$url_base/$name" "$dir/$name"; rc=$?
    if [ "$rc" -eq 3 ]; then fail maven not_published; return; fi
    if [ "$rc" -ne 0 ]; then fail maven fetch_failed; return; fi
    fetch "$url_base/$name.sha256" "$dir/$name.sha256"; rc=$?
    if [ "$rc" -eq 3 ]; then fail maven not_published; return; fi
    if [ "$rc" -ne 0 ]; then fail maven fetch_failed; return; fi
    published=$(tr -d '\r' <"$dir/$name.sha256" | head -n1 | cut -d' ' -f1 | tr 'A-F' 'a-f')
    actual=$(sha256_of "$dir/$name")
    if [ -z "$published" ] || [ "$published" != "$actual" ]; then
      fail maven checksum_mismatch
      return
    fi
    [ "$ext" = "aar" ] && aar_sha="$actual"
  done
  if ! grep -Fq "<version>$VERSION</version>" "$dir/$art-$VERSION.pom" ||
    ! grep -Fq "<packaging>aar</packaging>" "$dir/$art-$VERSION.pom"; then
    fail maven pom_mismatch
    return
  fi
  echo "cleanroom: leg maven PASS $VERSION aar $(printf '%s' "$aar_sha" | cut -c1-12)"
}

leg_hex() {
  need_tools hex curl grep cut tr mktemp || return
  local jsontool=""
  if command -v jq >/dev/null 2>&1; then
    jsontool="jq"
  elif command -v python3 >/dev/null 2>&1; then
    jsontool="python3"
  else
    fail hex tool_unavailable
    return
  fi
  mk_work || { fail hex tool_unavailable; return; }
  local meta="$WORK/hex-release.json" rc registry
  fetch "$HEX_API/packages/crosswake/releases/$VERSION" "$meta"; rc=$?
  if [ "$rc" -eq 3 ]; then fail hex not_published; return; fi
  if [ "$rc" -ne 0 ]; then fail hex resolve_failed; return; fi
  if [ "$jsontool" = "jq" ]; then
    registry=$(jq -r '.checksum // empty' "$meta" 2>/dev/null)
  else
    registry=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1])).get("checksum") or "")' "$meta" 2>/dev/null)
  fi
  registry=$(printf '%s' "$registry" | tr 'A-F' 'a-f')
  if [ -z "$registry" ]; then fail hex not_published; return; fi

  if ! command -v mix >/dev/null 2>&1; then fail hex tool_unavailable; return; fi
  local host="$WORK/cleanroom_host"
  mkdir -p "$host"
  if [ -n "${CLEANROOM_ELIXIR_VERSION:-}" ] && [ -n "${CLEANROOM_ERLANG_VERSION:-}" ]; then
    printf 'erlang %s\nelixir %s\n' "$CLEANROOM_ERLANG_VERSION" "$CLEANROOM_ELIXIR_VERSION" >"$host/.tool-versions"
    echo "cleanroom: toolchain elixir $CLEANROOM_ELIXIR_VERSION erlang $CLEANROOM_ERLANG_VERSION"
  else
    echo "cleanroom: toolchain path"
  fi
  local log="$WORK/hex.log"
  if ! (cd "$host" && mix new . --app cleanroom_host) >"$log" 2>&1; then
    fail hex tool_unavailable
    return
  fi
  printf 'defmodule CleanroomHost.MixProject do\n  use Mix.Project\n\n  def project do\n    [app: :cleanroom_host, version: "0.0.0", elixir: "~> 1.15", deps: deps()]\n  end\n\n  def application, do: [extra_applications: [:logger]]\n\n  defp deps, do: [{:crosswake, "== %s"}]\nend\n' "$VERSION" >"$host/mix.exs"
  if ! (cd "$host" && mix deps.get) >>"$log" 2>&1; then
    fail hex resolve_failed
    return
  fi
  local lock locked
  lock=$(grep -E '^[[:space:]]*"crosswake":' "$host/mix.lock" 2>/dev/null | head -n1)
  locked=$(printf '%s' "$lock" | grep -Eo '"[0-9a-fA-F]{64}"' | tail -n1 | tr -d '"' | tr 'A-F' 'a-f')
  if [ -z "$locked" ] || [ "$locked" != "$registry" ]; then
    fail hex checksum_mismatch
    return
  fi
  if ! (cd "$host" && mix compile) >>"$log" 2>&1; then
    fail hex compile_failed
    return
  fi
  local vsn
  vsn=$(cd "$host" && mix run -e 'v = Application.spec(:crosswake, :vsn) |> to_string(); IO.puts("vsn=" <> v)' 2>>"$log" | grep -E '^vsn=' | tail -n1)
  if [ "$vsn" != "vsn=$VERSION" ]; then
    fail hex vsn_mismatch
    return
  fi
  echo "cleanroom: leg hex PASS $VERSION checksum $(printf '%s' "$locked" | cut -c1-12)"
}

leg_ios() {
  need_tools ios git swift mktemp || return
  mk_work || { fail ios tool_unavailable; return; }
  local refs
  refs=$(git ls-remote "$MIRROR_URL" "refs/tags/v$VERSION" 2>/dev/null)
  if [ -z "$refs" ]; then fail ios not_published; return; fi
  local clone="$WORK/ios-mirror" log="$WORK/ios.log"
  if ! git clone --quiet --depth 1 --branch "v$VERSION" "$MIRROR_URL" "$clone" >"$log" 2>&1; then
    fail ios clone_failed
    return
  fi
  if ! swift build --package-path "$clone" >>"$log" 2>&1; then
    fail ios build_failed
    return
  fi
  echo "cleanroom: leg ios PASS $VERSION tag_commit $(git -C "$clone" rev-parse HEAD | cut -c1-12)"
}

IFS=',' read -r -a LEG_LIST <<<"$LEGS"
for leg in "${LEG_LIST[@]}"; do
  case "$leg" in
    hex | maven | ios) ;;
    *) echo "cleanroom: override refused (unknown leg)"; exit 2 ;;
  esac
done
for leg in "${LEG_LIST[@]}"; do
  "leg_$leg"
done
LEGS_RUN="$LEGS"

if [ "$FAILED" -ne 0 ]; then
  echo "cleanroom: result FAIL legs $LEGS_RUN version $VERSION"
  exit 1
fi
if [ "$SELFTEST" = "1" ]; then
  echo "cleanroom: result SELFTEST legs $LEGS_RUN version $VERSION"
  exit 0
fi
echo "cleanroom: result PASS legs $LEGS_RUN version $VERSION"
exit 0
