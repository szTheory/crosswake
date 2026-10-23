#!/bin/sh
# Rebuild or verify the work clone W of the durable candidate.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
sh "$HERE/locate-190.sh" --ensure >/dev/null || exit 2
. /private/tmp/crosswake-phase190-run/env-190.sh
if [ ! -d "$W" ]; then
  git -C "$R190" clone --no-hardlinks --branch candidate "$D" "$W" >/dev/null 2>&1 || { echo "ensure-work: clone_failed"; exit 2; }
  (cd "$W" && mix deps.get >"$R190/deps.log" 2>&1) || { echo "ensure-work: deps_failed"; exit 2; }
  (cd "$W" && MIX_ENV=test mix compile >"$R190/compile.log" 2>&1) || { echo "ensure-work: compile_failed"; exit 2; }
  echo "ensure-work: recreated"; exit 0
fi
wh=$(git --no-optional-locks -C "$W" rev-parse HEAD 2>/dev/null)
dh=$(git --no-optional-locks -C "$D" rev-parse HEAD 2>/dev/null)
if [ -z "$wh" ] || [ "$wh" != "$dh" ] || ! git -C "$W" diff --quiet HEAD || ! git -C "$W" diff --cached --quiet || [ ! -d "$W/deps" ]; then
  echo "ensure-work: work_diverged"; exit 2
fi
echo "ensure-work: reused"
