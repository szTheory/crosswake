# Phase 166: Clean-Checkout Engineering Quality - Context

**Gathered:** 2026-09-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 166 establishes one deterministic, maintainer-facing contract for verifying the supported
repository from a clean checkout. It covers the root library, checked-in Phoenix example host,
browser proof, iOS package, frozen Android package/JVM posture, formatting, warnings-as-errors,
milestone-touched engineering quality, repository artifact intent, post-run cleanliness, and
concise actionable failure output.

This phase tightens and composes existing proof. It does not add product or mobile capability,
redesign Phase 165's CI authority, expand Android, reconcile public documentation or pull requests
(Phase 167), prepare or publish a release candidate (Phase 168), or resume the parked first-adopter
workstream.

</domain>

<decisions>
## Implementation Decisions

### Clean-checkout entry point
- **D-01:** Add one purpose-named repository verification facade, such as
  `script/verify_repository.sh`, as the canonical complete local clean-checkout command. It composes
  fixed stages rather than acting as an arbitrary-command runner.
- **D-02:** Preserve the current narrower meaning of `mix verify` (companion packages plus the
  hermetic core lane). Do not silently redefine an established Elixir entry point to own browser,
  Swift, Gradle, and repository-policy work.
- **D-03:** Expose independently runnable, purpose-named stages for prerequisite/bootstrap checks,
  root proof, example-host proof, browser proof, iOS package proof, Android package/JVM proof,
  formatting, warnings-as-errors, and repository cleanliness. The complete facade and focused
  reruns must use the same stage commands.
- **D-04:** The prerequisite stage validates exact required tools and versions before expensive
  work. It may fetch lock-governed project dependencies into ignored or invocation-owned
  locations, but it must not install global/system tooling, mutate host package managers, request
  signing material, or require secrets.
- **D-05:** Missing Apple tooling is an explicit unsupported-host failure for a requested complete
  local run, never a silent omission. CI retains Phase 165's Linux/macOS placement and uses the same
  behavioral stage commands without pretending local execution reproduces GitHub permissions,
  branch protection, or runner control-plane behavior.
- **D-06:** Add executable parity protection between the supported stage inventory and its CI
  owners. A stage without an owner, an owner with divergent command behavior, or a copied command
  that drifts must fail with an exact correction. Preserve Phase 165's literal leaf manifest and
  `Crosswake CI` authority.

### Code-cleanup boundary
- **D-07:** ENG-02 starts with every non-planning file changed from a mechanically recorded v22
  base through the final Phase 166 tree. Expand only through a bounded, evidence-triggered
  ownership cone when a touched path directly calls, imports, includes, generates, mutates, tests,
  or shares an authoritative invariant with an adjacent path.
- **D-08:** Record every scope expansion as `candidate -> evidence -> owner -> disposition` and
  stop when no direct ownership edge remains. Broad repository cleanup, style-only refactoring,
  and unrelated historical debt are outside Phase 166.
- **D-09:** A branch is removable as dead only when supported-entrypoint and workflow/config
  searches, dependency tracing, dynamic-dispatch review, a focused regression test, and the full
  clean gate agree. Static reachability alone is insufficient for Mix tasks, runtime module lookup,
  shell dispatch, generated paths, or GitHub workflow behavior.
- **D-10:** Treat code as accidentally duplicated only when two owners implement the same invariant
  over the same inputs, outputs, authority, and failure semantics. Literal proof identity,
  cross-platform implementations, fixtures, defensive validators, and negative sentinels are not
  duplication merely because their text resembles another path.
- **D-11:** Remove a compatibility fallback only when it is migration-only, no supported caller or
  current policy requires it, and focused behavioral proof prevents its return. Current product
  fallbacks, public-version compatibility, and authority sentinels remain explicit. An uncertain
  candidate is recorded as unproven and retained.
- **D-12:** Extract a focused module only at a demonstrated responsibility, side-effect, or trust
  boundary. File length alone is not evidence. Prefer behavioral contract tests over assertions
  that search source text for an earlier implementation.

### Artifact and residue policy
- **D-13:** Maintain one small explicit artifact policy with three classes: ignored transient
  build/cache/runtime families; intentionally tracked source and generated-contract outputs; and
  forbidden tracked secret-bearing, editor, crash, credential, or local-only families with only
  narrowly documented safe fixtures.
- **D-14:** Each intentionally tracked generated contract names its canonical source,
  regeneration command, and byte-for-byte drift check. `.gitignore` remains the familiar human
  convention layer but is not sufficient ENG-03 evidence, and the policy does not inventory every
  downloaded or tool-version-dependent ignored file.
- **D-15:** Canonical Phase 166 evidence runs in an isolated exact-commit checkout. In-place complete
  verification requires an empty baseline; focused development stages may run with working changes
  but must not add residue.
- **D-16:** Use Git's stable NUL-delimited porcelain output to inspect staged, unstaged, and
  non-ignored untracked state before and after the complete run. Cleanup and the final snapshot run
  on success and failure. Independently regenerate and diff tracked contracts without staging
  files or changing the Git index.
- **D-17:** Artifact diagnostics expose only a stable category, repository-relative path, and one
  correction command. They never print suspicious file contents, secrets, payloads, tokens, cache
  keys, or unrelated environment state.
- **D-18:** Cleanup owns only invocation-created paths with exact validated prefixes. Never use
  `git clean -xfd`, compare an arbitrary dirty baseline as if it were clean, trust
  `.git/info/exclude` as repository policy, enumerate/delete global temporary state, or stage the
  worktree to detect generated drift. Replace any `git add -A` remediation with a non-staging,
  explicit-path comparison.

### Failure and legacy-label experience
- **D-19:** Use dependency-aware hybrid execution. Prerequisite and repository-invariant preflight
  fails fast; dependent steps preserve order; independent root, host, browser, iOS, Android,
  format, warnings, and cleanliness families continue so one run reveals actionable independent
  defects.
- **D-20:** A failed prerequisite marks its dependents `BLOCKED`, not neutral or irrelevant. Any
  `FAIL` or `BLOCKED` result makes the complete run nonzero. Cleanup and final repository-state
  inspection always execute.
- **D-21:** Finish with a bounded deterministic summary using stable purpose IDs and literal
  `PASS`, `FAIL`, and `BLOCKED` words. Meaning never depends on color. Plain output is authoritative;
  any future TTY color is additive and must honor `NO_COLOR`.
- **D-22:** Each failure supplies one minimal, non-secret, copy-pasteable, repository-root-relative
  remediation command including required working directory and environment. Preserve full child
  logs while keeping the final summary concise. GitHub annotations and step summaries are additive
  renderings, not a second semantic authority.
- **D-23:** Preserve `Crosswake CI`, current leaf IDs/display names, referenced historical test
  paths, evidence schemas, and phase artifacts where they are compatibility or provenance
  contracts. New active commands, stage IDs, headings, and diagnostics use purpose names.
- **D-24:** Write active comments invariant-first, with a phase reference only as secondary
  provenance. Rename an existing machine identity only through one atomic, fully verified migration
  of its manifest, workflow producer, tests, remediation, evidence consumers, and required-check
  authority; never as cosmetic cleanup.

### the agent's Discretion
- Exact filenames, flag spelling, and internal representation of the fixed stage inventory, provided
  the public facade, focused stages, and CI owners cannot drift.
- Exact tool/version preflight ordering and dependency-fetch commands, provided they remain locked,
  idempotent, non-global, non-secret, and leave tracked state unchanged.
- Exact implementation of the v22 base ledger, ownership-cone evidence, artifact policy, and
  negative fixtures within the locked scope and safety rules above.
- Exact line wrapping and terminal/GitHub rendering, provided stable purpose IDs, closed result
  words, bounded detail, accessibility, privacy, and copy-paste remediation remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project and workstream authority
- `AGENTS.md` — current priority, workstream routing, Android freeze, sensitive-data rules, and
  executable-verification posture.
- `.planning/PROJECT.md` — Phoenix-first thesis, proof-as-product house style, current v22 lane, and
  separation from the parked adopter workstream.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — ENG-01 through ENG-04 scope and
  the Phase 167/168 boundary.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 166 goal, success criteria,
  dependency on Phase 165, and downstream phase ownership.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — active Phase 166 position and carried
  Phase 164/165 decisions.
- `.planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md`
  — exact resource cleanup, test isolation, required-context ownership, and closed failure semantics.
- `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md`
  — fixed CI authority, literal leaf inventory, runner/cache posture, concise remediation, and
  privacy-safe evidence decisions that Phase 166 must preserve.

### Governing first-adopter boundary
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, stop list, Android freeze,
  privacy boundary, and executable proof policy.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — RAG-oriented priority, diagnostics principles,
  host-proof emphasis, and forbidden product breadth.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — codename/privacy constraints and bounded
  physical-proof claims that repository output must not weaken.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked external gate and exact
  non-inference/resume posture.

### Curated research, DX, and voice authority
- `prompts/crosswake-elixir-oss-dna.md` — install truth, named proof lanes, deterministic host proof,
  and maintainer-facing OSS conventions.
- `prompts/crosswake-gsd-project-brief.md` — explicit CI/CD, release, DX, and proof-as-product vision.
- `prompts/crosswake-research-synthesis.md` — current architectural thesis and precedence over
  older prompt-era research.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — ecosystem test pyramid, polyglot CI, clean
  dependency boundaries, and documentation/DX lessons; current project decisions override its
  legacy names or superseded version recommendations.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — shared contract-fixture, native proof,
  generator, doctor, and maintainer-DX patterns; current project boundaries override broader ideas.
- `brandbook/BRAND-SPEC.md` — current calm, explicit, accessible, purpose-led voice and terminology;
  supersedes `prompts/crosswake-brand-book.md`.

### Existing verification and repository seams
- `mix.exs` — established narrower `mix verify` and `mix companions.test` meanings plus package
  allowlist and generated-doc behavior.
- `examples/phoenix_host/mix.exs` — example-host bootstrap/test lifecycle and database ownership.
- `.tool-versions` — root toolchain identity.
- `.gitignore` — existing transient, secret, editor, native, browser, and local-tooling exclusions.
- `script/check_phase165_efficient_ci.sh` — fixed-section aggregate check, fail trap, purpose IDs,
  and corrective-command precedent.
- `script/ci_leaf_manifest.json` — exact Phase 165 proof identity and remediation inventory that
  Phase 166 must preserve and reconcile.
- `.github/workflows/crosswake-ci.yml` — current complete PR proof graph and `Crosswake CI`
  aggregation authority.
- `.github/actions/setup-elixir-cache/action.yml` — exact toolchain/dependency topology and
  operation-owned cache-boundary precedent.
- `examples/phoenix_host/package.json` — locked browser dependencies and script entry points.
- `examples/phoenix_host/playwright.config.ts` — browser-project and artifact-output behavior.
- `packages/crosswake-shell-core-ios/Package.swift` — supported iOS package boundary.
- `packages/crosswake-shell-core-android/gradlew` — supported frozen Android package/JVM entry point.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix verify` and `mix companions.test`: keep as focused Elixir/package stages rather than widening
  their established meaning.
- `script/check_phase165_efficient_ci.sh`: reuse its strict shell posture, named sections, bounded
  failure trap, and exact correction pattern while replacing phase-led user-facing names.
- `script/ci_leaf_manifest.json`: reuse its literal proof inventory and remediation ownership as
  the parity source, not as permission for a second dynamic CI engine.
- Existing browser, generated-shell, package, dependency-security, contract-drift, and example-host
  scripts: compose their supported commands instead of reimplementing their behavior.
- `.gitignore`, Mix package `files`, and existing generator drift tests: combine them into the
  explicit artifact-intent and residue contract.

### Established Patterns
- Proof is split into literal behavioral leaves with one fail-closed `Crosswake CI` umbrella.
- Shell gates use `set -euo pipefail`, stable `[crosswake]` output, named sections, and one exact
  corrective command.
- Hermetic and dependency-present lanes keep separate dependency/build state; Android JVM proof is
  portable and frozen; Apple work alone earns macOS.
- Generated contracts are checked by regeneration plus byte comparison, and tests own exact
  temporary resources rather than shared globs.

### Integration Points
- The new complete facade composes current scripts and package-native commands; it does not replace
  them.
- Phase 165's leaf manifest, CI workflow, producer/aggregator guards, and required-check audit are
  the authority boundary for local/CI parity.
- Repository policy connects `.gitignore`, tracked generated outputs, Mix package allowlists,
  browser/native output roots, and NUL-safe Git status inspection.
- The Phase 166 recurring contract should enter CI only through an existing appropriate proof leaf
  or an exact manifest-governed addition that preserves the single umbrella authority.

</code_context>

<specifics>
## Specific Ideas

- Model the maintainer experience after the successful facade-plus-focused-target pattern used by
  mature ecosystems: one calm complete command, exact component reruns, and no hidden system setup.
- Use dependency-aware keep-going behavior: stop invalid chains early, continue independent proof,
  and always run the cleanliness finalizer.
- Treat terminal output as the relevant UI. Optimize for scanability, copy/paste, no-color access,
  low noise, safe detail, and stable purpose language rather than exposing orchestration internals.
- Apply an adversarial pass to every cleanup candidate and artifact rule: dynamic dispatch,
  compatibility consumers, ignored-source concealment, secret leakage, path parsing, cleanup scope,
  and status misclassification must fail closed.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 166-Clean-Checkout Engineering Quality*
*Context gathered: 2026-09-09*
