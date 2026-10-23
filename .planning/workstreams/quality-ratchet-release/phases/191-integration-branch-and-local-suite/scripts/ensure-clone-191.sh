#!/bin/sh
# Phase 191 integration clone (D-01). Prints fixed ensure-clone: labels only.
# Never writes into the recovery checkout or the durable candidate.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
sh "$HERE/locate-191.sh" >/dev/null || exit 2
. /private/tmp/crosswake-phase191-run/env-191.sh
. "$HERE/git-pinned-191.sh"
fail() { echo "ensure-clone: $1"; exit 2; }

if [ -d "$IC" ]; then
  [ -d "$IC/.git" ] || fail clone_diverged
  [ "$(g "$IC" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "$BRANCH" ] || fail clone_diverged
  WANT=$CAND_HEAD
  if [ -f "$EV/heads-191.txt" ]; then
    LAST=$(grep -Eo '[0-9a-f]{40}' "$EV/heads-191.txt" | tail -n 1)
    [ -n "$LAST" ] && WANT=$LAST
  fi
  [ "$(g "$IC" rev-parse HEAD 2>/dev/null)" = "$WANT" ] || fail clone_diverged
  st=$(g "$IC" status --porcelain=v1 --untracked-files=all 2>/dev/null) || fail clone_diverged
  [ -z "$st" ] || fail clone_diverged
  [ -d "$IC/deps" ] || fail clone_diverged
  echo "ensure-clone: reused"
  exit 0
fi

# (a) origin URL, read as a file
URL=$(awk '/^\[remote "origin"\]/{f=1;next} /^\[/{f=0} f && $1=="url"{sub(/^[ \t]*url[ \t]*=[ \t]*/,""); print; exit}' "$REC/.git/config")
case "$URL" in *github.com*) : ;; *) fail origin_unreadable ;; esac
# (b) clone
g "$PARENT" clone --no-tags --branch main "$URL" "$IC" >/dev/null 2>&1 || fail clone_failed
# (c) main pin
g "$IC" fetch --no-tags origin refs/heads/main:refs/remotes/origin/main >/dev/null 2>&1 || fail clone_failed
[ "$(g "$IC" rev-parse refs/remotes/origin/main)" = "$MAIN_SHA" ] || fail main_moved
# (d) candidate
g "$IC" fetch --no-tags "$D" refs/heads/candidate:refs/heads/candidate-src >/dev/null 2>&1 || fail candidate_mismatch
[ "$(g "$IC" rev-parse refs/heads/candidate-src)" = "$CAND_HEAD" ] || fail candidate_mismatch
# (e) ancestry
g "$IC" merge-base --is-ancestor "$MAIN_SHA" "$CAND_HEAD" || fail not_ancestor
# (f) branch and fast-forward
g "$IC" switch -q -c "$BRANCH" "$MAIN_SHA" >/dev/null 2>&1 || fail clone_failed
g "$IC" merge --ff-only -q refs/heads/candidate-src >/dev/null 2>&1 || fail not_ancestor
# (g) identity
AN=$(g "$IC" log -1 --format=%an "$CAND_HEAD")
AE=$(g "$IC" log -1 --format=%ae "$CAND_HEAD")
case "$AE" in *@users.noreply.github.com) : ;; *) fail identity_unproven ;; esac
g "$IC" log --format=%ae "$MAIN_SHA" > "$R191/main-author-emails.txt" 2>/dev/null
grep -qxF "$AE" "$R191/main-author-emails.txt" || fail identity_unproven
g "$IC" config user.name "$AN" || fail identity_unproven
g "$IC" config user.email "$AE" || fail identity_unproven
# (h) build
( cd "$IC" && LC_ALL=C.UTF-8 mix deps.get >/dev/null 2>&1 ) || fail deps_failed
( cd "$IC" && LC_ALL=C.UTF-8 MIX_ENV=test mix compile >/dev/null 2>&1 ) || fail compile_failed
( cd "$IC/examples/phoenix_host" && LC_ALL=C.UTF-8 mix deps.get >/dev/null 2>&1 ) || fail deps_failed
( cd "$IC/examples/phoenix_host" && LC_ALL=C.UTF-8 npm ci >/dev/null 2>&1 ) || fail deps_failed
# (i)
printf '%s\n' "$CAND_HEAD" > "$R191/clone-source-head"
echo "ensure-clone: recreated"
