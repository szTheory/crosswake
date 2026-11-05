---
phase: 197-public-docs-truth
verified: 2026-11-05T20:20:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-01-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-01-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-02-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-02-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-03-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-03-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-04-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-04-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-05-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-05-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-06-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-06-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-07-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-07-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-08-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-08-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-09-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-09-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-10-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-10-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-11-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-11-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-12-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-12-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-13-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-13-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-14-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-14-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-15-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-15-SUMMARY.md"
  - "CHANGELOG.md"
  - "README.md"
  - "guides/android_uat.md"
  - "guides/companion_compatibility.md"
  - "guides/install.md"
  - "guides/see_it_run.md"
  - "guides/telemetry.md"
  - "release-please-config.json"
  - "script/docs-report"
  - "script/docs_report.exs"
  - "script/verify_published_cleanroom.sh"
  - "test/crosswake/guides/cleanroom_doc_markers_test.exs"
  - "test/crosswake/proof/phase132_compat_matrix_drift_test.exs"
  - "test/crosswake/proof/phase68_android_uat_test.exs"
covered_digest: "v4:sha256:3fd63e2b09215ea6318436b4095f96c2149350431b24caa7682ebb9c67b83d1c"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 197: Public docs truth Verification Report

**Phase Goal:** A first adopter following the public docs from a normal host gets commands that exist, versions that are real and capability claims backed by evidence.
**Verified:** 2026-11-05T20:20:00Z
**Status:** passed
**Re-verification:** No, initial verification

## What was checked

I read the ROADMAP success criteria (as amended 2026-10-29), the workstream REQUIREMENTS.md and
the 15 plans, then checked the actual files on `docs/197-public-docs-truth`. For the doc and
script paths below, `git diff origin/main HEAD` is empty, so the tree equals what PR 268 merged
to main. I re-ran the ExUnit files that guard the phase, `script/docs-report`, and
`mix crosswake.docs.sync --check`. I did not re-run the networked four-leg clean-room command;
its recorded output is cited as evidence and the offline test that drives the same script
(`published_cleanroom_test.exs`) was re-run.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|---|---|---|
| 1 | SC1: REL-06 clean-room command executes README "Integrating" and `install.md` steps without a clone and passes; no repo-only command outside a clone-labeled block; both state which steps need a clone; both include bridge hook, esbuild flags, `attach/1` and `:ios_host`; `:ios_host` is a named deferral against 0.2.11 | VERIFIED | `197-EVIDENCE/cleanroom-0.2.11-197.txt`: `leg docs PASS 0.2.11 executed=18 not_applicable=2 deferred=ios_host clone=4 shown=4 source=commit:e4a25fb...`, `result PASS legs hex,maven,ios,docs`, rc 0. README (lines 127-232) and install.md carry `cleanroom:` markers on every fence; bridge hook, `--external:/crosswake/*`, `--format=esm`, `Crosswake.Bridge.attach()` and `config :crosswake, :ios_host` all present. The only `script/` and `examples/` commands sit in `cleanroom:clone` blocks, each followed by "Needs a clone of the Crosswake repository; skip this if you installed from Hex." A summary line at install.md:17 states the rule. Re-ran `cleanroom_doc_markers_test.exs` and `published_cleanroom_test.exs`: pass. `:ios_host` deferral record: `sc1-ios-host-deferral-197.txt` (not counted as executed or passed; reader audit shows 0.2.11 does not read `:ios_host`). |
| 2 | SC2: matrix has no copied version and links hex.pm; one recorded `release.status --live` run; phase132 test has no stale literals; CHANGELOG makes no false "current release" claim and points to GitHub Releases; telemetry lists `[:crosswake, :offline, :replay]`; `see_it_run.md` says the twin receipt attests `a53fbef` | VERIFIED | `guides/companion_compatibility.md`: table is Hex Package / Companion ID / Latest on Hex (hex.pm links) / Requires / Engine, no version cell. `release-status-live-197.txt`: `status: OK`, live_hex=ok for all 5 companions plus core/ios/android lockstep. `@published_versions` is gone from phase132; the only `0.1.0` is the injected negative control (line 298-301). CHANGELOG: grep for "current published", "current release" and `published Hex (family\|release)` finds none in `[Unreleased]`; the "Published Hex truth" section points to GitHub Releases and hex.pm. `guides/telemetry.md:191` lists the event. `guides/see_it_run.md:196` states the receipt attests `a53fbef`, not `main`. Tests re-run: phase132, `changelog_unreleased_wording_test`, `unreleased_claim_qualifier_test`, phase133 telemetry, phase69 docs parity: pass. |
| 3 | SC3: `mix docs` warnings, relative link/anchor check and leak scan run in report mode with counts recorded, none a required check | VERIFIED | Re-ran `script/docs-report` on the current tree: `docs.warnings total=197 extras=2`, `docs.links broken=0 checked=234 files=30`, `docs.leaks hits=95 allowlisted=0 stale_allowlist=0 files=30`, `REPORT-ONLY`, rc 0. Identical to `197-DOCS-REPORT.md` "After" and `docs-report-after-197.txt`. Baseline recorded before the first doc-touching commit (`ordering-197.txt`, `merge-base --is-ancestor` rc 0). `docs_report_test.exs` (asserts no workflow references the report) passes. |
| 4 | SC4: `android_uat.md` has no automated "Last verified" stamp and no phantom families; "Android frozen" grep over README, support matrix and native shell guide returns zero | VERIFIED | `guides/android_uat.md` has a version-free Status section, no "Last verified" or `x-release-please` text, and the 15-family list (phantoms `account_management`, `diagnostic_export`, `companion_snapshot`, `location_capture` removed). `release-please-config.json` no longer lists the file. Fresh grep for "android frozen" over README, support_matrix, native_shell and android_uat: no hits (rc 1). Evidence file has a positive control (an appended sentence produces a hit). `phase68_android_uat_test.exs` and `native_evidence_drift_test.exs` pass. |

**Score:** 4/4 truths verified (0 behavior-unverified)

### Judgment on the `:ios_host` deferral

The deferral is honest and does not make the goal fail. ROADMAP SC1, REQUIREMENTS DOCS-01 and
CONTEXT D-04 were all amended on 2026-10-29, before execution, to say that the `:ios_host` step
is a named deferral against 0.2.11, never counted as executed. The facts support this: the
reader audit against the real 0.2.11 tarball shows 0.2.11 does not read `:ios_host`. The run
output prints `deferred=ios_host` instead of folding the step into `executed`. The docs
themselves say "Crosswake releases after 0.2.11" at the point of use. The linked guides
(support matrix, capability map, native shell, compatibility, upgrade, architecture) carry the
same qualifier (D-26), and `mix crosswake.docs.sync --check` passes, so the generated guides
match their renderers. A first adopter on 0.2.11 is told the setting is not read yet, so no
command or claim is misstated.

What remains open is that the `:ios_host` wiring is documented but has not been executed
against a release that reads it. That is tracked, not silent: ROADMAP Phase 199 SC5 requires the
docs leg against 0.2.12 to pass with `deferred=none`. Phase 199 must not accept an exemption.

### Required Artifacts

| Artifact | Status | Details |
|---|---|---|
| `README.md`, `guides/install.md` (marked, Hex-only, clone-labeled) | VERIFIED | Markers on every fence, tokens present, clone labels present |
| `script/verify_published_cleanroom.sh` (docs leg, WR-04/05/06, IN-03) | VERIFIED | Offline test file (205-test batch) passes; real run PASS recorded |
| `script/docs-report`, `script/docs_report.exs`, `script/docs_leak_allowlist.json` | VERIFIED | Exist, run, exit 0, counts match record |
| `guides/companion_compatibility.md` | VERIFIED | Version-free, hex.pm links |
| `CHANGELOG.md` | VERIFIED | No false current-release claim |
| `guides/telemetry.md`, `guides/see_it_run.md`, `guides/android_uat.md` | VERIFIED | Claims present as required |
| Guard tests (marker, phase132, phase68, changelog wording, unreleased-claim qualifier, ios_host values) | VERIFIED | All pass |

### Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| clean-room docs leg | README.md / install.md markers | commit-pinned fetch, marker parser | WIRED (real run executed 18 steps from the docs themselves) |
| `guides/support_matrix.md` | `renderer.ex` | `mix crosswake.docs.sync` | WIRED (`--check` passed) |
| phase132 test | companion matrix | version-literal scan with negative control | WIRED |
| Phase 197 deferral | Phase 199 SC5 | `deferred=none` requirement in ROADMAP | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Guard suite for the phase | `mix test` over 7 files (markers, published_cleanroom, docs_report, phase132, phase68, native_evidence_drift, mix_test_gate) | 205 tests, 0 failures | PASS |
| Wording, qualifier, telemetry and docs-parity tests | `mix test` over 5 files | 47 tests, 0 failures | PASS |
| Collection-assertion ledger (fixed in `c224e084`) | `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` | 21 tests, 0 failures | PASS |
| Generated guides in sync | `mix crosswake.docs.sync --check` | passed | PASS |
| Docs report | `script/docs-report` | counts match record, rc 0 | PASS |

The full-suite record (`197-EVIDENCE/suite-197.txt`) shows the final run on the merged
tree as `3134 tests, 0 failures, verdict=PASS` against a floor of 3114. The earlier failing run
(5 failures in the Phase170 ledger test) is kept in the file as superseded and its fix landed
before the final run. I did not re-run the full suite.

### Probe Execution

Step 7c: no `scripts/*/tests/probe-*.sh` probes are declared by the phase plans. SKIPPED. The
clean-room command is the phase's runnable probe; its recorded real run is cited above.

### Requirements Coverage

Cross-referenced from PLAN frontmatter (all 15 plans) against the workstream
`REQUIREMENTS.md` (lines 55-57, 112-114), by grep.

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| DOCS-01 | 197-03 to 197-09 (one each), 197-13, 197-14, 197-15 | SATISFIED | SC1 evidence above; requirement text itself carries the 2026-10-29 `:ios_host` amendment |
| DOCS-02 | 197-10, 197-11, 197-12, 197-13, 197-14, 197-15 | SATISFIED | SC2 evidence above |
| DOCS-03 | 197-01, 197-02, 197-12, 197-13, 197-14 | SATISFIED | SC3 and SC4 evidence above |

All three IDs appear in plan frontmatter and in REQUIREMENTS.md, marked `[x]` and "Complete" in
the traceability table. No ORPHANED requirement: REQUIREMENTS.md maps only DOCS-01, DOCS-02 and
DOCS-03 to Phase 197, and every one is claimed by a plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `test/crosswake/release/published_cleanroom_test.exs` | 533 | `@zero_ref` read at line 533 but defined at line 574, so it is `nil` there (compiler warns "undefined module attribute") | Warning (not a blocker) | In the docs-leg tool-removal test, `CLEANROOM_DOCS_REF` is passed as `nil`, which unsets the variable instead of setting the zero ref. The test still asserts the specific `FAIL docs tool_unavailable` line and rc 1, so it keeps discriminating, but it is not running the environment it was written for. Fix: move `@zero_ref` above its first use. |
| Phase files | - | `TBD`, `FIXME`, `XXX` markers | none | Debt-marker grep over the changed docs and scripts found only an `mktemp` template and unrelated text |

### Human Verification Required

None. All checks were run or inspected automatically, in line with the zero-human rule. No
credentials or irreversible approvals are needed to verify this phase.

### Advisory notes (non-blocking)

1. **Leak counter is unchanged at 95.** Success criterion 3 asks only for report mode with counts
   recorded, and D-19 says to count only this cycle. The count is recorded and was not claimed
   as reduced. Promotion to a required check is a later decision from the baseline and after
   counts, never from one number alone.
2. **ExDoc versus GitHub anchor slugs differ** for headings with punctuation (recorded in
   `197-DOCS-REPORT.md`). The link counter checks the GitHub rule; some existing links resolve on
   GitHub but not on HexDocs. Recorded, not fixed.
3. **UAT note:** the selective test run that showed 2 `Phase175LinkedAuthorizationTest` failures is a
   directory-scoped-run artifact (a helper defined in another test file), not a phase 197
   change. I did not hit it because I ran named files.
4. **Unrelated working-tree state:** `.planning/config.json` is modified and a
   `.review-diagnostics/` directory is untracked. Neither is part of this phase and neither was
   touched.

### Gaps Summary

No gaps. Every roadmap success criterion is backed by an artifact in the tree and, where it
claims behavior, by a test that I re-ran or a recorded real run. The one honest open item,
`:ios_host` execution, is a documented and roadmap-tracked deferral to Phase 199 SC5, not a
phase 197 failure.

---

_Verified: 2026-11-05T20:20:00Z_
_Verifier: Claude (gsd-verifier)_
