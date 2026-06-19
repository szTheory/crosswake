---
phase: 120-collateral-artifact-ci-and-troubleshooting
verified: 2026-06-19T21:06:26Z
status: passed
score: 9/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps: []
deferred: []
residual_risks:
  - "ROADMAP.md/STATE.md still show stale Phase 120 progress in the working tree, but implementation commits and phase artifacts exist; this is planning-state drift, not a phase-goal failure."
  - "The native collateral workflow is advisory and manual-dispatch; verifier proved captured/unavailable semantics with dry-run evidence, not live simulator/emulator screenshots in this environment."
  - "The worktree contains unrelated dirty Phase 119/planning changes; verification staged only this artifact."
---

# Phase 120: Collateral, Artifact CI, And Troubleshooting Verification Report

**Phase Goal:** Users can see durable route-ownership evidence and recover from common route/diagnostic failures while every artifact stays honestly labeled.  
**Verified:** 2026-06-19T21:06:26Z  
**Status:** passed  
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Required browser route-tour proof runs in CI and is part of the merge-blocking E2E gate. | VERIFIED | `.github/workflows/offline-sync-e2e-gate.yml` defines `route-tour-proof`, uploads `crosswake-route-tour-evidence`, and includes `route-tour-proof` in `merge-blocking-offline-sync-e2e.needs`. |
| 2 | Route-tour proof covers Phoenix-owned LiveView, bounded bridge, offline-island replay, and native-screen/route-unavailable posture with semantic assertions. | VERIFIED | `examples/phoenix_host/e2e/route_tour.spec.ts` asserts `library`, `bridge-proof`, `offline-study`, and `selective-native-claim-capture`; verifier ran `npx playwright test e2e/route_tour.spec.ts` - PASS, 1 test. |
| 3 | Screenshots are collateral only, captured after assertions. | VERIFIED | `route_tour.spec.ts` calls `captureRouteScreenshot` only after each `prove*Route` function; summary/manifest wording says screenshots are collateral. |
| 4 | Evidence bundles include a run-level manifest with required route metadata. | VERIFIED | `examples/phoenix_host/e2e/support/evidence_manifest.ts` writes `evidence-manifest.json` with version, commit SHA, route id, runtime owner, platform, command, proof/support labels, source job, timestamp, artifacts, retention, and limitations. |
| 5 | Missing required browser artifacts fail packaging/validation. | VERIFIED | `assertRequiredArtifacts` throws on missing merge-blocking artifacts; `test/crosswake/guides/evidence_manifest_test.exs` has synthetic missing-artifact failures; CI asserts manifest and screenshots before upload. |
| 6 | Rich evidence is bounded to CI artifacts while committed collateral stays small. | VERIFIED | Workflow uploads route-tour evidence with `retention-days: 14`; committed evidence is limited to example manifests under `examples/phoenix_host/evidence/` and `examples/native_evidence/`. |
| 7 | Native simulator/emulator collateral is advisory and records captured or unavailable outcomes honestly. | VERIFIED | `script/capture-native-collateral.mjs` writes platform entries with `proof_class: advisory evidence`, coordinate mode, command, timestamp, commit SHA, limitations, and `unavailable_reason`; verifier dry-run produced iOS and Android unavailable entries. |
| 8 | Native collateral does not imply physical-device, camera/media, provider-authority, app-store, or merge-blocking support. | VERIFIED | `.github/workflows/native-collateral-advisory.yml`, capture helper, example manifest, and `native_evidence_drift_test.exs` all carry non-claim language and synthetic overclaim guards. |
| 9 | Troubleshooting docs map common route/diagnostic failures to route-owner recovery actions and are exposed through README/ExDoc. | VERIFIED | `guides/troubleshooting.md` covers doctor findings, denials, route-unavailable states, offline rejected/conflict outcomes, native evidence labels, commands, owner fixes, and limitations; README and `mix.exs` link the guide; verifier-run ExUnit passed. |

**Score:** 9/9 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/phoenix_host/e2e/route_tour.spec.ts` | Browser route-owner tour | VERIFIED | 147 lines; semantic assertions precede screenshot capture; targeted Playwright run passed. |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | Shared offline proof helpers | VERIFIED | Reads app-created IndexedDB mutations, asserts UUID shape, polls `/_e2e/sync-state`, and checks outbox deletion without minting state. |
| `examples/phoenix_host/e2e/support/evidence_manifest.ts` | Route-tour manifest writer | VERIFIED | Writes one run-level manifest and fails on missing required browser artifacts. |
| `examples/phoenix_host/evidence/evidence-manifest.example.json` | Browser evidence example manifest | VERIFIED | Contains four required route entries and canonical labels. |
| `test/crosswake/guides/evidence_manifest_test.exs` | Manifest contract validator | VERIFIED | 340 lines; validates required fields, labels, missing artifacts, unavailable reasons, and generated manifest path. |
| `.github/workflows/offline-sync-e2e-gate.yml` | Required route-tour CI and artifact upload | VERIFIED | `route-tour-proof` job is wired into merge-blocking aggregator and uploads bounded artifacts with `if-no-files-found: error`. |
| `.github/workflows/native-collateral-advisory.yml` | Non-blocking native collateral workflow | VERIFIED | Manual `workflow_dispatch`; advisory job names; 14-day artifact retention; not referenced by required browser aggregator. |
| `script/capture-native-collateral.mjs` | Native captured/unavailable manifest helper | VERIFIED | Dry-run verifier output contained both iOS and Android unavailable entries with concrete reasons. |
| `examples/native_evidence/evidence-manifest.example.json` | Native advisory manifest example | VERIFIED | Contains captured iOS simulator and unavailable Android emulator examples with advisory labels and limitations. |
| `guides/troubleshooting.md` | Route-owner troubleshooting guide | VERIFIED | 411 lines; symptom index plus owner sections and required findings/outcomes. |
| `test/crosswake/guides/troubleshooting_test.exs` | Troubleshooting docs scanner | VERIFIED | Synthetic regressions cover missing owner, command, label, limitation, route-unavailable, offline outcomes, and native overclaims. |
| `README.md`, `mix.exs` | Public guide-map exposure | VERIFIED | README links troubleshooting and evidence path; ExDoc extras/groups include troubleshooting. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `route_tour.spec.ts` | Phoenix host routes | Browser navigation and router-source assertions | VERIFIED | Checks `/library`, `/bridge-proof`, `/offline`, and native claim capture fallback plus route ids and runtime owner strings. |
| `route_tour.spec.ts` | App-owned offline replay | IndexedDB, online event, `/study/sync`, Ecto inspection route | VERIFIED | Reads app-created mutation, waits for `/study/sync`, polls synced review, verifies outbox empty and duplicate idempotency. |
| `offline-sync-e2e-gate.yml` | `route_tour.spec.ts` | `npx playwright test e2e/route_tour.spec.ts` | VERIFIED | CI route-tour job runs the spec before manifest assertion/upload. |
| `offline-sync-e2e-gate.yml` | `evidence_manifest.ts` | Generated `evidence-manifest.json` validation | VERIFIED | CI validates generated manifest with `CROSSWAKE_EVIDENCE_MANIFEST_PATH`. |
| `native-collateral-advisory.yml` | `capture-native-collateral.mjs` | Workflow invokes helper for iOS and Android | VERIFIED | Workflow calls helper per platform and uploads advisory bundles. |
| `capture-native-collateral.mjs` | Native verification scripts | Existing iOS/Android verify script commands in manifest | VERIFIED | Commands reference `script/verify_generated_ios_shell.sh` and `script/verify_generated_android_shell.sh` with checked-in host roots. |
| `guides/troubleshooting.md` | Doctor/support truth | Canonical codes and links | VERIFIED | Docs scanner checks required findings from doctor truth and support-label vocabulary. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `route_tour.spec.ts` | `mutations[0].client_mutation_id` | Browser IndexedDB outbox created by `/offline` UI while offline | Yes | FLOWING - honesty guard and Playwright assertions reject test-minted offline state. |
| `evidence_manifest.ts` | `routes`, `crosswake_version`, `commit_sha` | Route-tour entries, `CROSSWAKE_VERSION`/`mix.exs`, `GITHUB_SHA`/`git rev-parse` | Yes | FLOWING - manifest is written after required screenshot files exist. |
| `capture-native-collateral.mjs` | native manifest route entries | Platform probes and existing native verification scripts, or explicit dry-run/tooling unavailable reasons | Yes | FLOWING - dry-run verifier output showed concrete unavailable reasons for both platforms. |
| `guides/troubleshooting.md` | required findings/outcomes | Doctor test vocabulary, support matrix labels, route-owner docs | Yes | FLOWING - docs scanner validates required concepts without pinning prose. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Route-tour semantic proof runs | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` | 1 passed | PASS |
| Manifest/native/troubleshooting docs contracts pass | `mix test test/crosswake/guides/evidence_manifest_test.exs test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/guides/troubleshooting_test.exs test/crosswake/doctor/doctor_test.exs` | 56 tests, 0 failures | PASS |
| E2E honesty guard scans route-tour/offline files | `node script/check-e2e-honesty.mjs` | PASS | PASS |
| Native collateral unavailable semantics are deterministic | `node script/capture-native-collateral.mjs --dry-run --output-dir /tmp/crosswake-native-collateral-verify` | Manifest written with iOS and Android unavailable reasons | PASS |
| Workflow YAML parses | `/usr/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/offline-sync-e2e-gate.yml"); YAML.load_file(".github/workflows/native-collateral-advisory.yml"); puts "workflow yaml ok"'` | PASS | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| E2E honesty scanner | `node script/check-e2e-honesty.mjs` | Passed | PASS |
| Native collateral dry run | `node script/capture-native-collateral.mjs --dry-run --output-dir /tmp/crosswake-native-collateral-verify` | Passed; manifest created | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| COLL-01 | `120-01-PLAN.md` | Deterministic browser route-tour proof with semantic assertions and evidence capture | SATISFIED | Playwright route-tour passed; CI route-tour job wired into merge-blocking aggregator. |
| COLL-02 | `120-02-PLAN.md` | Explicit bounded evidence bundle manifest and artifact packaging | SATISFIED | Manifest writer, example manifest, ExUnit validator, required artifact assertions, and CI artifact upload with retention. |
| NATIVE-COLL-01 | `120-03-PLAN.md` | Advisory iOS/Android collateral captured where available and unavailable where not | SATISFIED | Capture helper, advisory workflow, native example manifest, drift guard, dry-run unavailable evidence. |
| TROUBLE-01 | `120-04-PLAN.md` | Troubleshooting/rough-edge docs map findings and outcomes to route-owner actions | SATISFIED | Troubleshooting guide, README/ExDoc exposure, docs scanner, doctor test coverage. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `script/capture-native-collateral.mjs` | 31 | `console.log` | INFO | CLI status output only; not a stub or handler placeholder. |
| `test/crosswake/guides/evidence_manifest_test.exs` | 326 | `placeholder artifact` | INFO | Test fixture content for synthetic artifact existence; not user-facing output. |

### Human Verification Required

None. Visual/native simulator collateral is explicitly advisory, and the implementation records unavailable outcomes rather than requiring human UAT to pass the phase.

### Gaps Summary

No blocking gaps found. The phase goal is achieved in the codebase: browser route ownership is semantically proven and packaged, native collateral is advisory/unavailable-aware, and route-owner troubleshooting is documented and mechanically guarded.

### Residual Risks

- ROADMAP/STATE progress text in the working tree is stale for Phase 120; this does not contradict implementation evidence, but should be reconciled by the orchestrator or state-management workflow.
- The verifier did not run a real iOS simulator or Android emulator capture. This is acceptable for the phase contract because native collateral is advisory and unavailable outcomes are explicit, but live native artifact quality remains environment-dependent.
- The worktree had unrelated dirty Phase 119/planning files before verification. This report and commit intentionally stage only `120-VERIFICATION.md`.

---

_Verified: 2026-06-19T21:06:26Z_  
_Verifier: the agent (gsd-verifier)_
