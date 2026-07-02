---
phase: 137-crosswake-sigra-extraction
plan: "04"
subsystem: sigra-ci-pipeline
tags: [ci, release-please, sigra, cleanroom-proof, publish-pipeline, no-engine]
dependency_graph:
  requires: [137-03]
  provides: [sigra-release-please-component, publish-hex-sigra-job, clean-room-proof-sigra-job, no-engine-cleanroom-mode]
  affects: [release-please.yml, release-please-config.json, .release-please-manifest.json, verify_companion_cleanroom.sh]
tech_stack:
  added:
    - crosswake_sigra independent release-please elixir component (one-shot release-as 0.1.0)
    - publish-hex-sigra CI job (CROSSWAKE_RELEASE=1, per-component gate, dry-run+publish+poll)
    - clean-room-proof-sigra CI job (no-engine invocation of verify_companion_cleanroom.sh)
    - no-engine mode in verify_companion_cleanroom.sh (NO_ENGINE=1 flag)
  patterns:
    - per-component gate: sigra jobs key on sigra_release_created (never aggregate releases_created)
    - no-engine mode: sentinel "none" or omitted $3/$4 activates NO_ENGINE=1 branch
    - one-shot release-as: 0.1.0 + _TODO_release_as note + release-as-cleanup auto-strip
key_files:
  created: []
  modified:
    - script/verify_companion_cleanroom.sh (no-engine mode — NO_ENGINE flag + conditional deps/smoke/config)
    - release-please-config.json (packages/crosswake_sigra component block added)
    - .release-please-manifest.json (packages/crosswake_sigra: 0.1.0 as 6th key)
    - .github/workflows/release-please.yml (~139 lines added: outputs + 2 jobs + cleanup/alert extensions)
decisions:
  - "no-engine mode activated by omitted/empty/none $3 — additive, default engine path unchanged (RESEARCH Pitfall 5)"
  - "crosswake_sigra NOT in linked-versions lockstep group — independently versioned (D-8)"
  - "release-as: 0.1.0 one-shot mirrors rulestead/rindle pattern; _TODO_release_as note added (recipe Step 12f)"
  - "publish-hex-sigra sets CROSSWAKE_RELEASE=1 at job level covering all mix steps (T-137-15)"
  - "clean-room-proof-sigra invokes verify_companion_cleanroom.sh with PACKAGE+VERSION only — no engine args (T-137-16)"
  - "release-as-cleanup and release-failure-alert extended to cover sigra (T-137-13)"
metrics:
  duration: "~8 minutes"
  completed: "2026-07-01"
  tasks_completed: 3
  files_changed: 4
status: complete
---

# Phase 137 Plan 04: CI Publish Pipeline Registration for crosswake_sigra Summary

Wired the full CI publish pipeline for `crosswake_sigra` as an independent release-please component: no-engine cleanroom script mode, config+manifest registration, ~139 lines of YAML in release-please.yml (sigra outputs + publish-hex-sigra + clean-room-proof-sigra + cleanup/alert extensions).

## What Was Built

**Task 1:** Added a `NO_ENGINE` mode to `script/verify_companion_cleanroom.sh`. When `$3`/`$4` are omitted, empty, or the sentinel `"none"`, sets `NO_ENGINE=1`. Under `NO_ENGINE=1`: deps-patch python emits a duo (crosswake + PACKAGE only — no engine dep line); smoke test asserts `validate_dependency() == :ok` unconditionally (no engine-present assertion); `config/runtime.exs` registers companion only (no engine config). Default engine path unchanged — strictly additive. Committed at `7ef4b24d`.

**Task 2:** Registered `crosswake_sigra` as an independent elixir release-please component in `release-please-config.json` (clone of rindle block: component, release-type: elixir, separate-pull-requests: true, _TODO_release_as note, release-as: "0.1.0", extra-files, changelog-sections). Added `"packages/crosswake_sigra": "0.1.0"` as the 6th key in `.release-please-manifest.json`. Both files remain valid JSON. `crosswake_sigra` is intentionally NOT in `linked-versions` (D-8). Committed at `d8f9d28a`.

**Task 3:** Extended `.github/workflows/release-please.yml` with ~139 lines:
- Added `sigra_release_created`/`sigra_tag_name`/`sigra_version` outputs (double-dash path-output → dot-notation alias, D-8)
- Added `publish-hex-sigra` job: `needs: release-please`, `if: sigra_release_created == 'true'`, `env: CROSSWAKE_RELEASE: "1"`, checkout via `sigra_tag_name`, `working-directory: packages/crosswake_sigra`, dry-run then publish, Hex.pm propagation poll
- Added `clean-room-proof-sigra` job: `needs: [release-please, publish-hex-sigra]`, `if: sigra_release_created == 'true'`, invokes `verify_companion_cleanroom.sh crosswake_sigra "$sigra_version"` (no engine args — no-engine mode)
- Extended `release-as-cleanup` `if:` to include `sigra_release_created == 'true'`; added `strip_release_as.py crosswake_sigra` strip block
- Extended `release-failure-alert` `needs:` with `publish-hex-sigra` and `clean-room-proof-sigra`; added their results to the issue body
- Committed at `18bab3a3`

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|-----------|
| T-137-13 | `release-as-cleanup` fires on `sigra_release_created` → `strip_release_as.py crosswake_sigra` — one-shot pin auto-removed after first release |
| T-137-14 | All sigra jobs gate on `sigra_release_created` (per-component, never aggregate `releases_created`) |
| T-137-15 | `CROSSWAKE_RELEASE=1` set at job level in `publish-hex-sigra` — all mix steps see Hex dep not path dep |
| T-137-16 | `clean-room-proof-sigra` invokes script in no-engine mode — no phantom rulestead/Rulestead dep or smoke assertion |

## Threat Flags

None — CI/config-only changes; no new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- script/verify_companion_cleanroom.sh: bash -n CLEAN; NO_ENGINE grep FOUND
- release-please-config.json: valid JSON; sigra component block FOUND; NOT in linked-versions VERIFIED
- .release-please-manifest.json: valid JSON; packages/crosswake_sigra: 0.1.0 FOUND
- .github/workflows/release-please.yml: valid YAML; publish-hex-sigra FOUND; clean-room-proof-sigra FOUND; sigra_release_created FOUND; strip_release_as.py crosswake_sigra FOUND
- Commits: 7ef4b24d (task 1), d8f9d28a (task 2), 18bab3a3 (task 3)
