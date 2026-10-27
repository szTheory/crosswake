# Phase 196: Spec and structure ratchet - Context

**Gathered:** 2026-10-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing offline, policy and bridge specifications reject empty evidence, and protect existing module structure against regression. Covers SPEC-01..05, ARCH-01..03 and the accepted GR-06 derived-secret grammar debt from Phase 195. Phase 195 is complete; this discussion does not reopen its general masking scope.

No new runtime capability, dependency framework, Android feature, emulator/device claim, release operation, or recurring mutation lane. The adopter lane remains parked. Implementation and the real Muex pilot follow planning; this context is not evidence that those outcomes have passed.
</domain>

<decisions>
## Implementation Decisions

The user explicitly delegated all relevant decision areas: research in parallel, compare relevant stakeholder perspectives, challenge the recommendations, synthesize a coherent set, and follow it without further selection prompts. Three read-only advisory researchers covered specifications/privacy, architecture, and mutation/GR-06. The choices below are that synthesis, not a transcript of individual user selections. No automatic transition to implementation was requested.

### Scope, sequencing and evidence authority

- **D-01:** Preserve all eight milestone requirements and GR-06. First harden evidence and boundary/policy specifications; then use those tests for the structural corrections and mutation pilot. The planner can interleave independent work, but the pilot measures the hardened tests. Preserve existing browser fixtures and native wire contracts.
- **D-02:** Measure new guards on actual `main` before promoting them into merge-blocking checks. Retain baseline findings and demonstrate each negative control. Promote deterministic recurring contracts through existing test/verification entry points; the Muex pilot stays one-time evidence. Report/advisory checks do not become required checks merely because this phase adds them. Record the tested commit and distinguish PR head from GitHub's synthetic merge commit.
- **D-03:** Copy a small, bounded check before adding a dependency. Use native Elixir AST/Mix facilities and existing test infrastructure. No committed Muex, property-testing, Bash-parser, graph, Credo or dialyzer dependency. The recorded overrun order remains SPEC-04, then ARCH-03, moved to v29 by an explicit roadmap change rather than weakened in place. A failed experiment is not permission to mark an unmet success criterion complete.

### Non-vacuous manifests and vector consumers — SPEC-01

- **D-04:** Separate unavailable optional evidence from a failed enabled proof. For the two named manifest tests, optional lanes may be visibly excluded/skipped when not requested. Once a lane or manifest input is supplied, assert prerequisites and validate the real generated manifest; missing, empty, malformed or wrong artifacts fail. Never use `assert true`, an empty `if File.exists?` body, or a fabricated fallback artifact as proof. Preserve committed-manifest coverage and the existing generated-manifest CI lane.
- **D-05:** Pin independently reviewed loaded and executed cardinalities in every existing vector-consuming test. A count computed from the same discovered collection is not an expectation. Scout values: request corpus 15 loaded; 9 Elixir executions and 14 Swift/Kotlin executions after the existing platform exclusions; reply-leg corpus 2. Reconfirm these values during planning before pinning. An intentional vector change updates expectations explicitly with its reason. Include other actual file consumers in the inventory, without claiming an inline native test consumes a JSON file that it never reads.
- **D-06:** Missing vector file, removed case, empty collection and exclusion of all cases must turn the relevant consumer red. Assert counts before loops and track actual executions after filtering. A platform exclusion is not a passing test of that platform's behavior. Phase 198 owns vector-set hashing and the generated parity ledger; this phase supplies trustworthy consumers, without duplicating that work.

### Delta-only absence guard — SPEC-02

- **D-07:** Extend `script/check_absence_is_not_success.exs` with native AST analysis of root and companion ExUnit files. Use a committed baseline of actual remaining unsafe findings after fixing the known sites in the same change. Identity is file + enclosing test/helper + normalized unsafe expression, with occurrence multiplicity; no line-number keys, blanket exemption for old tests, or added-lines-only diff. Deleting a cardinality guard can introduce a new unsafe finding without modifying the assertion line.
- **D-08:** Recognize the three scoped classes: collection-wide assertions without non-empty proof, `for` over glob-discovered files without cardinality, and literal `assert true`. Required non-empty proof must apply to the same collection in the same reachable lexical branch. Resolve simple module attributes before calling them non-empty; `[]` and arbitrary attributes are not evidence. Reuse the collection inventory selectively: its existing `compile_time_literal?/1` heuristic is unsafe to promote unchanged. Assertions intentionally specifying an empty result are legitimate and remain distinguishable from universal predicates over an empty collection.
- **D-09:** Fail on parse/read errors or an empty scan. New unsafe findings and increased occurrence counts fail; baseline removal is reviewable and stale entries are pruned explicitly. Do not auto-refresh the baseline to make CI green. Controls include deleting only the guard, guarding a different collection, guarding only another branch, duplicating an exempt finding, an empty module attribute, and literal `assert true`. Keep analysis bounded; do not build a general interprocedural verifier.

### Privacy boundaries and policy oracle — SPEC-03, SPEC-05

- **D-10:** Use explicit boundary tables first. `Journal.scope_ref!/1` lengths 15/16/128/129 refer to the opaque suffix after `v1.`. Test LF/CRLF and prefix/suffix injection, nonbinary inputs and exact constant error text. The scope value must never appear in errors, inspection, logs or proof output. Use synthetic values only.
- **D-11:** For every `SafeObservation` field and measurement key, test valid closed values, synthetic adversarial strings, and measurements 0, 1_000_000 and 1_000_001. Exercise constructor output and telemetry/logger/doctor projections, including forged structs where projections accept them. Do not consider constructor rejection sufficient evidence that projections cannot leak. The scout directly reproduced a route ID ending in LF surviving `new/1` and `to_telemetry/1`; fix that demonstrated boundary with absolute anchors while preserving the intended accepted domain. A small seeded loop may supplement a demonstrated gap; it does not replace explicit cases or justify `stream_data` here.
- **D-12:** Exhaust the bounded policy product: runtime 3 × offline 3 × entry 2 × security omitted/standard/sensitive 3 × sync absent/present 2 = 108 unique cases. Use a hand-written factored verdict table: explicit runtime/offline cells plus independent entry/security/sync rules. Expected verdicts must not call production validators or be generated by observing current compiler output. Pin both the unique-case count and executions, and compare exact sorted `{key, route_id}` errors. Keep malformed option types and `Route.new/1` short-circuit behavior in separate examples from the compiler's aggregate verdicts.
- **D-13:** Replace diagnostic-key inference from English error messages with structured NimbleOptions keys and explicit normalization. Preserve atom keys; split grouped unknown-option keys into per-key diagnostics rather than silently widening `Policy.Error.key` to lists or collapsing distinct keys into a new generic taxonomy. Missing route ID remains `{:id, nil}`; do not fabricate a route identity. `Compiler.validation_key/1` must never produce a nil key for a compiler error. Test mixed batches with an invalid route preceding valid/duplicate routes: the compressed-route indexing and zip are a source-attribution risk to reproduce and correct if confirmed. Controls mutate an allowed/denied policy verdict, remove required security, and corrupt a diagnostic key or route attribution.

### Compile structure and explicit exception boundaries — ARCH-01, ARCH-02

- **D-14:** Break the denial-family cycle through one tiny dependency-free protocol-version leaf. Keep `Bridge.Contract.version/0` as the existing API delegating to the leaf; let `Manifest.Types` obtain its default from that leaf. Preserve the existing version and exact wire representation. This removes the coupling without moving denial structs/serializers or hiding the edge by changing only its compile/runtime label. No broader module split.
- **D-15:** Use the pinned Mix xref implementation's own exit thresholds, including `--fail-above`, rather than another SCC implementation or a human-output parser. Fresh-compile before collecting graph evidence. Require zero compile-label/compile-connected cycles and a committed maximum for all cycles measured after the repair. The read-only scout on Elixir 1.19.5 saw one compile-connected cycle and four total SCCs, superseding the earlier report's three; these are scouting observations, not the committed repaired baseline. Do not use `--only-direct`, which can remove relevant mixed-label edges. Check compilation/source coverage separately so a missing/stale manifest cannot impersonate an acyclic graph. Controls must exercise a real mixed-label cycle, threshold overflow and missing compilation evidence using the dependency's real output.
- **D-16:** The three bare rescues in `bridge.ex` serve advisory router-location diagnostics. Use explicit internal `{:ok, value}` / `{:error, closed_reason}` outcomes, nonexceptional filesystem reads and finite expected exception handling. Preserve the original authoring error, denial and diagnostic fallback; do not turn a missing location hint into a new public failure or echo raw exception data.
- **D-17:** Scan each of the named root modules and descendants: bridge, policy, router, offline, manifest and compatibility. The AST guard must reject a broad rescue renamed from `_` to a variable as well. Two existing arbitrary companion/host extension boundaries in `compatibility/route_gate.ex` need intentional broad containment to remain fail-closed. Preserve their existing `:dependency_missing` / `:adapter_unloadable` denials and catch behavior through explicit sanitized outcomes and two reviewed semantic exception records, keyed by file + module/function + normalized clause/call target. No wildcard rescue remains; named whole-exception boundaries outside those exact sites fail. Missing, stale or duplicated exception records fail. Controls raise an arbitrary custom exception, verify no authorization success or raw exception telemetry, and introduce a renamed broad rescue outside the allowed sites. Narrowing extension containment to a few familiar exception classes would weaken the current boundary.

### Runtime dependency surface — ARCH-03

- **D-18:** Ratchet evaluated declared production runtime direct dependencies across the six Mix projects: core and five companions, matching the original Mix-focused architecture proposal. Include optional declarations as dependency surface; exclude dependencies unavailable in `:prod` and those with `runtime: false`. Record optionality and a nonblank one-line purpose for every entry. Compare names/classification, not lockfile versions, fetched transitive graphs or path spelling. Check both local and `CROSSWAKE_RELEASE=1` declaration branches without fetching dependencies.
- **D-19:** Discover and assert the non-empty exact project roster as well as each dependency set. Evaluate projects sequentially in isolated processes/Mix contexts; avoid VM-global cwd races. Additions, removals and classification changes require deliberate baseline edits; no automatic acceptance. Controls include a new optional runtime dependency, dev/test-to-prod promotion, `runtime: false` change, missing project and missing justification. Native dependency choices remain with Phase 198's Android JSON-stack decision and v29's toolchain work; do not silently broaden this Mix ratchet into new multi-ecosystem tooling.

### Throwaway Muex pilot — SPEC-04

- **D-20:** Freeze the evaluation protocol before observing results. Pin the inspected Muex 0.12.0 in task-specific `MIX_HOME` / `MIX_ARCHIVES`; try its isolated archive path first. A pinned locally built escript is a fallback only after an observed archive-integration failure and must pass the same controls. Use the one main checkout as the target; temporary tool-install scratch is not candidate state. Record target commit/tree cleanliness, tool/toolchain provenance, exact file and test selection, commands, runtime and output identity. Do not modify or commit project `mix.exs` / `mix.lock` for the pilot.
- **D-21:** Cover all four required groups through five explicit files: `SafeObservation`, `Journal`, `Policy.Compiler`, `Policy.Route`, `Bridge.Contract`. The inspected configuration uses a comma-separated `--files` value. Initial baseline uses `--no-filter --no-optimize --concurrency 1 --timeout 10000 --fail-at 0 --format json --output <fresh-attempt-path>`, subject to a real preflight confirming the pinned executable accepts it. No `--since`, sampling, coverage-guided selection or mutation cap masquerading as a full baseline. Verify selected tests actually execute with a relevant known-kill control; a populated `test_files` list alone is insufficient.
- **D-22:** Validate the actual versioned report schema. It has `summary.total`, six outcome counts (`killed`, `survived`, `invalid`, `timeout`, `equivalent`, `no_coverage`), score bounds and mutation records; no `mutations_generated` field exists. Require total = record count = sum of outcome counts, known statuses, allowed paths and at least one killed/survived result per selected file. Reject missing/stale/malformed reports, empty output, mismatched totals, nonzero process failure and timeout. The zero-mutant path may emit no report at all. Invalid compilation, uncovered cases, equivalent classifications and timeouts are not behavioral kills. Keep these categories visible instead of inflating a single score.
- **D-23:** Record per-file baseline score bounds, runtime and all survivors keyed by file + mutator + normalized before/after text, with a collision discriminator if needed. Classify survivors once as missing behavioral assertion, equivalent, or tool/infrastructure noise. Use known-kill and deliberately weakened-test known-survive controls, plus zero/missing/malformed/inconsistent report, timeout, invalid-only and no-tests controls. Fixtures/adapters must come from the tool's real output.
- **D-24:** Adopt only for later local advisory use if the controls discriminate, every target has useful executed mutants, survivors are classified, no timeout/infrastructure problem remains unresolved, and the prospective operational appetite holds: at most 30 minutes aggregate pilot wall time on the recorded machine, and invalid + uncovered outcomes at most 20% of non-equivalent emitted mutants. These are chosen project appetite limits, not external best-practice claims or measured results. Exceeding them favors drop for this slice. A score threshold is not an adoption gate. An incomplete/zero-target run cannot satisfy required coverage by calling it a drop; keep the requirement pending or apply the recorded overrun change. No weekly/PR mutation lane, committed tool dependency or bespoke harness follows automatically from either verdict.

### GR-06 bounded workflow grammar closure

- **D-25:** Close the accepted preventive grammar gap in `test/js/ci_secret_masking.test.mjs`, using a documented bounded convention and dependency-free analysis. The prior census found zero live secret-referencing instances in the seven missing forms; do not describe this debt as a reproduced current CI leak. Preserve the Phase 195 supported-mask and workflow-inventory contracts.
- **D-26:** Canonical scalar plain/export assignments with an exact unconditional stdout mask before any use remain supported. Explicitly deny credential-connected declaration (`local`/`declare`/`readonly`), append, `read`, `printf -v`, inline/multiple assignments and same-line early use unless an individual form is intentionally supported and execution-tested. Deny secret-connected persistence to `GITHUB_ENV` / `GITHUB_OUTPUT` as Crosswake's local convention, avoiding cross-step taint analysis. GitHub permits masked same-job outputs; do not invent a platform prohibition. Ordinary nonsecret metadata writes remain valid.
- **D-27:** Classify relevant statements in real run blocks, including inline and folded/block YAML forms. Unsupported credential-related shell/YAML constructs must produce an explicit sanitized finding, not zero candidates. Report file + statement category without values. Fresh census asserts a non-empty workflow/ref inventory and accounts for candidates as supported + denied + unknown; live denied and unknown counts must be zero. Derive counts from the tree rather than pinning today's totals. Inject every previously invisible family, multiple assignments with the secret in a later assignment, and use-before-mask on the assignment line. Execute synthetic controls to prove expansion, stdout registration and ordering; parser acceptance alone is not evidence of masking. Keep the existing bounded derived-secret definition; no arbitrary Bash/secret completeness claim.

### Agent discretion

The planner chooses file organization, minimal AST helpers, focused test grouping, sequential waves and PR boundaries within this scope. Preserve exact required outcomes and the measured-main promotion rule. Continue ordinary local work without per-step permission. Every main merge, publish, tag and remote-branch deletion still requires its own displayed one-use gate. This discussion grants none of those operations.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents must read the governing files and the relevant topic owners before planning or implementation.

### Governing scope and carried decisions
- `AGENTS.md` — privacy, explicit workstream, delivery and approval rules.
- `.planning/BEARINGS.md` — non-vacuity, negative controls, real dependency output and stop list.
- `.planning/ROADMAP-ROLLING.md` — v28 boundaries and named later receivers.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing posture and verification authority.
- `.planning/PROJECT.md` — thesis, constraints and v28 decisions; older status prose is historical.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — active lifecycle and exact next action.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 196 success criteria, research requirement and overrun order.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — SPEC-01..05 and ARCH-01..03.
- `.planning/workstreams/quality-ratchet-release/v28.0-SCOPE.md` — accepted dependency and milestone appetite.
- `.planning/workstreams/quality-ratchet-release/v28.0-research/SYNTHESIS.md` — original scope reconciliation.
- `.planning/workstreams/quality-ratchet-release/v28.0-research/TEST-QUALITY.md` — original spec findings and limited preliminary Muex probe.
- `.planning/workstreams/quality-ratchet-release/v28.0-research/ARCHITECTURE-QUALITY.md` — original cycle/dependency proposal; remeasure baselines.
- `.planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-CONTEXT.md` — recurring proof and real-output conventions.
- `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-REVIEW-GAP.md` — original GR-06 finding.
- `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-REVIEW-DISPOSITION.md` — accepted receiver, no new deferral.
- `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/mask-gr-warn-control-195.txt` — prior seven-form census.

### Primary external references checked during discussion
- [Pinned Mix xref source](https://github.com/elixir-lang/elixir/blob/v1.19.5/lib/mix/lib/mix/tasks/xref.ex) — graph labels, mixed cycles and exit thresholds.
- [Mix dependency semantics](https://hexdocs.pm/mix/Mix.Tasks.Deps.html) — environment/runtime/optional classification.
- [Erlang regular expressions](https://www.erlang.org/doc/apps/stdlib/re.html) — absolute anchors versus line-end matching.
- [NimbleOptions validation error](https://nimble-options.hexdocs.pm/NimbleOptions.ValidationError.html) — structured keys, including grouped unknown keys; also inspect installed 1.1.1 source.
- [Muex 0.12.0 configuration](https://github.com/Oeditus/muex/blob/v0.12.0/lib/muex/config.ex), [JSON reporter](https://github.com/Oeditus/muex/blob/v0.12.0/lib/muex/reporter/json.ex), [installation](https://github.com/Oeditus/muex/blob/v0.12.0/docs/INSTALLATION.md) — pinned behavior takes precedence over inconsistent unversioned prose.
- [GitHub workflow commands](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands), [Bash manual](https://www.gnu.org/software/bash/manual/bash.html) — masking/persistence and actual assignment forms.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- `script/check_absence_is_not_success.exs`, `test/crosswake/proof/absence_is_not_success_test.exs` — existing guard and test entry points.
- `script/inventory_collection_assertions.exs` — AST inventory to reuse selectively; non-empty literal/attribute heuristic needs correction before reuse.
- `test/crosswake/guides/evidence_manifest_test.exs`, `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` — the two named optional-artifact gaps.
- `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`, `test/crosswake/proof/phase165_ci_integrity_test.exs` — known glob loops to repair alongside the guard.
- `priv/contract_vectors/`, `test/crosswake/bridge/bridge_behavioral_vector_test.exs`, `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift`, `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt` — shared corpus and native consumers. Existing `BridgeReplyLegTests.swift` / `BridgeReplyLegTest.kt` also consume the reply corpus.

### Production boundaries
- `lib/crosswake/offline/journal.ex`, `lib/crosswake/offline/safe_observation.ex` — explicit privacy boundaries and observation projections; LF defect reproduced in the latter.
- `lib/crosswake/policy/route.ex`, `lib/crosswake/policy/compiler.ex`, `lib/crosswake/policy/validator.ex`, `lib/crosswake/policy/error.ex` — finite policy product, structured error normalization and batch provenance.
- `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/denial.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/shell/denial.ex` — coupled denial family; compile-time version capture is the narrow seam.
- `lib/crosswake/bridge.ex`, `lib/crosswake/compatibility/route_gate.ex` — three advisory-location bare rescues and two broad extension-containment boundaries.
- `mix.exs`, `packages/crosswake_rulestead/mix.exs`, `packages/crosswake_rindle/mix.exs`, `packages/crosswake_sigra/mix.exs`, `packages/crosswake_chimeway/mix.exs`, `packages/crosswake_threadline/mix.exs` — six dependency declaration owners.

### Integration points
- `.github/workflows/crosswake-ci.yml` — confirm actual formatter/xref/current test wiring during research before adding a recurring gate.
- `test/js/ci_secret_masking.test.mjs` — existing GR-06 grammar, real-tree census and executed synthetic controls; do not fork a second analyzer.
- Native vector consumers keep existing platform exclusions and wire behavior. Counts are not an Android emulator/device claim.
</code_context>

<specifics>
## Specific Ideas

The user's preference is smaller, flatter dependency trees: another small copy is preferable to a dependency unless evidence demonstrates the dependency is necessary. Breadth/depth should stop when further exploration no longer changes a decision. Relevant lenses here were privacy/security, policy correctness, Elixir/Mix architecture, native parity, CI operations, maintainer cost and diagnostic UX; no new product UI is involved.

The 30-minute/20% pilot limits are prospective decisions. The actual full-module Muex runtime, useful-mutant coverage, survivor noise, repaired cycle baseline and final guard census remain unmeasured. Planning must research those points rather than present this discussion as a successful pilot or an implemented fix.
</specifics>

<deferred>
## Deferred Ideas

- Weekly/PR Muex lanes and score ratchets — maintainer; trigger: adopted pilot plus four-week stable advisory baseline; receiver: rolling-roadmap LATER mutation work.
- Property-testing dependency or broader seeded generation — maintainer; trigger: actual pilot survivors demonstrate boundary gaps a small deterministic corpus cannot reasonably cover; receiver: rolling-roadmap LATER property tests.
- General Bash parser/dataflow engine — maintainer; trigger: a fresh workflow census demonstrates necessary secret-connected syntax that bounded conventions cannot express; receiver: later scoped security-tooling proposal, not an implicit GR-06 expansion.
- Swift/Gradle dependency ratchets and Android JSON/toolchain choices — native maintainer; trigger: Phase 198 JSON-stack review or v29 toolchain PR; receivers: Phase 198 and v29. The six-Mix-project baseline does not claim native dependency coverage.
- Broader module splits, package/tarball layering and native mutation tools — maintainer; existing rolling-roadmap triggers and receivers remain unchanged.
- Original clean-room WR-04/05/06 and IN-03 — Phase 197 receiver unchanged; no reopened Phase 195 delivery, twin run or release action.
</deferred>

---

*Phase: 196-spec-and-structure-ratchet*
*Context gathered: 2026-10-27*
