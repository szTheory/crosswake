---
phase: 181-core-host-command-seam
plan: 08
status: complete
requirements: [SEAM-05]
commits: 3
plan_head_before: 7aca4bf887cc3340ada12022d5f1f39eedd013ab
plan_head_after: 84c8f35
actuals:
  tasks: 2
  commits: 3
---

# Phase 181 Plan 08: Docs and generated truth for manifest 1.2.0 Summary

The generated contract snippet, the rendered support matrix, the CHANGELOG and the compatibility and architecture guides now all say the same thing: manifest schema 1.2.0, additive, iOS-only, bridge protocol 1.1.0 and Android unchanged, nothing released.

## Commits (candidate /private/tmp/crosswake-phase181-impl, branch phase181-impl)

| Task | SHA | Message |
|------|-----|---------|
| 1 (tracer) | b9bdcf9 | docs(181-08): render manifest schema 1.2.0 into contract snippet and support matrix |
| 2 | 23c153e | docs(181-08): state manifest 1.2.0 host-command seam truth in changelog and guides |
| 2 fix | 84c8f35 | docs(181-08): keep seam changelog entry inside existing Unreleased subsection |

Candidate HEAD after last commit: 84c8f35 (clean tree).

## Files changed

- lib/mix/tasks/crosswake.contract.gen.ex: docs_snippet/1 reads Types.manifest_schema_version(); Android vector literal stays 1.1.0.
- docs/_contract_snippet.md (regenerated, shows 1.2.0, bridge 1.1.0).
- lib/crosswake/support_matrix/renderer.ex: legend sentence for the Phase 181 move; guides/support_matrix.md regenerated.
- test/crosswake/support_matrix/renderer_test.exs: new test for the sentence.
- CHANGELOG.md, guides/compatibility.md (new "Manifest 1.2.0: the host-command seam" section with a 1.2.0 row and the host_command_seam_version comparison rule), guides/architecture.md (example now 1.2.0, one sentence on per-route host_commands).

## Verification

- contract.gen: exit 0; git diff against 96e5a63 on Android paths and both bridge_contract_vectors.json: clean.
- docs.sync --check: 0. guides/capability_map.md and its two sources: byte-identical to 96e5a63.
- Support-matrix + docs-sync + contract tests: 87 tests, 0 failures. Guides: 182 tests, 0 failures.
- Final full suites after last commit: root `MIX_ENV=test mix test` 2209 tests, 0 failures (78 excluded); examples/phoenix_host 150 tests, 0 failures (run after commit 2; commit 3 only moved a CHANGELOG bullet).

## Deviations

**[Rule 1 - Bug] CHANGELOG heading broke a pinned fixture.** My first CHANGELOG entry was a new `###` subsection under Unreleased. The doctor publish-readiness fixture (test/fixtures/proof/phase52_publish_readiness.json) pins the list of Unreleased subsections, so Phase52OperatorTruthTest and a Phase135 deferred-failures test failed in the full suite. The guides-only test run did not catch it. Fix: the entry is now a bullet under the existing "Unpublished support claims" subsection (commit 84c8f35); fixture untouched.

Compatibility 1.2.0 row was added as a small table in a new section rather than inside the existing change-type table, to avoid disturbing that table's tested shape.

## Next action

Execute 181-09 (remaining D-20 guides: bridge.md, native_shell_upgrade.md, generated iOS template README). Note for 181-09: any new `###` heading in CHANGELOG Unreleased breaks the phase52 readiness fixture.

## Self-Check: PASSED
