---
phase: 195-pipeline-repair-and-hygiene
verified: 2026-10-26T20:00:00Z
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
  - script/verify_published_cleanroom.sh
  - script/verify_repository.mjs
  - test/js/ci_secret_masking.test.mjs
covered_digest: "v3:sha256:f8abe105a7f504854ac52ba70435f1d99394b60c3ef47c16b28b59cd703b04e8"
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
    - "REL-03: root-proof failure tail masks bearer, secret-access-key, cookie and short-value shapes (quoted, multi-word, mid-line)"
  gaps_remaining:
    - "REL-03: credential keys in Elixir tuple, escaped-JSON and CLI-flag forms still leak; single-quoted add-mask passes the guard (195-REVIEW-GAP.md GR-01, GR-02)"
  regressions: []
gaps:
  - requirement: REL-03
    truth: "CI never echoes secrets: the root-proof failure tail masks credential values"
    status: failed
    reason: "Post-verification gap review (195-REVIEW-GAP.md) reproduced leaks the verifier did not probe: Elixir tuple keys, escaped-JSON keys, CLI --password flags, quoted Bearer, next-line values (GR-01); isMaskLine accepts a single-quoted add-mask that masks only the literal name (GR-02). Re-confirmed by the orchestrator on main 5862a3d."
    missing:
      - "Mask tuple, escaped-JSON, CLI-flag, quoted-Bearer and next-line credential forms (GR-01), seeds first"
      - "Reject single-quoted ::add-mask:: in isMaskLine (GR-02)"
deferred: []
human_verification: []
---

# Phase 195: Pipeline Repair and Hygiene Verification Report

**Phase Goal:** `main`, the release PR and the PR queue are green and trustworthy, CI runs only recurring lanes and never echoes secrets, the repository holds no scratch state, and one fail-closed clean-room command is proven against real published artifacts.
**Verified:** 2026-10-26
**Status:** passed
**Re-verification:** Yes, after gap closure (plans 195-14 and 195-15)

**Previous verification:** gaps_found, 7/8. REL-03 failed because `maskSecretShapes` leaked quoted secret values, mid-line Cookie headers and multi-word quoted passwords (review findings CR-01, CR-02).

## What was checked and what I found

I re-ran the masker myself against `origin/main` (merge commit 5862a3dc, PR #256; `script/verify_repository.mjs` and `test/js` are byte-identical on the checkout), with synthetic values built from fragments in a scratch folder. The four original leak cases now mask, 13 further shapes mask, and three prose lines stay untouched. `node --test test/js/*.mjs` exits 0 (186 pass, 0 fail). The seven other requirements show no regression against live GitHub state. Nothing was changed except this report. Next action: none for this phase; Phase 196 may start.

## REL-03 re-verified independently

Probe: `maskSecretShapes` imported from the repo, each input contains a synthetic value (built from two fragments), the check is whether that value survives in the output.

| Shape | Result |
|-------|--------|
| aws_quoted (`AWS_SECRET_ACCESS_KEY="..."`) | masked |
| curl_cookie (mid-line `Cookie:` inside a quoted curl header) | masked |
| password_multiword (`password = "my ... pass"`) | masked in full |
| prose_token_expired (`token expired for user`) | unchanged |
| single-quoted `api_key='...'` | masked |
| JSON `"client_secret": "..."` | masked |
| mid-line `Authorization: Bearer ...` | masked |
| `Set-Cookie: session=...; Path=/` | masked |
| URL userinfo `https://user:...@host` | masked |
| JWT (three dotted segments) | masked |
| `export SECRET_KEY=...` | masked |
| escaped quote inside a quoted password | masked |
| YAML `token: ...` | masked |
| `Authorization: Basic ...` | masked |
| `X-Api-Key: ...` | masked |
| prose "password reset requested; the token is invalid" | unchanged |
| prose "secret santa list ready" | unchanged |
| pathological input (100k-token Cookie value, 300k backslashes) | 1 ms total (linear) |

Both halves of REL-03 hold: derived secrets are passed to `::add-mask::` (audit file, `maven-publish-fire-drill.yml`), and the failure-tail masker covers the quoted, multi-word and mid-line forms. The prior test-suite weakness (seeds only the shapes the regexes were written for) is addressed: 24 gap seeds, prose lines, linear-time inputs and a stricter `isMaskLine`. PR #256 head 7db34f2 had 49 contexts with none failed or cancelled.

## Observable Truths

| # | Requirement | Truth | Status | Evidence |
|---|-------------|-------|--------|----------|
| 1 | REL-01 | Version-line-insensitive goldens; release PR passes with no hand edits | VERIFIED (regression check) | #236 OPEN, head b1e8d95 unchanged, zero failing contexts; state is BEHIND main, which is expected (merge is Phase 199) |
| 2 | REL-02 | Parity test uses SHA plus version comment; #210/#211 green or closed | VERIFIED (prior live read) | unchanged, not re-opened |
| 3 | REL-03 | CI masks derived secrets; failure tail masks bearer, secret-access-key, cookie, short-value shapes | VERIFIED | Independent reproduction above; JS suite rc 0, 186 pass, 0 fail |
| 4 | REL-04 | Only recurring lanes; one weekly canary | VERIFIED (regression check) | Weekly Canary green on 0b28e6d; no new schedules in PR #256 |
| 5 | REL-05 | Grouped monthly actions PR; no open PR older than 14 days without a reason | VERIFIED (regression check) | Open PRs: #236 (release PR, reason recorded), #252 and #253 (created today) |
| 6 | REL-06 | SEED-003 closed; fail-closed clean-room run against real 0.2.11 artifacts | VERIFIED (regression check) | Evidence files present; `script/verify_published_cleanroom.sh` unchanged by 14/15 |
| 7 | HYG-01 | Root holds only allowlisted files; no bundle | VERIFIED (regression check) | `git ls-tree origin/main` root shows the 15-entry allowlisted set, no scratch files or bundle |
| 8 | HYG-02 | Merged/superseded branches deleted, unmerged tagged; worktrees only main | VERIFIED (override) | Override carried forward; the fix branch was auto-deleted on merge and removed locally, under the approved allow |

**Score:** 8/8 truths verified (0 present-but-behavior-unverified).

## Key Evidence Run by the Verifier

| Check | Result |
|-------|--------|
| `maskSecretShapes` probe, 17 shapes plus linear-time input | all secrets masked, prose unchanged, 1 ms |
| `node --test test/js/*.mjs` | rc 0, 186 pass, 0 fail |
| `git diff origin/main HEAD -- script test/js` | empty (checkout runs the merged code) |
| PR #256 | MERGED, merge commit 5862a3dc, 49 checks, none failed |
| Main runs on 5862a3dc | only Release Please (push trigger), still in progress at check time; the prior main commit ff63e5d and 0b28e6d runs are success. Main's PR-lane CI ran on the PR head |
| Open PRs | #236, #252, #253 |
| Debt markers in the two masker files | none |

## Requirements Coverage

| Requirement | Status |
|-------------|--------|
| REL-01 | SATISFIED |
| REL-02 | SATISFIED |
| REL-03 | SATISFIED (gap closed) |
| REL-04 | SATISFIED |
| REL-05 | SATISFIED |
| REL-06 | SATISFIED |
| HYG-01 | SATISFIED |
| HYG-02 | SATISFIED (override) |

All eight IDs are claimed by plans and mapped to Phase 195. No orphaned IDs.

## Anti-Patterns and Open Items

| Item | Severity | Note |
|------|----------|------|
| WR-04, WR-05, WR-06, IN-03 | Warning | Deferred to Phase 197 and recorded in the disposition and roadmap; clean-room fail-closed still holds on traced paths |
| IN-01, IN-02 | Info | Marked wontfix in the disposition |
| #236 is BEHIND main | Info | Expected; release merge is Phase 199 |
| #253 open, protection refused merge in the prior pass | Warning | Not a REL requirement; re-offer at the next queue pass |
| `crosswake_inspect_test.exs:136` one-off CI failure | Warning | Not reproduced; keep watching |
| `privacy-push-195.txt` untracked | Info | Intentional (names the pushed head) |

## Gaps Summary

**Orchestrator addendum (2026-10-26).** The verifier's report above found the original four REL-03 cases closed and returned `passed`. A focused code review of the two changed files, run in parallel (195-REVIEW-GAP.md), then reproduced shapes the verifier did not probe. The orchestrator re-confirmed three on main 5862a3d with synthetic fragment-built seeds: an Elixir tuple key, an escaped-JSON key and a CLI `--password` flag each leak. GR-02 (a single-quoted `::add-mask::$VAR` passes the guard) is also a REL-03 hole. Status is therefore `gaps_found` (7/8): CR-01 to WR-03 are fixed as recorded, and GR-01 and GR-02 remain. GR-03 to GR-10 are warnings and info for the next gap plan to triage.

---

_Verified: 2026-10-26_
_Verifier: Claude (gsd-verifier)_
