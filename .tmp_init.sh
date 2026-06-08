#!/bin/bash
INIT=$(gsd-sdk query init.execute-phase "80")
if [[ "$INIT" == @file:* ]]; then INIT=$(cat "${INIT#@file:}"); fi
echo "INIT=$INIT"
AGENT_SKILLS=$(gsd-sdk query agent-skills gsd-executor)
echo "AGENT_SKILLS=$AGENT_SKILLS"
RUNTIME=$(gsd-sdk query config-get runtime --default claude 2>/dev/null || echo "claude")
echo "RUNTIME=$RUNTIME"
USE_WORKTREES=$(gsd-sdk query config-get workflow.use_worktrees 2>/dev/null || echo "true")
echo "USE_WORKTREES=$USE_WORKTREES"
CONTEXT_WINDOW=$(gsd-sdk query config-get context_window 2>/dev/null || echo "200000")
echo "CONTEXT_WINDOW=$CONTEXT_WINDOW"
if [ -f .gitmodules ]; then
  SUBMODULE_PATHS=$(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
  echo "SUBMODULE_PATHS=$SUBMODULE_PATHS"
else
  echo "SUBMODULE_PATHS="
fi
