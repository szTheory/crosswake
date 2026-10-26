---
phase: 195-pipeline-repair-and-hygiene
verified: 2026-10-26T18:00:00Z
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
  - script/verify_published_cleanroom.sh
  - script/verify_repository.mjs
  - test/js/ci_secret_masking.test.mjs
covered_digest: "v3:sha256:5170d026060156e8f2eee7b1d409771ecde06fbd4a2e19a2c4558393924c6a59"
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "HYG-02: each remote delete behind its own allow"
    reason: "User gave one explicit batch approval for the last 17 tag/delete operations (plan 13 deviation); each op was bound to its ledger tip and read back; user ran the batch script themselves"
    accepted_by: "user (explicit batch decision, recorded in plan 13 ledger)"
    accepted_at: "2026-10-26"
gaps:
  - truth: "REL-03 / goal clause: the root-proof failure tail masks bearer, secret-access-key, cookie and short-value shapes, so CI never echoes secrets"
    status: failed
    reason: "maskSecretShapes masks only the unquoted, single-token, start-of-line forms its tests seed. Quoted secret-access-key values, mid-line cookies and multi-word quoted values leak in whole or part, and the keyword rule over-masks prose. Reproduced by the verifier."
    artifacts:
      - path: "script/verify_repository.mjs"
        issue: "maskSecretShapes (lines ~58-66 region): quoted values unmasked (CR-01), partial leak of multi-word values and unmasked mid-line Cookie / Digest / URL userinfo / JWT (CR-02), prose over-masking (WR-01), quadratic cookie regex (WR-02)"
      - path: "test/js/ci_secret_masking.test.mjs"
        issue: "Seeds use only the shapes the regexes were written for, so 11/11 pass without covering the gaps; isMaskLine has no word boundary and counts commented lines (WR-03)"
    missing:
      - "Mask quoted values (KEY=\"v\", key = \"v\") through the closing quote for secret-access-key and the generic keyword rule"
      - "Mask the rest of a multi-word quoted value, a mid-line Cookie header, Digest, URL userinfo and JWT shapes"
      - "Restrict the keyword rule so prose such as 'token expired' is not masked"
      - "Add test seeds for each of these shapes, plus a fails-when-mask-removed control for them"
deferred: []
human_verification: []
---

# Phase 195: Pipeline Repair and Hygiene Verification Report

**Phase Goal:** `main`, the release PR and the PR queue are green and trustworthy, CI runs only recurring lanes and never echoes secrets, the repository holds no scratch state, and one fail-closed clean-room command is proven against real published artifacts.
**Verified:** 2026-10-26
**Status:** gaps_found
**Re-verification:** No, initial verification
**Checked against:** origin/main ff63e5d8 (checkout is docs/195-closeout, main plus planning docs)

## What was checked and what I found

I read the requirements, the review and its disposition, the evidence files, and the code on origin/main. I ran the masking function myself, the masking test file, and live GitHub reads of the PR list and the PRs named in the requirements. Seven of eight requirements hold. REL-03 does not meet the goal clause "never echoes secrets", so the phase is `gaps_found`. Nothing was changed except this report. Next action: a gap-closure plan for the masker (`/gsd-plan-phase 195 --gaps --ws=quality-ratchet-release`).

## REL-03 judged explicitly

REL-03 has two halves.

1. "CI masks secret-derived values before any echo": **met.** The audit file lists every secret-derived value; the two derived ones in `maven-publish-fire-drill.yml` (`TOKEN`, `AUTH`) are passed to `::add-mask::` (lines 154 and 156); direct secrets are auto-masked by Actions.
2. "the root-proof failure tail masks bearer, secret-access-key, cookie and short-value shapes; a test proves a seeded fake secret never appears and fails when the mask is removed": **met only in the narrowest literal reading.** The unquoted single-token forms are masked (`AWS_SECRET_ACCESS_KEY=abcdefghijk` becomes `=***`, `Cookie: sid=abcdef123` becomes `Cookie: ***`, `Authorization: Bearer abc123xyz` becomes `Authorization: ***`, `password=hunter2x` becomes `password=***`), and the test file passes 11/11 with a removed-mask control.

The goal clause "never echoes secrets" is **not met**. I ran `maskSecretShapes` from `script/verify_repository.mjs` and got:

| Input | Output | Result |
|-------|--------|--------|
| `AWS_SECRET_ACCESS_KEY="abcdefghijk"` | unchanged | LEAK |
| `curl -H "Cookie: sid=abcdef123"` | unchanged | LEAK |
| `password = "my secret pass"` | `password = "my secret ***"` | PARTIAL LEAK |
| `Authorization: Bearer xyz123abc` | `Authorization: ***` | masked |
| `token expired for user` | `token *** for user` | over-mask (diagnosability) |

Quoted secret-access-key and mid-line cookie values are the common real-world forms in env dumps and curl echoes, and these two named shapes in REL-03's own text leak. I therefore mark the truth FAILED (BLOCKER) rather than passing it on the test's narrow seeds. Absence of a counter-test is not evidence: the tests pass because they only seed what the regexes were written for. This matches review findings CR-01 and CR-02 (WR-01 to WR-03 are related); all 11 findings are still `open` in the disposition.

## Observable Truths

| # | Requirement | Truth | Status | Evidence |
|---|-------------|-------|--------|----------|
| 1 | REL-01 | Version-line-insensitive goldens; release PR passes eight test jobs with no hand edits on the PR head | VERIFIED | `test/support/version_stamp.ex` and its test exist; #236 green on head b1e8d95 (50 of 50 contexts after one re-run for HTTP 504s, cause not code); rehearsal evidence files present |
| 2 | REL-02 | Parity test uses 40-hex SHA plus version comment; #210/#211 green or closed | VERIFIED | Live read: #210 and #211 MERGED |
| 3 | REL-03 | CI masks derived secrets; failure tail masks bearer, secret-access-key, cookie, short-value shapes | FAILED | See the REL-03 section; CR-01, CR-02 reproduced |
| 4 | REL-04 | 14 weekly proof schedules, Cancel Obsolete controller and `select_obsolete_ci_runs.py` removed; one weekly canary; native split | VERIFIED | Only three `cron:` entries remain on main (required-checks-audit daily, see-it-run-collateral weekly, weekly-canary Monday); no `phaseNN-proof` schedule; no obsolete-selector script; `see-it-run-native.yml` exists and `web-and-gif` is its own job; canary run 40354096432 success on 0b28e6d (the first run on 735c3bc failed on a missing node pin and was fixed forward in PR #254) |
| 5 | REL-05 | One grouped monthly actions PR plus security updates; #239/#240/#241 merged; #238 merged or closed; no open PR older than 14 days without a reason | VERIFIED | `.github/dependabot.yml`: one `actions` group, monthly, `applies-to: version-updates`; live read #238 to #241 MERGED; open PRs are #236 (15 days, reason recorded in `pr-age-195.txt`: release PR, merge is Phase 199), #252 and #253 (0 days) |
| 6 | REL-06 | SEED-003 closed with mirror-tag evidence; one fail-closed clean-room command run once against real 0.2.11 artifacts, output retained | VERIFIED | `cleanroom-0.2.11-195.txt`: hex, maven, ios legs PASS, rc 0; `cleanroom-negative-195.txt`: missing version rc 1, wrong artifact rc 1 (checksum mismatch); `seed003-mirror-tag-195.txt`: mirror tag v0.2.11 tree equals monorepo tree; `published_cleanroom_test.exs` exists. Robustness warnings WR-04 to WR-06 are open but do not defeat fail-closed on the traced paths |
| 7 | HYG-01 | Root scratch files and the bundle removed; SETUP.md under docs/ without personal email; root allowlist test | VERIFIED | Root on origin/main holds exactly the 15 allowlisted files; no tracked `*.bundle`; `docs/SETUP.md` present; `repository_root_allowlist_test.exs` enforces both rules |
| 8 | HYG-02 | Merged/superseded remote branches deleted, unmerged work tagged `archive/<name>` first; worktrees show only main | VERIFIED (override) | `git worktree list` shows one line; remote heads are main, the release branch, #252 and #253 heads (plus the closeout branch); 10 `archive/*` tags present locally. "Own allow per delete" was replaced for the last 17 operations by an explicit user batch approval (override above) |

**Score:** 7/8 truths verified (0 present-but-behavior-unverified).

### Coincidental-reliance note (advisory, not scored)

REL-03's test suite is the clearest example: its seeds establish the precondition (single unquoted word at line start) that the production masker's regexes assume, so it passes without the production input shapes.

## Key Evidence Run by the Verifier

| Check | Result |
|-------|--------|
| `node --test test/js/ci_secret_masking.test.mjs` | pass 11, fail 0 (does not cover the leaking shapes) |
| `maskSecretShapes` direct calls | leaks listed above |
| Root file listing on origin/main | 15 files, all allowlisted |
| Live PR reads: #210, #211, #238 to #241 | all MERGED |
| Open PRs | #236, #252, #253 |
| Orchestrator regression gate | `mix test` 2788 tests, 0 failures; JS 148 pass, 0 fail |

## Requirements Coverage

| Requirement | Status | Note |
|-------------|--------|------|
| REL-01 | SATISFIED | |
| REL-02 | SATISFIED | |
| REL-03 | BLOCKED | Masker leaks quoted and mid-line forms |
| REL-04 | SATISFIED | |
| REL-05 | SATISFIED | |
| REL-06 | SATISFIED | |
| HYG-01 | SATISFIED | |
| HYG-02 | SATISFIED (override) | Batch approval deviation, user-approved |

All eight IDs are claimed by plans and mapped to Phase 195 in REQUIREMENTS.md. No orphaned IDs. REL-07 and DOCS-01 map to later phases and are not in scope here.

## Anti-Patterns and Open Items

| Item | Severity | Note |
|------|----------|------|
| CR-01, CR-02 (masker leaks) | BLOCKER | Gap above |
| WR-01 to WR-03 (over-masking, quadratic regex, vacuous test guard) | Warning | Part of the same gap-closure plan |
| WR-04 to WR-06 (clean-room curl has no timeout, some failures labelled `not_published`, loose POM check) | Warning | Fail-closed still holds; harden in a follow-up |
| IN-01 to IN-03 | Info | Mixed checkout pin comments, dead schedule conditions, `need_tools` omits `head`/`tr` |
| #253 open, merge refused by protection (behind main, CI `action_required`) | Warning | Not a REL requirement; re-offer at the next queue pass |
| `crosswake_inspect_test.exs:136` one-off CI failure (run 40361272003), cause unknown | Warning | Not reproduced in the full local suite; keep watching |
| `mix test test/crosswake/proof` alone fails 2 Phase175 tests (cross-directory helper) | Info | Full suite green |
| No debt markers (`TBD`/`FIXME`/`XXX`) were found in the requirement-bearing files checked | None | |

## Gaps Summary

One gap blocks the goal: the secret masker in `script/verify_repository.mjs`. The rest of the phase holds against live state: lanes trimmed to three recurring schedules, the queue reduced to three PRs with reasons, the root clean, one fail-closed clean-room run retained for real 0.2.11 artifacts, and the release PR green. Close the gap with a plan that adds the missing seeds first (so they fail), then fixes the regexes, and re-run the REL-03 tests with the mask-removed control.

---

_Verified: 2026-10-26_
_Verifier: Claude (gsd-verifier)_
