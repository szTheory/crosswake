#!/bin/sh
# One-time evidence tooling (phase 183 D-17). Not product code.
set -eu
umask 077
CAND=${1:?candidate dir}; OUT=${2:?output record}; PREV=${3:-}
MANIFEST=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json
ACTIVATION=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/route_activation.json
STUDY=examples/phoenix_host/priv/static/offline_study.js
MEDIA=examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff

g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}
if ! P=$(g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none 2>/dev/null | wc -c) ; then echo "refused: probe_unavailable"; exit 4; fi
if ! g rev-parse --git-dir >/dev/null 2>&1; then echo "refused: probe_unavailable"; exit 4; fi
if [ "$P" -ne 0 ]; then echo "refused: source_dirty"; exit 3; fi
EXC=$(g rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null) || { echo "refused: probe_unavailable"; exit 4; }
if [ -f "$EXC" ]; then
  N=$(grep -Ev '^[[:space:]]*(#|$)' "$EXC" | wc -l | tr -d ' ')
  if [ "$N" -ne 0 ]; then echo "refused: source_dirty"; exit 3; fi
fi
if [ -e "$OUT" ]; then echo "refused: record_exists"; exit 5; fi

HEAD_SHA=$(g rev-parse HEAD); TREE=$(g rev-parse 'HEAD^{tree}')
dig() { g show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }
DM=$(dig $MANIFEST); DA=$(dig $ACTIVATION); DS=$(dig $STUDY); DF=$(dig $MEDIA)
PHYS=$(cd "$CAND" && pwd -P)
OUTDIR=$(dirname "$OUT")
TMP=$(mktemp "$OUTDIR/.prep-record.XXXXXX")
jq -n --arg p "$PHYS" --arg h "$HEAD_SHA" --arg t "$TREE" --arg m "$DM" --arg a "$DA" --arg s "$DS" --arg f "$DF" \
  '{candidate_path:$p,expected_head:$h,expected_tree:$t,origin:"http://127.0.0.1:4790",resource_digests:[$m,$a,$s],fixture_digests:[$f]}' > "$TMP"
chmod 0600 "$TMP"
mv -n "$TMP" "$OUT"
if [ -e "$TMP" ]; then rm -f "$TMP"; echo "refused: record_exists"; exit 5; fi
[ "$(jq -r .expected_head "$OUT")" = "$HEAD_SHA" ] || { echo "refused: write_failed"; exit 6; }
echo "new head $HEAD_SHA"; echo "new tree $TREE"
echo "new manifest $DM"; echo "new activation $DA"; echo "new study_js $DS"; echo "new media $DF"
if [ -n "$PREV" ] && [ -f "$PREV" ]; then
  echo "old head $(jq -r .expected_head "$PREV")"; echo "old tree $(jq -r .expected_tree "$PREV")"
  echo "old manifest $(jq -r '.resource_digests[0]' "$PREV")"; echo "old activation $(jq -r '.resource_digests[1]' "$PREV")"
  echo "old study_js $(jq -r '.resource_digests[2]' "$PREV")"; echo "old media $(jq -r '.fixture_digests[0]' "$PREV")"
fi
