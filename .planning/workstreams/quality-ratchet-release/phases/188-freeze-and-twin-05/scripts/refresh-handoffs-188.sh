#!/bin/sh
# One-time evidence tooling (phase 188 D-09). Git-derived values only; argument required.
set -eu
umask 077
W=$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release
if [ -n "${T188_SELFTEST_ROOT:-}" ]; then
  ROOT=$(cd "$T188_SELFTEST_ROOT" 2>/dev/null && pwd -P) || { echo "refused: selftest_root"; exit 3; }
  case "$ROOT" in /private/tmp/crosswake-selftest-188-02.*) ;; *) echo "refused: selftest_root"; exit 3 ;; esac
  CAND=$ROOT/cand; P180=$ROOT/p180; P182=$ROOT/p182
else
  CAND=/private/tmp/crosswake-phase180-impl
  P180=$W/phases/180-bounded-digital-twin-demonstration
  P182=$W/phases/182-loopback-origin-for-local-ios-host
fi
R180=$P180/180-SEAM-HANDOFF.json
R182=$P182/182-FINAL-HEAD.json
B180=$P180/180-SEAM-HANDOFF.pre-188.json
B182=$P182/182-FINAL-HEAD.pre-188.json
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}

# 1 argument
FZ=${1:-}
case "$FZ" in "" | *[!0-9a-f]*) echo "refused: usage"; exit 2 ;; esac
[ "${#FZ}" -eq 40 ] || { echo "refused: usage"; exit 2; }

# 2 clean candidate and HEAD equals argument
g rev-parse --git-dir >/dev/null 2>&1 || { echo "refused: source_dirty"; exit 3; }
st_rc=0
st=$(g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none 2>/dev/null) || st_rc=$?
[ "$st_rc" -eq 0 ] || { echo "refused: source_dirty"; exit 3; }
[ -z "$st" ] || { echo "refused: source_dirty"; exit 3; }
EXC=$(g rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null) || { echo "refused: source_dirty"; exit 3; }
if [ -f "$EXC" ]; then
  N=$(grep -Ev '^[[:space:]]*(#|$)' "$EXC" | wc -l | tr -d ' ')
  [ "$N" -eq 0 ] || { echo "refused: source_dirty"; exit 3; }
fi
HEAD_SHA=$(g rev-parse HEAD) || { echo "refused: head_mismatch"; exit 4; }
[ "$HEAD_SHA" = "$FZ" ] || { echo "refused: head_mismatch"; exit 4; }
TREE=$(g rev-parse 'HEAD^{tree}') || { echo "refused: head_mismatch"; exit 4; }

# 3 schemas
[ -f "$R180" ] && [ -f "$R182" ] || { echo "refused: schema_unexpected"; exit 8; }
jq -e '.schema=="crosswake.phase180.seam_handoff/1" and (.repaired_head|type)=="string" and (.repaired_tree|type)=="string"' "$R180" >/dev/null 2>&1 || { echo "refused: schema_unexpected"; exit 8; }
jq -e '.schema=="crosswake.phase182.final_head/1" and (.head|type)=="string" and (.tree|type)=="string" and (.base_head|type)=="string" and (.core_diff_paths|type)=="array"' "$R182" >/dev/null 2>&1 || { echo "refused: schema_unexpected"; exit 8; }
OLD180=$(jq -r .repaired_head "$R180"); OLDT180=$(jq -r .repaired_tree "$R180")
OLD182=$(jq -r .head "$R182"); OLDT182=$(jq -r .tree "$R182"); BASE182=$(jq -r .base_head "$R182")

# 4 ancestry
for old in "$OLD180" "$OLD182" "$BASE182"; do
  rc=0
  g merge-base --is-ancestor "$old" "$FZ" >/dev/null 2>&1 || rc=$?
  [ "$rc" -eq 0 ] || { echo "refused: not_ancestor"; exit 5; }
done

# 5 no existing copy
if [ -e "$B180" ] || [ -e "$B182" ]; then echo "refused: pre188_exists"; exit 6; fi

# diff list, captured with its status
d_rc=0
DIFF=$(g diff --name-only "$BASE182" "$FZ" 2>/dev/null) || d_rc=$?
[ "$d_rc" -eq 0 ] || { echo "refused: verify_failed"; exit 7; }
PATHS=$(printf '%s\n' "$DIFF" | jq -R -s 'split("\n")|map(select(length>0))')
NPATHS=$(printf '%s' "$PATHS" | jq 'length')
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 6 copies
cp -n "$R180" "$B180"; cmp -s "$R180" "$B180" || { echo "refused: verify_failed"; exit 7; }
cp -n "$R182" "$B182"; cmp -s "$R182" "$B182" || { echo "refused: verify_failed"; exit 7; }

# 7 build both new records in temp files before replacing either
M180=$(stat -f %Lp "$R180"); M182=$(stat -f %Lp "$R182")
T180=$(mktemp "$P180/.refresh.XXXXXX"); T182=$(mktemp "$P182/.refresh.XXXXXX")
jq --arg h "$HEAD_SHA" --arg t "$TREE" --arg oh "$OLD180" --arg ot "$OLDT180" --arg at "$NOW" \
  '.repaired_head=$h | .repaired_tree=$t
   | .supersedes={repaired_head:$oh,repaired_tree:$ot,source:"180-SEAM-HANDOFF.pre-188.json"}
   | .refreshed={by:"refresh-handoffs-188.sh",at:$at,candidate_path:"/private/tmp/crosswake-phase180-impl"}' "$R180" > "$T180"
jq --arg h "$HEAD_SHA" --arg t "$TREE" --arg oh "$OLD182" --arg ot "$OLDT182" --arg at "$NOW" --argjson paths "$PATHS" \
  '.supersedes={head:$oh,tree:$ot,core_diff_paths:.core_diff_paths,source:"182-FINAL-HEAD.pre-188.json"}
   | .head=$h | .tree=$t | .core_diff_paths=$paths
   | .core_diff_paths_meaning="every path changed between base_head and the frozen Phase 188 head, not only Phase 182 core files"
   | .checks_status="not_rerun_at_freeze_head" | .simulator_status="not_rerun_at_freeze_head"
   | .refreshed={by:"refresh-handoffs-188.sh",at:$at,candidate_path:"/private/tmp/crosswake-phase180-impl"}' "$R182" > "$T182"
chmod "$M180" "$T180"; chmod "$M182" "$T182"
mv "$T180" "$R180"; mv "$T182" "$R182"

# 8 verify
jq -e --arg h "$HEAD_SHA" --arg t "$TREE" '.repaired_head==$h and .repaired_tree==$t' "$R180" >/dev/null || { echo "refused: verify_failed"; exit 7; }
jq -e --arg h "$HEAD_SHA" --arg t "$TREE" '.head==$h and .tree==$t' "$R182" >/dev/null || { echo "refused: verify_failed"; exit 7; }
echo "refreshed 180 head $HEAD_SHA"
echo "refreshed 182 head $HEAD_SHA paths $NPATHS"
