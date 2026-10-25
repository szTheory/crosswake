#!/usr/bin/env bash
# export-stash-189.sh N - patch, untracked tar and expectation for stash N (mirror read only).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
N=${1:-}
case $N in [0-3]) : ;; *) echo "export-stash: usage" >&2; exit 2 ;; esac
mkdir -p -m 0700 "$RUNS/expect" "$RUNS/scratch-03" || exit 1
M="$RUNS/mirror.git"
id=$(gs "$M" rev-parse --verify "refs/stash-backup/$N^{commit}") || { echo "export-stash: ref missing"; exit 1; }
gs "$M" diff --binary "$id^1" "$id" > "$OUT/stash-$N.patch" || { echo "export-stash: diff failed"; exit 1; }
gs "$M" archive --format=tar "$id^3" > "$OUT/stash-$N-untracked.tar" || { echo "export-stash: archive failed"; exit 1; }
{
  printf '%s\n' "$id"
  gs "$M" rev-parse "$id^{tree}"
  gs "$M" rev-parse "$id^1"
  gs "$M" ls-tree -r "$id^3"
} > "$RUNS/expect/stash-$N.expect.new" || { echo "export-stash: expect failed"; exit 1; }
mv "$RUNS/expect/stash-$N.expect.new" "$RUNS/expect/stash-$N.expect"
echo "export stash-$N: ok untracked $(gs "$M" ls-tree -r "$id^3" | awk 'END{print NR+0}')"
