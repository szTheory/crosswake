---
phase: 197
reviewers: [codex]
reviewed_at: 2026-11-05T13:02:39Z
plans_reviewed: [197-01-PLAN.md, 197-02-PLAN.md, 197-03-PLAN.md, 197-04-PLAN.md, 197-05-PLAN.md, 197-06-PLAN.md, 197-07-PLAN.md, 197-08-PLAN.md, 197-09-PLAN.md, 197-10-PLAN.md, 197-11-PLAN.md, 197-12-PLAN.md, 197-13-PLAN.md, 197-14-PLAN.md]
models:
  codex: "gpt-6-luna (reasoning=high)"
model_sources:
  codex: "banner"
---

# Cross-AI Plan Review — Phase 197

<!-- gsd:plan-revision-conflicts:begin -->
## Plan-Revision Conflicts

<!-- gsd:plan-revision-conflicts:end -->

Lanes that did not produce a review: cursor (authentication required), opencode (no assistant text), antigravity (headless read_file permission auto-denied). Only codex reviewed.

## Codex Review

## 197-01

**Summary:** Adds the report-only docs checker, leak counter, link checker and fixture tests. The chosen scan scope matches the 30 Markdown extras in [`mix.exs`](/Users/jon/projects/crosswake/mix.exs:124).

**Strengths:** The plan covers unreadable inputs, empty extras, non-vacuity and mutation controls. It also keeps warning counts explicitly unmeasured until the next plan, consistent with the report’s UNVERIFIED contract in [197-CONTEXT.md](/Users/jon/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-CONTEXT.md:111).

**Concerns (MEDIUM):** The allowlist plan says to handle unparseable JSON, but does not require validating a valid JSON document’s schema or entry types. A syntactically valid but malformed file could be treated as an empty allowlist or crash the report, contrary to the UNVERIFIED-on-bad-input rule. The existing report pattern checks decoded structure before using it ([`bearings_report.exs`](/Users/jon/projects/crosswake/script/bearings_report.exs:85)).

**Suggestions:** Add controls for a wrong schema version, missing `entries`, and entries missing `file`, `text`, or `reason`; each should yield exit 2.

**Risk Assessment:** MEDIUM.

## 197-02

**Summary:** Completes the warnings counter, records baseline counts before doc edits, and amends the phase requirements and state.

**Strengths:** The baseline precondition checks the measured files against `origin/main`, and the plan records the SHA and `ex_doc` version as required by D-19.

**Concerns (MEDIUM):** The amendment task updates the Phase 197 plan list from 9 to 14 plans when needed, but does not update the roadmap progress row, which also says `0/9` ([`ROADMAP.md`](/Users/jon/projects/crosswake/.planning/workstreams/quality-ratchet-release/ROADMAP.md:239), [`ROADMAP.md`](/Users/jon/projects/crosswake/.planning/workstreams/quality-ratchet-release/ROADMAP.md:307)). That leaves the roadmap internally inconsistent after the task.

**Suggestions:** Update the progress row to `0/14` as part of the same roadmap edit.

**Risk Assessment:** MEDIUM.

## 197-03

**Summary:** Fixes the carried fetch, failure-reason, Maven identity and tool-inventory defects before the docs leg is added.

**Strengths:** The plan targets the actual loose POM checks and error conflation in [`verify_published_cleanroom.sh`](/Users/jon/projects/crosswake/script/verify_published_cleanroom.sh:109) and [`verify_published_cleanroom.sh`](/Users/jon/projects/crosswake/script/verify_published_cleanroom.sh:162). Its fixture controls distinguish missing releases from parse and resolve failures.

**Concerns (LOW):** The POM parser strips XML blocks with line-oriented text tooling. The fixture plan should confirm the real published POM’s formatting and nesting are handled, not just the compact synthetic fixture.

**Suggestions:** Add a fixture shaped like the actual published POM, including parent and dependency sections around the project coordinates.

**Risk Assessment:** LOW.

## 197-04

**Summary:** Adds the commit-pinned docs leg, marker parser, Phoenix host generation and scrubbed execution environment.

**Strengths:** It extends the existing three-leg script explicitly ([`verify_published_cleanroom.sh`](/Users/jon/projects/crosswake/script/verify_published_cleanroom.sh:40)) and includes an environment sentinel test for caller credentials.

**Concerns (LOW):** Documented run blocks have no per-step timeout. A network command or broken task could leave the local proof hanging; the plan acknowledges the run is local but does not bound it.

**Suggestions:** Add a configurable, bounded timeout for each run block, or explicitly define how operators interrupt a stuck leg and preserve its failure evidence.

**Risk Assessment:** MEDIUM.

## 197-05

**Summary:** Switches the docs leg’s default source to the Hex tarball and proves host generation against the real toolchain.

**Strengths:** This keeps docs and code tied to one published artifact, as required for the later release run. The pinned Phoenix generator already has a repository precedent in [`verify_companion_cleanroom.sh`](/Users/jon/projects/crosswake/script/verify_companion_cleanroom.sh:287).

**Concerns (LOW):** The smoke requires live Hex access and a generator install, so local success depends on registry availability and toolchain behavior. The plan appropriately keeps that smoke separate from the hermetic suite.

**Suggestions:** Preserve the exact failure output if the smoke stops before the intended doctor step, and keep the hermetic tarball cases as the repeatable gate.

**Risk Assessment:** LOW.

## 197-06

**Summary:** Implements six apply modes, substitutions, path guards and the compile harness.

**Strengths:** The path guard and idempotence controls address the main risk of turning fetched documentation into writes. The host files are within the disposable host generated by the docs leg.

**Concerns (LOW):** The plan describes the `deps` insertion anchor precisely, but the other modes’ “anchor missing” behavior is less specific for modes such as `append` and `create`, which do not naturally require an anchor.

**Suggestions:** State which modes have anchors and what each anchor is; state explicitly that `create` and `append` use their own existence/idempotence rules.

**Risk Assessment:** LOW.

## 197-07

**Summary:** Adds `since=` handling, required-step checks, the version-conditional `:ios_host` deferral and an executed-step floor.

**Strengths:** The exemption is explicitly version-bound and named in output. That matches the amended D-04 decision and avoids counting the 0.2.11-unread setting as executed. The source guide confirms the documented setting and reader constraints ([`native_shell.md`](/Users/jon/projects/crosswake/guides/native_shell.md:65)).

**Concerns (LOW):** The floor is intentionally a placeholder until 197-09. If the plan sequence is interrupted before then, the interim floor provides little protection.

**Suggestions:** Keep 197-09 as a hard prerequisite for considering the docs leg complete; do not treat the placeholder floor as phase evidence.

**Risk Assessment:** LOW.

## 197-08

**Summary:** Rewrites the README integration section and install guide as marked, executable steps, with repo-only steps labeled for clone users.

**Strengths:** The planned content follows existing install guidance for the bridge hook, esbuild, attach and iOS host configuration ([`install.md`](/Users/jon/projects/crosswake/guides/install.md:105), [`native_shell.md`](/Users/jon/projects/crosswake/guides/native_shell.md:65)). It also requires the final selftest to run after the last doc edit.

**Concerns (LOW):** The clean-room proof exercises only `:ios_host` as a named deferral against 0.2.11, so the plan correctly relies on 197-09’s independent value validator and reader audit to cover what that run cannot.

**Suggestions:** Keep the final evidence tied to the exact final doc contents, as planned, and fail the plan if either document changes afterward.

**Risk Assessment:** LOW.

## 197-09

**Summary:** Adds the merge-blocking marker and route-consistency tests, pins the executed floor and audits the documented iOS host values.

**Strengths:** The negative controls cover marker removal, repo-only commands, missing wiring tokens, route drift and deferral drift. The value test exercises the real validator, which requires a compiled router and checks production origin rules ([`ios_host_config.ex`](/Users/jon/projects/crosswake/lib/crosswake/shell/ios_host_config.ex:56)).

**Concerns (LOW):** The reader audit is based on an extracted 0.2.11 tarball, but the plan’s audit line format alone does not ensure the extraction itself is successful before marking readers `found`.

**Suggestions:** Make the audit command fail closed on tarball fetch or extraction errors and record its actual exit status, rather than writing a successful line from an assumed reader list.

**Risk Assessment:** LOW.

## 197-10

**Summary:** Removes copied release versions from the companion matrix, adds Hex links, revises the drift test and records one live registry check.

**Strengths:** This follows D-10’s reason for removing hand-kept versions: release-please changes the manifest in its PR without editing the guide ([197-CONTEXT.md](/Users/jon/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-CONTEXT.md:85)).

**Concerns (MEDIUM):** The plan expects the test helper to yield five extracted companion rows, but the current helper explicitly returns only two package manifests ([`phase132_compat_matrix_drift_test.exs`](/Users/jon/projects/crosswake/test/crosswake/proof/phase132_compat_matrix_drift_test.exs:360)). The guide has five rows ([`companion_compatibility.md`](/Users/jon/projects/crosswake/guides/companion_compatibility.md:24)). The stated row-set equality cannot pass as written.

**Suggestions:** Define the intended set explicitly: either compare the two extracted companion manifests to their two rows and separately guard the full five-row matrix, or update the source of expected rows so it genuinely contains all five.

**Risk Assessment:** MEDIUM.

## 197-11

**Summary:** Removes stale CHANGELOG release claims while preserving `publish.parity` through a version-free pointer rule.

**Strengths:** The proposed predicate preserves the existing manifest/version ordering checks and replaces only the stale sentence match in [`publish_readiness.ex`](/Users/jon/projects/crosswake/lib/crosswake/doctor/publish_readiness.ex:1083). The broken-copy controls test the actual readiness function against the real repository context.

**Concerns (LOW):** The plan changes a doctor readiness rule as part of a docs phase. It has focused regression coverage, but this adds product behavior beyond editing public copy.

**Suggestions:** Keep the change limited to the candidate predicate and retain the planned checks over the doctor suite and closeout verifier.

**Risk Assessment:** LOW.

## 197-12

**Summary:** Corrects Android UAT claims, adds replay telemetry documentation and records the twin receipt’s attested commit.

**Strengths:** The replay event details match the emitting code: prefix `[:crosswake, :offline, :replay]`, suffix `:stop`, measurements and metadata ([`telemetry.ex`](/Users/jon/projects/crosswake/lib/crosswake/telemetry.ex:127), [`telemetry.ex`](/Users/jon/projects/crosswake/lib/crosswake/telemetry.ex:362)). The Android family test is designed as two-way set equality with a non-vacuity guard.

**Concerns (LOW):** None material found against the cited source.

**Suggestions:** Keep the family parser scoped to the named heading, as the plan specifies.

**Risk Assessment:** LOW.

## 197-13

**Summary:** Records the final suite, report after-counts, baseline ordering and real negative-control evidence.

**Strengths:** The ordering check proves the baseline commit precedes the first doc-touching commit, which is the core D-19 guarantee. The plan records command exit codes rather than relying on piped output.

**Concerns (LOW):** None material found against the cited source.

**Suggestions:** Ensure the after-count report uses the final HEAD SHA after all doc changes and before any subsequent evidence-only commits, as planned.

**Risk Assessment:** LOW.

## 197-14

**Summary:** Runs the privacy scan, pushes the feature branch, performs the real four-leg clean-room run and opens a green PR without merging.

**Strengths:** The plan separates the PR head SHA from the synthetic merge SHA and explicitly leaves merge, tags and publishes behind a fresh one-use approval. This matches the clean-room script’s current all-legs result contract ([`verify_published_cleanroom.sh`](/Users/jon/projects/crosswake/script/verify_published_cleanroom.sh:33)) and the project’s approval boundary.

**Concerns (LOW):** The PR body requires a Claude Code attribution line, but the supplied project instructions do not define that requirement. It may be an execution-environment convention unavailable to a different agent.

**Suggestions:** Confirm the attribution requirement from the applicable executor instructions before including it; keep the privacy scan over the actual final PR body.

**Risk Assessment:** LOW.

## Cross-plan notes

The plans’ dependency order is coherent: the baseline is captured before public-doc edits, the marked docs precede the final report, and the real clean-room run is last. The two concrete plan corrections are to validate the docs allowlist schema in 197-01 and reconcile both the 14-plan count and Phase 197 progress row in 197-02. The 197-10 expected row count also needs to match the actual two-manifest helper or an expanded source set.

Review only; I did not run tests.

---

## Consensus Summary

Single reviewer (codex); no cross-reviewer consensus is possible. Treat these as one grounded reviewer's findings, each with file:line citations.

### Agreed Strengths
None computable (one reviewer). Codex judged the dependency order coherent: baseline before doc edits, marked docs before the final report, real clean-room run last.

### Agreed Concerns
None computable (one reviewer). Codex's MEDIUM findings, highest priority:
- 197-01: allowlist schema not validated; a syntactically valid but malformed file could pass as empty. Add wrong-schema, missing `entries` and missing-field controls that exit 2.
- 197-02: the roadmap progress row still says `0/9` after the amendment; update it to `0/14`.
- 197-10: the drift-test helper returns two manifests but the guide has five rows, so the stated row-set equality cannot pass as written.
- 197-04: no per-step timeout on documented run blocks (rated MEDIUM overall).

### Divergent Views
None.
