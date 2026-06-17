---
phase: 110-native-publish-lockstep-infrastructure
plan: "02"
subsystem: publish-credentials
tags: [setup, runbook, gpg, sonatype, maven-central, ios-mirror, secrets]
dependency_graph:
  requires: []
  provides: [SETUP.md, publish-credential-runbook]
  affects: [110-03-preflight, Wave 2 preflight job]
tech_stack:
  added: []
  patterns:
    - "12-factor credential separation (human provisions, CI verifies)"
    - "GPG primary-key-only (no signing subkey) for Maven Central compatibility"
    - "Fine-grained PAT with least-privilege scope on single repo"
    - "GitHub Rulesets API for tag immutability (not legacy branch-protection)"
key_files:
  created:
    - SETUP.md
  modified: []
decisions:
  - "GPG --quick-generate-key with no subkey is mandated to avoid Maven Central 'Invalid signature for file' footgun (D-06)"
  - "iOS mirror repo created empty — CI seeds on first Phase 111 release (D-09)"
  - "Tag ruleset is best-effort defense-in-depth; no-force CI push is the load-bearing guard (D-10)"
  - "Namespace status and PAT scope are un-checkable by the preflight; documented as limitations"
metrics:
  duration: "2 minutes"
  completed_date: "2026-06-14T18:57:40Z"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
---

# Phase 110 Plan 02: SETUP.md Provisioning Runbook Summary

**One-liner:** Footgun-aware, 8-section one-time credential runbook covering GPG primary-key-only generation, Sonatype user-token provisioning, empty iOS mirror repo creation, least-privilege MIRROR_PUSH_TOKEN PAT, and tag ruleset — with documented preflight blind spots.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write SETUP.md provisioning runbook covering all 8 ordered items | 6da5b04 | SETUP.md (created, 375 lines) |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. SETUP.md is a complete runbook; no data wiring required (documentation-only plan).

## Threat Flags

No new network endpoints, auth paths, file-access patterns, or schema changes introduced. SETUP.md itself is documentation only. Threat mitigations T-110-05 through T-110-08 are addressed:

- **T-110-05** (Information Disclosure): Runbook uses placeholders only; `gh secret set` with hidden prompts; no literal secret values.
- **T-110-06** (Spoofing): Item 4 mandates both `keys.openpgp.org` (VKS + email confirm) and `keyserver.ubuntu.com` (HKP) upload with clean-environment recv-keys verification.
- **T-110-07** (EoP): Item 6 mandates fine-grained PAT with `Contents: write` on mirror repo ONLY, with documented PAT-scope limitation.
- **T-110-08** (Tampering): Item 7 documents `non_fast_forward` + `deletion` ruleset as best-effort; load-bearing guard is the no-force CI push in plan 110-03.

## Self-Check: PASSED

- `SETUP.md` exists: FOUND
- Task 1 commit `6da5b04` exists in log
- Verify chain (plan automated check) exits 0: CONFIRMED
- All 8 secret names present verbatim: CONFIRMED
- GPG footgun-safe command present: CONFIRMED
- Line count 375 >= 80: CONFIRMED
- No secret values committed: CONFIRMED
