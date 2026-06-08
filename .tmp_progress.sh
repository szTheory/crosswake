#!/bin/bash
INIT=$(gsd-sdk query init.progress)
if [[ "$INIT" == @file:* ]]; then INIT=$(cat "${INIT#@file:}"); fi
echo "INIT=$INIT"
DISCUSS_MODE=$(gsd-sdk query config-get workflow.discuss_mode 2>/dev/null || echo "discuss")
echo "DISCUSS_MODE=$DISCUSS_MODE"
ROADMAP=$(gsd-sdk query roadmap.analyze)
echo "ROADMAP=$ROADMAP"
STATE=$(gsd-sdk query state-snapshot)
echo "STATE=$STATE"
