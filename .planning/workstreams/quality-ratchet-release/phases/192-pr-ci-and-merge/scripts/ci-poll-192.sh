#!/bin/sh
# Phase 192 CI poller (LAND-03, D-08, D-06). GET reads only; no write to GitHub.
# Modes: required | check SHA | wait PR SHA MAX_POLLS
# Exit: 0 pass, 1 check failed, 2 scope or input error, 3 pending. Prints only `ci-poll:` labels.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/common-192.sh"

# --- required set, read live from branch protection -----------------------
# sets RQ_STATE: ok | changed | unreadable
req_core() {
  RQ_STATE=unreadable
  ghx api "repos/$REPO_SLUG/branches/main/protection/required_status_checks" > "$R192/ci-prot.json" 2>/dev/null || return 0
  _rq=$(jq -r --arg c "$CI_CHECK" --argjson a "$CI_APP" \
    'if (type=="object" and .strict==true and ((.checks|type)=="array") and (.checks|length)==1 and .checks[0].context==$c and .checks[0].app_id==$a) then "ok" else "changed" end' \
    "$R192/ci-prot.json" 2>/dev/null) || return 0
  case "$_rq" in ok|changed) RQ_STATE=$_rq ;; esac
  return 0
}

# --- check-run selection: name + app + head_sha, highest id ----------------
# sets CK_STATE: none | pending | completed | unreadable ; CK_ID, CK_STATUS, CK_WORD
check_core() {
  CK_STATE=unreadable
  CK_ID=
  CK_STATUS=
  CK_WORD=
  is_sha40 "$1" || return 0
  ghx api "repos/$REPO_SLUG/commits/$1/check-runs" --paginate \
    --jq ".check_runs[] | select(.name==\"$CI_CHECK\" and .app.id==$CI_APP and .head_sha==\"$1\") | [.id,.status,(.conclusion // \"-\")] | @tsv" \
    > "$R192/ci-ck.tsv" 2>/dev/null || return 0
  _n=$(awk 'END{print NR+0}' "$R192/ci-ck.tsv")
  if [ "$_n" -eq 0 ]; then CK_STATE=none; return 0; fi
  awk -F'\t' 'NF!=3 || $1 !~ /^[0-9]+$/ || $2=="" || $3=="" {bad=1} END{exit bad+0}' "$R192/ci-ck.tsv" || return 0
  _last=$(sort -n "$R192/ci-ck.tsv" | tail -n 1)
  CK_ID=$(printf '%s\n' "$_last" | awk -F'\t' '{print $1}')
  CK_STATUS=$(printf '%s\n' "$_last" | awk -F'\t' '{print $2}')
  _c=$(printf '%s\n' "$_last" | awk -F'\t' '{print $3}')
  if [ "$CK_STATUS" != completed ]; then CK_STATE=pending; return 0; fi
  case "$_c" in
    success|failure|cancelled|timed_out|action_required|neutral|skipped|stale|startup_failure) CK_WORD=$_c ;;
    *) CK_WORD=other ;;
  esac
  CK_STATE=completed
  return 0
}

mode=${1:-}

case "$mode" in
  required)
    req_core
    case "$RQ_STATE" in
      ok) echo "ci-poll: required set ok"; exit 0 ;;
      changed) echo "ci-poll: required set changed"; exit 2 ;;
      *) echo "ci-poll: unreadable"; exit 2 ;;
    esac
    ;;
  check)
    SHA=${2:-}
    is_sha40 "$SHA" || { echo "ci-poll: bad sha"; exit 2; }
    check_core "$SHA"
    case "$CK_STATE" in
      none) echo "ci-poll: check none"; exit 2 ;;
      pending) echo "ci-poll: check pending $CK_STATUS"; exit 3 ;;
      completed)
        echo "ci-poll: check completed $CK_WORD"
        [ "$CK_WORD" = success ] && exit 0
        exit 1
        ;;
      *) echo "ci-poll: unreadable"; exit 2 ;;
    esac
    ;;
  wait)
    PR=${2:-}
    SHA=${3:-}
    MAX=${4:-}
    is_int "$PR" || { echo "ci-poll: bad pr"; exit 2; }
    is_sha40 "$SHA" || { echo "ci-poll: bad sha"; exit 2; }
    is_int "$MAX" || { echo "ci-poll: bad max"; exit 2; }
    req_core
    case "$RQ_STATE" in
      ok) : ;;
      changed) echo "ci-poll: required set changed"; exit 2 ;;
      *) echo "ci-poll: unreadable"; exit 2 ;;
    esac
    i=0
    while :; do
      i=$((i + 1))
      ghx pr view "$PR" -R "$REPO_SLUG" --json number,state,headRefOid,url > "$R192/ci-pr.json" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
      _pv=$(jq -r '[.state,.headRefOid,.url]|@tsv' "$R192/ci-pr.json" 2>/dev/null) || { echo "ci-poll: unreadable"; exit 2; }
      PSTATE=$(printf '%s\n' "$_pv" | awk -F'\t' '{print $1}')
      PHEAD=$(printf '%s\n' "$_pv" | awk -F'\t' '{print $2}')
      PURL=$(printf '%s\n' "$_pv" | awk -F'\t' '{print $3}')
      [ -n "$PSTATE" ] && [ -n "$PHEAD" ] || { echo "ci-poll: unreadable"; exit 2; }
      [ "$PSTATE" = OPEN ] || { echo "ci-poll: pr not open"; exit 1; }
      [ "$PHEAD" = "$SHA" ] || { echo "ci-poll: head changed"; exit 1; }
      check_core "$SHA"
      case "$CK_STATE" in
        unreadable) echo "ci-poll: unreadable"; exit 2 ;;
        completed) break ;;
        none|pending)
          if [ "$i" -ge "$MAX" ]; then
            if [ "$CK_STATE" = none ]; then echo "ci-poll: no check-run"; else echo "ci-poll: timeout"; fi
            exit 1
          fi
          sleep "$POLL_SLEEP"
          ;;
      esac
    done
    # --- completed: find the workflow run and failing jobs ------------------
    RUN=none
    ghx run list -R "$REPO_SLUG" --workflow crosswake-ci.yml --commit "$SHA" --event pull_request \
      --json databaseId,headSha,status,conclusion,event > "$R192/ci-runs.json" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
    _r=$(jq -r --arg s "$SHA" '[.[]|select(.headSha==$s)|.databaseId]|max // empty' "$R192/ci-runs.json" 2>/dev/null) || { echo "ci-poll: unreadable"; exit 2; }
    if is_int "$_r"; then RUN=$_r; fi
    NSJ=0
    NSNAMES=
    if [ "$RUN" != none ]; then
      ghx run view "$RUN" -R "$REPO_SLUG" --json jobs > "$R192/ci-jobs.json" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
      jq -r '.jobs[] | select(.conclusion != "success" and .conclusion != "skipped") | .name' "$R192/ci-jobs.json" > "$R192/ci-jobs.txt" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
      NSJ=$(awk 'END{print NR+0}' "$R192/ci-jobs.txt")
      NSNAMES=$(awk 'NR>1{printf ","} {printf "%s",$0}' "$R192/ci-jobs.txt")
    fi
    mkdir -p "$EV192"
    {
      printf 'head %s check_run %s conclusion %s run %s nonsuccess_jobs %s' "$SHA" "$CK_ID" "$CK_WORD" "$RUN" "$NSJ"
      [ -z "$NSNAMES" ] || printf ' %s' "$NSNAMES"
      printf '\n'
    } >> "$EV192/ci-history-192.txt"
    if [ "$CK_WORD" != success ]; then
      echo "ci-poll: conclusion $CK_WORD"
      exit 1
    fi
    is_int "$RUN" || { echo "ci-poll: unreadable"; exit 2; }
    # --- success: the synthetic merge GitHub tested (D-08) -------------------
    ghx api "repos/$REPO_SLUG/pulls/$PR" --jq '[.merge_commit_sha, .head.sha]|@tsv' > "$R192/ci-pull.tsv" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
    SYN=$(awk -F'\t' 'NR==1{print $1}' "$R192/ci-pull.tsv")
    PH2=$(awk -F'\t' 'NR==1{print $2}' "$R192/ci-pull.tsv")
    [ "$PH2" = "$SHA" ] || { echo "ci-poll: head changed"; exit 1; }
    is_sha40 "$SYN" || { echo "ci-poll: synthetic merge unproven"; exit 1; }
    ghx api "repos/$REPO_SLUG/git/commits/$SYN" --jq '[([.parents[].sha]|join(" ")), .tree.sha]|@tsv' > "$R192/ci-syn.tsv" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
    SPAR=$(awk -F'\t' 'NR==1{print $1}' "$R192/ci-syn.tsv")
    STREE=$(awk -F'\t' 'NR==1{print $2}' "$R192/ci-syn.tsv")
    if [ "$SPAR" != "$MAIN_SHA $SHA" ] || ! is_sha40 "$STREE"; then
      echo "ci-poll: synthetic merge unproven"
      exit 1
    fi
    # jobs whose checkout ref is the pull request head SHA (178 D-18)
    g "$IC" show HEAD:.github/workflows/crosswake-ci.yml > "$R192/ci-wf.yml" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
    HSJ=$(awk '
      /^jobs:/ {injobs=1; next}
      injobs && /^  [A-Za-z0-9_-]+:[ ]*$/ {id=$1; sub(/:$/,"",id); next}
      injobs && id != "" && /^[ ]+ref:[ ]*\$\{\{[ ]*github\.event\.pull_request\.head\.sha/ { if (!(id in seen)) {seen[id]=1; order[++n]=id} }
      END { for (k=1;k<=n;k++) printf "%s%s", (k>1?",":""), order[k] }
    ' "$R192/ci-wf.yml")
    [ -n "$HSJ" ] || HSJ=none
    {
      printf 'pr %s\n' "$PR"
      printf 'url %s\n' "$PURL"
      printf 'head %s\n' "$SHA"
      printf 'check_name %s\n' "$CI_CHECK"
      printf 'check_app %s\n' "$CI_APP"
      printf 'check_run_id %s\n' "$CK_ID"
      printf 'conclusion success\n'
      printf 'run_id %s\n' "$RUN"
      printf 'run_event pull_request\n'
      printf 'required_set ok\n'
      printf 'synthetic_merge %s\n' "$SYN"
      printf 'synthetic_parents %s %s\n' "$MAIN_SHA" "$SHA"
      printf 'synthetic_tree %s\n' "$STREE"
      printf 'ran_on synthetic_merge\n'
      printf 'head_sourced_jobs %s\n' "$HSJ"
      printf 'nonsuccess_jobs %s\n' "$NSJ"
      printf 'result success\n'
    } | ev_write "$EV192/ci-192.txt" || { echo "ci-poll: unreadable"; exit 2; }
    echo "ci-poll: success"
    exit 0
    ;;
  *)
    echo "ci-poll: usage"
    exit 2
    ;;
esac
