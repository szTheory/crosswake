#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="${ROOT_DIR}/examples/phoenix_host"
OWNED_TMP_DIR="${TMPDIR:-/tmp}"
seeds="17 101 1009"
mode="${1:-}"

snapshot_dir="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-phase164-isolation.XXXXXX")"
cleanup_snapshot_dir() {
  rm -rf "${snapshot_dir}"
}
trap cleanup_snapshot_dir EXIT

snapshot_temp() {
  find "${OWNED_TMP_DIR}" -maxdepth 1 -name 'crosswake-example-host-*' -print 2>/dev/null \
    | LC_ALL=C sort
}

snapshot_diff() {
  git -C "${ROOT_DIR}" diff --binary -- \
    test/support/example_host.ex \
    test/crosswake/proof/phase164_example_host_isolation_test.exs \
    script/check_example_host_isolation.sh \
    .github/workflows/requires-example-host-gate.yml
}

report_snapshot_change() {
  seed="$1"
  class="$2"
  kind="$3"
  before="$4"
  after="$5"

  changed="$(comm -3 "${before}" "${after}" 2>/dev/null | sed -n '1s/^[[:space:]]*//p')"
  if [ -z "${changed}" ]; then
    changed="repository diff changed during the run"
  fi

  echo "[crosswake] FAIL example-host-isolation seed=${seed} class=${class} residue=${kind} path=${changed}" >&2
  echo "[crosswake] remediation: restore only the named owned resource, then rerun this seed/class." >&2
  return 1
}

assert_no_residue() {
  seed="$1"
  class="$2"
  before_temp="$3"
  after_temp="$4"
  before_diff="$5"
  after_diff="$6"

  if ! cmp -s "${before_temp}" "${after_temp}"; then
    report_snapshot_change "${seed}" "${class}" "owned-temp" "${before_temp}" "${after_temp}"
  fi

  if ! cmp -s "${before_diff}" "${after_diff}"; then
    report_snapshot_change "${seed}" "${class}" "tracked-path" "${before_diff}" "${after_diff}"
  fi
}

run_class() {
  seed="$1"
  class="$2"
  before_temp="${snapshot_dir}/${seed}-${class}-temp-before"
  after_temp="${snapshot_dir}/${seed}-${class}-temp-after"
  before_diff="${snapshot_dir}/${seed}-${class}-diff-before"
  after_diff="${snapshot_dir}/${seed}-${class}-diff-after"
  log="${snapshot_dir}/${seed}-${class}.log"

  snapshot_temp >"${before_temp}"
  snapshot_diff >"${before_diff}"

  status=0
  if [ "${class}" = "tagged" ]; then
    (
      cd "${ROOT_DIR}"
      MIX_ENV=test mix test --only requires_example_host --seed "$seed"
    ) >"${log}" 2>&1 || status=$?
  else
    (
      cd "${ROOT_DIR}"
      CROSSWAKE_INCLUDE_EXAMPLE_HOST=1 mix test --seed "$seed"
    ) >"${log}" 2>&1 || status=$?
  fi

  if [ "${status}" -ne 0 ]; then
    echo "[crosswake] FAIL example-host-isolation seed=${seed} class=${class} exit=${status}" >&2
    tail -n 80 "${log}" >&2
    return "${status}"
  fi

  snapshot_temp >"${after_temp}"
  snapshot_diff >"${after_diff}"
  assert_no_residue "${seed}" "${class}" "${before_temp}" "${after_temp}" "${before_diff}" "${after_diff}"
  echo "[crosswake] PASS example-host-isolation seed=${seed} class=${class}"
}

if [ "${mode}" = "--self-test-residue" ]; then
  before="${snapshot_dir}/self-test-before"
  after="${snapshot_dir}/self-test-after"
  : >"${before}"
  printf '%s\n' "${OWNED_TMP_DIR%/}/crosswake-example-host-self-test.sqlite3" >"${after}"
  report_snapshot_change "17" "tagged" "owned-temp" "${before}" "${after}"
  exit 1
fi

if [ -n "${mode}" ] && [ "${mode}" != "--matrix-only" ]; then
  echo "usage: script/check_example_host_isolation.sh [--matrix-only|--self-test-residue]" >&2
  exit 2
fi

if [ "${mode}" != "--matrix-only" ]; then
  (
    cd "${EXAMPLE_DIR}"
    MIX_ENV=dev mix deps.get
    MIX_ENV=dev mix compile
  )

  (
    cd "${ROOT_DIR}"
    MIX_ENV=test mix compile
    MIX_ENV=test mix test test/crosswake/proof/phase164_example_host_isolation_test.exs
  )
fi

for seed in ${seeds}; do
  run_class "${seed}" "tagged"
  run_class "${seed}" "complete"
done

echo "[crosswake] PASS example-host-isolation matrix seeds=${seeds} classes=tagged,complete"
