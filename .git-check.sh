#!/bin/bash
WT_GIT_DIR=`git rev-parse --git-dir 2>/dev/null`
case "$WT_GIT_DIR" in
  *.git/worktrees/*)
      SENTINEL="$WT_GIT_DIR/gsd-spawn-toplevel"
      [ ! -f "$SENTINEL" ] && git rev-parse --show-toplevel > "$SENTINEL" 2>/dev/null
      EXPECTED_TL=`cat "$SENTINEL" 2>/dev/null`
      ACTUAL_TL=`git rev-parse --show-toplevel 2>/dev/null`
      if [ -n "$EXPECTED_TL" ] && [ "$ACTUAL_TL" != "$EXPECTED_TL" ]; then
        echo "FATAL: cwd drifted from spawn-time worktree root (#3097)" >&2
        exit 1
      fi
    ;;
esac

if [ -f .git ]; then  # worktree
  HEAD_REF=`git symbolic-ref --quiet HEAD || echo "DETACHED"`
  ACTUAL_BRANCH=`git rev-parse --abbrev-ref HEAD`
  if [ "$HEAD_REF" = "DETACHED" ] || \
     echo "$ACTUAL_BRANCH" | grep -Eq '^(main|master|develop|trunk|release/.*)$'; then
    echo "FATAL: refusing to commit — worktree HEAD is on '$ACTUAL_BRANCH' (expected per-agent branch)." >&2
    exit 1
  fi
  if ! echo "$ACTUAL_BRANCH" | grep -Eq '^worktree-agent-[A-Za-z0-9._/-]+$'; then
    echo "FATAL: refusing to commit — worktree HEAD '$ACTUAL_BRANCH' is not in the worktree-agent-* namespace." >&2
    exit 1
  fi
fi
exit 0
