#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

GUIDE="guides/adopter_profiles.md"
HOST_README="examples/phoenix_host/README.md"
PHASE5_PROOF="script/verify_phase5_example_hosts.sh"

required_names=(
  "Phoenix SaaS Portal"
  "Selective Native Flow"
  "Local-First Study Flow"
)

for file in "$GUIDE" "$HOST_README" "$PHASE5_PROOF"; do
  [[ -f "$file" ]] || {
    echo "missing required file: $file" >&2
    exit 1
  }
done

for name in "${required_names[@]}"; do
  grep -Fq "$name" "$GUIDE" || {
    echo "missing profile name in $GUIDE: $name" >&2
    exit 1
  }

  grep -Fq "$name" "$HOST_README" || {
    echo "missing profile name in $HOST_README: $name" >&2
    exit 1
  }
done

grep -Fq "one shared Phoenix host" "$HOST_README" || {
  echo "host contract must preserve one shared Phoenix host" >&2
  exit 1
}

grep -Fq "paired iOS and Android example hosts" "$HOST_README" || {
  echo "host contract must preserve paired native proof hosts" >&2
  exit 1
}

grep -Fq "4-6 routes" "$HOST_README" || {
  echo "host contract must lock route budgets" >&2
  exit 1
}

grep -Fq "3-4 routes" "$HOST_README" || {
  echo "host contract must lock the local-first route budget" >&2
  exit 1
}

grep -Fq ":live_view" "$GUIDE" || {
  echo "guide must mention :live_view" >&2
  exit 1
}

grep -Fq ":native_screen" "$GUIDE" || {
  echo "guide must mention :native_screen" >&2
  exit 1
}

grep -Fq ":offline_island" "$GUIDE" || {
  echo "guide must mention :offline_island" >&2
  exit 1
}

grep -Fq "route unavailable" "$GUIDE" || {
  echo "guide must preserve the SaaS failure vocabulary" >&2
  exit 1
}

grep -Fq "Supported behavior" "$GUIDE" || {
  echo "guide must call out supported SaaS behavior" >&2
  exit 1
}

grep -Fq "Degraded behavior" "$GUIDE" || {
  echo "guide must call out degraded SaaS-shell behavior" >&2
  exit 1
}

grep -Fq "Deferred behavior" "$GUIDE" || {
  echo "guide must call out deferred SaaS behavior" >&2
  exit 1
}

grep -Fq "host-owned auth" "$GUIDE" || {
  echo "guide must preserve the host-owned auth posture" >&2
  exit 1
}

grep -Fq "haptics.impact" "$GUIDE" || {
  echo "guide must preserve the exercised SaaS shell request path" >&2
  exit 1
}

grep -Fq "Supported behavior" "$HOST_README" || {
  echo "host README must call out supported SaaS behavior" >&2
  exit 1
}

grep -Fq "Degraded behavior" "$HOST_README" || {
  echo "host README must call out degraded SaaS-shell behavior" >&2
  exit 1
}

grep -Fq "Deferred behavior" "$HOST_README" || {
  echo "host README must call out deferred SaaS behavior" >&2
  exit 1
}

grep -Fq "pack_incompatible" "$GUIDE" || {
  echo "guide must preserve the selective-native failure vocabulary" >&2
  exit 1
}

grep -Fq "conflict requires attention" "$GUIDE" || {
  echo "guide must preserve the local-first failure vocabulary" >&2
  exit 1
}

grep -Fq "script/verify_phase5_example_hosts.sh" "$HOST_README" || {
  echo "host contract must extend the existing Phase 5 proof posture" >&2
  exit 1
}

grep -Fq "guides/support_matrix.md" "$GUIDE" || {
  echo "guide must route status back to the support matrix" >&2
  exit 1
}

grep -Fq "guides/install.md" "$GUIDE" || {
  echo "guide must route proof entry back to the install guide" >&2
  exit 1
}

grep -Fq "verify_generated_ios_shell.sh" "$GUIDE" && {
  echo "guide must not duplicate exact proof-hook names" >&2
  exit 1
}

grep -Fq "verify_generated_android_shell.sh" "$GUIDE" && {
  echo "guide must not duplicate exact proof-hook names" >&2
  exit 1
}

grep -Eiq "starter app|starter-app|template|plugin bus|plugin-bus" "$HOST_README" && {
  echo "host contract drifted into starter-app or plugin-bus language" >&2
  exit 1
}

echo "Adopter profile contract verified."
