---
phase: 175-rehearsal-and-publish
plan: 139
subsystem: release-candidate-preflight
tags: [node, git, porcelain, fake-process]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan138 safe diagnostic for a rejected one-row dry-run envelope
provides:
  - Acceptance of Git's exact optional final Done trailer after the expected new-tag row
  - Regressions showing unrelated extra output remains rejected
affects: [175-106, 175-46, 175-47, 175-48, 175-89]
requirements-completed: []
key-files:
  created:
    - evidence/175-plan139-git-dry-run.json
    - 175-139-SUMMARY.md
  modified:
    - script/release_candidate/plan105_mirror_tag_collector.mjs
    - script/release_candidate/plan105_mirror_tag_collector.test.mjs
    - 175-LEARNINGS.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - AGENTS.md
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 139: Git Dry-Run Output

## What happened

A temporary local bare-repository check showed that successful Git porcelain dry-run output has three parts: a `To` line naming the local bare remote, the expected new-tag row, and a final `Done` line. Stderr was empty. The collector accepted the row but rejected the full output because it did not allow Git's final line.

The parser now accepts one exact final `Done` line after the existing expected row and optional fixed `To` banner. It still rejects unrelated lines, a line after `Done`, duplicate `Done` lines, and extra blank lines.

## Checks

- Focused fake-process run: 7 cases passed, 0 failed.
- Node syntax checks passed for the collector and test file.
- Scoped whitespace check passed.
- The successful parser test used fake adapters; it did not contact a remote or create a tag.

## What this says about Plan137

This local reproduction likely explains why Plan137 rejected the preview: the parser would have rejected the same output shape. Plan137's original stdout was not saved, so we cannot confirm that its output contained these exact lines. Its attempt and one-use approval remain consumed. No tag was created, and the release remains blocked.

## Next step

Run `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to plan one fresh exact-head preflight using the corrected collector. That plan must use the new collector digest, display a new approval card, and wait for a new plain `allow` before any remote check. The previous `allow` cannot be reused. A tag write remains a separate later decision.
