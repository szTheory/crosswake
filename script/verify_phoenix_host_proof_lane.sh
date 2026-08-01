#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
host_root="${repo_root}/examples/phoenix_host"

for executable in tsc playwright; do
  if [[ ! -x "${host_root}/node_modules/.bin/${executable}" ]]; then
    echo "missing existing Phoenix-host Node dependency: ${executable}" >&2
    exit 1
  fi
done

cd "${host_root}"
npm run typecheck:offline-route-proof
npm run proof:offline-island
