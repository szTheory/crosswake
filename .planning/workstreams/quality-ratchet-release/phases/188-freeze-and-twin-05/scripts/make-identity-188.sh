#!/bin/sh
# One-time evidence tooling (phase 188 D-10). Values come from git output only.
set -eu
umask 077
if [ -n "${T188_SELFTEST_ROOT:-}" ]; then
  ROOT=$(cd "$T188_SELFTEST_ROOT" 2>/dev/null && pwd -P) || { echo "refused: selftest_root"; exit 3; }
  case "$ROOT" in /private/tmp/crosswake-selftest-188-02.*) ;; *) echo "refused: selftest_root"; exit 3 ;; esac
  CAND=$ROOT/cand; PD=$ROOT/pd
else
  CAND=/private/tmp/crosswake-phase180-impl
  PD=$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05
fi
OUT=$PD/188-IDENTITY.json
MANIFEST=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json
ACTIVATION=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/route_activation.json
MEDIA=examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}
g rev-parse --git-dir >/dev/null 2>&1 || { echo "refused: probe_unavailable"; exit 4; }
st=$(g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none 2>/dev/null) || { echo "refused: probe_unavailable"; exit 4; }
[ -z "$st" ] || { echo "refused: source_dirty"; exit 3; }
EXC=$(g rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null) || { echo "refused: probe_unavailable"; exit 4; }
if [ -f "$EXC" ]; then
  N=$(grep -Ev '^[[:space:]]*(#|$)' "$EXC" | wc -l | tr -d ' ')
  [ "$N" -eq 0 ] || { echo "refused: source_dirty"; exit 3; }
fi
if [ -e "$OUT" ]; then echo "refused: record_exists"; exit 5; fi

HEAD_SHA=$(g rev-parse HEAD) || { echo "refused: probe_unavailable"; exit 4; }
TREE=$(g rev-parse 'HEAD^{tree}') || { echo "refused: probe_unavailable"; exit 4; }
BLOB=$(mktemp)
trap 'rm -f "$BLOB"' EXIT
dig() {
  g cat-file blob "HEAD:$1" > "$BLOB" || { echo "refused: probe_unavailable"; exit 4; }
  shasum -a 256 < "$BLOB" | cut -d' ' -f1
}
DM=$(dig "$MANIFEST"); DA=$(dig "$ACTIVATION"); DF=$(dig "$MEDIA")
SZ=$(g cat-file -s "HEAD:$MEDIA") || { echo "refused: probe_unavailable"; exit 4; }
case "$SZ" in "" | *[!0-9]*) echo "refused: probe_unavailable"; exit 4 ;; esac
NOTE="Computed by make-identity-188.sh from git show HEAD output of the frozen Phase 188 candidate; read by the twin for media and generated digests only."
TMP=$(mktemp "$PD/.identity.XXXXXX")
jq -n --arg h "$HEAD_SHA" --arg t "$TREE" --arg mp "$MEDIA" --argjson sz "$SZ" --arg df "$DF" --arg dm "$DM" --arg da "$DA" --arg note "$NOTE" \
  '{schema:"crosswake.phase180.identity/1",supersedes:"183-IDENTITY.json",candidate_head:$h,candidate_tree:$t,media:{path:$mp,size:$sz,sha256:$df},generated:{manifest_sha256:$dm,activation_sha256:$da},note:$note}' > "$TMP"
chmod 0600 "$TMP"
mv -n "$TMP" "$OUT"
if [ -e "$TMP" ]; then rm -f "$TMP"; echo "refused: record_exists"; exit 5; fi
[ "$(jq -r .candidate_head "$OUT")" = "$HEAD_SHA" ] || { echo "refused: write_failed"; exit 6; }
echo "identity head $HEAD_SHA"
