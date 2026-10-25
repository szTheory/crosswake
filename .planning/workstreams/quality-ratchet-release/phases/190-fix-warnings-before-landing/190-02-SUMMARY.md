---
phase: 190-fix-warnings-before-landing
plan: 02
subsystem: privacy-scan
tags: [FIX-01, scan, selftest]
requires: []
provides: [scan-privacy-190.sh, selftest-scan-190.sh]
key-files:
  created:
    - scripts/scan-privacy-190.sh
    - scripts/selftest-scan-190.sh
    - 190-EVIDENCE/selftest-scan-190.out
decisions:
  - "Successor scan copies the 188 scan byte-for-byte from the copy step onward, plus one added `scan: no files scanned` line."
status: complete
requirements: [FIX-01]
actuals:
  tasks: 2
  commits: 0
---

# Phase 190 Plan 02: Privacy scan successor (FIX-01) Summary

The new privacy scan can no longer report a clean pass for a scope with no files.

## What was checked and what happened

The 188 scan counted list lines, not files. Control S15 ran the unchanged 188 scan on an empty directory and it exited 0 with `scan: files 0`, so the defect is real. The new `scan-privacy-190.sh` refuses the same input with exit 2 (`scan: empty directory`, control S02).

Successor behavior, each proven by a control:
- Empty directory, nested empty folders only, empty list, blank-only list: exit 2.
- Missing entry: exit 2 (`scan: path missing or unreadable`).
- Symlink as a list entry, or anywhere inside a listed directory (even next to regular files): exit 2, `scan: symlink refused`.
- FIFO inside a directory: exit 2, `scan: special file refused`.
- One clean file: exit 0, `scan: files 1`; directory of two clean files: `scan: files 2`.
- Planted home-path hit (built from fragments): exit 1, `scan: hits 1`, planted text absent from output.
- TERM during a scan: exit 2, no scratch folder left. Two parallel scans: both exit 0 with identical output.

Control count: 15 of 15 as expected (output in `190-EVIDENCE/selftest-scan-190.out`). The `--tracer` mode reports 3 of 3. The 188 originals still verify (10 OK). The successor scan of its own scripts and the evidence output reports `files 3`, `hits 0`. No fixture folders remain.

## Deviations from Plan

None. The TDD red step against the 188 original is represented by control S15 (original passes empty directory) rather than a separate temporary copy run.

## Commit

Commit skipped per checkout rule (recovery checkout frozen; no git command run). Plan commits: 0 by design.

## Self-Check: PASSED
