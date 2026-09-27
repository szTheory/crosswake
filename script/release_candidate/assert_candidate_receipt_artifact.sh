#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: assert_candidate_receipt_artifact.sh RECEIPT_DIR" >&2
  exit 2
fi

python3 - "$1" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
expected = {"artifacts.json", "candidate-receipt.json", "candidate-receipt.md"}
entries = list(root.iterdir())
actual = {entry.name for entry in entries}
valid = actual == expected and all(entry.is_file() and not entry.is_symlink() for entry in entries)
if not valid:
    print("candidate receipt artifact has an unexpected file roster", file=sys.stderr)
    raise SystemExit(1)
PY
