#!/bin/sh
# Phase 192 push gate (D-04, D-05, D-06, R-3). Prints only `push:` labels.
# Modes: --dry-run | --push. Exactly one argument; anything else is refused.
# Exit 0 pass, 1 check failed, 2 scope or input error.
set -u
umask 077

case "$#:${1:-}" in
  1:--dry-run) MODE=dry-run ;;
  1:--push) MODE=push ;;
  *) echo "push: refused argument"; exit 2 ;;
esac

HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/common-192.sh"

H=unread; M=unread; RB=unread; RA=unread

record() { # RESULT [CAUSE]
  _rec="mode $MODE head $H main $M remote_before $RB remote_after $RA result $1"
  [ -z "${2:-}" ] || _rec="$_rec cause $2"
  printf '%s\n' "$_rec" >> "$EV192/push-192.txt"
}

fail() { echo "push: $1"; exit "${2:-1}"; }

[ "$(g "$IC" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "$BRANCH" ] || fail "wrong branch" 2
[ -z "$(g "$IC" status --porcelain=v1 --untracked-files=all 2>/dev/null)" ] || fail "clone dirty" 2

sh "$FINALIZE" --check-binding > "$R192/push-bind.out" 2>&1
brc=$?
if [ "$brc" -ne 0 ] || ! grep -qx 'finalize: binding pass' "$R192/push-bind.out"; then
  fail "scan binding fail" 1
fi

H=$(g "$IC" rev-parse HEAD 2>/dev/null) || H=unread
is_sha40 "$H" || { H=unread; fail "scan binding fail" 1; }

refuse() { # LABEL EXIT RESULT [CAUSE]
  record "$3" "${4:-}"
  echo "push: $1"
  exit "$2"
}

M=$(live_ref refs/heads/main); mrc=$?
if [ "$mrc" -ne 0 ] || [ "$M" = absent ]; then
  M=unread
  refuse "remote unreadable" 2 refused remote_unreadable
fi
if [ "$M" != "$MAIN_SHA" ]; then
  refuse "main moved" 1 refused main_moved
fi

if ! g "$IC" merge-base --is-ancestor "$MAIN_SHA" "$H" >/dev/null 2>&1; then
  refuse "main not in head" 1 refused main_not_in_head
fi

RB=$(live_ref "$PUSH_REF"); rbrc=$?
if [ "$rbrc" -ne 0 ]; then
  RB=unread
  refuse "remote unreadable" 2 refused remote_unreadable
fi
if [ "$RB" = "$H" ]; then
  RA=$RB
  record already_delivered
  echo "push: already delivered"
  exit 0
fi
if [ "$RB" != absent ]; then
  if ! g "$IC" cat-file -e "$RB^{commit}" >/dev/null 2>&1; then
    refuse "remote branch unknown" 1 refused remote_branch_unknown
  fi
  if ! g "$IC" merge-base --is-ancestor "$RB" "$H" >/dev/null 2>&1; then
    refuse "not fast-forward" 1 refused not_fast_forward
  fi
fi

cause_word() {
  if grep -Eiq 'could not read Username|Authentication failed|403|Permission denied' "$R192/push.out"; then
    echo auth
  elif grep -Eiq 'rejected' "$R192/push.out"; then
    echo rejected
  else
    echo other
  fi
}

if [ "$MODE" = dry-run ]; then
  g "$IC" -c credential.helper= -c 'credential.helper=!gh auth git-credential' -c http.postBuffer=524288000 push --porcelain --no-follow-tags --dry-run origin "HEAD:$PUSH_REF" > "$R192/push.out" 2>&1
  prc=$?
  RA=$(live_ref "$PUSH_REF") || RA=unread
  if [ "$prc" -eq 0 ]; then
    record dry-run_ok
    echo "push: dry-run ok"
    exit 0
  fi
  CW=$(cause_word)
  record failed "$CW"
  echo "push: dry-run failed"
  echo "push: cause $CW"
  exit 1
fi

# push mode: one attempt, never repeated
g "$IC" -c credential.helper= -c 'credential.helper=!gh auth git-credential' -c http.postBuffer=524288000 push --porcelain --no-follow-tags origin "HEAD:$PUSH_REF" > "$R192/push.out" 2>&1
prc=$?
RA=$(live_ref "$PUSH_REF") || RA=unread
if [ "$RA" = "$H" ]; then
  record delivered
  echo "push: delivered"
  exit 0
fi
CW=$(cause_word)
record failed "$CW"
echo "push: not delivered"
echo "push: cause $CW"
exit 1
