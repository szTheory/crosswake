#!/bin/sh
# Phase 192 post-merge verifier (LAND-04, criterion 4, R-1, D-04, D-08). GET reads only; never reruns,
# dispatches, edits a workflow or touches the release PR.
# Modes: baseline tracer|before|after | verify [MAX_POLLS]
# Exit: 0 pass, 1 check failed, 2 scope or input error. Prints only `postmerge:` labels.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/common-192.sh"

PM_SLEEP=60
[ -z "${T192_SLEEP:-}" ] || PM_SLEEP=$POLL_SLEEP
PKGS="crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline"
BDIR="$EV192/binding"
BF="$BDIR/merge-binding-192.txt"

say() { echo "postmerge: $1"; }
die() { say "$1"; exit "${2:-1}"; }

kv() { # FILE KEY -> rest of the first line whose first word is KEY
  [ -f "$1" ] || return 0
  awk -v k="$2" '$1==k {sub(/^[^ ]+ /,""); print; exit}' "$1"
}

# --- release and package surface: OUTFILE (stdout of the record) ----------
take_baseline() { # OUTFILE ; returns 2 on any failed or empty read
  _tb_out=$1
  _tb_t="$R192/pm-base.txt"
  : > "$_tb_t"
  ghx api "repos/$REPO_SLUG/releases" --paginate --jq '.[].tag_name' > "$R192/pm-rel.txt" 2>/dev/null || return 2
  [ -s "$R192/pm-rel.txt" ] || return 2
  LC_ALL=C sort "$R192/pm-rel.txt" | awk 'NF==1 && $1 !~ /[^A-Za-z0-9._+-]/ {print "release " $1; next} {bad=1} END{exit bad+0}' >> "$_tb_t" || return 2
  ghx api "repos/$REPO_SLUG/releases/latest" --jq '[.tag_name,.published_at]|@tsv' > "$R192/pm-lat.tsv" 2>/dev/null || return 2
  awk -F'\t' 'NR==1 && NF==2 && $1 ~ /^[A-Za-z0-9._+-]+$/ && $2 ~ /^[0-9TZ:-]+$/ {print "release_latest " $1 " " $2; ok=1} END{exit !ok}' "$R192/pm-lat.tsv" >> "$_tb_t" || return 2
  ghx api "repos/$REPO_SLUG/tags" --paginate --jq '.[].name' > "$R192/pm-tag.txt" 2>/dev/null || return 2
  [ -s "$R192/pm-tag.txt" ] || return 2
  LC_ALL=C sort "$R192/pm-tag.txt" | awk 'NF==1 && $1 !~ /[^A-Za-z0-9._+-]/ {print "tag " $1; next} {bad=1} END{exit bad+0}' >> "$_tb_t" || return 2
  for _p in $PKGS; do
    curl -fsS "https://hex.pm/api/packages/$_p" > "$R192/pm-hex.json" 2>/dev/null || return 2
    _hv=$(jq -r '.latest_stable_version // empty' "$R192/pm-hex.json" 2>/dev/null) || return 2
    case "$_hv" in
      [0-9]*.[0-9]*.[0-9]*) : ;;
      *) return 2 ;;
    esac
    case "$_hv" in
      *[!0-9A-Za-z.+-]*) return 2 ;;
    esac
    printf 'hex %s %s\n' "$_p" "$_hv" >> "$_tb_t"
  done
  ev_write "$_tb_out" < "$_tb_t" || return 2
  return 0
}

mode=${1:-}

case "$mode" in
  baseline)
    LABEL=${2:-}
    case "$LABEL" in
      tracer|before|after) : ;;
      *) die "bad label" 2 ;;
    esac
    mkdir -p "$EV192"
    take_baseline "$EV192/baselines-$LABEL-192.txt" || die "unreadable" 2
    say "baseline $LABEL recorded"
    exit 0
    ;;

  verify)
    MAX=${2:-45}
    is_int "$MAX" && [ "$MAX" -ge 1 ] || die "input missing" 2
    MF="$EV192/merge-192.txt"
    CF="$EV192/ci-192.txt"
    BEF="$EV192/baselines-before-192.txt"
    [ -f "$MF" ] && [ -f "$BF" ] && [ -f "$CF" ] && [ -f "$BEF" ] || die "input missing" 2
    MC=$(kv "$MF" merge_commit)
    BHEAD=$(kv "$MF" bound_head)
    BSTATE=$(kv "$BF" state)
    BH2=$(kv "$BF" head)
    BTREE=$(kv "$BF" synthetic_tree)
    BMAIN=$(kv "$BF" main)
    is_sha40 "$MC" && is_sha40 "$BHEAD" && is_sha40 "$BH2" && is_sha40 "$BTREE" && is_sha40 "$BMAIN" || die "input missing" 2
    [ "$(kv "$MF" result)" = merged ] && [ "$BSTATE" = consumed ] && [ "$BH2" = "$BHEAD" ] || die "input missing" 2

    # (a) the pull request check fact, from the poller's evidence
    CHEAD=$(kv "$CF" head)
    CCON=$(kv "$CF" conclusion)
    CTREE=$(kv "$CF" synthetic_tree)
    if [ "$CHEAD" != "$BHEAD" ] || [ "$CCON" != success ] || [ "$CTREE" != "$BTREE" ]; then
      die "pr check fact missing" 1
    fi

    # (b) the merge commit: two parents, order, tested tree, on main
    ghx api "repos/$REPO_SLUG/commits/$MC" --jq '[(.parents|length|tostring), ([.parents[].sha]|join(" "))]|@tsv' > "$R192/pm-par.tsv" 2>/dev/null || die "unreadable" 2
    NPAR=$(awk -F'\t' 'NR==1{print $1}' "$R192/pm-par.tsv")
    PARS=$(awk -F'\t' 'NR==1{print $2}' "$R192/pm-par.tsv")
    is_int "$NPAR" || die "unreadable" 2
    [ "$NPAR" -eq 2 ] || die "parents $NPAR" 1
    P1=$(printf '%s\n' "$PARS" | awk '{print $1}')
    P2=$(printf '%s\n' "$PARS" | awk '{print $2}')
    is_sha40 "$P1" && is_sha40 "$P2" || die "unreadable" 2
    { [ "$P1" = "$MAIN_SHA" ] && [ "$P1" = "$BMAIN" ]; } || die "first parent not main" 1
    [ "$P2" = "$BHEAD" ] || die "second parent not bound head" 1
    ghx api "repos/$REPO_SLUG/git/commits/$MC" --jq '.tree.sha' > "$R192/pm-tree.txt" 2>/dev/null || die "unreadable" 2
    MTREE=$(awk 'NR==1{print $1}' "$R192/pm-tree.txt")
    is_sha40 "$MTREE" || die "unreadable" 2
    [ "$MTREE" = "$BTREE" ] || die "tree differs from tested merge" 1
    ghx api "repos/$REPO_SLUG/compare/$MC...main" --jq '.status' > "$R192/pm-cmp.txt" 2>/dev/null || die "unreadable" 2
    CST=$(awk 'NR==1{print $1}' "$R192/pm-cmp.txt")
    case "$CST" in
      identical|ahead) : ;;
      '') die "unreadable" 2 ;;
      *) die "merge not on main" 1 ;;
    esac

    # (c) push-triggered runs on the merge commit
    i=0
    RPID=
    while :; do
      i=$((i + 1))
      ghx run list -R "$REPO_SLUG" --commit "$MC" --event push --json databaseId,workflowName,status,conclusion,headSha > "$R192/pm-runs.json" 2>/dev/null || die "unreadable" 2
      jq -e 'type=="array"' "$R192/pm-runs.json" >/dev/null 2>&1 || die "unreadable" 2
      jq -c --arg s "$MC" '[.[]|select(.headSha==$s)]' "$R192/pm-runs.json" > "$R192/pm-runs-sel.json" 2>/dev/null || die "unreadable" 2
      RPSEL=$(jq -r '[.[]|select(.workflowName=="Release Please")]|sort_by(.databaseId)|last|select(. != null)|[.databaseId,.status,(.conclusion // "-")]|@tsv' "$R192/pm-runs-sel.json" 2>/dev/null) || die "unreadable" 2
      PEND=$(jq -r '[.[]|select(.workflowName!="Release Please" and .workflowName!="See It Run Collateral" and .status!="completed")]|length' "$R192/pm-runs-sel.json" 2>/dev/null) || die "unreadable" 2
      is_int "$PEND" || die "unreadable" 2
      RPST=
      if [ -n "$RPSEL" ]; then
        RPID=$(printf '%s\n' "$RPSEL" | awk -F'\t' '{print $1}')
        RPST=$(printf '%s\n' "$RPSEL" | awk -F'\t' '{print $2}')
        RPCON=$(printf '%s\n' "$RPSEL" | awk -F'\t' '{print $3}')
        is_int "$RPID" || die "unreadable" 2
        if [ "$RPST" = completed ] && [ "$PEND" -eq 0 ]; then break; fi
      fi
      if [ "$i" -ge "$MAX" ]; then
        if [ -z "$RPST" ]; then die "release-please run missing" 1; fi
        if [ "$RPST" != completed ]; then die "release-please conclusion pending" 1; fi
        die "other push run not green" 1
      fi
      sleep "$PM_SLEEP"
    done
    [ "$RPCON" = success ] || die "release-please conclusion $RPCON" 1

    ghx run view "$RPID" -R "$REPO_SLUG" --json jobs > "$R192/pm-jobs.json" 2>/dev/null || die "unreadable" 2
    jq -e '(.jobs|type)=="array"' "$R192/pm-jobs.json" >/dev/null 2>&1 || die "unreadable" 2
    PCRE='^(Publish|Mirror iOS core|Clean-room proof|release: exact-public artifact proof)'
    NPUB=$(jq -r --arg re "$PCRE" '[.jobs[]|select(.name|test($re))]|length' "$R192/pm-jobs.json" 2>/dev/null) || die "unreadable" 2
    NSKIP=$(jq -r --arg re "$PCRE" '[.jobs[]|select((.name|test($re)) and .conclusion=="skipped")]|length' "$R192/pm-jobs.json" 2>/dev/null) || die "unreadable" 2
    is_int "$NPUB" && is_int "$NSKIP" || die "unreadable" 2
    [ "$NPUB" -ge 1 ] || die "publish-class jobs not found" 1
    [ "$NPUB" -eq "$NSKIP" ] || die "publish-class job ran" 1
    GCON=$(jq -r '[.jobs[]|select(.name=="release: approved-candidate merge guard")]|first|.conclusion // "-"' "$R192/pm-jobs.json" 2>/dev/null) || die "unreadable" 2
    [ "$GCON" = success ] || die "guard not success" 1

    NOTH=$(jq -r '[.[]|select(.workflowName!="Release Please" and .workflowName!="See It Run Collateral")]|length' "$R192/pm-runs-sel.json" 2>/dev/null) || die "unreadable" 2
    NOGR=$(jq -r '[.[]|select(.workflowName!="Release Please" and .workflowName!="See It Run Collateral" and .status=="completed" and .conclusion=="success")]|length' "$R192/pm-runs-sel.json" 2>/dev/null) || die "unreadable" 2
    is_int "$NOTH" && is_int "$NOGR" || die "unreadable" 2
    [ "$NOTH" -eq "$NOGR" ] || die "other push run not green" 1
    ADV=$(jq -r '[.[]|select(.workflowName=="See It Run Collateral")]|sort_by(.databaseId)|last|if . == null then "absent" elif .status != "completed" then "in_progress" else (.conclusion // "absent") end' "$R192/pm-runs-sel.json" 2>/dev/null) || die "unreadable" 2
    case "$ADV" in
      success|failure|cancelled|in_progress|absent) : ;;
      *) ADV=other ;;
    esac

    # release surface unchanged
    take_baseline "$EV192/baselines-after-192.txt" || die "unreadable" 2
    cmp -s "$BEF" "$EV192/baselines-after-192.txt" || die "baseline changed" 1

    {
      printf 'merge_commit %s\n' "$MC"
      printf 'parents 2\n'
      printf 'first_parent %s\n' "$P1"
      printf 'second_parent %s\n' "$P2"
      printf 'tree_equals_tested_merge yes\n'
      printf 'merge_on_main yes\n'
      printf 'pr_check_success yes\n'
      printf 'release_please_run %s\n' "$RPID"
      printf 'release_please success\n'
      printf 'guard success\n'
      printf 'publish_class_jobs %s skipped %s\n' "$NPUB" "$NSKIP"
      printf 'other_push_runs %s green %s\n' "$NOTH" "$NOGR"
      printf 'advisory_see_it_run %s\n' "$ADV"
      printf 'baselines_unchanged yes\n'
      printf 'main_green yes\n'
      printf 'result pass\n'
    } | ev_write "$EV192/postmerge-192.txt" || die "unreadable" 2
    say "main green"
    exit 0
    ;;

  *)
    die "usage" 2
    ;;
esac
