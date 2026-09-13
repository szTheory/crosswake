#!/usr/bin/env bash
# Build, dry-run, officially unpack, and normalize the exact six-package candidate family.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
if command -v asdf >/dev/null 2>&1; then
  RUNTIME=(asdf exec)
else
  RUNTIME=()
fi
PACKAGES=(
  crosswake
  crosswake_rulestead
  crosswake_rindle
  crosswake_sigra
  crosswake_chimeway
  crosswake_threadline
)

fail() {
  if [ -n "${LOG:-}" ] && [ -f "$LOG" ]; then
    echo "[crosswake] package log (credential-free):" >&2
    tail -n 80 "$LOG" >&2
  fi
  echo "[crosswake] FAIL: candidate Hex artifact proof is blocked."
  echo "[crosswake] What to do next: inspect the named package step in its invocation-local log and rerun from the exact candidate ref."
  exit 1
}

usage() {
  echo "usage: hex_artifacts.sh --ref <40-lowercase-sha> --output-dir <new-directory> [--manifest <path>]" >&2
  exit 2
}

CANDIDATE_REF=""
OUTPUT_DIR=""
MANIFEST=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ref) [ "$#" -ge 2 ] || usage; CANDIDATE_REF="$2"; shift 2 ;;
    --output-dir) [ "$#" -ge 2 ] || usage; OUTPUT_DIR="$2"; shift 2 ;;
    --manifest) [ "$#" -ge 2 ] || usage; MANIFEST="$2"; shift 2 ;;
    *) usage ;;
  esac
done

printf '%s' "$CANDIDATE_REF" | grep -Eq '^[0-9a-f]{40}$' || usage
[ -n "$OUTPUT_DIR" ] || usage

cd "$REPO_ROOT"
ACTUAL_REF=$(git rev-parse HEAD)
[ "$ACTUAL_REF" = "$CANDIDATE_REF" ] || fail
git diff --quiet "$CANDIDATE_REF" -- . || fail

UNTRACKED_PACKAGE_FILES=$(git ls-files --others --exclude-standard -- \
  lib priv mix.exs README.md LICENSE CHANGELOG.md guides \
  packages/crosswake_rulestead packages/crosswake_rindle packages/crosswake_sigra \
  packages/crosswake_chimeway packages/crosswake_threadline)
[ -z "$UNTRACKED_PACKAGE_FILES" ] || fail
[ ! -e "$OUTPUT_DIR" ] || fail

umask 077
mkdir -p "$OUTPUT_DIR/tarballs" "$OUTPUT_DIR/unpacked" "$OUTPUT_DIR/.scratch/mix-home/archives" "$OUTPUT_DIR/.scratch/hex-home"
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd -P)
if [ -n "$MANIFEST" ]; then
  MANIFEST_PARENT=$(cd "$(dirname "$MANIFEST")" && pwd -P) || fail
  MANIFEST="$MANIFEST_PARENT/$(basename "$MANIFEST")"
else
  MANIFEST="$OUTPUT_DIR/artifacts.json"
fi

cleanup() {
  rm -rf -- "$OUTPUT_DIR/.scratch"
}
trap cleanup EXIT

SOURCE_ARCHIVES=$("${RUNTIME[@]}" elixir -e 'Application.ensure_all_started(:mix); IO.write(Mix.path_for(:archives))') || fail
HEX_ARCHIVE=$(find "$SOURCE_ARCHIVES" -mindepth 1 -maxdepth 1 -type d -name 'hex-*' | sort | tail -1)
[ -n "$HEX_ARCHIVE" ] || fail
cp -R "$HEX_ARCHIVE" "$OUTPUT_DIR/.scratch/mix-home/archives/"

MIX_HOME_ISOLATED="$OUTPUT_DIR/.scratch/mix-home"
HEX_HOME_ISOLATED="$OUTPUT_DIR/.scratch/hex-home"
SENTINEL="crosswake-hermetic-dry-run-not-a-credential"
ASDF_ERLANG_VERSION=$(awk '$1 == "erlang" { print $2 }' "$REPO_ROOT/.tool-versions")
ASDF_ELIXIR_VERSION=$(awk '$1 == "elixir" { print $2 }' "$REPO_ROOT/.tool-versions")

env -u HEX_API_KEY -u HEX_API_KEY_READ_ONLY \
  MIX_HOME="$MIX_HOME_ISOLATED" HEX_HOME="$HEX_HOME_ISOLATED" \
  mix hex.config api_key "$SENTINEL" >/dev/null

ARTIFACT_ARGS=()
CORE_TARBALL=""
CORE_UNPACKED_ROOT=""

prepare_companion_source() {
  local package="$1"
  local source_root="$OUTPUT_DIR/.scratch/sources/$package"
  local package_dir="$source_root/packages/$package"
  local dependency_source

  mkdir -p "$source_root"
  git archive "$CANDIDATE_REF" "packages/$package" | tar -x -C "$source_root"
  mkdir -p "$package_dir/deps"

  for dependency_source in "$REPO_ROOT/packages/$package/deps/"*; do
    [ -e "$dependency_source" ] || continue
    [ "$(basename "$dependency_source")" != "crosswake" ] || continue
    ln -s "$(cd "$dependency_source" && pwd -P)" "$package_dir/deps/$(basename "$dependency_source")"
  done

  mkdir "$package_dir/deps/crosswake"
  cp -R "$CORE_UNPACKED_ROOT/." "$package_dir/deps/crosswake/"

  TARBALL="$CORE_TARBALL" DEP_ROOT="$package_dir/deps/crosswake" LOCKFILE="$package_dir/mix.lock" \
    MIX_HOME="$MIX_HOME_ISOLATED" "${RUNTIME[@]}" elixir -e '
      Application.ensure_all_started(:mix)
      Mix.Local.append_archives()
      {:ok, unpacked} = :mix_hex_tarball.unpack(File.read!(System.fetch_env!("TARBALL")), :memory)
      metadata = unpacked.metadata

      requirements =
        metadata["requirements"]
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(fn {_name, requirement} ->
          app =
            case requirement["app"] do
              "jason" -> :jason
              "nimble_options" -> :nimble_options
              "phoenix" -> :phoenix
              "phoenix_live_view" -> :phoenix_live_view
              "telemetry" -> :telemetry
              _other -> raise "candidate core dependency set changed"
            end

          {app, requirement["requirement"],
           [hex: app, repo: requirement["repository"], optional: requirement["optional"]]}
        end)

      inner = Base.encode16(unpacked.inner_checksum, case: :lower)
      outer = Base.encode16(unpacked.outer_checksum, case: :lower)
      lockfile = System.fetch_env!("LOCKFILE")
      lock = Mix.Dep.Lock.read(lockfile)
      entry = {:hex, :crosswake, metadata["version"], inner, [:mix], requirements, "hexpm", outer}
      File.write!(lockfile, inspect(Map.put(lock, :crosswake, entry), pretty: true, limit: :infinity) <> "\n")

      marker =
        {{:hex, 2, 0},
         %{
           name: "crosswake",
           version: metadata["version"],
           repo: "hexpm",
           managers: [:mix],
           inner_checksum: inner,
           outer_checksum: outer
         }}

      File.write!(Path.join(System.fetch_env!("DEP_ROOT"), ".hex"), :erlang.term_to_binary(marker))
    ' || fail

  # A clean CI checkout has no companion-local deps directory. Resolve the pinned
  # lock before entering the offline package audit; the unpacked candidate core
  # remains the selected crosswake dependency through its generated .hex marker.
  if ! (cd "$package_dir" && env -u HEX_API_KEY -u HEX_API_KEY_READ_ONLY \
    MIX_HOME="$MIX_HOME_ISOLATED" HEX_HOME="$HEX_HOME_ISOLATED" \
    ASDF_ERLANG_VERSION="$ASDF_ERLANG_VERSION" ASDF_ELIXIR_VERSION="$ASDF_ELIXIR_VERSION" \
    "${RUNTIME[@]}" mix deps.get >/dev/null); then
    fail
  fi

  printf '%s' "$package_dir"
}

for PACKAGE in "${PACKAGES[@]}"; do
  if [ "$PACKAGE" = "crosswake" ]; then
    PACKAGE_DIR="$REPO_ROOT"
  else
    [ -n "$CORE_TARBALL" ] && [ -n "$CORE_UNPACKED_ROOT" ] || fail
    PACKAGE_DIR=$(prepare_companion_source "$PACKAGE") || fail
  fi

  VERSION=$(cd "$PACKAGE_DIR" && env \
    ASDF_ERLANG_VERSION="$ASDF_ERLANG_VERSION" ASDF_ELIXIR_VERSION="$ASDF_ELIXIR_VERSION" \
    "${RUNTIME[@]}" elixir -e '
    source = File.read!("mix.exs")
    case Regex.run(~r/@version\s+"([^"]+)"/, source) do
      [_, version] -> IO.write(version)
      _ -> System.halt(1)
    end
  ') || fail

  TARBALL="$OUTPUT_DIR/tarballs/$PACKAGE-$VERSION.tar"
  UNPACKED_ROOT="$OUTPUT_DIR/unpacked/$PACKAGE"
  LOG="$OUTPUT_DIR/.scratch/$PACKAGE.log"

  echo "[crosswake] package=$PACKAGE version=$VERSION step=dry-run"
  if ! (cd "$PACKAGE_DIR" && env -u HEX_API_KEY -u HEX_API_KEY_READ_ONLY \
    CROSSWAKE_RELEASE=1 MIX_HOME="$MIX_HOME_ISOLATED" HEX_HOME="$HEX_HOME_ISOLATED" HEX_OFFLINE=1 \
    ASDF_ERLANG_VERSION="$ASDF_ERLANG_VERSION" ASDF_ELIXIR_VERSION="$ASDF_ELIXIR_VERSION" \
    "${RUNTIME[@]}" mix hex.publish package --dry-run --yes >"$LOG" 2>&1); then
    fail
  fi

  echo "[crosswake] package=$PACKAGE version=$VERSION step=build"
  if ! (cd "$PACKAGE_DIR" && env -u HEX_API_KEY -u HEX_API_KEY_READ_ONLY \
    CROSSWAKE_RELEASE=1 MIX_HOME="$MIX_HOME_ISOLATED" HEX_HOME="$HEX_HOME_ISOLATED" HEX_OFFLINE=1 \
    ASDF_ERLANG_VERSION="$ASDF_ERLANG_VERSION" ASDF_ELIXIR_VERSION="$ASDF_ELIXIR_VERSION" \
    "${RUNTIME[@]}" mix hex.build --output "$TARBALL" >>"$LOG" 2>&1); then
    fail
  fi

  mkdir "$UNPACKED_ROOT"
  echo "[crosswake] package=$PACKAGE version=$VERSION step=official-unpack"
  if ! TARBALL="$TARBALL" UNPACKED_ROOT="$UNPACKED_ROOT" MIX_HOME="$MIX_HOME_ISOLATED" \
    "${RUNTIME[@]}" elixir -e '
      Application.ensure_all_started(:mix)
      Mix.Local.append_archives()
      bytes = File.read!(System.fetch_env!("TARBALL"))

      case :mix_hex_tarball.unpack(bytes, String.to_charlist(System.fetch_env!("UNPACKED_ROOT"))) do
        {:ok, _result} -> :ok
        _other -> System.halt(1)
      end
    ' >>"$LOG" 2>&1; then
    fail
  fi

  OUTER_CHECKSUM=$(shasum -a 256 "$TARBALL" | awk '{print $1}')
  ARTIFACT_ARGS+=("$PACKAGE" "$VERSION" "$TARBALL" "$UNPACKED_ROOT" "$OUTER_CHECKSUM" "built_tarball")

  if [ "$PACKAGE" = "crosswake" ]; then
    CORE_TARBALL="$TARBALL"
    CORE_UNPACKED_ROOT="$UNPACKED_ROOT"
  fi
done

echo "[crosswake] package_family=6 step=normalize"
if ! "${RUNTIME[@]}" mix run --no-start -e 'Crosswake.ReleaseCandidate.Artifact.inspect_cli!(System.argv())' -- \
  "$CANDIDATE_REF" "$OUTPUT_DIR" "$MANIFEST" "${ARTIFACT_ARGS[@]}" >/dev/null; then
  fail
fi

echo "[crosswake] OK: six candidate Hex artifacts were dry-run, built, officially unpacked, and normalized without publication authority."
echo "[crosswake] manifest=$MANIFEST external_state_changed=false"
