---
phase: 33-corridor-routes-and-ci-infrastructure
plan: "02"
subsystem: ci
tags: [ci, workflow, phase34, proof, hermetic, advisory, commerce]
requirements-completed: [PROOF-02]

dependency_graph:
  requires:
    - .github/workflows/phase23-proof.yml
  provides:
    - .github/workflows/phase34-proof.yml
  affects:
    - merge gate for all v3.4 PRs

tech_stack:
  added: []
  patterns:
    - hermetic-vs-advisory CI split (established in v3.2/phase23, now extended for v3.4)

key_files:
  created:
    - .github/workflows/phase34-proof.yml
  modified: []

decisions:
  - "Broad mix test --exclude requires_example_host run (not explicit per-file list) auto-discovers Phase 36 proof file by tag discipline"
  - "BEAM versions and action pins (actions/checkout@v6, erlef/setup-beam@v1, elixir 1.19.5/otp 27.3) preserved from phase23-proof.yml"
  - "Filename is phase34-proof.yml per D-10 — named for milestone proof surface it gates, not the phase that creates it"

metrics:
  duration: 84s
  completed: "2026-05-29"
  tasks_completed: 1
  files_created: 1
  files_modified: 0
---

# Phase 33 Plan 02: CI Infrastructure (phase34-proof.yml) Summary

Two-job hermetic+advisory CI workflow for v3.4 paywall corridor proof, mirroring phase23-proof.yml with hermetic lane running `mix test --exclude requires_example_host` and advisory lane gated to schedule/workflow_dispatch only.

## What Was Built

Created `.github/workflows/phase34-proof.yml` as a direct structural adaptation of `.github/workflows/phase23-proof.yml`. The workflow provides two jobs:

**Hermetic merge-blocking job (`merge-blocking-commerce-proof`):**
- Runs on `pull_request`, `push` to main, and `workflow_dispatch` (explicit `if:` guard skips `schedule`)
- `runs-on: macos-15`, `timeout-minutes: 20`
- Steps: Checkout → Setup BEAM (elixir 1.19.5 / otp 27.3) → `mix deps.get` → `mix compile --warnings-as-errors` (separate step, not folded into test) → `mix test --exclude requires_example_host`
- The broad test run auto-discovers Phase 36's hermetic proof file because it stays untagged — no per-file path maintenance required

**Advisory job (`advisory-commerce-proof`):**
- `continue-on-error: true` — never gates merge
- `if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}` — cannot appear as a PR status check
- Three placeholder echo steps (StoreKit simulator / Play Billing test-track / device-storefront) + advisory status summary `::notice::` step
- Echo text updated from "v3.2" references to v3.4 paywall corridor context

**4-condition `promotion_path` comment block** copied verbatim from phase23-proof.yml lines 19-28 (conditions are milestone-agnostic). Header comment framing updated from "Phase 23 / v3.2 commerce support" to "Phase 34+ / v3.4 paywall corridor proof".

## Verification

All acceptance criteria passed:

```
YAML validation: OK
name: Phase 34 Proof                                           ✓
merge-blocking-commerce-proof job key                         ✓
advisory-commerce-proof job key                               ✓
mix compile --warnings-as-errors (separate step)              ✓
mix test --exclude requires_example_host                      ✓
hermetic if: pull_request || push || workflow_dispatch        ✓
advisory if: schedule || workflow_dispatch                    ✓
continue-on-error: true                                       ✓
schedule cron: "0 6 * * 1"                                    ✓
4-condition promotion_path comment block (#   1. through 4.)  ✓
```

## Deviations from Plan

None - plan executed exactly as written.

The `phase23-proof.yml` hermetic job used explicit per-file test paths (lines 77-97 of source). As specified in D-07, these were replaced with the single broad `mix test --exclude requires_example_host` run. This is the intended deviation from phase23's style, not an unplanned one.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The workflow executes only: `mix deps.get`, `mix compile`, `mix test`, and echo placeholder commands. Reuses existing `actions/checkout@v6` and `erlef/setup-beam@v1` action pins from phase23 (project-established posture). STRIDE T-33-CI-01 (advisory job accidentally gating merge) mitigated by both `continue-on-error: true` AND `if:` guard. STRIDE T-33-CI-02 (warnings detection bypass) mitigated by explicit separate compile step.

## Self-Check

- [x] `.github/workflows/phase34-proof.yml` exists
- [x] Commit 73ab403 exists in git log
