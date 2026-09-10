#!/usr/bin/env bash
# Fixed-purpose repository proof facade; arguments can select records but cannot create commands (D-01).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

case "${1:-}" in
  --all)
    test "$#" -eq 1 || { echo "usage: script/verify_repository.sh (--all | --stage <purpose-id> | --self-test)" >&2; exit 64; }
    exec node script/verify_repository.mjs --all
    ;;
  --stage)
    test "$#" -eq 2 || { echo "usage: script/verify_repository.sh --stage <purpose-id>" >&2; exit 64; }
    exec node script/verify_repository.mjs --stage "$2"
    ;;
  --self-test)
    test "$#" -eq 1 || { echo "usage: script/verify_repository.sh --self-test" >&2; exit 64; }
    exec node script/verify_repository.mjs --self-test
    ;;
  *)
    echo "usage: script/verify_repository.sh (--all | --stage <purpose-id> | --self-test)" >&2
    exit 64
    ;;
esac
