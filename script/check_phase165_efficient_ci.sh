#!/usr/bin/env bash
# Credential-free aggregate for recurring Phase 165 efficient-CI contracts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CURRENT_SECTION="startup"
CORRECTIVE_COMMAND="install the reported required tool and rerun this gate"

section() {
  CURRENT_SECTION="$1"
  CORRECTIVE_COMMAND="$2"
  printf '\n[crosswake] PHASE-165 section=%s\n' "$CURRENT_SECTION"
}

on_error() {
  status=$?
  printf '[crosswake] FAIL phase165 section=%s exit=%s\n' "$CURRENT_SECTION" "$status" >&2
  printf '[crosswake] corrective-command=%s\n' "$CORRECTIVE_COMMAND" >&2
  exit "$status"
}

trap on_error ERR

for tool in python3 node mix actionlint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '[crosswake] FAIL phase165 section=tooling missing=%s\n' "$tool" >&2
    printf '[crosswake] corrective-command=install %s and rerun script/check_phase165_efficient_ci.sh\n' "$tool" >&2
    exit 2
  fi
done

section "classification-policy" "python3 script/classify_ci_change.py --self-test"
python3 script/classify_ci_change.py --self-test

section "cancellation-policy" "python3 script/select_obsolete_ci_runs.py --self-test"
python3 script/select_obsolete_ci_runs.py --self-test

section "aggregator-result-semantics" "python3 script/check_aggregator_result_semantics.py --self-test"
python3 script/check_aggregator_result_semantics.py --self-test

section "manifest-and-static-needs" "python3 script/check_ci_leaf_manifest.py --self-test"
python3 script/check_ci_leaf_manifest.py --self-test

section "maximum-authority-shape" "python3 script/check_ci_leaf_manifest.py --maximum-shape test/fixtures/ci/maximum-shape-crosswake-ci.yml --needs-fixture test/fixtures/ci/maximum-shape-needs.json"
python3 script/check_ci_leaf_manifest.py \
  --maximum-shape test/fixtures/ci/maximum-shape-crosswake-ci.yml \
  --needs-fixture test/fixtures/ci/maximum-shape-needs.json

section "workflow-producer-inventory" "python3 script/list_merge_blocking_checks.py --emitters"
python3 script/list_merge_blocking_checks.py --emitters >/dev/null

section "required-context-local-audit" "script/check_required_checks_registered.sh --local-only"
script/check_required_checks_registered.sh --local-only

section "evidence-schema" "node scripts/ci_monitor.cjs test-evidence"
node scripts/ci_monitor.cjs test-evidence

section "policy-contracts" "mix test test/crosswake/proof/phase165_ci_policy_test.exs"
mix test test/crosswake/proof/phase165_ci_policy_test.exs

section "integrity-contracts" "mix test test/crosswake/proof/phase165_ci_integrity_test.exs"
mix test test/crosswake/proof/phase165_ci_integrity_test.exs

section "evidence-contracts" "mix test test/crosswake/proof/phase165_evidence_test.exs"
mix test test/crosswake/proof/phase165_evidence_test.exs

section "workflow-syntax" "actionlint .github/workflows/crosswake-ci.yml"
actionlint .github/workflows/crosswake-ci.yml

printf '\n[crosswake] PASS phase165 efficient-and-maintainable-ci\n'
