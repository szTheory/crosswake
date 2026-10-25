#!/bin/sh
# Phase 192 one-use merge gate (LAND-04, D-04, D-06, D-07, R-1, R-3).
# Modes: propose PR | answer allow|hold | merge | status
# Exit: 0 pass, 1 refused or voided, 2 scope or input error, 3 delivery uncertain.
# Prints only `merge-gate:` labels. The binding holds public values only (no path, account or token).
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/common-192.sh"

BDIR="$EV192/binding"
BF="$BDIR/merge-binding-192.txt"
PRF="$R192/mg-pr.json"
mode=${1:-}

say() { echo "merge-gate: $1"; }
die() { say "$1"; exit "${2:-1}"; }

# --- owner-only durable binding folder ------------------------------------
bdir_ready() {
  if [ ! -d "$BDIR" ]; then
    mkdir -m 0700 "$BDIR" 2>/dev/null || die "binding dir unsafe" 2
  fi
  if [ "$(stat -f %u "$BDIR" 2>/dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$BDIR" 2>/dev/null)" != 700 ]; then
    die "binding dir unsafe" 2
  fi
}

bget() { # KEY
  [ -f "$BF" ] || return 0
  awk -v k="$1" '$1==k {sub(/^[^ ]+ /,""); print; exit}' "$BF"
}

bstate() { # NEWSTATE: rewrite the binding with a new state, atomically
  awk -v s="$1" '$1=="state" {print "state " s; next} {print}' "$BF" | ev_write "$BF" || die "unreadable" 2
}

jf() { jq -r "$1" "$PRF" 2>/dev/null; } # filter over the last PR read

# --- read the PR into PRF with the given JSON field list --------------------
pr_read() { # PR FIELDS
  ghx pr view "$1" -R "$REPO_SLUG" --json "$2" > "$PRF" 2>/dev/null || return 1
  jq -e 'type=="object"' "$PRF" >/dev/null 2>&1 || return 1
  return 0
}

# --- synthetic merge facts: sets SYN and STREE; returns 1 unproven, 2 unreadable
syn_read() { # PR HEAD
  SYN=
  STREE=
  ghx api "repos/$REPO_SLUG/pulls/$1" --jq .merge_commit_sha > "$R192/mg-syn.txt" 2>/dev/null || return 2
  SYN=$(awk 'NR==1{print}' "$R192/mg-syn.txt")
  is_sha40 "$SYN" || return 1
  ghx api "repos/$REPO_SLUG/git/commits/$SYN" --jq '[([.parents[].sha]|join(" ")), .tree.sha]|@tsv' > "$R192/mg-syn2.tsv" 2>/dev/null || return 2
  _sp=$(awk -F'\t' 'NR==1{print $1}' "$R192/mg-syn2.tsv")
  STREE=$(awk -F'\t' 'NR==1{print $2}' "$R192/mg-syn2.tsv")
  [ "$_sp" = "$MAIN_SHA $2" ] || return 1
  is_sha40 "$STREE" || return 1
  return 0
}

case "$mode" in
  propose)
    PR=${2:-}
    is_int "$PR" || die "bad pr" 2
    bdir_ready
    sh "$FINALIZE" --check-binding > "$R192/mg-fin.out" 2>&1
    frc=$?
    if [ "$frc" -ne 0 ] || ! grep -qx 'finalize: binding pass' "$R192/mg-fin.out"; then
      die "scan binding fail" 1
    fi
    pr_read "$PR" number,state,headRefOid,headRefName,baseRefName,isCrossRepository,mergeStateStatus,mergeable,url,title || die "unreadable" 2
    [ "$(jf '.state // empty')" = OPEN ] && [ "$(jf '.baseRefName // empty')" = main ] \
      && [ "$(jf '.headRefName // empty')" = land/v25-v27 ] && [ "$(jf '.isCrossRepository')" = false ] \
      && [ "$(jf '.number // empty')" = "$PR" ] || die "wrong pr" 1
    HEAD=$(jf '.headRefOid // empty')
    ICH=$(g "$IC" rev-parse HEAD 2>/dev/null) || ICH=
    is_sha40 "$HEAD" && [ "$HEAD" = "$ICH" ] || die "head not scanned head" 1
    [ "$(jf '.mergeStateStatus // empty')" = CLEAN ] && [ "$(jf '.mergeable // empty')" = MERGEABLE ] || die "not clean" 1
    URL=$(jf '.url // empty')
    TITLE=$(jf '.title // empty')
    sh "$HERE/ci-poll-192.sh" check "$HEAD" > "$R192/mg-ci.out" 2>&1
    circ=$?
    if [ "$circ" -ne 0 ] || ! grep -qx 'ci-poll: check completed success' "$R192/mg-ci.out"; then
      die "check not success" 1
    fi
    LM=$(live_ref refs/heads/main) || die "unreadable" 2
    [ "$LM" = "$MAIN_SHA" ] || die "main moved" 1
    syn_read "$PR" "$HEAD"
    src=$?
    [ "$src" -ne 2 ] || die "unreadable" 2
    [ "$src" -eq 0 ] || die "synthetic merge unproven" 1
    NONCE=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
    SUBJ=$(g "$IC" log -1 --format=%s "$HEAD" 2>/dev/null)
    {
      printf 'pr %s\n' "$PR"
      printf 'url %s\n' "$URL"
      printf 'head %s\n' "$HEAD"
      printf 'synthetic_merge %s\n' "$SYN"
      printf 'synthetic_tree %s\n' "$STREE"
      printf 'main %s\n' "$LM"
      printf 'nonce %s\n' "$NONCE"
      printf 'proposed_at %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      printf 'state proposed\n'
    } | ev_write "$BF" || die "unreadable" 2
    {
      printf 'pr_url %s\n' "$URL"
      printf 'head %s\n' "$HEAD"
      printf 'head_short %s\n' "$(printf '%s' "$HEAD" | cut -c1-7)"
      printf 'head_subject %s\n' "$SUBJ"
      printf 'title %s\n' "$TITLE"
      printf 'merge_method merge commit\n'
      printf 'CI on main is green will mean three things. The required Crosswake CI check passed on this head and on the merge preview it ran on. The merge commit will contain exactly that tested content. Every push-triggered workflow run on the merge commit that is not advisory must succeed, with Release Please succeeding and every publish job skipped. See It Run Collateral is advisory, often cancelled, and is recorded, not counted.\n'
      printf 'Allow applies only to this pull request and this head commit, once.\n'
      printf 'Hold stops before the merge.\n'
    } | ev_write "$EV192/proposal-192.txt" || die "unreadable" 2
    say "proposal ready"
    exit 0
    ;;

  answer)
    WORD=${2:-}
    case "$WORD" in
      allow|hold) : ;;
      *) die "answer invalid" 2 ;;
    esac
    bdir_ready
    [ -f "$BF" ] && [ "$(bget state)" = proposed ] || die "no proposed binding" 1
    BPR=$(bget pr)
    BHEAD=$(bget head)
    is_int "$BPR" && is_sha40 "$BHEAD" || die "no proposed binding" 1
    pr_read "$BPR" number,headRefOid || die "unreadable" 2
    if [ "$(jf '.headRefOid // empty')" != "$BHEAD" ]; then
      bstate void
      die "void head changed" 1
    fi
    if [ "$WORD" = allow ]; then
      bstate allowed
      say "allowed"
    else
      bstate held
      say "held"
    fi
    exit 0
    ;;

  merge)
    bdir_ready
    [ -f "$BF" ] && [ "$(bget state)" = allowed ] || die "no allowed binding" 1
    BPR=$(bget pr)
    BHEAD=$(bget head)
    BMAIN=$(bget main)
    BTREE=$(bget synthetic_tree)
    is_int "$BPR" && is_sha40 "$BHEAD" && is_sha40 "$BMAIN" && is_sha40 "$BTREE" || die "no allowed binding" 1
    voidit() { bstate void; die "void $1" 1; }
    pr_read "$BPR" number,state,headRefOid,mergeStateStatus || die "unreadable" 2
    [ "$(jf '.headRefOid // empty')" = "$BHEAD" ] || voidit "head changed"
    [ "$(jf '.state // empty')" = OPEN ] && [ "$(jf '.mergeStateStatus // empty')" = CLEAN ] || voidit "not clean"
    sh "$HERE/ci-poll-192.sh" check "$BHEAD" > "$R192/mg-ci.out" 2>&1
    circ=$?
    if [ "$circ" -ne 0 ] || ! grep -qx 'ci-poll: check completed success' "$R192/mg-ci.out"; then
      if grep -qx 'ci-poll: unreadable' "$R192/mg-ci.out"; then die "unreadable" 2; fi
      voidit "check not success"
    fi
    LM=$(live_ref refs/heads/main) || die "unreadable" 2
    { [ "$LM" = "$BMAIN" ] && [ "$LM" = "$MAIN_SHA" ]; } || voidit "main moved"
    syn_read "$BPR" "$BHEAD"
    src=$?
    [ "$src" -ne 2 ] || die "unreadable" 2
    { [ "$src" -eq 0 ] && [ "$STREE" = "$BTREE" ]; } || voidit "synthetic changed"
    set -- pr merge "$BPR" -R "$REPO_SLUG" --merge --match-head-commit "$BHEAD"
    for _a in "$@"; do
      case "$_a" in
        --squash|--rebase|--admin|--auto|--disable-auto|--delete-branch|-s|-r|-d|*update-branch*) die "argv refused" 2 ;;
      esac
    done
    bstate consumed
    log_write pr_merge "$@"
    ghx "$@" > "$R192/merge.out" 2>&1
    MRC=$?
    pr_read "$BPR" state,mergeCommit,headRefOid,mergedAt || die "delivery uncertain" 3
    PSTATE=$(jf '.state // empty')
    case "$PSTATE" in
      MERGED)
        MC=$(jf '.mergeCommit.oid // empty')
        is_sha40 "$MC" || die "delivery uncertain" 3
        {
          printf 'pr %s\n' "$BPR"
          printf 'bound_head %s\n' "$BHEAD"
          printf 'merge_commit %s\n' "$MC"
          printf 'merge_call_rc %s\n' "$MRC"
          printf 'merged_at %s\n' "$(jf '.mergedAt // "unknown"')"
          printf 'result merged\n'
        } | ev_write "$EV192/merge-192.txt" || die "unreadable" 2
        say "merged"
        exit 0
        ;;
      OPEN|CLOSED)
        say "not merged"
        if grep -Eiq 'match-head|head branch was modified|head commit' "$R192/merge.out" 2>/dev/null; then C=head_mismatch
        elif grep -Eiq 'not mergeable|conflict|required status|policy|blocked|not clean' "$R192/merge.out" 2>/dev/null; then C=not_mergeable
        elif grep -Eiq 'auth|401|403|login|token|permission' "$R192/merge.out" 2>/dev/null; then C=auth
        else C=other; fi
        say "cause $C"
        exit 1
        ;;
      *) die "delivery uncertain" 3 ;;
    esac
    ;;

  status)
    if [ -f "$BF" ]; then
      ST=$(bget state)
      case "$ST" in
        proposed|allowed|held|void|consumed) say "state $ST" ;;
        *) say "state none" ;;
      esac
    else
      say "state none"
    fi
    exit 0
    ;;

  *)
    die "usage" 2
    ;;
esac
