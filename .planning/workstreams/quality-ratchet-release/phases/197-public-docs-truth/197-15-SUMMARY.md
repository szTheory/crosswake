---
phase: 197-public-docs-truth
plan: 15
subsystem: public-docs
tags: [docs, unreleased-claims, d-26, renderer, generated-guides, guard-test, docs-01, docs-02]

requires:
  - phase: 197-public-docs-truth
    provides: "197-11 CHANGELOG [Unreleased] bullets naming schema 1.2.0 and :ios_host; 197-01 script/mix_test_gate.sh and script/docs-report"
provides:
  - "Qualifier 'not in a published release yet; see CHANGELOG [Unreleased]' on every :ios_host section of capability_map, support_matrix, native_shell and native_shell_upgrade"
  - "Same qualifier on every manifest 1.2.0 section of compatibility, native_shell_upgrade, support_matrix and architecture"
  - "Crosswake.Guides.UnreleasedClaimQualifierTest: section-scoped guard over eight claim pairs, non-vacuity per pair, removal control, fence-only control"
  - "ROADMAP Phase 199 success criterion 6: qualifiers and guard test come off in the human PR that records 0.2.12 as published"
  - "native_shell.md entry-route sentence matching valid_entry/1 and entry_exists/2"
affects: [197-13, 197-14, 199]

actuals:
  tokens: 9000
  tasks: 3
  commits: 4
plan_head_before: a8d9c31c4efc4163fffc10f0608fa338b1afa779
plan_head_after: dac407310938628bb9ff177ddb1257b2ae54ae0f

tech-stack:
  added: []
  patterns:
    - "A claim about unreleased behavior is guarded per heading-delimited section: the token and the qualifier are matched in out-of-fence prose only, so a qualifier inside a code block does not count"
    - "Generated guides change only through their renderer plus mix crosswake.docs.sync; the renderer-pinned legend line stays byte-for-byte and the qualifier is a new element beside it"

key-files:
  created:
    - test/crosswake/guides/unreleased_claim_qualifier_test.exs
  modified:
    - lib/crosswake/capability_map/renderer.ex
    - lib/crosswake/support_matrix/renderer.ex
    - lib/crosswake/planning/first_adopter_context.ex
    - guides/capability_map.md
    - guides/support_matrix.md
    - guides/native_shell.md
    - guides/native_shell_upgrade.md
    - guides/compatibility.md
    - guides/architecture.md
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md

key-decisions:
  - "The guard reads the heading line together with the body, so a section whose heading names the token (for example 'Manifest 1.2.0: ...') must still carry the qualifier in its prose."
  - "Each qualifier sentence sits on one physical line, because the guard matches the substring 'not in a published release yet' and a Markdown line wrap inside it would hide it."

requirements-completed: []

duration: 25min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 15: Unreleased claims qualified in the linked guides Summary

**Every linked guide section that names the `:ios_host` declaration or manifest schema `1.2.0` now says no published release has it yet and points to CHANGELOG `[Unreleased]`, the two generated guides got it through their renderers, and one network-free merge-blocking test keeps all eight claim pairs qualified until Phase 199 removes them.**

## Accomplishments

- Task 1 (tracer, `de366a17`): one sentence added to `ios_host_setup_section/0` in the capability-map renderer; `mix crosswake.docs.sync` regenerated `guides/capability_map.md` in the same commit as the renderer. `UnreleasedClaimQualifierTest` created with `sections/1`, `unqualified_sections/2`, `@claims`, a per-pair non-vacuity test, and two controls: the qualifier sentence removed from a copy of the capability map (asserted to differ from the original) is flagged as `["## Declared iOS Host Setup"]`, and a qualifier that appears only inside a code fence does not count. ROADMAP Phase 199 got success criterion 6 by a scoped one-line edit.
- Task 2 (`c4942203`): support-matrix renderer got the `:ios_host` sentence in `ios_host_generation_section/0` and a new string element with the `1.2.0` qualifier right after the existing `1.1.0 -> 1.2.0 (Phase 181)` line, which is unchanged (one occurrence). `native_shell.md` and `native_shell_upgrade.md` (both the `:ios_host` section and the host-command section) are qualified. In `native_shell.md` the clause "the entry must be declared by the selected router" is replaced: the declaration requires a non-empty `entry_route_id`, and `mix crosswake.gen.shell ios` refuses an entry the selected router does not declare. Claims grew to six.
- Task 3 (`dac40731`): qualifier directly under the `compatibility.md` heading `## Manifest 1.2.0: the host-command seam (iOS only)`, and in the `architecture.md` sentence that introduces the manifest example (the example block is unchanged). Claims grew to eight.

## Prior-text grep (Task 2 instruction)

`grep` over `test/`, `lib/`, `guides/` and `README.md` for "declared by the selected router" found only the one line in `guides/native_shell.md`; no test pins the rewritten sentence. `crosses into the shell` and the compatibility heading sentence are likewise not pinned. No other test needed updating.

## Verification Run (all through `script/mix_test_gate.sh`; per-task gates in the plan, final state shown)

- CI docs step (final): `mix crosswake.docs.sync --check` passes; the docs test set ran 283 (5 excluded), failures 0, min 255: PASS.
- `docs.sync_test` plus `ios_host_config_test`: ran 22, min 22: PASS. Guard test plus `docs.sync_test`: ran 11, min 8: PASS.
- `unreleased_claim_qualifier_test`, `compatibility_test`, `architecture_code_walkthrough_test`, `host_command_seam_guide_test`: ran 46, min 29: PASS.
- Extra sweep of the other tests that read these guides (adoption-context scan, docs_report, phase52, phase155, phase165, phase166, adopter_profile, phase48, support_matrix, capability renderer, first_adopter_context): ran 201, failures 0: PASS.
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted` clean on every changed Elixir file. Phase 199 `awk` check exit 0.
- Acceptance greps: `not in a published release yet` counts: capability_map 1, support_matrix 2, native_shell 1, native_shell_upgrade 2, compatibility 1, architecture 1. The pinned legend line count is 1. `non-empty \`entry_route_id\`` in native_shell 1. `@claims` has 8 entries. The old entry clause is absent. `git log origin/main..HEAD -- .planning/config.json` prints nothing.
- `script/docs-report --detail` (report only, exit 0): `docs.warnings total=197 extras=2`, `docs.links broken=0 checked=234 files=30`, `docs.leaks hits=95 allowlisted=0 stale_allowlist=0 files=30`. Warnings and leaks equal the 197-01 baseline (197 and 95); no broken link; the new sentences added no leak hit.
- Privacy scan (`bash privacy-193.sh`, absolute paths) clean before each of the four commits. Nothing was pushed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `mix crosswake.adoption_context.scan` failed on `script/docs-report`**
- **Found during:** Task 1 verify (the plan's CI-docs-step command)
- **Issue:** the scan reports `routing.unclassified_path script/docs-report`; the extensionless script was added in 197-01 and never classified. CI's docs step runs this scan, so it would fail on the PR. Same failure and same fix as `106e5a54` for `script/bearings-report`.
- **Fix:** added `"docs-report"` next to `"bearings-report"` in the extensionless scannable basenames in `lib/crosswake/planning/first_adopter_context.ex`. `first_adopter_context_test.exs` ran 34, failures 0.
- **Files modified:** lib/crosswake/planning/first_adopter_context.ex
- **Commit:** `cedfa2a8` (its own commit, ahead of Task 1)

### Process

**2. Local scan still exits 1 because of the user's untracked files.** After the fix, the only remaining `routing.unclassified_path` lines are the `.err` files under the untracked `.review-diagnostics/` directory, which belongs to the user and is not in a CI checkout. They were left alone, as instructed; the scan output with those lines filtered out is empty. A clean-checkout run (CI) is expected to exit 0.

**3. Four commits.** Per the one-commit-per-task protocol each task has its own commit (Task 3 uses the plan's message); plus the deviation fix above. The plan's Task 3 text asked for one commit of its last files; it holds those.

**4. Task 2 `ios_host` placement.** In `native_shell.md` the qualifier follows the section's first paragraph sentences (before the config block) rather than the very first sentence; it is in the same section as both `:ios_host` mentions, which is what the guard requires.

**Total deviations:** 1 auto-fixed (Rule 3), 3 process notes. **Impact:** none on scope; the fix removes a CI failure that 197-01 introduced.

## Known Stubs

None.

## Threat Flags

None. Doc text and tests only; no endpoint, auth path or schema change. T-197-38 (shipped-claim repudiation) and T-197-39 (generated-guide tampering) are mitigated as planned.

## Requirements

DOCS-01 and DOCS-02 are also carried by plans 13 and 14 (and others), so neither is marked complete here.

## Self-Check: PASSED

Files found: test/crosswake/guides/unreleased_claim_qualifier_test.exs and all modified files above. Commits found as ancestors of HEAD: `cedfa2a8`, `de366a17`, `c4942203`, `dac40731`.
