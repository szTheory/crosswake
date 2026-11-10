#!/usr/bin/env bash
# Phase 201 one-time reconciliation helper (not a CI gate): compare two six-entry Artifact
# observation arrays per package, on metadata_digest and payload_digest.
#
# usage: compare-manifests-201.sh <A.json> <B.json>
# prints: compare: package=<p> metadata=<equal|differ> payload=<equal|differ>   (six lines)
#         compare: metadata_equal=<n>/6 payload_equal=<n>/6 verdict=<EQUAL|DIFFER>
# exit:   0 EQUAL (6/6 and 6/6), 1 DIFFER, 2 unreadable file, not exactly six entries, or a
#         package or digest field is missing (absence is never scored as equality).
set -euo pipefail

PACKAGES="crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline"

usage() {
  echo "usage: compare-manifests-201.sh <A.json> <B.json>" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
A="$1"
B="$2"

# Shape gate for each file: an array of exactly six objects; each of the six packages appears
# exactly once; both digests are 64 lowercase hex characters.
shape_ok() {
  jq -e --arg pkgs "$PACKAGES" '
    ($pkgs | split(" ")) as $want
    | type == "array" and length == 6
      and all(.[]; type == "object"
              and (.package | type == "string")
              and (.metadata_digest | type == "string" and test("^[0-9a-f]{64}$"))
              and (.payload_digest | type == "string" and test("^[0-9a-f]{64}$")))
      and ([.[].package] | sort) == ($want | sort)
  ' "$1" >/dev/null 2>&1
}

[ -r "$A" ] || { echo "compare: unreadable $A" >&2; exit 2; }
[ -r "$B" ] || { echo "compare: unreadable $B" >&2; exit 2; }
shape_ok "$A" || { echo "compare: $A is not a six-package manifest with both digests" >&2; exit 2; }
shape_ok "$B" || { echo "compare: $B is not a six-package manifest with both digests" >&2; exit 2; }

digest() {
  # digest <file> <package> <field>
  jq -er --arg p "$2" --arg f "$3" '.[] | select(.package == $p) | .[$f]' "$1"
}

meta_equal=0
payload_equal=0
for p in $PACKAGES; do
  ma=$(digest "$A" "$p" metadata_digest)
  mb=$(digest "$B" "$p" metadata_digest)
  pa=$(digest "$A" "$p" payload_digest)
  pb=$(digest "$B" "$p" payload_digest)
  if [ "$ma" = "$mb" ]; then m=equal; meta_equal=$((meta_equal + 1)); else m=differ; fi
  if [ "$pa" = "$pb" ]; then q=equal; payload_equal=$((payload_equal + 1)); else q=differ; fi
  echo "compare: package=$p metadata=$m payload=$q"
done

if [ "$meta_equal" -eq 6 ] && [ "$payload_equal" -eq 6 ]; then
  echo "compare: metadata_equal=$meta_equal/6 payload_equal=$payload_equal/6 verdict=EQUAL"
  exit 0
fi
echo "compare: metadata_equal=$meta_equal/6 payload_equal=$payload_equal/6 verdict=DIFFER"
exit 1
