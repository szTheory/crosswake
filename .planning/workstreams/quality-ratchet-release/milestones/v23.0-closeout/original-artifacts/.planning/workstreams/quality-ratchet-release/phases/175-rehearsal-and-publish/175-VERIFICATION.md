---
phase: 175-rehearsal-and-publish
verified: "2026-10-11T19:58:54.127798+00:00"
status: gaps_found
score: 8/9 success criteria verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - "SC-1 / REL-10: the first publish omitted the runbook ancestor; timing cannot be repaired retroactively."
security_gate:
  status: accepted_historical_exception
  blocking_threats: 0
  forward_release_hold: satisfied_per_exact_operation
vacuity_taxonomy:
  - check_id: "Crosswake.Proof.Phase174MatrixInstallerContractTest # \"installer success cannot precede a swallowed installer failure\""
    shape: "matches none of A-F, because exact source scalars and command ordering are validated"
    non_vacuity_evidence: "Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes."
  - check_id: "Crosswake.Proof.Phase174MatrixInstallerContractTest # \"omitting the matrix installer fails independently of the legacy installer\""
    shape: "matches none of A-F, because exact source scalars and command ordering are validated"
    non_vacuity_evidence: "Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes."
  - check_id: "Crosswake.Proof.Phase174MatrixInstallerContractTest # \"the legacy router cannot substitute for the generated matrix router\""
    shape: "matches none of A-F, because exact source scalars and command ordering are validated"
    non_vacuity_evidence: "Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes."
  - check_id: "Crosswake.Proof.Phase174MatrixInstallerContractTest # \"the shared matrix runs the real installer and recompiles before doctor\""
    shape: "matches none of A-F, because exact source scalars and command ordering are validated"
    non_vacuity_evidence: "Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes."
  - check_id: "candidate.ci"
    shape: "A"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.cleanroom"
    shape: "A"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.config"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.coordinates"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.credentials"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.external-state"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.identity"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate.workflows"
    shape: "A"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "candidate_readiness"
    shape: "A"
    non_vacuity_evidence: "All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry."
  - check_id: "hex.rehearsal"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "ios.rehearsal"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "leg_run"
    shape: "matches none of A-F, because exact typed source facts and bound operation identity are validated"
    non_vacuity_evidence: "All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry."
  - check_id: "maven.rehearsal"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "mirror.authority"
    shape: "matches none of A-F, because exact scalar identity and typed proof bytes are compared"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "package.family"
    shape: "A"
    non_vacuity_evidence: "Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite."
  - check_id: "protected_merge"
    shape: "matches none of A-F, because exact typed source facts and bound operation identity are validated"
    non_vacuity_evidence: "All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry."
  - check_id: "registry_response"
    shape: "matches none of A-F, because exact typed source facts and bound operation identity are validated"
    non_vacuity_evidence: "All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry."
  - check_id: "release.rel17.approved_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.companion_chimeway_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.companion_rindle_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.companion_rulestead_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.companion_sigra_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.companion_threadline_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.core_hex_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.core_ios_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.core_maven_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.hex_final_boundary"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.ios_final_boundary"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.legacy_ios_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.maven_final_boundary"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.recovery_hex_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.recovery_ios_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.recovery_maven_job_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.release_creation_guard"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "release.rel17.roster_exact"
    shape: "D"
    non_vacuity_evidence: "All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits."
  - check_id: "response_row"
    shape: "matches none of A-F, because exact typed source facts and bound operation identity are validated"
    non_vacuity_evidence: "All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry."
  - check_id: "runbook_ancestry"
    shape: "matches none of A-F, because exact typed source facts and bound operation identity are validated"
    non_vacuity_evidence: "All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry."
---

# Phase 175 — Rehearsal and Publish Verification

## Current Phase 175 Verdict

phase_status: OPEN_HISTORICAL_BREACH
score_passed: 8
score_total: 9
SC-1: BREACHED
REL-10: BREACHED

## Success Criteria

| Criterion | Status | What passed or remains breached |
|---|---|---|
| SC-1: runbook before first publish | BREACHED | PR #147 excluded the runbook ancestor. Later releases cannot change that timing. |
| SC-2: three safe rehearsals | PASS | Core 0.2.11 Hex 38154895539, iOS 38154903768 and Maven 38154909396 passed; Maven validated and dropped. No publication from these rehearsals. See `evidence/175-plan148-core0211-rehearsals-verified.json`. |
| SC-3: response table before publication | PASS | Existing `175-PUBLISH-LEG-2.md` preserves the pre-publication response table and chronology. |
| SC-4: first companion published | PASS | Rulestead 0.1.1 was directly confirmed on Hex; ordinary run 35461665164 and clean-room check passed. See `175-07-SUMMARY.md`. This does not cure SC-1. |
| SC-5: fresh core on three registries | PASS | PR #232/core 0.2.11, ordinary run 38155320492: all three publishers passed and exact Hex/iOS/Maven responses returned HTTP 200. Maven coordinate is `io.github.sztheory:crosswake-shell-core-android:0.2.11`. See `evidence/175-plan148-core0211-registry-observation.json`. |
| SC-6: same-run exact-public and six child COMPLETE | PASS | Run 38155320492: all six children succeeded; exact-public artifact 11709291645 and validated rollup 11709855205 report COMPLETE. Six public package rows, five host profiles and two dependency-install passes each passed. See `evidence/175-plan148-core0211-public-proof-verification.json`. |
| SC-7: separate second companion | PASS | Fresh successor PR #235/Chimeway 0.1.2, ordinary run 38167555514: guarded Hex publisher and public clean-room doctor passed; direct Hex returned HTTP 200 and parsed 0.1.2. PR #115/0.1.1 stopped before Hex and remains absent; its consumed gate was never reused. See `evidence/175-plan148-companion-next-publication-verification.json` and `...-registry-observation.json`. |
| SC-8: documentation truth | PASS | Existing DOC-04/DOC-06 release-literal and subtree-split corrections remain. PR #233 corrected the main iOS guide/source: generated-app Xcode build is required for six child COMPLETE. Published older HexDocs are not claimed overwritten. |
| SC-9: shared fail-closed release gate | PASS | 98 workflow controls and 94 tracked guard/receipt/path tests passed; current companion source passed all 49 CI jobs plus fresh safe rehearsal and canonical hosted receipt. Separate core/companion pre-merge, final and actual post-merge envelopes each passed all six conditions. Protected merge audits prove exact parents/tree/trailer/runbook; actual publishers re-fetch at the side-effect boundary. Recovery paths are covered by source and negative controls, not by a recovery publication. |

## Requirements Coverage

| Requirement | Status | Result |
|---|---|---|
| REL-10 | BREACHED | First-publish runbook timing is historically unsatisfied. |
| REL-11 | SATISFIED | Three safe rehearsals, including isolated Maven VALIDATED-to-DROP. |
| REL-12 | SATISFIED | Rulestead 0.1.1 publication and public clean-room check; historical breach separate. |
| REL-13 | SATISFIED | Core 0.2.11 three publishers and direct registry checks in ordinary run 38155320492. |
| REL-14 | SATISFIED | Exact-public ran and passed with its artifact in that same ordinary run. |
| REL-15 | SATISFIED | Core six child COMPLETE plus separate Chimeway 0.1.2 ordinary publication and direct Hex check. |
| REL-16 | SATISFIED | Existing pre-publication partial-failure response table retained. |
| REL-17 | SATISFIED FORWARD CONTROL | Shared exact-operation gate, live re-fetches, six-condition envelopes, actual protected merges and field/path mutations passed. No blanket authorization or retroactive compliance. |
| DOC-04 | SATISFIED | Fixed-version publication claim removed and recurring literal guard retained. |
| DOC-06 | SATISFIED | Durable mirror-split guidance uses git subtree split. |

## Automated Checks and Limits

- Installer repair PR #237 passed 2,069 local tracked tests and all 49 CI jobs. Its actual candidate host log proves ten successful Crosswake installer-before-doctor pairs. Protected squash d0dbdf7bf196cea167ced3c50cf620bf3cb2452b retained the exact approved tree; proposal-only run 38170038757 passed with all eight publishers skipped. This closes the local-only Phase 174 installer source gap without another release. See `evidence/175-plan148-matrix-installer-hosted-installer-verification.json`.

- Repair #233 revised source passed 2,065 local tracked tests, zero failures, 78 exclusions; 100 focused tests, 230 exact classified sites and all 49 hosted checks passed.
- The independent forward-control suite passed 94 tests and 98 workflow checks. Archive-only test failure due to missing Git HEAD is preserved; the tracked run is authoritative.
- Android public consumer proof passed the full generated build and debug lint. No release-lint, Android device or new parity claim is made.
- iOS public consumer proof built a generated app with Xcode. No physical-iPhone or adopter-readiness claim is made.
- The six accepted historical high findings and twelve lower findings remain distinct in SECURITY; zero current blocking high findings does not mean zero total open findings.

## Preserved History and Route Replacement

The approved installer source gap from Phase 174Plan07 was repaired in PR 237 with fresh hosted execution. The prior verification and validation snapshots are archived byte-for-byte with hashes in `evidence/175-plan148-reconciliation-input-archives.json`. All 0.2.3 through 0.2.10 PARTIAL/stopped results and consumed bindings remain unchanged. Chimeway #115 tag creation is not Hex publication; version 0.1.1 remains stopped and absent. Repair #233 created fresh #235/0.1.2 within the original second-package goal. Plans 44–48 supplied acceptance contracts; unused standalone legacy execution routes are superseded, not claimed executed. Plan 148 groups delivery and this reconciliation. Phase 174 remains the last completed phase; Phase 175 remains active solely with the historical breach.

## Vacuity Taxonomy

Shapes reference `.planning/research/v23/PITFALLS.md`; this table covers the 13 actual canonical receipt IDs, six EvidenceGate condition IDs, 18 REL-17 scanner IDs and four installer-contract test names. It does not claim an exhaustive new audit of all 148 historical plans.

| Check ID | Shape | Non-vacuity check |
|---|---|---|
| `Crosswake.Proof.Phase174MatrixInstallerContractTest # "installer success cannot precede a swallowed installer failure"` | matches none of A-F, because exact source scalars and command ordering are validated | Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes. |
| `Crosswake.Proof.Phase174MatrixInstallerContractTest # "omitting the matrix installer fails independently of the legacy installer"` | matches none of A-F, because exact source scalars and command ordering are validated | Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes. |
| `Crosswake.Proof.Phase174MatrixInstallerContractTest # "the legacy router cannot substitute for the generated matrix router"` | matches none of A-F, because exact source scalars and command ordering are validated | Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes. |
| `Crosswake.Proof.Phase174MatrixInstallerContractTest # "the shared matrix runs the real installer and recompiles before doctor"` | matches none of A-F, because exact source scalars and command ordering are validated | Original approved source failed the positive installer check; all four repaired focused cases passed. The missing-call, wrong-router and swallowed-failure mutations reject. Actual exact-head CI confirms ten successful installer-before-doctor pairs across five profiles and two passes. |
| `candidate.ci` | A | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.cleanroom` | A | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.config` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.coordinates` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.credentials` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.external-state` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.identity` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate.workflows` | A | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `candidate_readiness` | A | All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry. |
| `hex.rehearsal` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `ios.rehearsal` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `leg_run` | matches none of A-F, because exact typed source facts and bound operation identity are validated | All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry. |
| `maven.rehearsal` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `mirror.authority` | matches none of A-F, because exact scalar identity and typed proof bytes are compared | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `package.family` | A | Actual core receipt has 13 PASS checks; CI/Hex each produced six independently matching package rows, five host profiles and two installs; receipt proof hashes match. Missing-source, mismatch and exact-roster regressions passed in the 94-test tracked guard suite. |
| `protected_merge` | matches none of A-F, because exact typed source facts and bound operation identity are validated | All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry. |
| `registry_response` | matches none of A-F, because exact typed source facts and bound operation identity are validated | All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry. |
| `release.rel17.approved_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.companion_chimeway_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.companion_rindle_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.companion_rulestead_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.companion_sigra_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.companion_threadline_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.core_hex_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.core_ios_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.core_maven_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.hex_final_boundary` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.ios_final_boundary` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.legacy_ios_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.maven_final_boundary` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.recovery_hex_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.recovery_ios_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.recovery_maven_job_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.release_creation_guard` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `release.rel17.roster_exact` | D | All 98 integrity controls passed on approved source. Per-path guard omission/order and identity mutations passed in tracked tests. Companion checkout-depth mutations remove depth or set 1/2 across five jobs (15 rejecting cases); original publisher checkout fails actual ancestry at one commit and full history passes at 3,825 commits. |
| `response_row` | matches none of A-F, because exact typed source facts and bound operation identity are validated | All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry. |
| `runbook_ancestry` | matches none of A-F, because exact typed source facts and bound operation identity are validated | All six source conditions passed in separately retained pre-merge, final and actual post-merge core and companion envelopes. Per-field and cross-path negative cases passed in the 94-test tracked suite; actual merges have exact two-parent identity, tree and runbook ancestry. |
