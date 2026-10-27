---
phase: 195-pipeline-repair-and-hygiene
verified: 2026-10-26T23:00:00Z
status: gaps_found
score: 7/8 must-haves verified
covered_files:
  - .github/workflows/weekly-canary.yml
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-06-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-06-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-07-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-07-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-08-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-08-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-09-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-09-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-10-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-10-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-11-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-11-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-12-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-12-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-13-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-13-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-14-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-14-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-15-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-15-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-16-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-16-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-17-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-17-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-18-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-18-SUMMARY.md
  - script/verify_published_cleanroom.sh
  - script/verify_repository.mjs
  - test/js/ci_secret_masking.test.mjs
covered_digest: "v3:sha256:788a73a48eee3ef3ab8e2a49cda35e4f35e701d17fc1188e522f20eee9bb36e0"
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "HYG-02: each remote delete behind its own allow"
    reason: "User gave one explicit batch approval for the last 17 tag/delete operations (plan 13 deviation); each op was bound to its ledger tip and read back; user ran the batch script themselves"
    accepted_by: "user (explicit batch decision, recorded in plan 13 ledger)"
    accepted_at: "2026-10-26"
re_verification:
  previous_status: gaps_found
  previous_score: 7/8
  gaps_closed:
    - "REL-03 round 2: GR-01 (tuple, escaped-JSON, CLI-flag, quoted-Bearer, next-line forms) and GR-02 (single-quoted add-mask accepted by the guard) are closed on main for the shapes they named"
  gaps_remaining:
    - "REL-03: KEY_LINE is quadratic (CR-01)"
    - "REL-03: PGP key block, key-name assignments and camel-case SecretAccessKey print unmasked (CR-02)"
  regressions: []
gaps:
  - requirement: REL-03
    truth: "CI never echoes secrets: the root-proof failure tail masks credential values"
    status: failed
    reason: "Re-probed on main 7621c0ce. CR-01: the KEY_LINE regex is quadratic (token: plus 40k spaces and x takes 0.9 s; space-tab pairs 3.6 s at 40k; time quadruples when input doubles), so a padded line hangs the failure path where the tail is the only diagnostic. CR-02: an ASCII-armored PGP private-key block, signingInMemoryKey=, deploy_key:, MIRROR_DEPLOY_KEY= and camel-case SecretAccessKey all print unmasked. signingInMemoryKey and MIRROR_DEPLOY_KEY are secrets this repository's workflows actually hold. Related review warnings WR-01 (Elixir inspect forms, e.g. a cookie map) also reproduce."
    artifacts:
      - path: "script/verify_repository.mjs"
        issue: "KEY_LINE (line 119) has two adjacent optional-whitespace quantifiers; PEM_KEY does not accept PRIVATE KEY BLOCK; CREDENTIAL_WORDS lacks bare key-name forms; secret-access-key rule needs a separator"
      - path: "test/js/ci_secret_masking.test.mjs"
        issue: "linear-time suite has no key, separator, long-whitespace-run, non-space input, so it cannot fail for CR-01; no seed per repository secret name"
    missing:
      - "Move trailing [ \\t]* inside the optional block-indicator group of KEY_LINE; add whitespace-run LINEAR_INPUTS rows (space, tab, space-tab) for KEY_LINE and the other separator rules"
      - "Accept an optional BLOCK in the PEM marker; make secret-access-key separators optional; add signing/deploy/auth key names and secretstring to the credential words"
      - "Add a seed row per secret name the workflows hold (signingInMemoryKey, signingInMemoryKeyPassword, MIRROR_DEPLOY_KEY) so the inventory and masker cannot drift"
deferred:
  - truth: "Derived-secret guard grammar (GR-06: local/declare/readonly, +=, read, printf -v, GITHUB_ENV writes)"
    addressed_in: "Phase 196"
    evidence: "Phase 196 ROADMAP carried line: 'GR-06 (derived-secret guard grammar ...) in test/js/ci_secret_masking.test.mjs; see 195-REVIEW-DISPOSITION.md'; zero census on the live tree"
human_verification: []
---

# Phase 195: Pipeline Repair and Hygiene Verification Report

**Phase Goal:** `main`, the release PR and the PR queue are green and trustworthy, CI runs only recurring lanes and never echoes secrets, the repository holds no scratch state, and one fail-closed clean-room command is proven against real published artifacts.
**Verified:** 2026-10-26
**Status:** gaps_found
**Re-verification:** Yes, after round-2 gap closure (plans 195-16 to 195-18, PR #257, merge commit 7621c0ce)

## What was checked and what I found

I imported the exported `maskSecretShapes` from `script/verify_repository.mjs` on the checkout (which matches main 7621c0ce for `script` and `test/js`) and fed it synthetic fake values built from fragments. The round-2 shapes (GR-01, GR-02) are closed and `node --test test/js/ci_secret_masking.test.mjs` passes (138 pass, 0 fail). But both critical findings in 195-REVIEW-GAP2.md reproduce on the merged code, so REL-03 ("CI never echoes secrets") is not met. Nothing was changed except this report. Next action: a third gap plan for REL-03 (CR-01, CR-02, then WR-01 to WR-03), then re-verify. Phase 196 should not start on the strength of REL-03 until that lands.

## REL-03 independent probe results

| Probe (fake values, built from fragments) | Result |
|-------|--------|
| ASCII-armored PGP private-key block (marker, blank line, body, END marker) | LEAK, body prints |
| `signingInMemoryKey=<fake>` | LEAK |
| `deploy_key: <fake>` | LEAK |
| `MIRROR_DEPLOY_KEY=<fake>` | LEAK |
| `{"SecretAccessKey":"<fake>"}` | LEAK |
| `%{"cookie" => ["sid=<fake>"]}` (Elixir inspect, WR-01) | LEAK |
| `password=<fake>` (control) | masked |
| `token:` + 20,000 spaces + `x` | 218 ms |
| `token:` + 40,000 spaces + `x` | 884 ms (4x for 2x input: quadratic) |
| `token:` + 40,000 tabs + `x` | 955 ms |
| `token:` + 40,000 space-tab pairs + `x` | 3,606 ms |

CR-01 and CR-02 are therefore real, not review speculation. Weighing them honestly: GitHub's own runner masking still covers values it knows as `secrets.*` when they appear verbatim, so the practical exposure is narrower than the masker's gaps suggest. But the requirement text and the plan's own claim are that the failure-tail masker covers credential shapes, and the shapes that fail are the forms of the secrets this repository's workflows hold (`ORG_GRADLE_PROJECT_signingInMemoryKey`, `MIRROR_DEPLOY_KEY`). CR-01 also turns the failure path into a hang on a padded line. I do not accept a pass here; two rounds of closing named shapes have each left more unprobed shapes, and the masker remains shape-based.

## Observable Truths

| # | Requirement | Truth | Status | Evidence |
|---|-------------|-------|--------|----------|
| 1 | REL-01 | Version-line-insensitive goldens; release PR passes with no hand edits | VERIFIED (regression check) | PR #236 open, reason recorded (release merge is Phase 199) |
| 2 | REL-02 | Parity test uses SHA plus version comment | VERIFIED (regression check) | unchanged by plans 16 to 18 |
| 3 | REL-03 | CI masks derived secrets; failure tail masks bearer, secret-access-key, cookie, short-value shapes | FAILED | probes above; CR-01 and CR-02 reproduce on 7621c0ce |
| 4 | REL-04 | Only recurring lanes; one weekly canary | VERIFIED (regression check) | Weekly Canary success on 0b28e6d; Release Please runs success on 7621c0ce, 5862a3d, ff63e5d |
| 5 | REL-05 | Grouped monthly actions PR; no open PR older than 14 days without a reason | VERIFIED (regression check) | Open PRs: #236 (reason recorded, created 2026-10-11), #252 and #253 (created today) |
| 6 | REL-06 | SEED-003 closed; fail-closed clean-room run against real 0.2.11 artifacts | VERIFIED (regression check) | evidence retained; `script/verify_published_cleanroom.sh` untouched by 16 to 18 |
| 7 | HYG-01 | Root holds only allowlisted files; no bundle | VERIFIED (regression check) | `git ls-tree origin/main` root shows allowlisted entries only |
| 8 | HYG-02 | Branches deleted or tagged; worktrees only main | VERIFIED (override) | override carried forward; `git worktree list` shows only the main checkout |

**Score:** 7/8 truths verified (0 present-but-behavior-unverified).

## Deviations in 195-18, weighed

- JWT left-boundary fix and the 250 ms floor: the floor still separates quadratic from linear at 200k characters (IN-03), but it did not catch CR-01 because no input exercises that rule. Not a gap by itself.
- Re-run of a red example-host job with no change: noted as a flake reconciliation, not evidence of a defect; main Release Please runs are green. Keep watching.
- Merge performed by the user: consistent with the AGENTS.md gate (merge to main needs the user's allow).

## Requirements Coverage

| Requirement | Status |
|-------------|--------|
| REL-01 | SATISFIED |
| REL-02 | SATISFIED |
| REL-03 | BLOCKED (CR-01, CR-02) |
| REL-04 | SATISFIED |
| REL-05 | SATISFIED |
| REL-06 | SATISFIED |
| HYG-01 | SATISFIED |
| HYG-02 | SATISFIED (override) |

All eight IDs are claimed by plans and mapped to Phase 195 in REQUIREMENTS.md. No orphans. REL-03 is currently ticked complete in REQUIREMENTS.md and the traceability table; it should be reopened until the gap closes.

## Anti-Patterns and Open Items

| Item | Severity | Note |
|------|----------|------|
| CR-01 quadratic KEY_LINE | Blocker | see gap |
| CR-02 unmasked repo-held secret forms | Blocker | see gap |
| WR-01 to WR-03 (Elixir inspect forms, name/value JSON, PEM body layouts) | Warning | reproduce in part (cookie map); fold into the next gap plan |
| WR-04 to WR-06, IN-01 to IN-04 | Warning/Info | triage in the next gap plan; GR-06 stays deferred to Phase 196 |
| Debt markers in the two masker files | None found | |
| `privacy-push-195.txt`, `privacy-push2-195.txt` untracked | Info | intentional evidence |

## Gaps Summary

One gap, REL-03, blocks the phase goal ("never echoes secrets"). The fix is small and well specified in 195-REVIEW-GAP2.md CR-01 and CR-02. Recommended: seed-first plan with a probe per repo secret name and a whitespace-run linear-time row, then re-verify.

---

_Verified: 2026-10-26_
_Verifier: Claude (gsd-verifier)_
