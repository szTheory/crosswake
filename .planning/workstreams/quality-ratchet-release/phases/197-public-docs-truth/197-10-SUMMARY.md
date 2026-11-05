---
phase: 197-public-docs-truth
plan: 10
subsystem: public-docs
tags: [docs, companion-matrix, drift-test, registry-truth, d-10, d-11, d-12, docs-02]

requires:
  - phase: 197-public-docs-truth
    provides: "197-09 marker test, pinned executed floor and reader audit; 197-01 script/mix_test_gate.sh"
provides:
  - "guides/companion_compatibility.md: version-free matrix (Hex Package, Companion ID, Latest on Hex, Requires `crosswake`, Engine Dependency)"
  - "phase132 drift test without @published_versions: no-version-literal and no-registry-state-word checks over the matrix rows, a 5-row order-independent set floor, and injection/reorder/empty controls"
  - "197-EVIDENCE/release-status-live-197.txt: one live release.status run, rc 0, per-package comparison, all five matrix packages state=ok"
affects: [197-11, 197-14, 199]

actuals:
  tokens: 5200
  tasks: 2
  commits: 2
plan_head_before: 1c6e37997877dbd50ffe203fa5126eddd61a0b73
plan_head_after: f183ed51aa8e5a76ab2058a74ccd85a84c95b0aa

tech-stack:
  added: []
  patterns:
    - "A doc matrix states no registry fact of its own: the test refutes version literals and registry-state words in table rows and presence is read from one recorded live run, never pinned"
    - "Row-set check is order-independent set equality against the package glob, with a floor and controls (two-package set, dropped rows, empty doc, one row short, reorder)"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/release-status-live-197.txt
  modified:
    - guides/companion_compatibility.md
    - test/crosswake/proof/phase132_compat_matrix_drift_test.exs

key-decisions:
  - "The matrix row-set is compared to the 5-package @package_glob set; extracted_companion_mix_files/0 (rulestead and rindle only) is used only where the deleted attribute's two keys were used."
  - "The hexdocs column is removed together with the Current Version column: its rindle cell stated a registry fact nothing checked, and the Latest on Hex page links each package's docs."

patterns-established:
  - "Version literal matching uses whole three-part literals (word boundaries), so 0.2.1 is never matched inside 0.2.11 and two-part requirements such as ~> 0.2 stay legal"

requirements-completed: []

duration: 25min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 10: Version-free companion matrix, no-literal drift test and live registry check Summary

**The companion matrix now carries no version literal and no registry-state wording (a `Latest on Hex` link per package instead), the phase132 drift test proves that with a 5-row set floor and injection, reorder and empty-matrix controls, and one live `mix crosswake.release.status --live` run (rc 0) shows all five matrix packages published with state `ok`.**

## Accomplishments

- Task 1 (tracer, `0b1cbd71`): the `Current Version` and `hexdocs` columns are gone; each row has `[hex.pm/packages/<pkg>](https://hex.pm/packages/<pkg>)`. The `Requires \`crosswake\`` header is unchanged (the phase142 workflow script still greps it). The paragraph about `unpublished`, rindle and rulestead state is deleted, with the rulestead HexDocs claim.
- Other hand-kept version literals in the guide are removed: the sigra companion's own version in the Engine Dependencies paragraph, and the sentences that stated `rulestead` is at 1.0.0 and `rindle` at 0.3.0 (both were false against the registry as well as drift-prone). The friction rule is now version-free: check the engine's latest release on hex.pm; at `1.0.0` or later, pin the engine to its `0.1.x` line.
- Literals kept in the guide, each deliberate: `~> 0.2` and `~> 0.1` (requirement syntax, two-part, drift-tested or contract text); `>= 0.2.0 and < 1.0.0`, `0.1.x`, `0.2.0` (explaining what `~> 0.2` means, the core floor); `>= 0.1.0 and < 1.0.0`, `0.x`, `1.0.0` (explaining the `~> 0.1` cap); Sigra `1.4.x` and `1.5.0` (hypothetical host-side examples, not registry claims). None sits in a table row.
- Test: `@published_versions` and every consumer removed (0 hits); the Current Version format-guard test and `current_version_column_index/1` deleted. New tests: no three-part literal in any matrix row (`matrix_version_literals/1`), no `unpublished|not yet|hexdocs` in any row including the header (`matrix_registry_state_words/1`), whole-literal matching, and the row-set check (`matrix_rows_check/2`, set equality, duplicates refused). Controls: injected `0.1.0` returns `{"crosswake_rindle", "0.1.0"}`; injected `not yet on hexdocs` and a re-added `hexdocs` header cell are caught; the two-package set, all rows dropped, an empty doc and one row short each return `{:error, :row_set_mismatch}`; swapping two rows leaves all three verdicts unchanged. Every control asserts its mutation changed the text. I also confirmed end to end that injecting `0.1.0` into the real guide turns the file red with `proof.compat_03.no_version_literal`, then restored it.
- Task 2 (`f183ed51`): the live run printed the real shape `- <package>: manifest version=<x> live registry state=<ok|...> source=<source>`, so the per-package check was written against it as planned. rc 0, status OK. All five matrix packages report `state=ok source=hex`: rulestead 0.1.1, rindle 0.1.0, sigra 0.1.3, chimeway 0.1.2, threadline 0.1.0. These equal the D-12 discussion-time values; no difference. The evidence file has a `# comparison` section naming each package, its live state, manifest version and whether its matrix row exists. The live command is not in any workflow.

## Task Commits

1. Task 1 (tracer): guide and drift test: `0b1cbd71` (docs)
2. Task 2: live registry evidence: `f183ed51` (docs)

## Verification Run (through `script/mix_test_gate.sh`)

- phase132 plus phase142 files: ran=77, failures=0, min 69: PASS.
- `absence_is_not_success_test.exs`: ran=59, failures=0, min 59: PASS.
- `mix format --check-formatted` on the changed test file: clean.
- Acceptance greps: `@published_versions` 0; `https://hex.pm/packages/crosswake_` 5; `Requires \`crosswake\`` 3; `unpublished|not yet on hexdocs|current HexDocs` 0; no `hexdocs` anywhere in the guide.
- Task 2: rc line present, per-package `state=ok` loop passes, `git grep "release.status --live" -- .github/workflows` finds nothing, `git log origin/main..HEAD -- .planning/config.json` prints nothing.
- Privacy scan (`privacy-193.sh` run with `bash`, absolute paths) clean on the guide, the test and the evidence. No push was made.

## Deviations from Plan

### Process

**1. Two commits instead of one.** The plan's Task 2 text asks for one commit of the guide, test and evidence under `docs(197): make companion matrix version claims registry-true`. The execution protocol is one atomic commit per task and Task 1 is a tracer whose proof gate runs before expansion, so Task 1 carries that message and Task 2 has its own.

**2. Privacy scan ordering.** My first scan attempt before the Task 1 commit failed with exit 2 (invoked through zsh; the script needs `bash`) and I committed before noticing. I then re-ran it correctly: clean, and nothing had been pushed, so no unscanned content left the machine.

### Auto-fixed Issues

None otherwise. The pin check found no new hit: only `phase132_compat_matrix_drift_test.exs` pinned the deleted column, cells and prose; `phase142_release_integrity_test.exs` greps the `Requires \`crosswake\`` text that stays.

## Notes

- The live output includes `REL-17 evidence: BLOCKED (missing_evidence)` under the exact 0.2.11 candidate section while overall status is OK and rc is 0. It is outside this plan's scope (no companion or matrix claim depends on it) and is recorded here, not changed.
- The `rc` line is followed by the `# comparison` section in the evidence file, so it is no longer the last line; the plan's verify greps match it by pattern.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or file access; the live run read hex.pm and the other registries anonymously and changed no external state (the command prints `credentials exercised: false; external state changed: false`).

## Requirements

DOCS-02 is not marked complete: plans 197-11, 197-12, 197-14 and 197-15 still carry it (CHANGELOG truth follows in 197-11).

## Self-Check: PASSED

- guides/companion_compatibility.md, test/crosswake/proof/phase132_compat_matrix_drift_test.exs and 197-EVIDENCE/release-status-live-197.txt exist.
- Commits `0b1cbd71` and `f183ed51` are ancestors of HEAD.
