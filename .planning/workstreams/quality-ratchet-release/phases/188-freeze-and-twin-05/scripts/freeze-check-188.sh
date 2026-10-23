#!/bin/sh
# One-time evidence tooling (phase 188 D-02). Fixed labels only; never prints paths.
set -eu
umask 077
if [ -n "${T188_SELFTEST_ROOT:-}" ]; then
  ROOT=$(cd "$T188_SELFTEST_ROOT" 2>/dev/null && pwd -P) || { echo "refused: selftest_root"; exit 3; }
  case "$ROOT" in /private/tmp/crosswake-selftest-188-02.*) ;; *) echo "refused: selftest_root"; exit 3 ;; esac
  RUNS=$ROOT/runs; CAND=$ROOT/cand; PD=$ROOT/pd
else
  RUNS=/private/tmp/crosswake-phase180-run
  CAND=/private/tmp/crosswake-phase180-impl
  PD=$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05
fi
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}

FZ=${1:-}
case "$FZ" in "" | *[!0-9a-f]*) echo "refused: usage"; exit 2 ;; esac
[ "${#FZ}" -eq 40 ] || { echo "refused: usage"; exit 2; }
OUT=$PD/188-FREEZE.json
if [ -e "$OUT" ]; then echo "refused: record_exists"; exit 5; fi

RES=""
FAILED=0
rec() {
  RES="$RES$1 $2
"
  if [ "$2" != pass ]; then FAILED=1; fi
}

# 1 head_equals_argument
HEAD_SHA=$(g rev-parse HEAD 2>/dev/null) || HEAD_SHA=none
if [ "$HEAD_SHA" = "$FZ" ]; then rec head_equals_argument pass; else rec head_equals_argument fail; fi

# 2 porcelain_empty
st_rc=0
st=$(g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none 2>/dev/null) || st_rc=$?
if [ "$st_rc" -eq 0 ] && [ -z "$st" ]; then rec porcelain_empty pass; else rec porcelain_empty fail; fi

# 3 info_exclude_empty
exc=$(g rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null) || exc=""
if [ -z "$exc" ]; then
  rec info_exclude_empty fail
elif [ -f "$exc" ]; then
  n=$(grep -Ev '^[[:space:]]*(#|$)' "$exc" | wc -l | tr -d ' ')
  if [ "$n" -eq 0 ]; then rec info_exclude_empty pass; else rec info_exclude_empty fail; fi
else
  rec info_exclude_empty pass
fi

# 4 elixir_probe_all_zero
prc=0
pout=$(cd "$CAND" && MIX_ENV=test MIX_BUILD_PATH="$RUNS/_build_188_freeze" mix run --no-start -e '{:ok, %{modified: 0, flagged: 0, excludes: 0}} = Crosswake.ProofLane.TwinProducers.probe_source(File.cwd!()); IO.puts("probe: all zero")' 2>&1) || prc=$?
plast=$(printf '%s\n' "$pout" | tail -n 1)
if [ "$prc" -eq 0 ] && [ "$plast" = "probe: all zero" ]; then rec elixir_probe_all_zero pass; else rec elixir_probe_all_zero fail; fi

# 5 push_url_no_push
pu=$(g remote get-url --push origin 2>/dev/null) || pu=""
if [ "$pu" = "no-push-phase180" ]; then rec push_url_no_push pass; else rec push_url_no_push fail; fi

# 6 no_gitlinks
lt_rc=0
lt=$(g ls-tree -r HEAD 2>/dev/null) || lt_rc=$?
gl=$(printf '%s\n' "$lt" | awk '$1=="160000"{n++} END{print n+0}')
if [ "$lt_rc" -eq 0 ] && [ "$gl" -eq 0 ]; then rec no_gitlinks pass; else rec no_gitlinks fail; fi

# 7 no_gitmodules
gm_rc=0
g cat-file -e "HEAD:.gitmodules" >/dev/null 2>&1 || gm_rc=$?
if [ "$gm_rc" -ne 0 ] && [ ! -e "$CAND/.gitmodules" ]; then rec no_gitmodules pass; else rec no_gitmodules fail; fi

if [ "$FAILED" -ne 0 ]; then
  printf '%s' "$RES"
  echo "refused: freeze_check_failed"
  exit 1
fi

TREE=$(g rev-parse 'HEAD^{tree}')
CHECKS=$(printf '%s' "$RES" | jq -R -s 'split("\n")|map(select(length>0)|split(" ")|{label:.[0],status:.[1]})')
SUMMARY="One frozen candidate commit means the cumulative tree at the single final HEAD $FZ, which carries every v26 change since 50fcd57, not one commit since 50fcd57."
EXC="Two git-ignored classes inside the candidate are the accepted exception to D-03; neither is twin-attested source and neither changes HEAD, the tree or the porcelain status: (1) _build output written by the example-host warm compile and by verify_twin; (2) the pre-existing example-host SQLite files examples/phoenix_host/crosswake_example.db, crosswake_example.db-shm and crosswake_example.db-wal, which the run is not expected to write because verify_twin gives its ecto.migrate and phx.server children a DATABASE_PATH inside the run root (twin_runtime.ex:140 and 551-552, twin_journey.ex:228-241), and whose size and sha256 are recorded before the launch and after the exit."
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP=$(mktemp "$PD/.freeze.XXXXXX")
jq -n --arg summary "$SUMMARY" --arg h "$FZ" --arg t "$TREE" --argjson checks "$CHECKS" --arg exc "$EXC" --arg at "$NOW" \
  '{summary:$summary,status:"all 7 freeze checks passed",schema:"crosswake.phase188.freeze/1",freeze_head:$h,freeze_tree:$t,checks:$checks,accepted_exception:$exc,recorded_at:$at}' > "$TMP"
chmod 0600 "$TMP"
mv -n "$TMP" "$OUT"
if [ -e "$TMP" ]; then rm -f "$TMP"; echo "refused: record_exists"; exit 5; fi
echo "freeze ok $FZ"
