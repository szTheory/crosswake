#!/bin/sh
# Phase 192 gh/curl test double built only from real captured responses (D-08, AGENTS.md real-shape lesson).
# Modes: capture DIR | install BIN SCEN | derive CAPTURED FILTER OUT
# Prints only `shim:` labels. capture makes GET reads only; captured data never leaves DIR.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/common-192.sh"

PR_UNION='number,state,headRefOid,headRefName,baseRefName,isCrossRepository,mergeStateStatus,mergeable,url,title,mergeCommit,mergedAt'
RUN_UNION='databaseId,name,workflowName,status,conclusion,headSha,event'

mode=${1:-}

cap_fail() { echo "shim: capture failed $1"; exit 2; }

do_capture() {
  D=${1:-}
  case "$D" in
    /private/tmp/crosswake-selftest-*) : ;;
    *) echo "shim: capture outside fixture"; exit 2 ;;
  esac
  [ -d "$D" ] || { echo "shim: capture outside fixture"; exit 2; }
  N=0
  # NAME then the gh/curl argv
  cap() {
    _cn=$1
    shift
    if [ "$1" = curl ]; then
      shift
      curl -fsS "$@" > "$D/$_cn" 2>/dev/null || cap_fail "${_cn%.json}"
    else
      ghx "$@" > "$D/$_cn" 2>/dev/null || cap_fail "${_cn%.json}"
    fi
    [ -s "$D/$_cn" ] || cap_fail "${_cn%.json}"
    jq -e . "$D/$_cn" >/dev/null 2>&1 || cap_fail "${_cn%.json}"
    N=$((N + 1))
  }
  # open release PR, else newest open PR
  ghx pr list -R "$REPO_SLUG" --state open --limit 100 --json number,headRefName > "$D/.open-list" 2>/dev/null || cap_fail pr-open
  OPN=$(jq -r '([.[]|select(.headRefName|startswith("release-please--"))]|sort_by(.number)|last) // (sort_by(.number)|last) | .number // empty' "$D/.open-list" 2>/dev/null)
  rm -f "$D/.open-list"
  is_int "$OPN" || cap_fail pr-open
  cap pr-open.json pr view "$OPN" -R "$REPO_SLUG" --json "$PR_UNION"
  ghx api "repos/$REPO_SLUG/commits/$MAIN_SHA/pulls" > "$D/.mp" 2>/dev/null || cap_fail pr-merged
  MPR=$(jq -r '[.[]|select(.merged_at != null)]|sort_by(.number)|first|.number // empty' "$D/.mp" 2>/dev/null)
  rm -f "$D/.mp"
  is_int "$MPR" || cap_fail pr-merged
  cap pr-merged.json pr view "$MPR" -R "$REPO_SLUG" --json "$PR_UNION"
  MH=$(jq -r '.headRefOid // empty' "$D/pr-merged.json" 2>/dev/null)
  is_sha40 "$MH" || cap_fail pr-merged
  cap pr-list.json pr list -R "$REPO_SLUG" --state open --limit 3 --json number,url,state,headRefName,headRefOid
  cap check-runs.json api "repos/$REPO_SLUG/commits/$MH/check-runs?per_page=100"
  cap pull.json api "repos/$REPO_SLUG/pulls/$MPR"
  cap git-commit.json api "repos/$REPO_SLUG/git/commits/$MAIN_SHA"
  cap commit.json api "repos/$REPO_SLUG/commits/$MAIN_SHA"
  cap compare.json api "repos/$REPO_SLUG/compare/$MAIN_SHA...main"
  cap run-list-push.json run list -R "$REPO_SLUG" --commit "$MAIN_SHA" --event push --json "$RUN_UNION"
  RP=$(jq -r '[.[]|select(.workflowName=="Release Please")|.databaseId]|max // empty' "$D/run-list-push.json" 2>/dev/null)
  is_int "$RP" || cap_fail run-view-jobs
  cap run-view-jobs.json run view "$RP" -R "$REPO_SLUG" --json jobs
  cap run-list-pr.json run list -R "$REPO_SLUG" --workflow crosswake-ci.yml --commit "$MH" --json "$RUN_UNION"
  cap protection.json api "repos/$REPO_SLUG/branches/main/protection/required_status_checks"
  cap releases.json api "repos/$REPO_SLUG/releases?per_page=3"
  cap release-latest.json api "repos/$REPO_SLUG/releases/latest"
  cap tags.json api "repos/$REPO_SLUG/tags?per_page=3"
  cap hex-crosswake.json curl https://hex.pm/api/packages/crosswake
  echo "shim: captured $N"
}

# --- install: write gh and curl stubs answering from a scenario folder -----
do_install() {
  BIN=${1:-}
  SC=${2:-}
  [ -d "$BIN" ] && [ -d "$SC" ] || { echo "shim: unknown"; exit 2; }
  mkdir -p "$SC/api" "$SC/curl" "$SC/.cnt"
  : > "$SC/argv.log"
  _stub=$BIN/.stub-body
  cat > "$_stub" <<'EOF'
set -f
LOGGED=$1
shift
SCEN=__SCEN__
KIND=$LOGGED
line=$KIND
for a in "$@"; do line="$line $a"; done
printf '%s\n' "$line" >> "$SCEN/argv.log"
PRU='number,state,headRefOid,headRefName,baseRefName,isCrossRepository,mergeStateStatus,mergeable,url,title,mergeCommit,mergedAt'
RUNU='databaseId,name,workflowName,status,conclusion,headSha,event'
JSONF=
JQE=
HAVEJQ=
args=
skip=
for a in "$@"; do
  if [ -n "$skip" ]; then
    case "$skip" in
      json) JSONF=$a ;;
      jq) JQE=$a; HAVEJQ=1 ;;
    esac
    skip=
    continue
  fi
  case "$a" in
    -R|--repo) skip=ign ;;
    --json) skip=json ;;
    --jq) skip=jq ;;
    --paginate|--slurp) : ;;
    --state|--limit|--commit|--workflow|--event|--branch|--user) skip=ign ;;
    -*) : ;;
    *) args="$args $a" ;;
  esac
done
set -- $args
NAME=
FIELDS=
if [ "$KIND" = curl ]; then
  url=$1
  NAME=curl/${url##*/}
  FIELDS=
else
  case "${1:-}:${2:-}" in
    pr:view) NAME=pr-view; FIELDS=$PRU ;;
    pr:list) NAME=pr-list; FIELDS=$PRU ;;
    pr:merge) echo "$line" >> "$SCEN/write.log"; rc=0; [ -f "$SCEN/pr-merge.rc" ] && rc=$(cat "$SCEN/pr-merge.rc")
      if { [ "$rc" -eq 0 ] || [ -f "$SCEN/pr-merge-lands" ]; } && [ -f "$SCEN/pr-view-after.json" ]; then cp "$SCEN/pr-view-after.json" "$SCEN/pr-view.json"; fi
      exit "$rc" ;;
    pr:create) echo "$line" >> "$SCEN/write.log"; rc=0; [ -f "$SCEN/pr-create.rc" ] && rc=$(cat "$SCEN/pr-create.rc"); exit "$rc" ;;
    run:rerun) echo "$line" >> "$SCEN/write.log"; rc=0; [ -f "$SCEN/run-rerun.rc" ] && rc=$(cat "$SCEN/run-rerun.rc"); exit "$rc" ;;
    run:list) NAME=run-list; FIELDS=$RUNU ;;
    run:view) NAME=run-view-${3:-}; FIELDS=jobs ;;
    api:*) ep=${2:-}; NAME=api/$(printf '%s' "$ep" | tr '/' '_'); FIELDS= ;;
    *) echo "shim: unknown"; exit 97 ;;
  esac
fi
# numbered files: FILE.1 FILE.2 ... served in order, last repeated
base=$SCEN/$NAME.json
if [ -f "$base.1" ]; then
  cf=$SCEN/.cnt/$(printf '%s' "$NAME" | tr '/' '_')
  n=0
  [ -f "$cf" ] && n=$(cat "$cf")
  n=$((n + 1))
  printf '%s\n' "$n" > "$cf"
  k=1
  while [ "$k" -lt "$n" ] && [ -f "$base.$((k + 1))" ]; do k=$((k + 1)); done
  src=$base.$k
elif [ -f "$base" ]; then
  src=$base
else
  echo "shim: no scenario"; exit 99
fi
if [ -f "$SCEN/$NAME.rc" ]; then
  rc=$(cat "$SCEN/$NAME.rc")
  if [ "$rc" -ne 0 ]; then exit "$rc"; fi
fi
if [ -n "$JSONF" ]; then
  allowed=",$FIELDS,"
  oldifs=$IFS
  IFS=,
  for f in $JSONF; do
    case "$allowed" in
      *",$f,"*) : ;;
      *) echo "shim: field not captured"; exit 98 ;;
    esac
  done
  IFS=$oldifs
  prog='def pick($ks): . as $o | reduce $ks[] as $k ({}; .[$k] = $o[$k]); ($f|split(",")) as $ks | if type=="array" then map(pick($ks)) else pick($ks) end'
  if [ -n "$HAVEJQ" ]; then
    jq -c --arg f "$JSONF" "$prog" "$src" | jq -r "$JQE"
  else
    jq -c --arg f "$JSONF" "$prog" "$src"
  fi
  exit $?
fi
if [ -n "$HAVEJQ" ]; then
  jq -r "$JQE" "$src"
  exit $?
fi
cat "$src"
EOF
  # embed scenario path; the stubs source the shared body
  _esc=$(printf '%s' "$SC" | sed 's/[&|]/\\&/g')
  sed "s|__SCEN__|$_esc|" "$_stub" > "$BIN/.stub-body.tmp" && mv -f "$BIN/.stub-body.tmp" "$_stub"
  printf '#!/bin/sh\n. "%s/.stub-body"\n' "$BIN" > "$BIN/gh.real"
  for t in gh curl; do
    {
      printf '#!/bin/sh\n'
      printf 'set -- %s "$@"\n' "$t"
      printf '. "%s/.stub-body"\n' "$BIN"
    } > "$BIN/$t"
    chmod 700 "$BIN/$t"
  done
  rm -f "$BIN/gh.real"
  echo "shim: installed"
}

# --- derive: jq FILTER over captured file(s); refuse any new JSON path ------
paths_of() { # FILE -> sorted unique normalized path list on stdout
  jq -r '[paths | map(if type=="number" then "N" else tostring end) | join(".")] | unique | .[]' "$1"
}

do_derive() {
  CAP=${1:-}
  FILT=${2:-}
  OUT=${3:-}
  [ -n "$CAP" ] && [ -n "$FILT" ] && [ -n "$OUT" ] || { echo "shim: unknown"; exit 2; }
  _dt=$(mktemp "$(dirname "$OUT")/.derive.XXXXXX") || { echo "shim: shape changed"; exit 2; }
  _dp=$(mktemp "$(dirname "$OUT")/.derive-p.XXXXXX") || { rm -f "$_dt"; echo "shim: shape changed"; exit 2; }
  _dq=$(mktemp "$(dirname "$OUT")/.derive-q.XXXXXX") || { rm -f "$_dt" "$_dp"; echo "shim: shape changed"; exit 2; }
  : > "$_dp"
  oldifs=$IFS
  IFS=:
  first=
  for f in $CAP; do
    [ -f "$f" ] || { IFS=$oldifs; rm -f "$_dt" "$_dp" "$_dq"; echo "shim: shape changed"; exit 2; }
    [ -n "$first" ] || first=$f
    paths_of "$f" >> "$_dp" 2>/dev/null || { IFS=$oldifs; rm -f "$_dt" "$_dp" "$_dq"; echo "shim: shape changed"; exit 2; }
  done
  IFS=$oldifs
  sort -u "$_dp" > "$_dq"
  if ! jq "$FILT" "$first" > "$_dt" 2>/dev/null; then
    rm -f "$_dt" "$_dp" "$_dq"
    echo "shim: shape changed"
    exit 2
  fi
  paths_of "$_dt" 2>/dev/null | sort -u > "$_dp"
  extra=$(comm -13 "$_dq" "$_dp" | awk 'END{print NR+0}')
  if [ "$extra" != 0 ]; then
    rm -f "$_dt" "$_dp" "$_dq"
    echo "shim: shape changed"
    exit 2
  fi
  rm -f "$_dp" "$_dq"
  mv -f "$_dt" "$OUT"
  echo "shim: derived"
}

case "$mode" in
  capture) do_capture "${2:-}" ;;
  install) do_install "${2:-}" "${3:-}" ;;
  derive) do_derive "${2:-}" "${3:-}" "${4:-}" ;;
  *) echo "shim: unknown"; exit 2 ;;
esac
