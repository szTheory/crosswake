#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "==> Verifying bounded bridge proof documentation and backend..."

QUICK_START="examples/QUICK_START.md"

if [[ ! -f "$QUICK_START" ]]; then
  echo "missing QUICK_START.md" >&2
  exit 1
fi

grep -Fq "/bridge-proof" "$QUICK_START" || {
  echo "QUICK_START.md must mention the /bridge-proof route" >&2
  exit 1
}

grep -iq "Share" "$QUICK_START" || {
  echo "QUICK_START.md must mention testing the Share capability" >&2
  exit 1
}

echo "==> Running bounded bridge backend tests..."
(cd examples/phoenix_host && mix test test/crosswake_example/bridge_proof_live_test.exs)

echo "Bounded bridge proof verified."
