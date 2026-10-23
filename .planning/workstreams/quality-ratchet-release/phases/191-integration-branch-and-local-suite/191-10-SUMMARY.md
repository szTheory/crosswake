---
phase: 191-integration-branch-and-local-suite
plan: 10
subsystem: planning-carry
tags: [carry, planning-records, integration-branch, privacy-scan]
requirements: [LAND-01]
status: complete
run: 2
commits: 5
plan_head_before: 70fada0dab57b033c8bf5f3b135849ace3cc6595
plan_head_after: 0dff1f22f35479e59f452511685d8b14f0c82cf8
actuals:
  tasks: 2
  commits: 5
key-files:
  created: [191-EVIDENCE/carry-manifest-191.tsv, 191-EVIDENCE/carry-commits-191.txt, 191-EVIDENCE/carry-verify-191.txt, 191-EVIDENCE/carry-scan-191.txt, 191-EVIDENCE/carry-expected-red-191.txt, 191-EVIDENCE/suite-CARRY-v23.0.txt, 191-EVIDENCE/suite-CARRY-v24.0.txt, 191-EVIDENCE/suite-CARRY-v25.0.txt, 191-EVIDENCE/suite-CARRY-v26.0.txt, 191-EVIDENCE/suite-CARRY-v27.0.txt]
  modified: [scripts/suite-gate-191.sh, scripts/scan-191.sh, scripts/selftest-scan-191.sh, 191-EVIDENCE/scan-triage-191.tsv, 191-EVIDENCE/heads-191.txt, 191-EVIDENCE/carry-precut-191.txt]
---

# Phase 191 Plan 10: Carry of the v23.0 to v27.0 planning records (run 2) Summary

## In plain words

The v23.0 to v27.0 planning records are now on the integration branch as five snapshot commits, and `land/v25-v27` was fast-forwarded onto them. Every check the plan asks for passed: the targeted test subset at each commit (with only the two expected red tests at v23.0 to v26.0, and no failures at v27.0), the exact-equality verify with the independent count floor, the privacy pre-check (0 blocking, 0 history-sensitive, 0 secret-scanner findings), and the four planning checks at the final head. Nothing was committed in the frozen recovery checkout and nothing was pushed.

## What was carried

Cut against the main commit d0dbdf7b from the recovery working tree: delta A 2527, M 13, D 141; 46 paths excluded (including the workstream-level config.json and state.json, A-2); 1767 same-path byte-identical main records left alone (358 of them hold a pattern, deferred hygiene). Manifest sha256 `77ed51616750ff779a9ee3baeaf772c76b43238b01e576717480f90dcaab0a8d`, 0 unmatched, 0 ignored-not-excluded, 0 symlinks.

| Commit | SHA | Files | Subset result |
|---|---|---|---|
| RESOLVER (parent) | 70fada0dab57b033c8bf5f3b135849ace3cc6595 | | |
| v23.0 (archive move and closeout) | 400273abadf236ecdb88fbd907e6cdfaba72de8f | 1648 (115 exact renames = 115 expected pure moves; 4 transformed moves) | 951 tests, 2 expected red (A-1) |
| v24.0 | 61c7c6a44a8c47afca75d04ee4084e3772a2ceb2 | 189 | 951 tests, same 2 expected red |
| v25.0 | bf0e12fa8ee2f8dcc9a94e6e0e334d9b1be267d4 | 258 | 951 tests, same 2 expected red |
| v26.0 | f58809359e6ed17e307ce9d5dae4c45fc8a052df | 177 | 951 tests, same 2 expected red |
| v27.0 | 0dff1f22f35479e59f452511685d8b14f0c82cf8 | 276 | 951 tests, 0 failures |

`land/v25-v27` equals `carry-trial-3` equals HEAD at `0dff1f22f35479e59f452511685d8b14f0c82cf8`. Redacted by the mechanical transforms: 245 files in the manifest (home path, temp path, account word and the braced dollar fields). The expected red at v23.0 to v26.0 (A-1) is `milestone archive presence matches active/shipped state` and its derived Phase135 assertion; both are green again at v27.0.

## Verify and floor

`carry-191.sh verify` passed (37 inventory rows covered). The independent floor from `carry-floor-191.sh` was floor_a 2527, floor_d 141, floor_rows 36, equal to the manifest A and D counts. Final head planning checks: Phase 167 JS test, adoption context scan, release workflow integrity script and the collection-assertion ledger check all exit 0.

## Privacy pre-check

`SCAN191_ADOPTER_SKIP=A-14`, no terms, range RESOLVER..CARRY: first pass gave 3394 blocking_final hits and 2 secret-scanner findings. All were checked and are benign (see Deviations 4 and 5); after triage rows the scan is blocking_final 0, history_sensitive 0, gitleaks_findings 0, result clean (triaged 3394).

## Deviations from Plan

1. [Run 1 carry] Fifth subset path `test/crosswake/release_candidate/evidence_live_test.exs` added to the subset (floor 5), as in run 1. Without it two Phase175LinkedAuthorizationTest tests fail on an undefined fixture helper (a test-selection effect).
2. [Rule 3 - gate] Committed `suite-gate-191.sh` now anchors the failure-header match to a two-space indent, so the nested ExUnit header printed inside the Phase135 derived assertion is not counted as an extra failure. `selftest-suite-191.sh` stayed 30 of 30 as expected (stored output unchanged); `selftest-carry-191.sh` stayed 25 of 25 with the new dollar row (not dead: the cut matched it, transformed went from 244 to 245).
3. [Evidence handling] Manifest-listed evidence files (heads-191.txt, scan-triage-191.tsv, carry-precut-191.txt) were not touched between the cut and the v27.0 apply; their carry/scan/check lines were appended after the final commit, so the carried copies are the cut-time versions and Plan 12's sync will pick up the appended ones. Stale run-1 post-cut evidence (carry manifest, expected-red, suite-CARRY-*) was moved out of the evidence folder before the cut so a failed record is not carried. The independent floor was measured with the evidence files written after the cut moved aside and put back (they would otherwise count as seven source-only paths).
4. [Rule 3 - benign scan hits] The scanner's home_path class is case-insensitive and read GitHub and Hex API URLs (`api.github.com/users/...`, `hex.pm/api/users/...`, `docs.github.com/en/rest/users/...`) in carried Phase 175 raw evidence as home paths: 3386 fingerprints, 3591 matches, all checked to carry one of those three URL prefixes. Also triaged with reasons: 6 email hits (fabricated `localhost@evil.com` and `127.0.0.1@evil.com` URL-userinfo fixtures in Phase 182 records), 1 pem_key (prose naming the marker class in 191-04-PLAN.md) and 1 udid (fabricated id in the scanner self-test). Each has a row in `scan-triage-191.tsv`.
5. [Rule 3 - scanner repair, before a fresh cut] Two secret-scanner findings: (a) a fabricated key fixture in `selftest-scan-191.sh`, fixed by splitting the literal; (b) a branch-name-to-object-id map in a Phase 175 evidence JSON (a generic-api-key false positive on the key name). The scanner had no way to triage a secret-layer finding, so `scan-191.sh` now reads triage rows of class `gitleaks` as exact fingerprint ignore entries (commit:file:rule:line, reason required) and always passes an explicit ignore file; `selftest-scan-191.sh` gained control S32 (a triage row suppresses only its own finding), now 32 of 32 as expected. Because both scripts are carried, this forced a fresh cut and branch (`carry-trial-3`). The gitleaks fingerprint is bound to the v23.0 commit SHA, so it stays valid only while that commit is unchanged.
6. Trial branches `carry-trial` (run 1, red) and `carry-trial-2` (green, superseded by deviation 5) are left in the integration clone for cleanup, not reused or removed.
7. Chain and trailer: A-14 applied (no terms, 11 labels, PRIVACY after G1); Co-Authored-By trailer as the plan specifies.

Commit in the recovery checkout: none (D-23). No push.

## Known Stubs

None.

## Self-Check: PASSED

All five carry SHAs are ancestors of `land/v25-v27`; each evidence file named above exists; recovery git state snapshot equals the before-snapshot.
