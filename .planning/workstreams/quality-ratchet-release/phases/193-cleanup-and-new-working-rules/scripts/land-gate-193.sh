#!/bin/bash
# Phase 193 land gate (D-02, D-11, D-26). Forked from the 192 push and merge gates; nothing from 191/192
# run folders is sourced. Prints only `land:` labels (never a path, token, term or log text).
# Modes:
#   scan-bind REPO                         scan REPO HEAD against live main, write the scan binding
#   push REPO BRANCH --dry-run|--push      the only refspec is HEAD:refs/heads/BRANCH
#   open REPO BRANCH TITLEFILE BODYFILE    privacy check, then open (or reuse) the pull request
#   ci-wait PR SHA MAXPOLLS                read-only wait for the required check on SHA
#   propose PR | answer allow|hold | merge | status
#   --self-test
# Env: LAND193_LABEL (pr1|pr2), LAND193_BDIR (owner-only binding folder), LAND193_WRITES (writes log file).
# Exit: 0 pass, 1 refused or voided, 2 scope or input error, 3 delivery uncertain.
# Self-test hooks (SELFTEST_193=1 only): T193_S191, T193_SLEEP, T193_COPY_TAMPER.
set -u
umask 077
SELF="$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")" || { echo "land: locate failed"; exit 2; }
HERE=$(dirname "$SELF")

_hk=
for _n in T193_S191 T193_SLEEP T193_COPY_TAMPER; do
  eval "_v=\${$_n:-}"
  [ -z "$_v" ] || _hk=1
done
if [ -n "$_hk" ] && [ "${SELFTEST_193:-}" != "1" ]; then
  echo "land: hook set outside self-test"
  exit 2
fi

. "$HERE/paths-193.sh" || { echo "land: locate failed"; exit 2; }
. "$TOP/$S191/git-pinned-191.sh" || { echo "land: locate failed"; exit 2; }

SYS_TMP="/pri""vate/tmp"
SD191="$TOP/$S191"
POLL_SLEEP=60
if [ -n "${T193_S191:-}" ]; then
  case "$T193_S191" in
    "$ST193_PREFIX"*) SD191=$T193_S191 ;;
    *) echo "land: hook outside fixture"; exit 2 ;;
  esac
fi
[ -z "${T193_SLEEP:-}" ] || POLL_SLEEP=$T193_SLEEP

CI_CHECK="Crosswake CI"
CI_APP=15368

say() { echo "land: $1"; }
die() { say "$1"; exit "${2:-1}"; }

is_sha40() {
  case "${1:-}" in
    *[!0-9a-f]*|'') return 1 ;;
  esac
  [ "${#1}" -eq 40 ]
}
is_int() {
  case "${1:-}" in
    *[!0-9]*|'') return 1 ;;
  esac
  return 0
}
ev_write() { # stdin -> FILE, mode 600, atomic
  _ew_f=$1
  _ew_t=$(mktemp "$(dirname "$_ew_f")/.evw.XXXXXX") || return 2
  cat > "$_ew_t" || { rm -f "$_ew_t"; return 2; }
  chmod 600 "$_ew_t" && mv -f "$_ew_t" "$_ew_f"
}
bfget() { # FILE KEY
  [ -f "$1" ] || return 0
  awk -v k="$2" '$1==k {sub(/^[^ ]+ /,""); print; exit}' "$1"
}
abspath() { # FILE -> absolute path of an existing file
  _ap_d=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) || return 1
  printf '%s/%s\n' "$_ap_d" "$(basename "$1")"
}

# ---- temp root and run folder ------------------------------------------------
[ "$_p193_tmpd" != "$SYS_TMP" ] || die "temp root unsafe" 2
case "$RUN193" in
  *[!A-Za-z0-9/._+-]*) die "temp root unsafe" 2 ;;
esac
if [ ! -d "$RUN193" ]; then mkdir -m 0700 "$RUN193" 2>/dev/null || die "temp root unsafe" 2; fi
if [ "$(stat -f %u "$RUN193" 2>/dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$RUN193" 2>/dev/null)" != 700 ]; then
  die "temp root unsafe" 2
fi

ghx() { ( cd "$RUN193" && GH_PROMPT_DISABLED=1 GH_NO_UPDATE_NOTIFIER=1 exec gh "$@" ); }

log_write() { # KIND then the gh argv; absolute paths by basename; never a token
  _lw_line=$1
  shift
  for _lw_a in "$@"; do
    case "$_lw_a" in
      /*) _lw_a=$(basename "$_lw_a") ;;
    esac
    _lw_line="$_lw_line $_lw_a"
  done
  printf '%s\n' "$_lw_line" >> "$WRITES"
}

mode=${1:-}
[ "$mode" = "--self-test" ] || {
  case "${LAND193_LABEL:-}" in
    pr1|pr2) LABEL=$LAND193_LABEL ;;
    *) die "label refused" 2 ;;
  esac
  BDIR=${LAND193_BDIR:-}
  WRITES=${LAND193_WRITES:-}
  [ -n "$BDIR" ] && [ -n "$WRITES" ] || die "env missing" 2
  [ -d "$(dirname "$WRITES")" ] || die "env missing" 2
}

bdir_ready() {
  if [ ! -d "$BDIR" ]; then
    mkdir -p -m 0700 "$BDIR" 2>/dev/null || die "binding dir unsafe" 2
  fi
  if [ "$(stat -f %u "$BDIR" 2>/dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$BDIR" 2>/dev/null)" != 700 ]; then
    die "binding dir unsafe" 2
  fi
  BDIR=$(cd "$BDIR" && pwd -P) || die "binding dir unsafe" 2
}

repo_ok() {
  [ -n "${1:-}" ] && [ -d "$1" ] || die "bad repo" 2
  g "$1" rev-parse --git-dir >/dev/null 2>&1 || die "bad repo" 2
}

branch_ok() { # the only branch names this gate will ever push
  case "${1:-}" in
    main|refs/*|*..*|*/|*.lock|*//*) return 1 ;;
  esac
  printf '%s\n' "${1:-}" | grep -Eq '^(docs|chore)/[a-z0-9][a-z0-9./-]*$'
}

# live remote read for REPO: prints SHA or `absent`; returns 2 when unreadable
live_ref() { # REPO REF
  g "$1" -c credential.helper= -c 'credential.helper=!gh auth git-credential' ls-remote origin "$2" > "$RUN193/lg-ref.out" 2>/dev/null || return 2
  _lr_n=$(awk 'END{print NR+0}' "$RUN193/lg-ref.out")
  if [ "$_lr_n" -eq 0 ]; then echo absent; return 0; fi
  [ "$_lr_n" -eq 1 ] || return 2
  _lr_sha=$(awk '{print $1}' "$RUN193/lg-ref.out")
  _lr_ref=$(awk '{print $2}' "$RUN193/lg-ref.out")
  is_sha40 "$_lr_sha" || return 2
  [ "$_lr_ref" = "$2" ] || return 2
  echo "$_lr_sha"
}

# ---- scan-bind ---------------------------------------------------------------
do_scan_bind() {
  [ "$#" -eq 1 ] || die "usage" 2
  REPO=$1
  repo_ok "$REPO"
  bdir_ready
  B=$(live_ref "$REPO" refs/heads/main); brc=$?
  if [ "$brc" -ne 0 ] || ! is_sha40 "$B"; then die "remote unreadable" 2; fi
  H=$(g "$REPO" rev-parse HEAD 2>/dev/null) || die "bad repo" 2
  is_sha40 "$H" || die "bad repo" 2
  g "$REPO" merge-base --is-ancestor "$B" "$H" >/dev/null 2>&1 || die "main not in head" 1

  # hash-checked relocated scanner copy with scratch under the 193 run folder (Pitfall 1)
  CP="$RUN193/s191"
  case "$CP" in
    "$RUN193"/s191) rm -rf "$CP" ;;
  esac
  mkdir -p "$CP/scripts" "$CP/191-EVIDENCE" || die "scan copy fail" 2
  mkdir -m 0700 "$CP/scan-tmp" || die "scan copy fail" 2
  scanfail() { say "scan copy fail"; exit 2; }
  for _f in scan-191.sh git-pinned-191.sh; do
    [ -f "$SD191/$_f" ] || scanfail
    cp "$SD191/$_f" "$CP/scripts/$_f" || scanfail
  done
  if [ -f "$SD191/../191-EVIDENCE/scan-triage-191.tsv" ]; then
    cp "$SD191/../191-EVIDENCE/scan-triage-191.tsv" "$CP/191-EVIDENCE/scan-triage-191.tsv" || scanfail
  fi
  if [ "${T193_COPY_TAMPER:-}" = 1 ]; then
    printf '#\n' >> "$CP/scripts/git-pinned-191.sh"
  fi
  for _f in scan-191.sh git-pinned-191.sh; do
    _s1=$(shasum -a 256 "$SD191/$_f" | awk '{print $1}')
    _s2=$(shasum -a 256 "$CP/scripts/$_f" | awk '{print $1}')
    { [ -n "$_s1" ] && [ "$_s1" = "$_s2" ]; } || scanfail
  done
  if [ -f "$SD191/../191-EVIDENCE/scan-triage-191.tsv" ]; then
    _s1=$(shasum -a 256 "$SD191/../191-EVIDENCE/scan-triage-191.tsv" | awk '{print $1}')
    _s2=$(shasum -a 256 "$CP/191-EVIDENCE/scan-triage-191.tsv" | awk '{print $1}')
    { [ -n "$_s1" ] && [ "$_s1" = "$_s2" ]; } || scanfail
  fi
  NEEDLE="$SYS_TMP/cross""wake-scan-191."
  REPL="$RUN193/scan-tmp/cw193-scan."
  mkdir -m 0700 "$RUN193/scan-tmp" 2>/dev/null || [ -d "$RUN193/scan-tmp" ] || scanfail
  chmod 700 "$RUN193/scan-tmp" || scanfail
  awk -v n="$NEEDLE" -v r="$REPL" '{ out = ""; line = $0
    while ((i = index(line, n)) > 0) { out = out substr(line, 1, i - 1) r; line = substr(line, i + length(n)) }
    print out line }' "$SD191/scan-191.sh" > "$CP/scripts/scan-191.rewritten" || scanfail
  mv -f "$CP/scripts/scan-191.rewritten" "$CP/scripts/scan-191.sh" || scanfail
  diff "$SD191/scan-191.sh" "$CP/scripts/scan-191.sh" > "$RUN193/lg-diff.out" 2>/dev/null; _drc=$?
  [ "$_drc" -eq 1 ] || scanfail
  _chg=$(awk '/^< /{n++} END{print n+0}' "$RUN193/lg-diff.out")
  [ "$_chg" -eq 2 ] || scanfail
  _l1=$(awk 'END{print NR+0}' "$SD191/scan-191.sh")
  _l2=$(awk 'END{print NR+0}' "$CP/scripts/scan-191.sh")
  [ "$_l1" -eq "$_l2" ] || scanfail
  grep -q -F -e "$SYS_TMP" "$CP/scripts/scan-191.sh"; _grc=$?
  [ "$_grc" -eq 1 ] || scanfail

  # D-26 (A-14 extended): the adopter-term skip is set only here, only for pr1 and pr2
  env -u CROSSWAKE_PRIVATE_ADOPTER_TERMS SCAN191_ADOPTER_SKIP=A-14 bash "$CP/scripts/scan-191.sh" "$REPO" "$B" "$H" > "$RUN193/lg-scan.out" 2>&1
  src=$?
  {
    printf 'head %s\n' "$H"
    printf 'base %s\n' "$B"
    printf 'scan_exit %s\n' "$src"
    printf 'adopter_check skipped_by_user A-14 scope D-26 label %s\n' "$LABEL"
    awk '/^scan: /' "$RUN193/lg-scan.out"
  } | ev_write "$BDIR/scan-$LABEL.txt" || die "unreadable" 2
  case "$src" in
    0) say "scan bound clean"; exit 0 ;;
    1) say "scan hits"; exit 1 ;;
    *) say "scan error"; exit 2 ;;
  esac
}

# ---- push --------------------------------------------------------------------
do_push() {
  [ "$#" -eq 3 ] || die "usage" 2
  REPO=$1
  BRANCH=$2
  case "$3" in
    --dry-run) PMODE=dry-run ;;
    --push) PMODE=push ;;
    *) die "refused argument" 2 ;;
  esac
  repo_ok "$REPO"
  branch_ok "$BRANCH" || die "branch refused" 2
  H=$(g "$REPO" rev-parse HEAD 2>/dev/null) || die "bad repo" 2
  is_sha40 "$H" || die "bad repo" 2
  M=$(live_ref "$REPO" refs/heads/main); mrc=$?
  if [ "$mrc" -ne 0 ] || ! is_sha40 "$M"; then die "remote unreadable" 2; fi
  g "$REPO" merge-base --is-ancestor "$M" "$H" >/dev/null 2>&1 || die "main not in head" 1
  if [ "$PMODE" = push ]; then
    bdir_ready
    SB="$BDIR/scan-$LABEL.txt"
    _bh=$(bfget "$SB" head); _bb=$(bfget "$SB" base); _be=$(bfget "$SB" scan_exit)
    _ba=$(bfget "$SB" adopter_check)
    if ! is_sha40 "$_bh" || ! is_sha40 "$_bb" || [ "$_bh" != "$H" ] || [ "$_bb" != "$M" ] || [ "$_be" != 0 ] \
      || [ "$_ba" != "skipped_by_user A-14 scope D-26 label $LABEL" ]; then
      die "scan binding fail" 1
    fi
  fi
  RB=$(live_ref "$REPO" "refs/heads/$BRANCH"); rbrc=$?
  [ "$rbrc" -eq 0 ] || die "remote unreadable" 2
  if [ "$RB" = "$H" ]; then die "already delivered" 0; fi
  if [ "$RB" != absent ]; then
    g "$REPO" cat-file -e "$RB^{commit}" >/dev/null 2>&1 || die "remote branch unknown" 1
    g "$REPO" merge-base --is-ancestor "$RB" "$H" >/dev/null 2>&1 || die "not fast-forward" 1
  fi
  set -- push --porcelain --no-follow-tags
  [ "$PMODE" != dry-run ] || set -- "$@" --dry-run
  set -- "$@" origin "HEAD:refs/heads/$BRANCH"
  for _a in "$@"; do
    case "$_a" in
      --force|-f|--force-with-lease*|--delete|-d|--tags|--mirror|--all|--prune|+*) die "argv refused" 2 ;; #REFUSAL
    esac
  done
  [ "$PMODE" != push ] || log_write push_branch push origin "HEAD:refs/heads/$BRANCH"
  g "$REPO" -c credential.helper= -c 'credential.helper=!gh auth git-credential' "$@" > "$RUN193/lg-push.out" 2>&1
  prc=$?
  cause=other
  if grep -Eiq 'could not read Username|Authentication failed|403|Permission denied|not logged|authentication' "$RUN193/lg-push.out"; then
    cause=auth
  elif grep -Eiq 'rejected' "$RUN193/lg-push.out"; then
    cause=rejected
  fi
  if [ "$PMODE" = dry-run ]; then
    if [ "$prc" -eq 0 ]; then say "dry-run ok"; exit 0; fi
    say "dry-run failed"
    say "cause $cause"
    exit 1
  fi
  RA=$(live_ref "$REPO" "refs/heads/$BRANCH"); rarc=$?
  if [ "$rarc" -eq 0 ] && [ "$RA" = "$H" ]; then say "delivered"; exit 0; fi
  if [ "$rarc" -eq 0 ] && [ "$prc" -ne 0 ] && [ "$RA" = "$RB" ]; then
    say "not delivered"
    say "cause $cause"
    exit 1
  fi
  die "delivery uncertain" 3
}

# ---- shared GitHub readers (read only) ------------------------------------------
PRF="$RUN193/lg-pr.json"
jf() { jq -r "$1" "$PRF" 2>/dev/null; }
pr_read() { # PR FIELDS
  ghx pr view "$1" -R "$REPO_SLUG" --json "$2" > "$PRF" 2>/dev/null || return 1
  jq -e 'type=="object"' "$PRF" >/dev/null 2>&1 || return 1
  return 0
}
main_live() { # prints the live main SHA of the repository on GitHub; returns 1 when unreadable
  ghx api "repos/$REPO_SLUG/branches/main" --jq .commit.sha > "$RUN193/lg-main.txt" 2>/dev/null || return 1
  _ml=$(awk 'NR==1{print}' "$RUN193/lg-main.txt")
  is_sha40 "$_ml" || return 1
  echo "$_ml"
}
# required contract read live from branch protection: RQ_STATE ok | changed | unreadable
req_core() {
  RQ_STATE=unreadable
  ghx api "repos/$REPO_SLUG/branches/main/protection/required_status_checks" > "$RUN193/lg-prot.json" 2>/dev/null || return 0
  _rq=$(jq -r --arg c "$CI_CHECK" --argjson a "$CI_APP" \
    'if (type=="object" and .strict==true and ((.checks|type)=="array") and (.checks|length)==1 and .checks[0].context==$c and .checks[0].app_id==$a) then "ok" else "changed" end' \
    "$RUN193/lg-prot.json" 2>/dev/null) || return 0
  case "$_rq" in ok|changed) RQ_STATE=$_rq ;; esac
  return 0
}
# check-run selection by name + app + head SHA, highest id: CK_STATE none | pending | completed | unreadable
check_core() {
  CK_STATE=unreadable
  CK_ID=
  CK_WORD=
  is_sha40 "$1" || return 0
  ghx api "repos/$REPO_SLUG/commits/$1/check-runs" --paginate > "$RUN193/lg-ck.json" 2>/dev/null || return 0
  jq -e '.check_runs | type == "array"' "$RUN193/lg-ck.json" >/dev/null 2>&1 || return 0
  jq -r --arg c "$CI_CHECK" --argjson a "$CI_APP" --arg s "$1" \
    '.check_runs[] | select(.name==$c and .app.id==$a and .head_sha==$s) | [.id,.status,(.conclusion // "-")] | @tsv' \
    "$RUN193/lg-ck.json" > "$RUN193/lg-ck.tsv" 2>/dev/null || return 0
  _n=$(awk 'END{print NR+0}' "$RUN193/lg-ck.tsv")
  if [ "$_n" -eq 0 ]; then CK_STATE=none; return 0; fi
  awk -F'\t' 'NF!=3 || $1 !~ /^[0-9]+$/ || $2=="" || $3=="" {bad=1} END{exit bad+0}' "$RUN193/lg-ck.tsv" || return 0
  sort -n "$RUN193/lg-ck.tsv" > "$RUN193/lg-ck.sorted" || return 0
  _last=$(awk 'END{print}' "$RUN193/lg-ck.sorted")
  CK_ID=$(printf '%s\n' "$_last" | awk -F'\t' '{print $1}')
  _st=$(printf '%s\n' "$_last" | awk -F'\t' '{print $2}')
  _c=$(printf '%s\n' "$_last" | awk -F'\t' '{print $3}')
  if [ "$_st" != completed ]; then CK_STATE=pending; return 0; fi
  case "$_c" in
    success|failure|cancelled|timed_out|action_required|neutral|skipped|stale|startup_failure) CK_WORD=$_c ;;
    *) CK_WORD=other ;;
  esac
  CK_STATE=completed
  return 0
}

# ---- binding helpers -----------------------------------------------------------
bind_init() { bdir_ready; BF="$BDIR/land-binding-$LABEL.txt"; }
bget() { bfget "$BF" "$1"; }
bstate() { # NEWSTATE: rewrite the binding with a new state, atomically
  awk -v s="$1" '$1=="state" {print "state " s; next} {print}' "$BF" | ev_write "$BF" || die "unreadable" 2
}

# ---- open ----------------------------------------------------------------------
do_open() {
  [ "$#" -eq 4 ] || die "usage" 2
  REPO=$1; BRANCH=$2; TF=$3; BODYF=$4
  repo_ok "$REPO"
  branch_ok "$BRANCH" || die "branch refused" 2
  [ -f "$TF" ] && [ -r "$TF" ] && [ -f "$BODYF" ] && [ -r "$BODYF" ] || die "bad input" 2
  bdir_ready
  TITLE=$(awk 'NR==1{print; exit}' "$TF")
  [ -n "$TITLE" ] || die "bad input" 2
  sh "$HERE/privacy-193.sh" "$TF" "$BODYF" > "$RUN193/lg-priv.out" 2>&1
  prc=$?
  case "$prc" in
    0) : ;;
    1) die "privacy hit" 1 ;;
    *) die "privacy check error" 2 ;;
  esac
  H=$(g "$REPO" rev-parse HEAD 2>/dev/null) || die "bad repo" 2
  is_sha40 "$H" || die "bad repo" 2
  list_prs() {
    ghx pr list -R "$REPO_SLUG" --head "$BRANCH" --state open --json number,headRefOid > "$RUN193/lg-prlist.json" 2>/dev/null || return 1
    jq -e 'type=="array"' "$RUN193/lg-prlist.json" >/dev/null 2>&1 || return 1
    NPR=$(jq -r 'length' "$RUN193/lg-prlist.json" 2>/dev/null) || return 1
    is_int "$NPR" || return 1
    return 0
  }
  list_prs || die "unreadable" 2
  VERB=reused
  if [ "$NPR" -eq 0 ]; then
    BODY_ABS=$(abspath "$BODYF") || die "bad input" 2
    log_write pr_create pr create -R "$REPO_SLUG" --base main --head "$BRANCH" --body-file "$BODY_ABS"
    ghx pr create -R "$REPO_SLUG" --base main --head "$BRANCH" --title "$TITLE" --body-file "$BODY_ABS" > "$RUN193/lg-prcreate.out" 2>&1
    list_prs || die "delivery uncertain" 3
    [ "$NPR" -eq 1 ] || die "delivery uncertain" 3
    VERB=opened
  fi
  [ "$NPR" -eq 1 ] || die "pr ambiguous" 1
  PN=$(jq -r '.[0].number' "$RUN193/lg-prlist.json")
  PH=$(jq -r '.[0].headRefOid' "$RUN193/lg-prlist.json")
  is_int "$PN" && is_sha40 "$PH" || die "unreadable" 2
  [ "$PH" = "$H" ] || die "head not pushed head" 1
  {
    printf 'pr %s\n' "$PN"
    printf 'head %s\n' "$PH"
  } | ev_write "$BDIR/pr-$LABEL.txt" || die "unreadable" 2
  say "pr $VERB $PN"
  exit 0
}

# ---- ci-wait -------------------------------------------------------------------
do_ci_wait() {
  [ "$#" -eq 3 ] || die "usage" 2
  PR=$1; SHA=$2; MAX=$3
  is_int "$PR" || die "bad pr" 2
  is_sha40 "$SHA" || die "bad sha" 2
  is_int "$MAX" && [ "$MAX" -ge 1 ] || die "bad max" 2
  req_core
  case "$RQ_STATE" in
    ok) : ;;
    changed) die "required set changed" 2 ;;
    *) die "unreadable" 2 ;;
  esac
  i=0
  while :; do
    i=$((i + 1))
    pr_read "$PR" number,state,headRefOid || die "unreadable" 2
    PSTATE=$(jf '.state // empty'); PHEAD=$(jf '.headRefOid // empty')
    [ -n "$PSTATE" ] && [ -n "$PHEAD" ] || die "unreadable" 2
    [ "$PSTATE" = OPEN ] || die "pr not open" 1
    [ "$PHEAD" = "$SHA" ] || die "head changed" 1
    check_core "$SHA"
    case "$CK_STATE" in
      unreadable) die "unreadable" 2 ;;
      completed) break ;;
      none|pending)
        if [ "$i" -ge "$MAX" ]; then say "ci pending"; exit 3; fi
        sleep "$POLL_SLEEP"
        ;;
    esac
  done
  if [ "$CK_WORD" = success ]; then
    say "ci success"
    say "ci ran on pr head SHA and its synthetic merge commit"
    exit 0
  fi
  NAMES=
  if ghx run list -R "$REPO_SLUG" --workflow crosswake-ci.yml --commit "$SHA" --event pull_request \
    --json databaseId,headSha > "$RUN193/lg-runs.json" 2>/dev/null; then
    _r=$(jq -r --arg s "$SHA" '[.[]|select(.headSha==$s)|.databaseId]|max // empty' "$RUN193/lg-runs.json" 2>/dev/null)
    if is_int "$_r" && ghx run view "$_r" -R "$REPO_SLUG" --json jobs > "$RUN193/lg-jobs.json" 2>/dev/null; then
      NAMES=$(jq -r '.jobs[] | select(.conclusion != "success" and .conclusion != "skipped") | .name' "$RUN193/lg-jobs.json" 2>/dev/null \
        | tr -cd 'A-Za-z0-9 ._/\n-' | awk 'NR>1{printf ","} {printf "%s",$0}')
    fi
  fi
  if [ -n "$NAMES" ]; then say "ci failure $NAMES"; else say "ci failure ($CK_WORD)"; fi
  exit 1
}

# ---- propose / answer / merge / status ------------------------------------------
do_propose() {
  [ "$#" -eq 1 ] || die "usage" 2
  PR=$1
  is_int "$PR" || die "bad pr" 2
  bind_init
  pr_read "$PR" number,state,headRefOid,headRefName,baseRefName,isCrossRepository,mergeStateStatus,url || die "unreadable" 2
  [ "$(jf '.state // empty')" = OPEN ] && [ "$(jf '.baseRefName // empty')" = main ] \
    && [ "$(jf '.isCrossRepository')" = false ] && [ "$(jf '.number // empty')" = "$PR" ] || die "wrong pr" 1
  HEADP=$(jf '.headRefOid // empty')
  is_sha40 "$HEADP" || die "wrong pr" 1
  URL=$(jf '.url // empty')
  [ "$(jf '.mergeStateStatus // empty')" = CLEAN ] || die "not clean" 1
  _sb="$BDIR/scan-$LABEL.txt"
  [ "$(bfget "$_sb" head)" = "$HEADP" ] && [ "$(bfget "$_sb" scan_exit)" = 0 ] || die "head not scanned head" 1
  if [ -f "$BDIR/pr-$LABEL.txt" ]; then
    [ "$(bfget "$BDIR/pr-$LABEL.txt" pr)" = "$PR" ] && [ "$(bfget "$BDIR/pr-$LABEL.txt" head)" = "$HEADP" ] || die "wrong pr" 1
  fi
  check_core "$HEADP"
  { [ "$CK_STATE" = completed ] && [ "$CK_WORD" = success ]; } || die "check not success" 1
  LM=$(main_live) || die "unreadable" 2
  ghx api "repos/$REPO_SLUG/commits/$HEADP" --jq '.commit.message | split("\n") | .[0]' > "$RUN193/lg-subj.txt" 2>/dev/null || die "unreadable" 2
  SUBJ=$(awk 'NR==1{print}' "$RUN193/lg-subj.txt" | tr -cd '[:print:]')
  SHORT=$(printf '%s' "$HEADP" | cut -c1-7)
  {
    printf 'Proposal to merge %s\n' "$URL"
    printf 'Head commit %s: %s\n' "$SHORT" "$SUBJ"
    printf 'What was checked: the pull request is open against main, is not from a fork and is clean; the required check "%s" passed on this exact head; the push scan ran clean on this head; main has not moved since this was prepared.\n' "$CI_CHECK"
    printf 'The private-term check was skipped for this push under D-26 (A-14 extended to the Phase 193 pushes); every other privacy check ran.\n'
    printf 'allow: merges this pull request once, as a merge commit, only while its head is still %s. It applies to nothing else.\n' "$SHORT"
    printf 'hold: stops here and merges nothing.\n'
  } > "$RUN193/lg-proposal.txt" || die "unreadable" 2
  sh "$HERE/privacy-193.sh" "$RUN193/lg-proposal.txt" > "$RUN193/lg-priv.out" 2>&1
  [ "$?" -eq 0 ] || die "privacy hit" 1
  ev_write "$BDIR/proposal-$LABEL.txt" < "$RUN193/lg-proposal.txt" || die "unreadable" 2
  NONCE=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
  {
    printf 'pr %s\n' "$PR"
    printf 'url %s\n' "$URL"
    printf 'head %s\n' "$HEADP"
    printf 'main %s\n' "$LM"
    printf 'check success\n'
    printf 'nonce %s\n' "$NONCE"
    printf 'proposed_at %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'state proposed\n'
  } | ev_write "$BF" || die "unreadable" 2
  say "proposal ready"
  exit 0
}

do_answer() {
  [ "$#" -eq 1 ] || die "usage" 2
  WORD=$1
  case "$WORD" in
    allow|hold) : ;;
    *) die "answer invalid" 2 ;;
  esac
  bind_init
  [ -f "$BF" ] && [ "$(bget state)" = proposed ] || die "no proposed binding" 1
  BPR=$(bget pr); BHEAD=$(bget head)
  is_int "$BPR" && is_sha40 "$BHEAD" || die "no proposed binding" 1
  pr_read "$BPR" number,headRefOid || die "unreadable" 2
  if [ "$(jf '.headRefOid // empty')" != "$BHEAD" ]; then
    bstate void
    die "void head changed" 1
  fi
  if [ "$WORD" = allow ]; then bstate allowed; say "allowed"; else bstate held; say "held"; fi
  exit 0
}

do_merge() {
  [ "$#" -eq 0 ] || die "usage" 2
  bind_init
  [ -f "$BF" ] && [ "$(bget state)" = allowed ] || die "no allowed binding" 1
  BPR=$(bget pr); BHEAD=$(bget head); BMAIN=$(bget main)
  is_int "$BPR" && is_sha40 "$BHEAD" && is_sha40 "$BMAIN" || die "no allowed binding" 1
  voidit() { bstate void; die "void $1" 1; }
  pr_read "$BPR" number,state,headRefOid,mergeStateStatus || die "unreadable" 2
  [ "$(jf '.headRefOid // empty')" = "$BHEAD" ] || voidit "head changed"
  [ "$(jf '.state // empty')" = OPEN ] && [ "$(jf '.mergeStateStatus // empty')" = CLEAN ] || voidit "not clean"
  check_core "$BHEAD"
  [ "$CK_STATE" != unreadable ] || die "unreadable" 2
  { [ "$CK_STATE" = completed ] && [ "$CK_WORD" = success ]; } || voidit "check not success"
  LM=$(main_live) || die "unreadable" 2
  [ "$LM" = "$BMAIN" ] || voidit "main moved"
  set -- pr merge "$BPR" -R "$REPO_SLUG" --merge --match-head-commit "$BHEAD"
  for _a in "$@"; do
    case "$_a" in
      --squash|--rebase|--admin|--auto|--disable-auto|--delete-branch|-s|-r|-d|*update-branch*) die "argv refused" 2 ;; #REFUSAL
    esac
  done
  bstate consumed
  log_write pr_merge "$@"
  ghx "$@" > "$RUN193/lg-merge.out" 2>&1
  MRC=$?
  pr_read "$BPR" state,mergeCommit || die "delivery uncertain" 3
  MC=$(jf '.mergeCommit.oid // empty')
  if [ "$(jf '.state // empty')" = MERGED ] && is_sha40 "$MC"; then
    {
      printf 'pr %s\n' "$BPR"
      printf 'bound_head %s\n' "$BHEAD"
      printf 'merge_commit %s\n' "$MC"
      printf 'merge_call_rc %s\n' "$MRC"
      printf 'result merged\n'
    } | ev_write "$BDIR/merge-$LABEL.txt" || die "unreadable" 2
    say "merged"
    exit 0
  fi
  die "delivery uncertain" 3
}

do_status() {
  bind_init
  if [ -f "$BF" ]; then
    case "$(bget state)" in
      proposed) say "state proposed" ;;
      allowed) say "state allowed" ;;
      held) say "state held" ;;
      void) say "state void" ;;
      consumed) say "state consumed" ;;
      *) say "state none" ;;
    esac
    _sp=$(bget pr)
    if is_int "$_sp" && pr_read "$_sp" state,headRefOid,mergeStateStatus; then
      _ps=$(jf '.state // empty')
      case "$_ps" in
        OPEN|MERGED|CLOSED) say "live pr $_ps" ;;
        *) say "live pr unknown" ;;
      esac
    else
      say "live pr unreadable"
    fi
  else
    say "state none"
  fi
  exit 0
}

# ---- self-test -------------------------------------------------------------------
selftest() {
  command -v jq >/dev/null 2>&1 || { say "selftest needs jq"; exit 2; }
  ST=$(mktemp -d "$_p193_tmpd/cw193-st.XXXXXX") || { say "scratch failed"; exit 2; }
  case "$ST" in
    "$ST193_PREFIX"*) : ;;
    *) say "scratch failed"; exit 2 ;;
  esac
  trap 'case "$ST" in "$ST193_PREFIX"*) chmod -R u+rwx "$ST" 2>/dev/null; rm -rf "$ST" ;; esac' EXIT
  trap 'exit 2' INT TERM HUP
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
  TOTAL=0
  GOOD=0
  OUT="$ST/out.txt"
  GHS="$ST/ghs"; BIN="$ST/bin"; W="$ST/work"; RM="$ST/remote.git"
  LBL=pr1; BD="$ST/bdir"; S191X=; STUBRC=0
  BR=docs/t1
  SLUG=$REPO_SLUG
  SL=/

  gq() { git -c user.name=fixture -c user.email=fixture@users.noreply.github.com -c commit.gpgsign=false "$@"; }
  lg() { # runs the gate against the fixture: sets RC, output in $OUT
    env SELFTEST_193=1 P193_RUN="$ST/run" PATH="$BIN:$PATH" GHS="$GHS" LAND193_LABEL="$LBL" LAND193_BDIR="$BD" \
      LAND193_WRITES="$ST/writes.txt" T193_SLEEP=0 STUBMARK="$ST/stubmark" STUB_RC="$STUBRC" \
      ${S191X:+T193_S191=$S191X} bash "$SELF" "$@" > "$OUT" 2>&1
    RC=$?
  }
  want() { [ "$RC" -eq "$1" ] && grep -qx "land: $2" "$OUT"; }
  has() { grep -qx "land: $1" "$OUT"; }
  nlines() { if [ -f "$1" ]; then awk 'END{print NR+0}' "$1"; else echo 0; fi; }
  wbind() { # FILE HEAD BASE EXIT [LABEL]
    printf 'head %s\nbase %s\nscan_exit %s\nadopter_check skipped_by_user A-14 scope D-26 label %s\nscan: clean\n' "$2" "$3" "$4" "${5:-pr1}" > "$1"
  }

  mkshim() {
    mkdir -p "$BIN"
    cat > "$BIN/gh" <<'SHIM'
#!/bin/bash
G=${GHS:?}
[ ! -f "$G/empty" ] || exit 0
args=("$@"); jqf=""; rest=()
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    --jq) jqf="${args[$((i + 1))]}"; i=$((i + 1)) ;;
    *) rest+=("${args[$i]}") ;;
  esac
done
emit() { if [ -n "$jqf" ]; then jq -r "$jqf" "$1"; else cat "$1"; fi; }
case "${rest[0]:-} ${rest[1]:-}" in
  "pr list") emit "$G/prlist.json" ;;
  "pr view") emit "$G/prview.json" ;;
  "pr create") printf '%s\n' "${rest[*]}" >> "$G/created.log"; cp "$G/newpr.json" "$G/prlist.json"; echo "https://github.com/example/repo/pull/7" ;;
  "pr merge")
    printf '%s\n' "${rest[*]}" >> "$G/merge.log"
    case "$(cat "$G/merge_mode")" in ok) cp "$G/prmerged.json" "$G/prview.json" ;; fail) exit 1 ;; esac ;;
  "run list") emit "$G/runs.json" ;;
  "run view") emit "$G/jobs.json" ;;
  api\ *)
    case "${rest[1]}" in
      *protection/required_status_checks) emit "$G/prot.json" ;;
      */check-runs) emit "$G/checks.json" ;;
      */branches/main) emit "$G/main.json" ;;
      */commits/*) emit "$G/commit.json" ;;
      *) exit 1 ;;
    esac ;;
  *) exit 1 ;;
esac
SHIM
    chmod 700 "$BIN/gh"
  }

  mkfix() { # fresh remote, work repo (HEAD two commits ahead of main), gh state
    chmod -R u+rwx "$ST/remote.git" "$ST/work" 2>/dev/null
    rm -rf "$RM" "$W" "$GHS" "$ST/bdir" "$ST/run" "$ST/writes.txt" "$ST/stubmark" "$ST/other"
    mkdir -m 700 "$ST/bdir" "$ST/run" "$GHS" || return 1
    git init -q --bare -b main "$RM" || return 1
    git init -q -b main "$W" || return 1
    echo a > "$W/a.txt"; git -C "$W" add a.txt; gq -C "$W" commit -q -m base
    git -C "$W" remote add origin "$RM"
    git -C "$W" push -q origin main 2>/dev/null
    BASE=$(git -C "$W" rev-parse HEAD)
    echo b > "$W/b.txt"; git -C "$W" add b.txt; gq -C "$W" commit -q -m c1
    C1=$(git -C "$W" rev-parse HEAD)
    echo c > "$W/c.txt"; git -C "$W" add c.txt; gq -C "$W" commit -q -m "c2 subject"
    HD=$(git -C "$W" rev-parse HEAD)
    S191X=
    STUBRC=0
    LBL=pr1
    BD="$ST/bdir"
    mkshim
    printf '{"strict":true,"checks":[{"context":"Crosswake CI","app_id":15368}]}\n' > "$GHS/prot.json"
    setcheck completed success "$HD"
    printf '{"number":7,"state":"OPEN","headRefOid":"%s","headRefName":"%s","baseRefName":"main","isCrossRepository":false,"mergeStateStatus":"CLEAN","url":"https://github.com/example/repo/pull/7","title":"t"}\n' "$HD" "$BR" > "$GHS/prview.json"
    printf '{"number":7,"state":"MERGED","headRefOid":"%s","mergeCommit":{"oid":"%s"}}\n' "$HD" "$C1" > "$GHS/prmerged.json"
    printf '{"commit":{"sha":"%s"}}\n' "$BASE" > "$GHS/main.json"
    printf '{"commit":{"message":"Subject line\\n\\nbody"}}\n' > "$GHS/commit.json"
    printf '[]\n' > "$GHS/prlist.json"
    printf '[{"number":7,"headRefOid":"%s"}]\n' "$HD" > "$GHS/newpr.json"
    printf '[{"databaseId":99,"headSha":"%s"}]\n' "$HD" > "$GHS/runs.json"
    printf '{"jobs":[{"name":"unit tests","conclusion":"failure"},{"name":"lint","conclusion":"success"}]}\n' > "$GHS/jobs.json"
    printf 'ok\n' > "$GHS/merge_mode"
  }
  setcheck() { # STATUS CONCLUSION SHA
    printf '{"check_runs":[{"id":11,"name":"Crosswake CI","app":{"id":15368},"head_sha":"%s","status":"%s","conclusion":"%s"}]}\n' "$3" "$1" "$2" > "$GHS/checks.json"
  }
  remote_refs() { git -C "$RM" for-each-ref --format='%(refname)' | sort | tr '\n' ' '; }

  # scanner fixtures: a stub scan-191.sh with N lines naming the scratch prefix, and the real helper
  mkstub() { # NLINES (2 = valid shape)
    NEED="$SYS_TMP/cross""wake-scan-191."
    rm -rf "$ST/s191x"; mkdir -p "$ST/s191x/scripts" "$ST/s191x/191-EVIDENCE"
    cp "$SD191/git-pinned-191.sh" "$ST/s191x/scripts/git-pinned-191.sh"
    printf 'fixture\n' > "$ST/s191x/191-EVIDENCE/scan-triage-191.tsv"
    {
      printf '#!/bin/bash\n'
      [ "$1" -lt 1 ] || printf 'SC=$(mktemp -d %sXXXXXX)\n' "$NEED"
      [ "$1" -lt 2 ] || printf 'case "$SC" in %s*) rm -rf "$SC" ;; esac\n' "$NEED"
      [ "$1" -lt 3 ] || printf '# also %s here\n' "$NEED"
      printf 'printf "%%s\\n%%s\\n" "$#" "${SCAN191_ADOPTER_SKIP:-none}" > "$STUBMARK"\n'
      printf 'echo "scan: clean"\n'
      printf 'exit ${STUB_RC:-0}\n'
    } > "$ST/s191x/scripts/scan-191.sh"
    S191X="$ST/s191x/scripts"
  }

  run_ctl() { # ID NAME FN
    TOTAL=$((TOTAL + 1))
    if mkfix && "$3"; then
      GOOD=$((GOOD + 1)); echo "$1 $2: as expected"
    else
      echo "$1 $2: NOT as expected"
    fi
  }
  tmpnames() { ls -1 "$TMPCW" 2>/dev/null | awk '/^crosswake/' | sort; }

  # ---- scan-bind controls
  c_label() { LBL=xx; lg scan-bind "$W"; want 2 "label refused" && [ ! -e "$ST/stubmark" ]; }
  c_bind_ok() {
    mkstub 2; tmpnames > "$ST/n1"
    lg scan-bind "$W"; want 0 "scan bound clean" || return 1
    tmpnames > "$ST/n2"; cmp -s "$ST/n1" "$ST/n2" || return 1
    B="$BD/scan-pr1.txt"
    [ "$(bfget "$B" head)" = "$HD" ] && [ "$(bfget "$B" base)" = "$BASE" ] && [ "$(bfget "$B" scan_exit)" = 0 ] || return 1
    [ "$(bfget "$B" adopter_check)" = "skipped_by_user A-14 scope D-26 label pr1" ] || return 1
    [ "$(awk 'NR==1' "$ST/stubmark")" = 3 ] && [ "$(awk 'NR==2' "$ST/stubmark")" = A-14 ] || return 1
    [ "$(stat -f %Lp "$B")" = 600 ]
  }
  c_bind_hits() { mkstub 2; STUBRC=1; lg scan-bind "$W"; want 1 "scan hits" && [ "$(bfget "$BD/scan-pr1.txt" scan_exit)" = 1 ]; }
  c_copy3() { mkstub 3; lg scan-bind "$W"; want 2 "scan copy fail" && [ ! -e "$ST/stubmark" ]; }
  c_copy1() { mkstub 1; lg scan-bind "$W"; want 2 "scan copy fail" && [ ! -e "$ST/stubmark" ]; }
  c_copyhash() {
    mkstub 2
    env SELFTEST_193=1 P193_RUN="$ST/run" PATH="$BIN:$PATH" GHS="$GHS" LAND193_LABEL=pr1 LAND193_BDIR="$BD" LAND193_WRITES="$ST/writes.txt" \
      STUBMARK="$ST/stubmark" T193_S191="$S191X" T193_COPY_TAMPER=1 bash "$SELF" scan-bind "$W" > "$OUT" 2>&1
    RC=$?
    want 2 "scan copy fail" && [ ! -e "$ST/stubmark" ]
  }
  c_bind_real() { # the real scanner copy runs from the 193 run folder and makes no crosswake entry
    tmpnames > "$ST/n1"
    lg scan-bind "$W"
    [ "$RC" -eq 0 ] || [ "$RC" -eq 1 ] || return 1
    tmpnames > "$ST/n2"; cmp -s "$ST/n1" "$ST/n2" || return 1
    [ "$(bfget "$BD/scan-pr1.txt" scan_exit)" = "$RC" ] && [ -d "$ST/run/scan-tmp" ] || return 1
    [ -z "$(ls -A "$ST/run/scan-tmp")" ]
  }

  # ---- push controls
  goodbind() { wbind "$BD/scan-pr1.txt" "$HD" "$BASE" 0; }
  c_push_ok() {
    goodbind; lg push "$W" "$BR" --push; want 0 "delivered" || return 1
    [ "$(remote_refs)" = "refs/heads/$BR refs/heads/main " ] || return 1
    [ "$(git -C "$RM" rev-parse refs/heads/main)" = "$BASE" ] && [ "$(git -C "$RM" rev-parse "refs/heads/$BR")" = "$HD" ] || return 1
    [ "$(nlines "$ST/writes.txt")" -eq 1 ] && grep -qx 'push_branch push origin HEAD:refs/heads/docs/t1' "$ST/writes.txt"
  }
  c_push_twice() { goodbind; lg push "$W" "$BR" --push; lg push "$W" "$BR" --push; want 0 "already delivered" && [ "$(nlines "$ST/writes.txt")" -eq 1 ]; }
  c_push_nobind() { lg push "$W" "$BR" --push; want 1 "scan binding fail" && [ "$(remote_refs)" = "refs/heads/main " ]; }
  c_push_headdiff() { wbind "$BD/scan-pr1.txt" "$BASE" "$BASE" 0; lg push "$W" "$BR" --push; want 1 "scan binding fail" && [ "$(remote_refs)" = "refs/heads/main " ]; }
  c_push_basediff() { wbind "$BD/scan-pr1.txt" "$HD" "$C1" 0; lg push "$W" "$BR" --push; want 1 "scan binding fail"; }
  c_push_scanexit() { wbind "$BD/scan-pr1.txt" "$HD" "$BASE" 1; lg push "$W" "$BR" --push; want 1 "scan binding fail"; }
  c_push_upper() { U=$(printf '%s' "$HD" | tr 'a-f' 'A-F'); wbind "$BD/scan-pr1.txt" "$U" "$BASE" 0; lg push "$W" "$BR" --push; want 1 "scan binding fail"; }
  c_push_short() { S=$(printf '%s' "$HD" | cut -c1-12); wbind "$BD/scan-pr1.txt" "$S" "$BASE" 0; lg push "$W" "$BR" --push; want 1 "scan binding fail"; }
  c_push_moved() {
    goodbind; git -C "$W" push -q origin "$C1:refs/heads/main" 2>/dev/null
    lg push "$W" "$BR" --push; want 1 "scan binding fail" && [ "$(remote_refs)" = "refs/heads/main " ]
  }
  c_push_nonff() {
    git -C "$W" checkout -q -b side "$BASE" 2>/dev/null; echo z > "$W/z.txt"; git -C "$W" add z.txt; gq -C "$W" commit -q -m side
    git -C "$W" push -q origin "side:refs/heads/$BR" 2>/dev/null
    git -C "$W" checkout -q main 2>/dev/null; git -C "$W" reset -q --hard "$HD"
    goodbind; lg push "$W" "$BR" --push; want 1 "not fast-forward"
  }
  c_push_unreadable() { git -C "$W" remote set-url origin "$ST/nowhere.git"; goodbind; lg push "$W" "$BR" --push; want 2 "remote unreadable"; }
  c_push_nomain() { git init -q --bare -b main "$ST/empty.git"; git -C "$W" remote set-url origin "$ST/empty.git"; goodbind; lg push "$W" "$BR" --push; want 2 "remote unreadable"; }
  c_push_branches() {
    for b in main refs/heads/x feature/x docs/..x docs/Upper; do
      lg push "$W" "$b" --dry-run; want 2 "branch refused" || return 1
    done
    return 0
  }
  c_push_badmode() { lg push "$W" "$BR" --force; want 2 "refused argument"; }
  c_push_dry() { lg push "$W" "$BR" --dry-run; want 0 "dry-run ok" && [ "$(remote_refs)" = "refs/heads/main " ] && [ ! -e "$ST/writes.txt" ]; }

  run_ctl L01 "scan-bind refuses a label other than pr1 and pr2" c_label
  run_ctl L02 "scan-bind binds head, base, exit and the D-26 skip, leaves no crosswake entry" c_bind_ok
  run_ctl L03 "scan-bind records scanner hits" c_bind_hits
  run_ctl L04 "scan copy with three rewritten lines is refused and no scan runs" c_copy3
  run_ctl L05 "scan copy with one rewritten line is refused and no scan runs" c_copy1
  run_ctl L06 "scan copy with a differing hash is refused and no scan runs" c_copyhash
  run_ctl L07 "real scanner copy runs under the 193 run folder with no crosswake entry" c_bind_real
  run_ctl L08 "push delivers only the branch, once" c_push_ok
  run_ctl L09 "second push says already delivered and writes nothing" c_push_twice
  run_ctl L10 "push without a scan binding is refused" c_push_nobind
  run_ctl L11 "binding head different from HEAD is refused" c_push_headdiff
  run_ctl L12 "binding base different from live main is refused" c_push_basediff
  run_ctl L13 "binding with scan_exit not 0 is refused" c_push_scanexit
  run_ctl L14 "upper-case binding head is refused" c_push_upper
  run_ctl L15 "shortened binding head is refused" c_push_short
  run_ctl L16 "main moved since scan-bind is refused" c_push_moved
  run_ctl L17 "non-fast-forward is refused" c_push_nonff
  run_ctl L18 "unreadable remote is exit 2" c_push_unreadable
  run_ctl L19 "remote without main is exit 2" c_push_nomain
  run_ctl L20 "main, refs, off-pattern and upper-case branches are refused" c_push_branches
  run_ctl L21 "a force argument is refused" c_push_badmode
  run_ctl L22 "dry-run writes nothing to the remote or the writes log" c_push_dry

  # ---- open / ci-wait controls
  mktxt() { printf 'Plain title\n' > "$ST/title.txt"; printf '%s\n' "$1" > "$ST/body.txt"; }
  c_open_priv() { mktxt "see ${SL}Us""ers/fixtureuser/x"; lg open "$W" "$BR" "$ST/title.txt" "$ST/body.txt"; want 1 "privacy hit" && [ ! -e "$GHS/created.log" ]; }
  c_open_new() {
    mktxt "A plain description"; lg open "$W" "$BR" "$ST/title.txt" "$ST/body.txt"; want 0 "pr opened 7" || return 1
    [ "$(nlines "$GHS/created.log")" -eq 1 ] && [ "$(bfget "$BD/pr-pr1.txt" pr)" = 7 ] && [ "$(bfget "$BD/pr-pr1.txt" head)" = "$HD" ]
  }
  c_open_reuse() {
    mktxt "A plain description"; cp "$GHS/newpr.json" "$GHS/prlist.json"
    lg open "$W" "$BR" "$ST/title.txt" "$ST/body.txt"; want 0 "pr reused 7" && [ ! -e "$GHS/created.log" ]
  }
  c_open_oldhead() {
    mktxt "A plain description"; printf '[{"number":7,"headRefOid":"%s"}]\n' "$BASE" > "$GHS/prlist.json"
    lg open "$W" "$BR" "$ST/title.txt" "$ST/body.txt"; want 1 "head not pushed head"
  }
  c_ci_pending() { setcheck in_progress - "$HD"; lg ci-wait 7 "$HD" 2; want 3 "ci pending"; }
  c_ci_none() { printf '{"check_runs":[]}\n' > "$GHS/checks.json"; lg ci-wait 7 "$HD" 2; want 3 "ci pending"; }
  c_ci_ok() { lg ci-wait 7 "$HD" 2; want 0 "ci success" && has "ci ran on pr head SHA and its synthetic merge commit"; }
  c_ci_fail() { setcheck completed failure "$HD"; lg ci-wait 7 "$HD" 2; want 1 "ci failure unit tests"; }
  c_ci_empty() { : > "$GHS/empty"; lg ci-wait 7 "$HD" 2; [ "$RC" -eq 2 ]; }
  c_ci_emptychk() { printf '' > "$GHS/checks.json"; lg ci-wait 7 "$HD" 2; [ "$RC" -eq 2 ]; }
  c_ci_reqchg() { printf '{"strict":true,"checks":[{"context":"Crosswake CI","app_id":15368},{"context":"x","app_id":1}]}\n' > "$GHS/prot.json"; lg ci-wait 7 "$HD" 2; want 2 "required set changed"; }
  c_ci_wrongapp() { printf '{"check_runs":[{"id":11,"name":"Crosswake CI","app":{"id":1},"head_sha":"%s","status":"completed","conclusion":"success"}]}\n' "$HD" > "$GHS/checks.json"; lg ci-wait 7 "$HD" 1; want 3 "ci pending"; }

  # ---- propose / answer / merge controls
  goodscan() { wbind "$BD/scan-pr1.txt" "$HD" "$BASE" 0; }
  proposed() { goodscan; lg propose 7; want 0 "proposal ready"; }
  c_prop_ok() {
    proposed || return 1
    [ "$(bfget "$BD/land-binding-pr1.txt" state)" = proposed ] && [ "$(bfget "$BD/land-binding-pr1.txt" head)" = "$HD" ] || return 1
    [ "$(bfget "$BD/land-binding-pr1.txt" main)" = "$BASE" ] || return 1
    [ "$(stat -f %Lp "$BD/land-binding-pr1.txt")" = 600 ] && [ "$(stat -f %Lp "$BD")" = 700 ] || return 1
    grep -q 'D-26' "$BD/proposal-pr1.txt" && grep -q 'example/repo/pull/7' "$BD/proposal-pr1.txt"
  }
  c_prop_noscan() { lg propose 7; want 1 "head not scanned head"; }
  c_prop_scanother() { wbind "$BD/scan-pr1.txt" "$BASE" "$BASE" 0; lg propose 7; want 1 "head not scanned head"; }
  c_ans_none() { lg answer allow; want 1 "no proposed binding"; }
  c_ans_bad() { proposed || return 1; lg answer maybe; want 2 "answer invalid"; }
  c_hold() {
    proposed || return 1; lg answer hold; want 0 "held" || return 1
    lg merge; want 1 "no allowed binding" && [ ! -e "$GHS/merge.log" ]
  }
  c_ans_void() {
    proposed || return 1
    sed 's/"headRefOid":"[0-9a-f]*"/"headRefOid":"'"$C1"'"/' "$GHS/prview.json" > "$GHS/p2"; mv "$GHS/p2" "$GHS/prview.json"
    lg answer allow; want 1 "void head changed" && [ "$(bfget "$BD/land-binding-pr1.txt" state)" = void ]
  }
  c_merge_void_head() {
    proposed || return 1; lg answer allow; want 0 "allowed" || return 1
    sed 's/"headRefOid":"[0-9a-f]*"/"headRefOid":"'"$C1"'"/' "$GHS/prview.json" > "$GHS/p2"; mv "$GHS/p2" "$GHS/prview.json"
    lg merge; want 1 "void head changed" && [ ! -e "$GHS/merge.log" ] && [ "$(bfget "$BD/land-binding-pr1.txt" state)" = void ]
  }
  c_merge_void_main() {
    proposed || return 1; lg answer allow || true
    printf '{"commit":{"sha":"%s"}}\n' "$C1" > "$GHS/main.json"
    lg merge; want 1 "void main moved" && [ ! -e "$GHS/merge.log" ]
  }
  c_merge_void_check() {
    proposed || return 1; lg answer allow || true
    setcheck completed failure "$HD"
    lg merge; want 1 "void check not success" && [ ! -e "$GHS/merge.log" ]
  }
  c_merge_ok() {
    proposed || return 1; lg answer allow; want 0 "allowed" || return 1
    lg merge; want 0 "merged" || return 1
    [ "$(nlines "$GHS/merge.log")" -eq 1 ] || return 1
    grep -qx "pr merge 7 -R $SLUG --merge --match-head-commit $HD" "$GHS/merge.log" || return 1
    grep -qx 'result merged' "$BD/merge-pr1.txt" && [ "$(bfget "$BD/merge-pr1.txt" merge_commit)" = "$C1" ] || return 1
    grep -qx "pr_merge pr merge 7 -R $SLUG --merge --match-head-commit $HD" "$ST/writes.txt" || return 1
    lg merge; want 1 "no allowed binding" && [ "$(nlines "$GHS/merge.log")" -eq 1 ]
  }
  c_merge_fail() {
    proposed || return 1; lg answer allow || true; printf 'fail\n' > "$GHS/merge_mode"
    lg merge; want 3 "delivery uncertain" || return 1
    [ "$(nlines "$GHS/merge.log")" -eq 1 ] && [ "$(bfget "$BD/land-binding-pr1.txt" state)" = consumed ] || return 1
    lg merge; want 1 "no allowed binding" && [ "$(nlines "$GHS/merge.log")" -eq 1 ]
  }
  c_status() { proposed || return 1; lg status; want 0 "live pr OPEN" && has "state proposed"; }
  c_bdir_mode() { chmod 755 "$BD"; lg propose 7; want 2 "binding dir unsafe"; }
  c_hook_outside() {
    env T193_SLEEP=1 LAND193_LABEL=pr1 LAND193_BDIR="$BD" LAND193_WRITES="$ST/writes.txt" bash "$SELF" status > "$OUT" 2>&1; RC=$?
    want 2 "hook set outside self-test"
  }
  c_static_tokens() {
    F1="cross""wake-phase191-run"; F2="locate""-191"; F3="env""-191"; F4="common""-192"; F5="privacy""-192"; F6="/pri""vate/tmp"
    grep -q -F -e "$F1" -e "$F2" -e "$F3" -e "$F4" -e "$F5" -e "$F6" "$SELF"; _g=$?
    [ "$_g" -eq 1 ] && grep -q -F 'privacy-193' "$SELF" && grep -q -F 'scope D-26' "$SELF"
  }
  c_static_merge_opts() { # the forbidden merge options appear only on lines marked as the refusal list
    O1="--squ""ash"; O2="--reb""ase"; O3="--adm""in"; O4="--au""to"; O5="--delete""-branch"
    grep -n -F -e "$O1" -e "$O2" -e "$O3" -e "$O4" -e "$O5" "$SELF" > "$ST/opts.txt"; _g=$?
    [ "$_g" -eq 0 ] || return 1
    ! grep -v -F '#REFUSAL' "$ST/opts.txt" > "$ST/opts-bad.txt" || return 1
    [ ! -s "$ST/opts-bad.txt" ]
  }

  run_ctl L23 "open with a failing privacy check is refused before any gh write" c_open_priv
  run_ctl L24 "open creates the pull request once and binds its number and head" c_open_new
  run_ctl L25 "open reuses an already-open pull request" c_open_reuse
  run_ctl L26 "open refuses a pull request whose head is not the pushed head" c_open_oldhead
  run_ctl L27 "ci-wait is exit 3 while the check is pending" c_ci_pending
  run_ctl L28 "ci-wait is exit 3 while no check-run exists yet" c_ci_none
  run_ctl L29 "ci-wait is exit 0 on success and names what CI ran on" c_ci_ok
  run_ctl L30 "ci-wait is exit 1 on failure and names the failing job" c_ci_fail
  run_ctl L31 "ci-wait is exit 2 on empty gh output" c_ci_empty
  run_ctl L32 "ci-wait is exit 2 on an empty check-run answer" c_ci_emptychk
  run_ctl L33 "ci-wait is exit 2 when the required set changed" c_ci_reqchg
  run_ctl L34 "a check from another app is not the required check" c_ci_wrongapp
  run_ctl L35 "propose binds pr, head, main in owner-only files and states D-26" c_prop_ok
  run_ctl L36 "propose without a scan binding is refused" c_prop_noscan
  run_ctl L37 "propose with a scan binding for another head is refused" c_prop_scanother
  run_ctl L38 "answer without propose is refused" c_ans_none
  run_ctl L39 "an answer other than allow or hold is invalid" c_ans_bad
  run_ctl L40 "hold never merges" c_hold
  run_ctl L41 "answer after the head changed voids the binding" c_ans_void
  run_ctl L42 "merge after the head changed voids the binding and does not call gh" c_merge_void_head
  run_ctl L43 "merge after main moved voids the binding" c_merge_void_main
  run_ctl L44 "merge with a failing check voids the binding" c_merge_void_check
  run_ctl L45 "clean allow-to-merge merges exactly once and a consumed binding is refused" c_merge_ok
  run_ctl L46 "merge delivery failure is exit 3 with no second call" c_merge_fail
  run_ctl L47 "status reads the binding and the live pull request" c_status
  run_ctl L48 "a binding folder with another mode is exit 2" c_bdir_mode
  run_ctl L49 "a self-test hook outside the self-test is refused" c_hook_outside
  run_ctl L50 "source names no run-folder tool, no 192 privacy check, no system temp root" c_static_tokens
  run_ctl L51 "forbidden merge options appear only in the refusal list" c_static_merge_opts

  echo "selftest land-gate-193: controls $GOOD of $TOTAL as expected"
  [ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 20 ] && exit 0
  exit 1
}


case "$mode" in
  scan-bind) shift; do_scan_bind "$@" ;;
  push) shift; do_push "$@" ;;
  open|ci-wait|propose|answer|merge|status) shift; "do_${mode//-/_}" "$@" ;;
  --self-test) selftest ;;
  *) die "usage" 2 ;;
esac
