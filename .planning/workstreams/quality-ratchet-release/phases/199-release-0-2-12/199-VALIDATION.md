---
phase: "199"
slug: "release-0-2-12"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-10"
---

# Phase 199 — Validation Strategy (REL-07)

> Per-phase validation contract, reconstructed from the PLAN, SUMMARY and EVIDENCE artifacts (no prior VALIDATION.md, State B). Requirement: REL-07 only. Audit run 2026-11-10 against origin/main 323227b5 in a scratch checkout that was removed afterwards. Implementation files were read only. No repository file was added or committed, and no live-state or irreversible step was re-run.

---

## Audit Scope

- **Executed (18 plans, 49 tasks):** 199-01 to 199-12 and 199-15 to 199-20. Each has a SUMMARY.
- **Deferred under D-31 (not gaps):** 199-13 and 199-14. Both carry `status: superseded` and `deferred_by: D-31`. 199-13 ended BLOCKED (199-13-BLOCKED.md). 199-14 was never started. The companion clause of REL-07 (threadline 0.1.1) is deferred with its reopening condition in 199-DECISIONS.md (D-31).
- **Basis of the REL-07 judgement:** the 0.2.14 core release (run 42713010358), per D-27 and D-32. The 0.2.12 run ended PARTIAL and the 0.2.13 run ended FAILURE. Both are recorded as published and superseded, and neither was re-run.
- **Evidence classes:**
  - *automated*: a repository suite, run in this audit.
  - *evidence*: a live step recorded in 199-EVIDENCE or 201-EVIDENCE. Where a grep, jq or awk can check the recorded result, it was re-derived offline. Live state was not re-run.
  - *manual-only*: a user gate, or a pending repository change that needs a new PR.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5, OTP 27.3); Python 3 unittest harness; bash with shellcheck; actionlint |
| **Gate runner** | `bash script/mix_test_gate.sh --out FILE --min N -- <paths>` (verdict from the ran count; no pipe) |
| **Workflow scanner** | `elixir script/check_release_workflow_integrity.exs` (106 roster checks) |
| **Quick run command** | `bash script/mix_test_gate.sh --out FILE --min 11 -- test/crosswake/release_candidate/mirror_release_tag_test.exs` |
| **Full suite command** | `bash script/mix_test_gate.sh --out FILE --min 1 -- test/crosswake/release_candidate test/crosswake/guides test/crosswake/proof` (add `test/crosswake/release_candidate/evidence_live_test.exs` to the proof selection; see O-7) |
| **Estimated runtime** | release_candidate ~15 s; guides ~15 s; proof directory several minutes under load |

---

## Sampling Rate

- **After any release-workflow edit:** the scanner and `test/crosswake/proof/phase199_release_gates_test.exs`.
- **After any SC3 or REL-06 script edit:** `mirror_release_tag_test.exs` and `test/crosswake/release_candidate/cleanroom_test.exs`.
- **Before any release:** the release_candidate and guides directories green, and live steps recorded in EVIDENCE.
- **Max feedback latency:** targeted runs under 20 s; the proof directory is several minutes and is run as a background job.

---

## Audit Results (this run)

| Command, run in the scratch checkout at origin/main 323227b5 | Result |
|---|---|
| `mirror_release_tag_test.exs` (SC3 tool) | 11 ran, 0 failures |
| `release_environments_test.exs` (approval environments preflight) | 10 ran, 0 failures |
| `proof/phase199_release_gates_test.exs` (gate pins and seeded mutations) | 23 ran, 0 failures |
| `companion_attestation_test.exs` | 2 ran, 0 failures (companion stage deferred; harness only) |
| `companion_publish_authorization_test.exs` (trailer render and check) | 7 ran, 0 failures |
| `python3 -I test/support/companion_attestation_check.py -v` | 9 ok |
| `release_candidate/` directory | 205 ran, 0 failures |
| `guides/` directory | 237 ran, 0 failures, 5 excluded (tag-gated, pre-existing) |
| Planning group: agents_contract, bearings_report, first_adopter_context, release_please_config, adoption-context scan task, release_status task | 158 ran, 0 failures |
| `proof/` directory | 922 ran, 2 failures, both a file-selection artifact (O-7). The same two files run with `release_candidate/evidence_live_test.exs`: 28 ran, 0 failures |
| `elixir script/check_release_workflow_integrity.exs` | 106 of 106 roster checks, 0 failed |
| `mix crosswake.docs.sync --check` | passed |
| `release-pr-head-controls-199.sh` (predicate, phase evidence script) | 19 of 19 ok, verdict PASS |
| Offline record checks (plan verify greps and jq against EVIDENCE) | all pass: 0.2.11 and 0.2.12 mirror lines; candidate docs PASS with deferred=ios_host; cleanroom-0.2.14 PASS with deferred=none and rc 0; run-final-201 jq (COMPLETE, exact-public success, six fully proven); D-31 present; no companion standing lines; REL-07 Complete in traceability and checkbox |
| Gate protocol audit (offline, gates-199 and gates-201) | see Per-Task map, rows 07 to 12 and 14 |

---

## Per-Task Verification Map

Rows are one per plan (its tasks are listed in the Task ID). All rows are REL-07. Status words: **green** (automated, run here), **evidence** (recorded live result, re-derived offline), **deferred** (D-31), **gap** (see Gap Register).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 199-01-T1..T3 | 01 | 1 | REL-07 (SC3) | — | Post-publish check: mirror tag holds the released tree and is newest; each mismatch exits 1 with a named reason; unreachable mirror exits 3 | unit + evidence | `bash script/mix_test_gate.sh --min 11 -- test/crosswake/release_candidate/mirror_release_tag_test.exs`; `shellcheck script/check_ios_mirror_release_tag.sh` | yes | green (11/11); live 0.2.11 PASS and 0.2.10 newer_mirror_tag control re-derived offline. Numeric-order gap: GAP-01 |
| 199-02-T1..T3 | 02 | 2 | REL-07 | — | Non-release PR queue dispositioned; no bot branch modified; main unchanged | evidence | none automated (live PR state, not re-run) | yes (queue-199.txt) | evidence (252 and 258 closed; 253 closed on user allow) |
| 199-03-T1..T3 | 03 | 3 | REL-07 | T-199-51 | Preflight fails closed on a missing or unprotected environment; a rate limit beyond the bound exits 3; no token in any file | unit + scanner + evidence | `bash script/mix_test_gate.sh --min 10 -- test/crosswake/release_candidate/release_environments_test.exs`; scanner; `--min 3 -- phase199_release_gates_test.exs` | yes | green (10/10, scanner, 23/23); live before rc=1 and after rc=0 recorded |
| 199-04-T1..T3 | 04 | 4 | REL-07 (SC2, D-01, D-02) | — | Each publisher waits on its own environment; core order Hex, then Maven, then iOS; no status-check function on a publisher | scanner + mutation | scanner; `phase199_release_gates_test.exs` (mutations such as "deleting the publish-hex environment key") | yes | green; two existing pins were rewritten to the new wiring (O-2) |
| 199-05-T1..T3 | 05 | 5 | REL-07 (SC2, D-04) | — | Tag creation waits on release-tags; `!cancelled()`, never `always()`; mirror check is read-only and runs after each iOS publish | scanner + mutation + actionlint | scanner; `phase199_release_gates_test.exs` (tag-gate and mirror mutations); `actionlint .github/workflows/release-please.yml` | yes | green; three existing pins rewritten (O-2); 0.2.14 run shows mirror_tag_check success |
| 199-06-T1..T3 | 06 | 6 | REL-07 (companion, D-03) | — | Attestation accepts only the five named companions; trailer check rejects any mismatch; no secret in the job | unit | `python3 -I test/support/companion_attestation_check.py -v`; `--min 2 -- companion_attestation_test.exs`; `--min 7 -- companion_publish_authorization_test.exs` | yes | green (tooling); live companion stage deferred (see 199-13 and 199-14 rows) |
| 199-07-T1..T3 | 07 | 7 | REL-07 (SC1) | — | Gate pipeline merged on green exact head; ordinary push passes the skipped tag gate; predicate rejects hand edits | unit + predicate + evidence | `bash release-pr-head-controls-199.sh release-pr-head-199.sh <repo>` (19 ok, PASS); shellcheck | yes (phase scripts) | green (controls re-run); live proposal run 42387805006 recorded. Predicate is a one-time script, not CI (O-11) |
| 199-08-T1..T3 | 08 | 8 | REL-07 (SC1, SC2) | — | Candidate pinned to head; rehearsals change no external state; fire drill runs only on its own allow; receipt bound to the head | evidence | none re-run (live dispatch). Offline: gate freshness check (audit scratch, not committed) | yes (core-candidate-199.json, core-rehearsals-199.json, core-receipt-199.json) | evidence; core-maven-drill display freshness not demonstrable for the 0.2.12 attempt (O-1) |
| 199-09-T1..T2 | 09 | 9 | REL-07 (REL-06, REL-17) | — | Candidate docs pass REL-06 with deferred=ios_host; REL-17 pre-merge gate PASS; trailer rendered and checked; no merge executed | evidence + unit | offline grep of cleanroom-candidate-docs-199.txt (PASS, deferred=ios_host); `--min 205 -- test/crosswake/release_candidate` (205/205) | yes | green (suite); evidence (recorded PASS) |
| 199-10-T1..T3 | 10 | 10 | REL-07 (SC1, SC2, D-04) | — | Release PR merged only on its own allow, pinned to head; three source tags created on one shared allow | evidence | offline gate awk over gates-199.txt (re-derived here); core-merge-199.json and core-tags-199.json jq | yes | evidence; one plan rule reinterpreted and disclosed (O-12) |
| 199-11-T1..T3 | 11 | 11 | REL-07 (SC2, D-02) | — | Hex then Maven each published only on its own allow; both visible afterwards | evidence | gate awk over gates-199.txt; Hex and Maven reads recorded 2026-11-08 (not re-run) | yes | evidence |
| 199-12-T1..T3 | 12 | 12 | REL-07 (SC2, SC3) | — | iOS mirror tag v0.2.12 pushed only on its own allow; SC3 proven both ways on live data; final run state recorded | evidence | offline grep of mirror-tag-0.2.12-199.txt (pre rc=1 mirror_tag_missing; post PASS) | yes | evidence; the 0.2.12 run is recorded PARTIAL and superseded (O-4) |
| 199-13-T1..T3 | 13 | 13 | REL-07 (companion) | — | DEFERRED: PR 262 not refreshed; threadline 0.1.1 not released | — | — | status superseded, deferred_by D-31; 199-13-BLOCKED.md | deferred (not a gap) |
| 199-14-T1..T3 | 14 | 14 | REL-07 (companion) | — | DEFERRED: companion merge, tag and Hex publish not run | — | — | status superseded, deferred_by D-31 | deferred (not a gap) |
| 199-15-T1..T2 | 15 | 15 | REL-07 (SC5, D-27) | — | REL-06 against 0.2.14 from the Hex tarball with deferred=none; reader audit gives first release 0.2.12 for each SC6 claim | evidence | offline greps of cleanroom-0.2.14-199.txt (result PASS legs hex,maven,ios,docs; deferred=none; rc 0) and cleanroom-reader-audit-199.txt | yes | evidence (re-derived PASS); point-in-time run |
| 199-16-T1..T2 | 16 | 16 | REL-07 (SC6, D-26) | — | Generated guides name the first release; qualifier guard removed; renderers regenerate and check clean | unit + docs.sync | `mix crosswake.docs.sync --check` (passed); `--min 1 -- test/crosswake/guides` (237/237); zero-hit grep for the retired phrase (none) | yes (guide suite) | green at close; no recurring absence guard (GAP-02) |
| 199-17-T1..T2 | 17 | 17 | REL-07 (SC6) | — | Hand-written guides and CHANGELOG hold no unpublished claim for a shipped feature | unit | guides suite including `changelog_unreleased_wording_test.exs` and `host_command_seam_guide_test.exs` | yes | green at close; no recurring absence guard (GAP-02) |
| 199-18-T1..T2 | 18 | 18 | REL-07 (completion, D-27, D-31, D-32) | — | REL-07 ticked on the 0.2.14 core release only, after seven conditions; STATE and ROADMAP handoffs agree; AGENTS.md within its cap | unit + evidence | `--min 1 -- test/crosswake/planning/agents_contract_test.exs test/crosswake/bearings_report_test.exs`; `wc -l AGENTS.md` (99, cap 102); 199-18 verify (offline parts re-run here) | yes | green; completion awk counts keys only, not results (GAP-03) |
| 199-19-T1..T3 | 19 | 19 | REL-07 (closeout landing) | T-199-79, T-199-80 | Landing copies redacted; per-file privacy dispositions; no main-side file overwritten; `.awk` scanned; nothing pushed | unit + privacy | `--min 1 -- test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` (in planning group, 158/158); privacy-193.sh per file (recorded) | yes | green (scan tests); evidence (dispositions recorded, O-5) |
| 199-20-T1..T3 | 20 | 20 | REL-07 (SC1, SC4, D-29) | T-199-46, T-199-82 | Closeout PR merged pinned to its CI-green head; docs branch deleted only after a 267-path equivalence proof with zero gaps; SC4 annotated as unmet | evidence | offline grep of closeout-final-199.txt (`bearings_rc: 1` recorded); equivalence not re-run (docs branch deleted; tip e540a41d) | yes | evidence; SC4 unmet, outside REL-07 (O-6) |

---

## Gap Register (REL-07)

Three gaps were found. Each is a behavior the repository's tests and the recorded evidence do not prove in a way that can fail. Each was probed in the scratch checkout. None is a failed requirement: no probe found an implementation defect, and no BLOCKER was raised. Each repository test would need a new PR, so each is recorded as manual-only under the user's pre-decided gate "Skip - mark gaps manual-only".

| Gap | Requirement behavior | Coverage found | Probe run in this audit | Proposed test (not committed) | Resolution | Class |
|-----|----------------------|----------------|-------------------------|-------------------------------|------------|-------|
| GAP-01 | SC3 newest-tag rule orders versions numerically (0.2.9 is older than 0.2.10 and 0.2.11) | Committed fixtures use only 0.2.10 to 0.2.12, so a lexicographic sort would pass them. Live evidence on the real mirror covers the numeric order: the 0.2.14 post-publish check ran while the mirror held v0.2.9 through v0.2.13 and returned newest v0.2.14 (PASS) | P1 (add a mirror with v0.2.9 and v0.2.10 beside v0.2.11, expect PASS): PASS on the real script. Same probe with the sort replaced by `sort -u`: FAIL with `newest v0.2.9 ... reason=newer_mirror_tag` | P1: new test in `test/crosswake/release_candidate/mirror_release_tag_test.exs` (snippet kept outside the repo) | SKIP, manual-only (needs a new PR). Probe verified | WARNING |
| GAP-02 | The retired D-26 qualifier "not in a published release yet" must not return to guides, lib or CHANGELOG | None after 199-16 removed `unreleased_claim_qualifier_test.exs`. The 199-16 and 199-17 zero-hit grep ran once and is not in CI. No script or workflow matches the phrase | Regression: phrase added to `guides/architecture.md` and `CHANGELOG.md`. Full guides directory 242 total, 0 failures; `docs.sync --check` passed. The regression went undetected | Q1: `test/crosswake/guides/unpublished_claim_absence_test.exs` (absence scan with non-vacuity control) | Q1: PASS on the clean tree (2/2); FAIL on the regressed tree, naming the file and line. SKIP, manual-only (needs a new PR). Probe verified | WARNING |
| GAP-03 | The REL-07 completion record must state PASS results, the standing-rules PASS precheck and the drill's applied line | The 199-18 verify counts seven `rel07_check` keys and the core standing lines. It never reads `result=`, the precheck, or the applied line. The live curl, mirror, jq and greps in the same verify are the real backstop | Three mutated copies of the records: all results FAIL; standing-rules precheck removed; drill applied line removed. The 199-18 awk passed all three | V1: `test/crosswake/planning/rel07_record_test.exs` (repo-relative evidence paths) | V1: PASS on the real records (3/3); each mutation FAILS in the matching test. SKIP, manual-only (needs a new PR or a verify change). Probe verified | WARNING |

Gaps checked and **not** found:

- **Rewritten scanner pins (199-04, 199-05).** Probe: removing the push-only term from the release-please `if:` turns the scanner red on `release.gate.tag_gate` and `release.rehearsal.maven_isolated` (2 failed). The push-only guarantee is still enforced. The flipped truth of `release.ios.independent_publication` was not probed separately (O-2).
- **SC3 unreachable mirror.** Covered by fixture test 8 (exit 3, UNVERIFIED).
- **Tag gate on proposal pushes.** Covered by scanner and by the 199-07 proposal run.

---

## Wave 0 Requirements

- Existing repository infrastructure covers every automated REL-07 behavior in the map above.
- Proposed tests P1, Q1 and V1 are not committed. They are the Wave 0 for a follow-up PR, which the user's gate defers to manual-only.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Promote P1 into `mirror_release_tag_test.exs` | REL-07 (SC3) | Needs a new PR; pre-decided gate "Skip - mark gaps manual-only" | Add the P1 test body (kept in the audit scratch, not the repo) before the fixtures section; run the mirror test file; expect 12 ran, 0 failures |
| Promote Q1 as `test/crosswake/guides/unpublished_claim_absence_test.exs` | REL-07 (SC6) | Needs a new PR; the proposed file must use repo-relative paths only | Run the guides directory; expect the non-vacuity control and the absence test to pass |
| Promote V1 as `test/crosswake/planning/rel07_record_test.exs` | REL-07 (completion) | Needs a new PR or a verify change; the proposed file must use repo-relative paths only | Run the planning test; expect 3 tests, 0 failures against the real records |
| Each release gate decision (allow or hold) | REL-07 | Irreversible external write; the user decides | Per 199-DECISIONS.md gate protocol; not validated by tests |
| Live pause at each environment, and the real publish, on 0.2.14 | REL-07 | Live GitHub run; not re-run | Recorded in 201-EVIDENCE/gates-201.txt and run-final-201.json |
| Companion release (threadline 0.1.1) | REL-07 companion clause (D-31) | Deferred by the user on 2026-11-10 | Reopens as a new plan when Release Please recreates the threadline PR from a main with the 30-minute CI bound and CI is green on its head |
| Hosted anonymous rate-limit throttle | REL-07 (preflight) | A throttle has not been observed; the path is fail-closed | Exit 3 blocks the release; no action needed unless it occurs |

---

## Observations (WARNING, not test gaps)

- **O-1 Gate freshness, 0.2.12 core-maven-drill.** The display is stamped 2026-11-07T16:30Z, but the last precheck before it in the file is 16:16:30Z, 13.5 minutes earlier. The protocol allows less than 10 minutes. The file also places a 2026-11-08T05:29:37Z precheck above the display line, so the record disagrees with itself. The attempt's dispatch was preceded by a fresh PASS precheck on 2026-11-08. The 0.2.14 drill display was 0.83 minutes after its precheck. This cannot be re-run; it is historical.
- **O-2 Rewritten pins.** 199-04 and 199-05 changed the truth of five existing pins to match the new wiring (`release.approval.linked_graph`, `release.ios.independent_publication`, `maven_fire_drill_isolated`, a phase175 mutation, and `release_please_config_test.exs`). The implementing SUMMARYs say the strictness is the same. The release-please push-only probe holds. Independent review of the other flipped pins is still open, and 199-04 asked the orchestrator for it.
- **O-3 Standing approvals on 0.2.14.** The core steps (merge, tags, Hex, Maven, iOS) ran on the standing basis (`standing:` lines, basis `standing-release-approvals-2026-11-09`), not on one-use displayed allows. REL-07 was amended on 2026-11-09 to accept this for releases after 0.2.13. The drill kept its own displayed allow.
- **O-4 Scope of "completes".** REL-07 is judged on 0.2.14 alone (D-27, D-32). 0.2.12 ended PARTIAL at the iOS clean-room proof, and 0.2.13 ended FAILURE at the exact-public proof. Both are recorded as published and superseded.
- **O-5 Privacy dispositions.** 199-19 and 199-20 landed 42 raw pre-merge sources with `not-identifying` dispositions. Two categories are judgement calls: the public GitHub account `users/github`, and the maintainer's public noreply address in three files. 199-07 also used a scoped privacy rule chosen by the orchestrator. Recorded for the user's review; not a test gap.
- **O-6 SC4 unmet (outside REL-07).** `script/bearings-report` ended ATTENTION (1) with rc 1 at the 199-20 close: seven unlanded branches and one worktree. REL-07 is not conditioned on SC4 (D-32), so it stays Complete. SC4 stays annotated as unmet. A later read may show a different count.
- **O-7 Suite selection dependency.** `test/crosswake/proof/phase175_linked_authorization_test.exs` calls `Crosswake.ReleaseCandidate.EvidenceLiveTest.fixture/1`, which lives in `test/crosswake/release_candidate/evidence_live_test.exs`. Run alone, the proof directory fails 2 tests. With that file included, 28 of 28 pass. The full suite includes it.
- **O-8 Load timeouts.** 199-05 saw one 60 s ExUnit timeout in `phase161_1_navigation_gate_integrity_test.exs`, and 199-16 saw 19 timeouts at load 11 to 30. Neither recurred in the runs used here. Environment-specific.
- **O-9 Hosted anonymous read.** Proven on proposal run 42387805006 and on the 0.2.14 guard runs. A throttle exits 3, which blocks the release. Fail-closed by design.
- **O-10 Predicate is not CI.** `release-pr-head-199.sh` is a one-time reconciliation script (199-07 says so). The recurring protection is the scanner and the guard.
- **O-11 Plan rule reinterpreted.** 199-10 treated "guard run no older than the PR head CI run" as satisfied on a current-main-head basis, because the run that created PR 236 is the latest possible. Disclosed in gates-199.txt.
- **O-12 199-12 frontmatter.** `status: complete` was set after the halt was resolved. The body keeps "Self-Check: FAILED" and the halt-resolution note, so the failure remains on the record.

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies. Not met: the evidence-only rows (02, 08, 10, 11, 12, 15, 20) and the three manual-only gaps depend on recorded live results.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify. Not met for the 0.2.12 gate rows (10 to 12), which are evidence-only.
- [ ] Wave 0 covers all MISSING references. Not met: P1, Q1 and V1 are proposed, not committed.
- [x] No watch-mode flags.
- [ ] Feedback latency under 60 s. Met for the targeted runs; not met for the proof directory (several minutes), which runs as a background job.
- [ ] `nyquist_compliant: true` set in frontmatter. Not set: three gaps are manual-only pending a new PR, so this is PARTIAL in audit-milestone terms.

**Approval:** pending (audit only; no approval given. The user gate "Skip - mark gaps manual-only" applied to GAP-01 to GAP-03.)

## Validation Audit 2026-11-10

| Metric | Count |
|---|---|
| Gaps found | 3 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only | 3 |
