#!/usr/bin/env bash
# Phase 201 one-time reconciliation helper (not a CI gate): officially unpack six Hex tarballs and
# inspect them with a chosen checkout's Crosswake.ReleaseCandidate.Artifact.inspect_cli!/1,
# keeping its stderr (the artifact-provenance lines live there).
#
# usage: inspect-family-201.sh --inspector <checkout> --refs <manifest.json> \
#          --tarballs <dir> --output-root <new dir>
# Uses the caller's MIX_HOME / HEX_HOME. Exit 0 manifest written, 1 inspection or unpack failed,
# 2 usage or missing input. Refuses an existing non-empty --output-root.
set -euo pipefail

PACKAGES="crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline"

usage() {
  echo "usage: inspect-family-201.sh --inspector <checkout> --refs <manifest.json> --tarballs <dir> --output-root <new dir>" >&2
  exit 2
}

INSPECTOR=""
REFS=""
TARBALLS=""
OUT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --inspector) [ "$#" -ge 2 ] || usage; INSPECTOR="$2"; shift 2 ;;
    --refs) [ "$#" -ge 2 ] || usage; REFS="$2"; shift 2 ;;
    --tarballs) [ "$#" -ge 2 ] || usage; TARBALLS="$2"; shift 2 ;;
    --output-root) [ "$#" -ge 2 ] || usage; OUT="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$INSPECTOR" ] && [ -n "$REFS" ] && [ -n "$TARBALLS" ] && [ -n "$OUT" ] || usage
[ -d "$INSPECTOR" ] && [ -f "$INSPECTOR/mix.exs" ] || { echo "inspect: --inspector is not a checkout" >&2; exit 2; }
[ -r "$REFS" ] || { echo "inspect: unreadable --refs" >&2; exit 2; }
[ -d "$TARBALLS" ] || { echo "inspect: --tarballs is not a directory" >&2; exit 2; }
jq -e 'type == "array" and length == 6' "$REFS" >/dev/null 2>&1 || { echo "inspect: --refs is not a six-entry array" >&2; exit 2; }

if [ -e "$OUT" ]; then
  [ -d "$OUT" ] && [ -z "$(ls -A "$OUT")" ] || { echo "inspect: refusing a non-empty --output-root" >&2; exit 2; }
fi

INSPECTOR=$(cd "$INSPECTOR" && pwd -P)
TARBALLS=$(cd "$TARBALLS" && pwd -P)
mkdir -p "$OUT/tarballs" "$OUT/unpacked"
OUT=$(cd "$OUT" && pwd -P)

# Exactly one tarball per package, and nothing else, in --tarballs.
tar_count=$(find "$TARBALLS" -maxdepth 1 -type f -name '*.tar' | wc -l | tr -d ' ')
[ "$tar_count" -eq 6 ] || { echo "inspect: expected exactly six .tar files in --tarballs, found $tar_count" >&2; exit 2; }

: > "$OUT/tarballs.sha256"
ARGS=()
for p in $PACKAGES; do
  version=$(jq -er --arg p "$p" '[.[] | select(.package == $p)] | if length == 1 then .[0].version else empty end' "$REFS") \
    || { echo "inspect: $p not present exactly once in --refs" >&2; exit 2; }
  ref=$(jq -er --arg p "$p" '.[] | select(.package == $p) | .candidate_ref' "$REFS") \
    || { echo "inspect: $p has no candidate_ref in --refs" >&2; exit 2; }
  src="$TARBALLS/$p-$version.tar"
  [ -f "$src" ] || { echo "inspect: missing $p-$version.tar" >&2; exit 2; }

  cp "$src" "$OUT/tarballs/$p-$version.tar"
  tarball="$OUT/tarballs/$p-$version.tar"
  unpacked="$OUT/unpacked/$p"
  mkdir "$unpacked"

  # Same official unpack call as verify_companion_cleanroom.sh matrix_fetch_public_family.
  if ! (cd "$INSPECTOR" && TARBALL="$tarball" UNPACKED_ROOT="$unpacked" elixir -e '
      Application.ensure_all_started(:mix)
      Mix.Local.append_archives()
      bytes = File.read!(System.fetch_env!("TARBALL"))

      case :mix_hex_tarball.unpack(bytes, String.to_charlist(System.fetch_env!("UNPACKED_ROOT"))) do
        {:ok, _result} -> :ok
        _other -> System.halt(1)
      end
    ' >"$OUT/unpack-$p.log" 2>&1); then
    echo "inspect: official unpack failed for $p (see $OUT/unpack-$p.log)" >&2
    exit 1
  fi

  sum=$(shasum -a 256 "$tarball" | awk '{print $1}')
  printf '%s  %s\n' "$sum" "$p-$version.tar" >> "$OUT/tarballs.sha256"
  ARGS+=("$p" "$version" "$ref" "$tarball" "$unpacked" "$sum" "built_tarball")
done

if ! (cd "$INSPECTOR" && mix run --no-start -e 'Crosswake.ReleaseCandidate.Artifact.inspect_cli!(System.argv())' -- \
    "$OUT" "$OUT/manifest.json" "${ARGS[@]}" >/dev/null 2>"$OUT/inspect.stderr"); then
  echo "inspect: Artifact.inspect_cli! failed (see $OUT/inspect.stderr)" >&2
  exit 1
fi
[ -s "$OUT/manifest.json" ] || { echo "inspect: no manifest written" >&2; exit 1; }
exit 0
