---
phase: 131-publish-pipeline-clean-room-lane-rulestead
plan: "03"
subsystem: publish-pipeline
tags: [hex-publish, release-please, companion-extraction, clean-room, elixir, ci, proof]
status: complete

dependency_graph:
  requires:
    - publish-hex-rulestead CI job (131-02)
    - script/verify_companion_cleanroom.sh (131-02)
    - rulestead_release_created / rulestead_version output aliases (131-01)
  provides:
    - clean-room-proof-rulestead CI job (post-publish PROOF-02 ordering gate)
    - 131-RELEASE-AS-REMOVAL.md follow-up runbook (D-04 Pitfall 6 documentation)
  affects:
    - .github/workflows/release-please.yml (clean-room-proof-rulestead job added)
    - .planning/phases/131-publish-pipeline-clean-room-lane-rulestead/131-RELEASE-AS-REMOVAL.md (new)

tech_stack:
  patterns:
    - Post-publish needs-graph ordering: needs: [release-please, publish-hex-rulestead] is the structural PROOF-02 guarantee
    - Per-component gate: rulestead_release_created (not aggregate releases_created) mirrors D-07
    - Thin YAML: all proof logic delegates to script/verify_companion_cleanroom.sh (D-16)
    - One-shot release-as bootstrap with removal runbook (D-04, Pitfall 6)

key_files:
  modified:
    - .github/workflows/release-please.yml
  created:
    - .planning/phases/131-publish-pipeline-clean-room-lane-rulestead/131-RELEASE-AS-REMOVAL.md

decisions:
  - "PROOF-02: needs: [release-please, publish-hex-rulestead] is the structural enforcement — clean-room cannot run before dry-run-gated publish (T-131-08 mitigated)"
  - "D-15: clean-room-proof-rulestead mirrors iOS/Android post-publish idiom: per-component gate + thin YAML delegating to the script"
  - "D-16: zero inline proof logic in YAML — all propagation poll, throwaway host, compile, smoke test, doctor steps live in script/verify_companion_cleanroom.sh"
  - "D-04/Pitfall 6: release-as removal runbook documented with exact trigger, JSON edit, verification, and rindle cross-reference"

metrics:
  duration: "5m"
  completed: "2026-06-26"
  tasks: 2
  files_modified: 2
---

# Phase 131 Plan 03: Post-Publish Clean-Room CI Job + Release-As Removal Runbook Summary

## One-liner

`clean-room-proof-rulestead` CI job wired post-publish via `needs: [release-please, publish-hex-rulestead]` (PROOF-02 structural ordering), delegating all proof logic to the parameterized script; `release-as` removal runbook documents the D-04 one-shot bootstrap removal so the next companion cut is 0.1.1 not a stuck 0.1.0.

## What Was Built

**Task 1 — `clean-room-proof-rulestead` job in `.github/workflows/release-please.yml` (9906bd1)**

Added the `clean-room-proof-rulestead` job at the end of `release-please.yml`, mirroring the `clean-room-proof-ios`/`-android` post-publish idiom:

- `needs: [release-please, publish-hex-rulestead]` — D-15/PROOF-02: structural guarantee that clean-room cannot run before the dry-run-gated companion publish completes
- `if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' }}` — D-07: per-component gate; consistent with the publish job gate (never fires on core-only releases)
- `runs-on: ubuntu-latest`
- `permissions: { contents: read }`
- Steps: `actions/checkout` (same SHA as sibling jobs), `erlef/setup-beam` via `.tool-versions` (strict, same SHA), `mix local.hex --force && mix local.rebar --force`, then a single thin step running `bash script/verify_companion_cleanroom.sh crosswake_rulestead "${{ needs.release-please.outputs.rulestead_version }}"` (D-16)

No inline mix-new, propagation-poll, smoke-test, or doctor logic — all proof execution lives in the Plan 02 script. The `clean-room-proof-ios`, `clean-room-proof-android`, and `phase130-proof.yml` jobs are unchanged.

**Task 2 — `131-RELEASE-AS-REMOVAL.md` runbook (e12409f)**

Created a short, imperative follow-up runbook documenting that `"release-as": "0.1.0"` in the `packages/crosswake_rulestead` config entry is a ONE-SHOT first-cut bootstrap (D-04) that MUST be removed immediately after the first `crosswake_rulestead-v0.1.0` Release PR merges (Pitfall 6). Runbook includes:

- Trigger condition: first `crosswake_rulestead-v0.1.0` Release PR merged + tag exists
- Exact JSON diff: delete `"release-as": "0.1.0"` from the companion entry
- One-line verification: `python3` assert that `release-as` is absent post-removal
- Suggested commit message
- Rindle reuse section (Phase 132 applies the same removal after its first Release PR)
- Cross-references: `script/extract_companion.md` Step 12f, Phase 131 RESEARCH.md §D-04 and Pitfall 6

`release-please-config.json` intentionally still carries `"release-as": "0.1.0"` — it must persist through the first cut.

## Verification Results

All plan acceptance criteria met:

| Check | Result |
|-------|--------|
| `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))"` | PASS — valid YAML |
| `j['needs']` contains both `release-please` and `publish-hex-rulestead` | PASS |
| `j['if']` references `rulestead_release_created` | PASS |
| `verify_companion_cleanroom.sh crosswake_rulestead` in steps | PASS |
| `rulestead_version` in steps | PASS |
| No inline mix-new or doctor logic (thin YAML, D-16) | PASS |
| `clean-room-proof-ios`, `clean-room-proof-android`, `phase130-proof.yml` unchanged | PASS |
| `131-RELEASE-AS-REMOVAL.md` exists with `release-as` and `0.1.0` | PASS |
| Runbook contains trigger condition (first Release PR merged) | PASS |
| Runbook contains exact JSON edit | PASS |
| Runbook cross-references `script/extract_companion.md` Step 12f | PASS |
| `release-please-config.json` STILL carries `"release-as": "0.1.0"` | PASS — `release-as intact pre-cut OK` |
| `python3 -c "import json; json.load(open('release-please-config.json'))"` | PASS — valid JSON |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All artifacts are fully implemented.

- The `clean-room-proof-rulestead` job's actual green run is post-publish / CI-only (PROOF-02 irreversible). The `needs:` ordering is statically verifiable now. The job cannot run until `crosswake_rulestead` exists on Hex.pm — this is by design, not a stub.
- `release-as: "0.1.0"` intentionally left in `release-please-config.json` — it must persist through the first Release PR cut. Removal is documented in the runbook.

## Threat Flags

No new security surface beyond the plan's threat model:
- T-131-08 mitigated: `needs: [release-please, publish-hex-rulestead]` makes the clean-room structurally unable to run before the dry-run-gated publish
- T-131-09 mitigated: `131-RELEASE-AS-REMOVAL.md` provides explicit trigger + verification + rindle cross-reference for the one-shot release-as risk
- T-131-SC: no npm/pip/cargo installs; only `mix local.hex`/`mix local.rebar` (first-party Hex tooling)
- No new network endpoints, auth paths, or schema changes outside planned scope

## Self-Check: PASSED

- `.github/workflows/release-please.yml` — FOUND, `clean-room-proof-rulestead` job present with `rulestead_release_created` gate and `needs: [release-please, publish-hex-rulestead]`
- `.planning/phases/131-publish-pipeline-clean-room-lane-rulestead/131-RELEASE-AS-REMOVAL.md` — FOUND, 126 lines, all acceptance criteria checks pass
- `release-please-config.json` — FOUND, `"release-as": "0.1.0"` still present on companion entry (pre-cut intact)
- Commits: 9906bd1 (clean-room-proof-rulestead job), e12409f (release-as removal runbook) — both verified in git log
