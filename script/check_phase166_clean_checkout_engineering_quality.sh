#!/usr/bin/env bash
# Recurring credential-free repository quality contract (Phase 166 provenance).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

export PYTHONDONTWRITEBYTECODE=1

CURRENT_SECTION="startup"
CORRECTIVE_COMMAND="install the reported required tool and rerun script/check_phase166_clean_checkout_engineering_quality.sh"

section() {
  CURRENT_SECTION="$1"
  CORRECTIVE_COMMAND="$2"
  printf '\n[crosswake] section=%s purpose=%s\n' "$CURRENT_SECTION" "$3"
}

on_error() {
  status=$?
  printf '[crosswake] FAIL section=%s exit=%s\n' "$CURRENT_SECTION" "$status" >&2
  printf '[crosswake] corrective-command=%s\n' "$CORRECTIVE_COMMAND" >&2
  exit "$status"
}

trap on_error ERR

for tool in python3 node mix actionlint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '[crosswake] FAIL section=tooling missing=%s\n' "$tool" >&2
    printf '[crosswake] corrective-command=install %s and rerun script/check_phase166_clean_checkout_engineering_quality.sh\n' "$tool" >&2
    exit 2
  fi
done

section \
  "repository-runner-contract" \
  "script/verify_repository.sh --self-test" \
  "fixed stage execution, dependency blocking, cleanup, and bounded output"
script/verify_repository.sh --self-test

section \
  "repository-runner-tests" \
  "node --test test/js/repository_verification.test.mjs" \
  "repository runner behavior and artifact finalization"
node --test test/js/repository_verification.test.mjs

section \
  "browser-determinism-contract" \
  "node --test test/js/playwright_repository_mode.test.mjs" \
  "zero-retry fresh-server browser repository mode"
node --test test/js/playwright_repository_mode.test.mjs

section \
  "repository-quality-contracts" \
  "mix test test/crosswake/proof/phase166_repository_quality_test.exs" \
  "artifact intent, ownership closure, and CI stage parity"
mix test test/crosswake/proof/phase166_repository_quality_test.exs

section \
  "ci-stage-parity-contract" \
  "python3 script/check_ci_leaf_manifest.py --self-test" \
  "bidirectional literal stage and workflow ownership"
python3 script/check_ci_leaf_manifest.py --self-test

section \
  "ci-authority-contract" \
  "script/check_phase165_efficient_ci.sh" \
  "forty-four proof leaves, classifier control, and fail-closed umbrella"
script/check_phase165_efficient_ci.sh

section \
  "workflow-syntax-contract" \
  "actionlint .github/workflows/crosswake-ci.yml" \
  "touched workflow syntax"
actionlint .github/workflows/crosswake-ci.yml

printf '\n[crosswake] PASS clean-checkout-engineering-quality\n'
