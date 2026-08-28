#!/usr/bin/env bash
# Fail-closed dependency advisory proof for the two supported Mix projects.
# Output is intentionally bounded to project, lock, package, and corrective command.
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="${ROOT_DIR}/examples/phoenix_host"
FIXTURE_FLAG="--assert-vulnerable-fixture"

print_failure() {
  project="$1"
  lock_path="$2"
  package="$3"
  command="$4"

  printf '[crosswake] FAIL dependency-security project=%s lock=%s package=%s\n' \
    "$project" "$lock_path" "$package"
  printf '[crosswake] corrective-command=%s\n' "$command"
}

assert_vulnerable_fixture() {
  fixture_arg="${1:-}"

  if [ -z "$fixture_arg" ]; then
    print_failure "fixture" "missing" "unknown" \
      "script/check_dependency_security.sh ${FIXTURE_FLAG} test/fixtures/security/advisory-bearing.lock"
    return 1
  fi

  case "$fixture_arg" in
    /*) fixture_path="$fixture_arg" ;;
    *) fixture_path="${ROOT_DIR}/${fixture_arg}" ;;
  esac

  fixture_dir="$(dirname "$fixture_path")"
  if [ ! -d "$fixture_dir" ]; then
    print_failure "fixture" "$fixture_arg" "unknown" \
      "script/check_dependency_security.sh ${FIXTURE_FLAG} test/fixtures/security/advisory-bearing.lock"
    return 1
  fi

  canonical_dir="$(cd "$fixture_dir" && pwd -P)"
  canonical_path="${canonical_dir}/$(basename "$fixture_path")"
  allowed_dir="${ROOT_DIR}/test/fixtures/security"

  if [ "$canonical_dir" != "$allowed_dir" ] || [ ! -s "$canonical_path" ]; then
    print_failure "fixture" "$fixture_arg" "unknown" \
      "script/check_dependency_security.sh ${FIXTURE_FLAG} test/fixtures/security/advisory-bearing.lock"
    return 1
  fi

  relative_path="${canonical_path#${ROOT_DIR}/}"

  if grep -Eq '"phoenix"[[:space:]]*:[[:space:]]*\{:hex,[[:space:]]*:phoenix,[[:space:]]*"1\.8\.7"' "$canonical_path"; then
    printf '[crosswake] EXPECTED-REJECTION dependency-security lock=%s package=phoenix\n' \
      "$relative_path"
    printf '[crosswake] corrective-command=mix deps.update phoenix\n'
    return 0
  fi

  print_failure "fixture" "$relative_path" "unknown" \
    "restore test/fixtures/security/advisory-bearing.lock"
  return 1
}

audit_project() {
  project="$1"
  project_dir="$2"
  lock_path="$3"
  audit_output="$4"

  if [ ! -s "${project_dir}/mix.lock" ]; then
    print_failure "$project" "$lock_path" "unknown" "mix deps.get"
    return 1
  fi

  (
    cd "$project_dir" || exit 1
    mix hex.audit >"$audit_output" 2>&1
  )
  audit_status=$?

  if [ "$audit_status" -eq 0 ] && [ -s "$audit_output" ]; then
    printf '[crosswake] OK dependency-security project=%s lock=%s advisories=0\n' \
      "$project" "$lock_path"
    return 0
  fi

  package="$(sed -nE 's/^[[:space:]]*([a-z][a-z0-9_]*)[[:space:]]+[0-9][^[:space:]]*[[:space:]]+-.*/\1/p; s/^[[:space:]]*([a-z][a-z0-9_]*)[[:space:]]+EEF-CVE-.*/\1/p' "$audit_output" | head -n 1)"
  if [ -z "$package" ]; then
    package="unknown"
    corrective_command="mix hex.audit"
  else
    corrective_command="mix deps.update ${package}"
  fi

  print_failure "$project" "$lock_path" "$package" "$corrective_command"
  return 1
}

if [ "${1:-}" = "$FIXTURE_FLAG" ]; then
  if [ "$#" -ne 2 ]; then
    assert_vulnerable_fixture "${2:-}"
    exit $?
  fi

  assert_vulnerable_fixture "$2"
  exit $?
fi

if [ "$#" -ne 0 ]; then
  print_failure "arguments" "unknown" "unknown" \
    "script/check_dependency_security.sh [${FIXTURE_FLAG} test/fixtures/security/advisory-bearing.lock]"
  exit 1
fi

if ! command -v mix >/dev/null 2>&1; then
  print_failure "tool" "mix.lock" "unknown" "install the repository Elixir toolchain"
  exit 1
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-dependency-security.XXXXXX")" || exit 1
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

status=0
audit_project "root" "$ROOT_DIR" "mix.lock" "${TMP_DIR}/root.audit" || status=1
audit_project "example-host" "$EXAMPLE_DIR" "examples/phoenix_host/mix.lock" \
  "${TMP_DIR}/example.audit" || status=1

exit "$status"
