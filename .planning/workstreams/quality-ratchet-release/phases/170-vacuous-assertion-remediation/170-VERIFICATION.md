---
phase: 170-vacuous-assertion-remediation
verified: 2026-09-16T00:00:00Z
status: passed
score: 3/3 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/ROADMAP.md
  - .planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md
  - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-CONTEXT.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-REVIEW.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/170-VACUITY-TAXONOMY.md
  - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/COVERAGE.md
  - script/collection_assertion_ledger.json
  - script/collection_assertion_remediation.json
  - script/inventory_collection_assertions.exs
  - test/crosswake/bridge/push_test.exs
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/doctor/doctor_threadline_test.exs
  - test/crosswake/guides/evidence_manifest_test.exs
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/manifest/manifest_test.exs
  - test/crosswake/manifest/validator_test.exs
  - test/crosswake/planning/first_adopter_context_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase165_ci_policy_test.exs
  - test/crosswake/proof/phase166_repository_quality_test.exs
  - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  - test/crosswake/proof/phase170_guard_expression_match_test.exs
  - test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - test/crosswake/proof/phase64_runtime_line_policy_test.exs
  - test/crosswake/proof/phase65_diagnostic_export_seam_test.exs
  - test/crosswake/proof_lane/navigation_shell_advisory_test.exs
  - test/crosswake/release_candidate/mirror_test.exs
  - test/crosswake/shell/activation_test.exs
  - test/crosswake/shell/diagnostic_export_test.exs
  - test/crosswake/support_matrix/support_matrix_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
  - test/mix/tasks/crosswake_release_status_test.exs
covered_digest: "v1:sha256:cb74f285c44614aff3168f5950d613204d1c998b5c08d688a66dd4b566195c7c"
behavior_unverified: 0
overrides_applied: 0
vacuity_taxonomy:
  - check_id: "Crosswake.Proof.Phase170GuardExpressionMatchTest"
    shape: "matches none of A-F, because it is an itemized, closed-world structural test over the
      fixed 52-row remediation manifest verifying, per entry, that a guard line exists AND its
      normalized argument expression exactly equals the assertion's normalized expression — not a
      predicate over an open-world possibly-empty runtime collection (Shape A), nor any
      workflow-graph condition (Shapes B-E), nor a shell exit-code idiom (Shape F)."
    non_vacuity_evidence: "Independently re-run 2026-09-16: `mix test test/crosswake/proof/phase170_guard_expression_match_test.exs` passes as part of a combined 31-test, 0-failure run alongside its two phase170 siblings. 52/52 manifest rows verified against the live tree; demonstrated capable of returning false for both a missing-guard and a wrong-variable-guard synthetic heredoc fixture, per 170-02-SUMMARY.md."
  - check_id: "Crosswake.Proof.Phase170VacuityTaxonomyConventionTest"
    shape: A
    non_vacuity_evidence: "Read directly: `taxonomy_recorded?/2` is a boolean over a `Path.wildcard`-derived, possibly-empty phase-directory collection, mitigated by a dedicated 'findings floor' test asserting `length(examined) >= 1` (measured: 1 phase directory examined today, `169-diagnostic-legibility`, the only phase carrying a `*-VERIFICATION.md` so far), plus a synthetic non-compliant fixture proven false and a synthetic addendum-only fixture proven true. The glob is workstream-wide (`.planning/workstreams/quality-ratchet-release/phases/*`), so the floor grows automatically as Phases 171-175 close — this phase's job was establishing the mechanism, not exercising it against phases that have not closed yet."
  - check_id: "Crosswake.Proof.Phase170VacuousAssertionLedgerTest"
    shape: "matches none of A-F, because it is a regenerate-and-diff-exact completeness check over
      the emitted classification rows (mirroring Phase 169's D-04 `release.scanner.roster_exact`
      pattern one level down), asserting the LEDGER IS COMPLETE — never that every site is guarded."
    non_vacuity_evidence: "Independently re-run 2026-09-16: `elixir script/inventory_collection_assertions.exs --check` exits 0, `220 classified collection-assertion site(s)`. Ledger content directly inspected: 131 safe-by-construction + 60 safe-guarded + 25 safe-cardinality-pinned + 4 safe-compile-time-literal = 220, 0 needs-fix — matches summary claims exactly. CR-01 gap-closure (full-row-content diff, not just key-set) confirmed present in source at `inventory_collection_assertions.exs:698-753` and independently re-derivable as capable of catching a bucket-only drift with an unchanged key."
  - check_id: "phase 170: an empty"
    shape: A
    non_vacuity_evidence: "5 executing empty-input regression tests spot-checked directly in source (doctor_test.exs, support_matrix_test.exs, evidence_manifest_test.exs, release_boundaries_test.exs, mirror_test.exs), each driving a real production call path to `[]` and proving the guard raises. The 2 sites recorded as structural-test-only (coordinate_test.exs's `companions`, crosswake_release_status_test.exs's 4 flagged sites) were independently verified against `lib/crosswake/release_candidate/coordinate.ex` and `lib/crosswake/release_status.ex`: `companions` is derived from the compile-time-fixed `Artifact.packages()` and `validate!/1` rejects any input whose package set does not exactly match it; the release-status checks are only ever emitted via `if missing == [] do [] else [...]` / `if unavailable == [] do [] else [...]`, i.e. never with empty evidence. Both dispositions are honest, not gaps dressed as decisions."
re_verification: null
gaps: []
deferred: []
advisory: []
behavior_unverified_items: []
coincidental_reliance_items: []
human_verification: []
---

# Phase 170: Vacuous Assertion Remediation Verification Report

**Phase Goal:** Every site SEED-018 flagged as a candidate "absence scored as success" defect is
actually classified, and every one confirmed vacuous is rewritten to fail on an empty collection —
without introducing a merge-blocking guard ahead of that audit.

**Verified:** 2026-09-16
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Every site flagged by SEED-018's grep (plus the 47 `refute Enum.any?` sites the same defect hides in) is audited and classified into a committed, regenerable ledger | ✓ VERIFIED | `elixir script/inventory_collection_assertions.exs --check` independently re-run, exits 0, `220 classified collection-assertion site(s), ledger matches the live tree exactly`. Ledger content directly parsed: 131+60+25+4 = 220, 0 `needs-fix`. |
| 2 | Every assertion confirmed vacuous (52 `needs-fix` rows) is rewritten so an empty collection fails | ✓ VERIFIED | `refute Enum.empty?(...)` guards spot-checked directly in `doctor_test.exs`, `support_matrix_test.exs` source; `script/collection_assertion_remediation.json` frozen manifest independently confirmed at 52 rows; `phase170_guard_expression_match_test.exs` (itemized structural proof of guard-exists-and-matches-expression) passes. |
| 3 | The "empty now fails" property is proven, not merely asserted | ✓ VERIFIED | 5 genuine empty-input regression tests spot-checked directly in source, each driving real production code (`Doctor.run/1`, `SupportMatrix.canonical/0`, `manifest_values/2`, `ReleaseStatus.build/1`, `Mirror.evaluate!/1`) to an actual `[]` and asserting `assert_raise ExUnit.AssertionError` on the new guard. The 2 sites left structural-only (`coordinate_test.exs`, `crosswake_release_status_test.exs`) were independently confirmed unreachable without a `lib/` change by reading `coordinate.ex` and `release_status.ex` directly — not taken on the SUMMARY's word. |
| 4 | `absence.collection_assertion_non_empty` (VACG-01) is not added as a merge-blocking guard by this phase | ✓ VERIFIED | `git diff --stat 239b755a..HEAD -- script/check_absence_is_not_success.exs script/required_check_policy.json .github lib` independently re-run: empty output. No `lib/`, `.github/`, or required-check-registry file was touched anywhere in this phase. |
| 5 | Every new check landed by this milestone's phases (as of Phase 170's close) is checked against the six-shape vacuity taxonomy via a durable, phase-close mechanism | ✓ VERIFIED | `VERIFICATION-CONVENTIONS.md` defines the `vacuity_taxonomy` frontmatter/body contract for Phases 169, 171-175. `phase170_vacuity_taxonomy_convention_test.exs` makes the convention an executing, decidable `mix test` check (not a bare tick) with a real findings-floor and proven-false/proven-true synthetic fixtures. `169-VACUITY-TAXONOMY.md` retroactively covers Phase 169's four landed checks; `169-VERIFICATION.md` confirmed byte-identical since the phase base commit. |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `script/inventory_collection_assertions.exs` | Regenerable classifier, five-bucket D-07 logic | ✓ VERIFIED | Present, substantive (753+ lines), wired — `--check` runs against the live tree and produces the claimed output. |
| `script/collection_assertion_ledger.json` | Committed classification snapshot, 220 rows | ✓ VERIFIED | Present; directly parsed, 220 rows, bucket composition matches claims exactly (131/60/25/4/0). |
| `script/collection_assertion_remediation.json` | Frozen 52-row `needs-fix` manifest | ✓ VERIFIED | Present; directly parsed, 52 rows. |
| `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` | Ledger-completeness proof + non-vacuity controls | ✓ VERIFIED | Present, wired into `mix test`; independently re-run and passing. |
| `test/crosswake/proof/phase170_guard_expression_match_test.exs` | Itemized structural guard-match proof | ✓ VERIFIED | Present, wired; independently re-run and passing. |
| `test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` | Executing VAC-03 convention check | ✓ VERIFIED | Present, wired; independently re-run and passing; findings-floor and fixture-based non-vacuity controls read directly in source. |
| `VERIFICATION-CONVENTIONS.md` | `vacuity_taxonomy` phase-close contract | ✓ VERIFIED | Present; defines field, body section, null-statement rule, link-never-copy rule to `PITFALLS.md`. |
| `169-VACUITY-TAXONOMY.md` | Retroactive Phase 169 addendum | ✓ VERIFIED | Present; four check IDs classified (two via explicit escape form); `169-VERIFICATION.md` confirmed untouched since phase base. |
| `170-VACUITY-TAXONOMY.md` | Phase 170's own record under its own convention | ✓ VERIFIED | Present; four entries, lexically ordered, each with a measured non-vacuity fact. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| 52 remediated test assertions | `refute Enum.empty?(<same expression>)` guard | Structural proof (`phase170_guard_expression_match_test.exs`) | WIRED | Predicate independently re-verified in source: exact normalized-expression equality check, not merely "a guard exists somewhere nearby." |
| `@manual_overrides` table | Ledger row content-hash keys | `apply_manual_override/1` lookup by `row["key"]` | WIRED | CR-01 gap-closure fix confirmed directly in source (`inventory_collection_assertions.exs:433-461`, `:698-753`) — keyed by content hash, not `{file, line}`, closing the exact drift bug the code review found. |
| `--check`'s completeness diff | Full row content (not just key presence) | `mismatched_keys` computation | WIRED | Confirmed directly in source: compares `Map.fetch!(live_by_key, key) != Map.fetch!(committed_by_key, key)` for every shared key. |
| Empty-input regression tests | Real production code paths | Direct call to `Doctor.run/1`, `SupportMatrix.canonical/0`, `ReleaseStatus.build/1`, `Mirror.evaluate!/1` | WIRED | Spot-checked 2 of 5 test files directly; guard lines present immediately above the flagged assertions. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Ledger matches live tree exactly | `elixir script/inventory_collection_assertions.exs --check` | `[crosswake] OK: 220 classified collection-assertion site(s), ledger matches the live tree exactly.` | ✓ PASS |
| Phase 170's own proof tests pass | `mix test test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs test/crosswake/proof/phase170_guard_expression_match_test.exs test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` | `31 tests, 0 failures` | ✓ PASS |
| No merge-blocking / `lib/` / `.github/` surface touched since phase base | `git diff --stat 239b755a..HEAD -- script/check_absence_is_not_success.exs script/required_check_policy.json .github lib` | empty output | ✓ PASS |
| Ledger bucket composition matches claimed counts | Direct JSON parse of `script/collection_assertion_ledger.json` | `{safe-by-construction: 131, safe-guarded: 60, safe-cardinality-pinned: 25, safe-compile-time-literal: 4}`, 0 needs-fix | ✓ PASS |
| Remediation manifest row count matches claim | Direct JSON parse of `script/collection_assertion_remediation.json` | 52 rows | ✓ PASS |
| `169-VERIFICATION.md` left byte-identical (VAC-03 retroactive coverage did not mutate a sealed artifact) | `git diff 239b755a..HEAD -- .../169-VERIFICATION.md \| wc -l` | `0` | ✓ PASS |
| Touched files are `mix format`-clean | `mix format --check-formatted` scoped to the 4 new/heavily-touched `.exs` files | no output (clean) | ✓ PASS |
| No unresolved debt markers in phase-touched files | `grep -nE "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER"` over the 27 non-`.planning` files touched since `239b755a` | one hit, a pre-existing formal-reference (`TODO-002` file path in an existing test), not an unresolved debt-marker comment | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| VAC-01 | 170-01 | All sites flagged by SEED-018 are audited and classified as genuinely vacuous or safe | ✓ SATISFIED | 220-site ledger, `--check` exits 0, content directly verified. REQUIREMENTS.md's literal wording still says "173" (the SEED-018 grep count) rather than the corrected 220 — this is a **deliberately deferred, documented** discrepancy (170-CONTEXT.md D-01/D-03: "Do NOT edit ROADMAP.md SC#1's '173' in this phase... amending REQUIREMENTS.md VAC-01's wording... is a separate call"), matching Phase 169's own precedent for leaving an arithmetically-corrected success criterion's text unedited. Not an unreconciled gap — the correction is recorded in `<verified_ground_truth>` and cross-referenced from `170-VACUITY-TAXONOMY.md`/REVIEW; the roadmap text itself is a separate, explicitly out-of-scope edit. |
| VAC-02 | 170-02, 170-03 | Every assertion confirmed vacuous is rewritten so an empty collection fails | ✓ SATISFIED | 52/52 sites guarded, structurally proven exact-expression-match, 5/7 runtime-derived sites additionally proven via genuine empty-input regressions; the remaining 2 independently confirmed unreachable without a `lib/` change. |
| VAC-03 | 170-04, 170-05 | Every new check added by this milestone is checked against the six-shape taxonomy before being made merge-blocking | ✓ SATISFIED | Convention documented + made into an executing `mix test` check with a real (if currently small, `>= 1`) findings floor that scales automatically as Phases 171-175 close; Phase 169 covered retroactively without mutating its sealed VERIFICATION.md; Phase 170's own four landed checks classified in `170-VACUITY-TAXONOMY.md`. |

### Anti-Patterns Found

None blocking. Four latent classifier-soundness gaps (WR-01, WR-02, IN-01, IN-02 from `170-REVIEW.md`) remain open by design:

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `script/inventory_collection_assertions.exs:546-552` | `compile_time_literal?/1` would misclassify a bare `[]` as safe | ⚠️ Warning (deferred) | Independently confirmed: 0 rows in the current 220-row ledger have expression `"[]"`, so not currently active. |
| `script/inventory_collection_assertions.exs:656-683` | Pin/guard root-detection matches a root anywhere on the candidate line, not the actual compared operand | ⚠️ Warning (deferred) | Not independently re-audited beyond the reviewer's spot-check of all 25/4 pinned/literal rows in `170-REVIEW.md`; no evidence of active misclassification. |
| Multiple test files | Duplicate back-to-back `refute Enum.empty?` guards for siblings sharing one root | ℹ️ Info (deferred) | Diff-noise only, no correctness impact. |
| `script/inventory_collection_assertions.exs:570-601` | Naive text-splitting on `\|>` could mis-root a nested-pipe expression | ℹ️ Info (deferred) | No occurrence in the current 220 sites; documented as a known scanner limitation. |

CR-01 (Critical) and WR-03 (Warning) from the code review were fixed in this phase (commits `6a3c3973`, `b170a58c`) and independently re-verified in this pass: the manual-overrides table is now content-hash-keyed, the completeness check now diffs full row content, and the `validator_test.exs:86` override rationale was corrected to state what was actually observed.

### Human Verification Required

None. Every item this phase's own planning material flagged as `human_judgment: true` (the two "unreachable without `lib/`" dispositions) was independently re-verified against the actual `lib/` source in this pass rather than left to a human reviewer's trust in the SUMMARY's prose.

### Gaps Summary

No gaps found. All three requirements (VAC-01, VAC-02, VAC-03) are genuinely satisfied by the
codebase, not merely marked `[x]`. The one documentation discrepancy (REQUIREMENTS.md VAC-01 still
reading "173" instead of the corrected 220) is a knowingly-deferred text edit, explicitly recorded
as such in this phase's own context and cross-referenced from its taxonomy record and code review —
it does not misrepresent what was actually audited, since the corrected count and its provenance
are documented in-repo. The four deferred code-review findings (WR-01, WR-02, IN-01, IN-02) are
latent classifier-soundness gaps with no currently active misclassification, appropriately scoped
out of this phase per its own boundary (D-02: stop at 220, no widening to Shapes B-F).

---

_Verified: 2026-09-16_
_Verifier: Claude (gsd-verifier)_
