#!/usr/bin/env bash
# Credential-free aggregate for every Phase 164 dependency-security and gate-authority contract.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

CURRENT_SECTION="startup"
CORRECTIVE_COMMAND="rerun the reported focused Phase 164 check"

section() {
  CURRENT_SECTION="$1"
  CORRECTIVE_COMMAND="$2"
  printf '\n[crosswake] PHASE-164 section=%s\n' "$CURRENT_SECTION"
}

on_error() {
  status=$?
  printf '[crosswake] FAIL phase164 section=%s exit=%s\n' "$CURRENT_SECTION" "$status" >&2
  printf '[crosswake] corrective-command=%s\n' "$CORRECTIVE_COMMAND" >&2
  exit "$status"
}

trap on_error ERR

# Lock coherence is load-bearing: both supported locks must resolve before an advisory lookup or
# a proof that assumes their contents. Keep these as the first two executed verification commands.
section "dependency-lock-root" "mix deps.get --check-locked"
mix deps.get --check-locked

section "dependency-lock-example-host" "(cd examples/phoenix_host && mix deps.get --check-locked)"
(cd examples/phoenix_host && mix deps.get --check-locked)

section "dependency-audits" "script/check_dependency_security.sh"
script/check_dependency_security.sh

section "dependency-negative-controls" "mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs"
mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs

section "workflow-producer-inventory" "python3 script/list_merge_blocking_checks.py --emitters"
python3 script/list_merge_blocking_checks.py --emitters >/dev/null

section "required-context-local-audit" "script/check_required_checks_registered.sh --local-only"
script/check_required_checks_registered.sh --local-only

section "required-context-negative-controls" "mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs"
mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs

section "exunit-live-ownership" "elixir script/check_exunit_ownership.exs"
elixir script/check_exunit_ownership.exs

section "exunit-ownership-negative-controls" "mix test test/crosswake/proof/phase164_exunit_ownership_test.exs"
mix test test/crosswake/proof/phase164_exunit_ownership_test.exs

section "example-host-lifecycle" "mix test test/crosswake/proof/phase164_example_host_isolation_test.exs"
mix test test/crosswake/proof/phase164_example_host_isolation_test.exs

section "example-host-six-run-matrix" "script/check_example_host_isolation.sh"
script/check_example_host_isolation.sh

section "aggregator-structural-parity" "mix test test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs"
mix test test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs

section "aggregator-result-semantics" "python3 script/check_aggregator_result_semantics.py --self-test"
python3 script/check_aggregator_result_semantics.py --self-test

printf '\n[crosswake] PASS phase164 dependency-security-and-gate-authority\n'
