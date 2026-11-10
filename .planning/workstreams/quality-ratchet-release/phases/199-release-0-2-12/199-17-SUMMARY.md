---
phase: 199-release-0-2-12
plan: 17
subsystem: docs
tags: [rel-07, sc6, hand-written-guides, changelog, published-0.2.14]
status: complete

requires:
  - phase: 199-release-0-2-12
    provides: "199-15 reader audit (first release 0.2.12 for ios_host, schema 1.2.0, parity ledger; all six CHANGELOG claims found in 0.2.14) and 199-16 generated-guide edits on the closeout branch"
provides:
  - "The five remaining hand-written qualifier sites reworded to name 0.2.12; zero hits for the qualifier phrase under guides and lib on the closeout branch"
  - "CHANGELOG [Unreleased] no longer lists any of the six shipped claims as unpublished"
  - "Full-suite result on the closeout branch head 4d74e27d for the closeout suite floors"
affects: [199-18, 199-19, 199-20]

plan_head_before: d9e11b5567bdfa813621a1668e254e07e78e4954
plan_head_after: 4d74e27db9a04dba20c1e1c9683d6115e8be4219
commits: 4
commits_note: "2 code commits on the WT branch docs/199-record-0-2-14-published (d9e11b55..4d74e27d: fba60249, 4d74e27d) plus 2 evidence commits in the main checkout on docs/199-release-0-2-12 (7263dde6, 8e469216); the SUMMARY commit follows. plan_head_before/after are the WT branch ledger; the main checkout base was f3ddc7ba."

actuals:
  tokens: 16000
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Hand-written guides use the same first-release sentence shape as the renderers: 'read from / emitted from 0.2.12 on; 0.2.11 and earlier do not / emit 1.1.0'"

key-files:
  created: []
  modified:
    - guides/architecture.md
    - guides/compatibility.md
    - guides/native_shell.md
    - guides/native_shell_upgrade.md
    - CHANGELOG.md
    - script/collection_assertion_ledger.json
    - test/crosswake/guides/host_command_seam_guide_test.exs
    - test/crosswake/guides/changelog_unreleased_wording_test.exs
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/docs-truth-199.txt

key-decisions:
  - "All six CHANGELOG bullets were removed, because the 199-15 audit shows every one of the six claims found in 0.2.14. The subsection stays, holding one plain line saying there are no unpublished support claims at this time. No 0.2.12, 0.2.13 or 0.2.14 section was added (Phase 197 policy: releases without a section are on GitHub Releases and hex.pm)."
  - "No hand-written guide here names a version to install, so all five sites use the first-release wording (0.2.12), not 0.2.14."
  - "Guards that pinned shipped claims as unreleased were rewritten in place to assert the opposite, so the test total stays 3256."

requirements-completed: []
---

# Phase 199 Plan 17: Hand-written guides and CHANGELOG stop calling shipped claims unpublished Summary

The five hand-written sites (architecture, compatibility, native_shell, two in native_shell_upgrade) now say the `:ios_host` declaration is read from 0.2.12 on and manifest schema 1.2.0 is emitted from 0.2.12 on, and the CHANGELOG no longer lists the six shipped claims as unpublished. Nothing was pushed or merged.

## What was checked and what happened

- Read the 199-15 audit lines: first release 0.2.12 for `ios_host` and `schema_1_2_0`; all six CHANGELOG claims `0.2.14=found`.
- Task 1 (tracer): reworded the five sites, commit `fba60249` in the worktree. The zero-hit grep for `not in a published release yet` over `guides` and `lib` of the worktree finds nothing; the seven SC6 guides each name 0.2.12; `mix crosswake.docs.sync --check` passes; no added line contains `latest`, `current release` or `[Unreleased]`. The 30 test files that mention these guides ran 422 tests with 0 failures.
- Task 2: removed the six bullets, commit `4d74e27d`. The plan's bullet-count check reports 0 bullets for each of the six claims (want 0). `### Unpublished support claims` and `### Published Hex truth` each appear once; no `## [0.2.12|13|14]` section; the GitHub Releases and hex.pm pointer sentence is untouched. The three plan guard tests ran 36 tests, 0 failures. Every test file mentioning the CHANGELOG, the ledger or "Unpublished support" ran 167 tests, 0 failures.
- Full suite on the closeout branch at `4d74e27d`: `total=3256 excluded=76 ran=3180 failures=0 verdict=PASS`, the same total as after 199-16.
- `script/docs-report` (report only): `docs.warnings total=197 extras=2`, `docs.links broken=0 checked=235`, `docs.leaks hits=95 allowlisted=0`.
- Evidence: `199-EVIDENCE/docs-truth-199.txt` now has nine `site:` lines (four from 199-16, five here).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A guard pinned the removed "Nothing described here is a release" sentence**
- **Found during:** Task 1 (first gate run: 1 failure of 422)
- **Issue:** `host_command_seam_guide_test.exs` "edited guides make no release-done claim" asserted that `native_shell_upgrade.md` contains "Nothing described here is a release", which is false now that the claim shipped. The plan's line 61 rewording had to drop it.
- **Fix:** The test now asserts the new 0.2.12 sentence and refutes the old one; the other refutes in that test are unchanged.
- **Files modified:** `test/crosswake/guides/host_command_seam_guide_test.exs`
- **Commit:** fba60249

**2. [Rule 1 - Bug] Three guards encoded the six shipped CHANGELOG bullets as unreleased**
- **Found during:** Task 2 (plan anticipated this)
- **Issue:** Two tests in `host_command_seam_guide_test.exs` regex-matched the seam and legacy-manifest bullets and asserted "not released" (they would crash with a match error once the bullets left). `changelog_unreleased_wording_test.exs` asserted `:ios_host` is listed as unpublished.
- **Fix:** Rewrote all three in place to assert the bullets are gone and that `native_shell_upgrade.md` still carries the detail the bullets carried (Android unchanged, `mix crosswake.gen.shell ios`, `host_commands_legacy_manifest`). The `:ios_host` one is now a plain string assertion with no collection.
- **Files modified:** the two test files above
- **Commit:** 4d74e27d

**3. [Rule 3 - Blocking] The rewritten `:ios_host` guard left an orphan row in the collection-assertion ledger**
- **Found during:** Task 2
- **Issue:** `script/collection_assertion_ledger.json` listed `changelog_unreleased_wording_test.exs:115`, and `phase170_vacuous_assertion_ledger_test.exs` pins the site counts (289 / 146 / 146).
- **Fix:** Deleted that one row and moved the pins to 288 / 145 / 145 with a dated comment, as 199-16 did for its removal. `inventory_collection_assertions.exs --check` prints OK for 288 sites.
- **Files modified:** `script/collection_assertion_ledger.json`, `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`
- **Commit:** 4d74e27d

**4. [Process] First test-gate attempt ran under zsh**
- zsh does not word-split an unquoted file list, so mix reported no matching paths. Re-run under bash; recorded in the evidence file. Not a code issue.

## Known Stubs

None.

## Threat Flags

None. Documentation and test-expectation edits only.

## Notes for 199-18

- Closeout branch `docs/199-record-0-2-14-published` in `~/projects/crosswake-199-wt`: head `4d74e27d`, clean, four commits ahead of origin/main `cbb90031` (b0daed0f, d9e11b55, fba60249, 4d74e27d), not pushed.
- Suite floor for the closeout: post-edit `total=3256 excluded=76 ran=3180 failures=0`. The baseline had 19 load-timeouts; the post-edit full run had none.
- `guides/install.md:238` still says to see the CHANGELOG `[Unreleased]` section for the release that adds the entry route id; it is not the removed qualifier phrase and the plan forbids touching install.md cleanroom markers, so it was left.
- 199-19 must run the privacy scan on every changed file before the one push; none was run here because nothing was pushed.

## Self-Check: PASSED

- WT commits `fba60249` and `4d74e27d` are on `docs/199-record-0-2-14-published`; evidence commits `7263dde6` and `8e469216` are on `docs/199-release-0-2-12`.
- The qualifier grep over `guides` and `lib` of the worktree has no hits; the CHANGELOG bullet-count check exits 0.
