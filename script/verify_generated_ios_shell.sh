#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild is required for generated iOS shell verification" >&2
  exit 1
fi

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-ios-shell.XXXXXX")"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

mix crosswake.gen.shell ios --target "$tmpdir" >/dev/null

project="$tmpdir/native/ios/crosswake_shell/CrosswakeShell.xcodeproj"
scheme="CrosswakeShell"

project_check="$(xcodebuild -list -project "$project" 2>&1)" || {
  echo "error: generated scheme is not buildable via xcodebuild -list" >&2
  printf '%s\n' "$project_check" >&2
  exit 1
}

destinations="$(xcodebuild -project "$project" -scheme "$scheme" -showdestinations 2>&1)"

destination="$(printf '%s\n' "$destinations" | awk '
  /platform:iOS Simulator/ && /name:iPhone/ {
    line = $0
    sub(/^.*\{ /, "", line)
    sub(/ \}.*$/, "", line)
    print line
    exit
  }
')"

if [[ -z "$destination" ]]; then
  echo "error: no iPhone simulator destination found for generated shell" >&2
  printf '%s\n' "$destinations" >&2
  exit 1
fi

xcodebuild \
  -project "$project" \
  -scheme "$scheme" \
  -destination "$destination" \
  test
