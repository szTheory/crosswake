#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
host_root="${repo_root}/examples/phoenix_host"

for required_file in \
  "${host_root}/e2e/crosswake_proof_lane/proof_lane.spec.ts" \
  "${host_root}/e2e/crosswake_proof_lane/support/proof_lane.ts"; do
  if [[ ! -f "${required_file}" ]]; then
    echo "missing required generated Phoenix-host proof file: ${required_file}" >&2
    exit 1
  fi
done

for executable in tsc playwright; do
  if [[ ! -x "${host_root}/node_modules/.bin/${executable}" ]]; then
    echo "missing existing Phoenix-host Node dependency: ${executable}" >&2
    exit 1
  fi
done

cd "${host_root}"
npm run typecheck:offline-route-proof
npm run proof:offline-island
