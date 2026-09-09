# Phase 166: Clean-Checkout Engineering Quality - Research

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENG-01 | The root suite, example host, browser proof, iOS package, Android package, format, and warnings-as-errors checks are deterministic from a clean checkout. | Fixed stage inventory, exact toolchain preflight, isolated invocation paths, deterministic browser settings, and clean-checkout evidence topology. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:57-60] |
| ENG-02 | Code touched by the milestone has explicit ownership boundaries, focused modules, and no known dead branches, accidental duplication, or misleading compatibility fallbacks. | Mechanically derived 94-path v22 candidate ledger, bounded ownership-cone method, adversarial removal criteria, and known cleanup candidates. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:62-63; git diff --name-only -z 8383aaea2a2b2e10bbe61dd843b51f4129a5d447 HEAD] |
| ENG-03 | Generated, temporary, secret-bearing, editor, and local-only artifacts are either ignored or intentionally tracked, and a clean verification run leaves Git clean. | Three-class policy, generated-contract registry, NUL-safe pre/post snapshots, exact cleanup ownership, and isolated exact-commit final evidence. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:65-66] |
| ENG-04 | Repository quality checks emit concise, actionable failures without stale phase labels, contradictory comments, or unactionable warning noise. | Closed runner state model, bounded summary, one remediation per failure, compatibility-identity preservation, and negative output tests. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:68-69] |
</phase_requirements>

## Summary

Phase 166 should introduce a small repository-verification control plane, not another test suite. The public shell facade should delegate to one fixed stage manifest and runner; focused and complete modes must resolve the same stage records. Each record should own prerequisites, dependencies, an argv-safe command, CI owner(s), remediation, and invocation-created paths. The runner should validate the manifest before any expensive work, execute dependency chains in order, continue independent families, always finalize cleanup/status, and render only the closed results `PASS`, `FAIL`, and `BLOCKED`. These result words are quoted verbatim from the locked phase contract. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-CONTEXT.md:15-40,107-121]

The repository already has the necessary behavioral commands and should add no package. The principal integration work is to compose `mix verify`, the example host lifecycle, Playwright, `swift test`, the frozen Gradle package, formatter and warnings checks, while retaining Phase 165's literal 44-leaf plus `classify-change` CI authority. The existing manifest's closed top-level schema is quoted as `"schema_version", "proof_leaves", "required_control_nodes", "legacy_compatibility_contexts"`; its preserved umbrella constants are quoted as `UMBRELLA_ID = "merge-blocking-crosswake-ci"` and `UMBRELLA_NAME = "Crosswake CI"`. [VERIFIED: mix.exs:62-87; script/check_ci_leaf_manifest.py:18-74,128-143]

Two adjacent defects are directly inside the ownership cone. First, generated-contract proof still runs `git add -A` and advertises `mix crosswake.contract.gen && git add -A && git diff --cached --exit-code`; D-18 explicitly forbids this. Second, Playwright currently has `retries: process.env.CI ? 2 : 0` and `reuseExistingServer: !process.env.CI`; retrying proof conflicts with the inherited no-test-retry rule, while reusing an arbitrary local server makes a complete local run non-hermetic. Address these as behavioral invariants, without renaming `guard-02-generate-and-diff`, `e2e-proof`, `route-tour-proof`, or any other protected identity. [VERIFIED: .github/workflows/crosswake-ci.yml:318-333; script/ci_leaf_manifest.json:52-70; examples/phoenix_host/playwright.config.ts:5-15,47-50; .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md:95-114]

**Primary recommendation:** implement a purpose-named shell facade over a dependency-aware fixed runner and manifest, then prove the same stage records in CI, in negative fixtures, and in one isolated exact-commit clean checkout.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Complete/focused execution | Repository tooling | CI control plane | Local tooling owns behavioral commands; CI invokes those commands rather than copying them. [VERIFIED: 166-CONTEXT.md:15-40] |
| Toolchain/bootstrap validation | Repository tooling | Language package managers | Preflight validates; lock-governed managers may fetch only into ignored or invocation-owned locations. [VERIFIED: 166-CONTEXT.md:27-32] |
| Root and companion proof | Elixir/Mix | Repository runner | `mix verify` already owns companion packages plus the hermetic root lane. [VERIFIED: mix.exs:62-87] |
| Example-host proof | Phoenix example host | Repository runner | The example project owns SQLite provisioning/migrations through its `test` alias. [VERIFIED: examples/phoenix_host/mix.exs:29-37] |
| Browser proof | Playwright/Phoenix host | Repository runner | Playwright owns browser assertions and server lifecycle; the runner owns deterministic flags and residue. [VERIFIED: examples/phoenix_host/playwright.config.ts:5-15,47-51] |
| iOS package proof | SwiftPM | macOS host | `swift test` is the current package behavioral command and Apple-tool absence must fail explicitly. [VERIFIED: .github/workflows/crosswake-ci.yml:898-929; 166-CONTEXT.md:33-37] |
| Android package/JVM proof | Gradle/JDK on Linux | Repository runner | Existing authority quotes `java-version: "17"` and wrapper `gradle-8.7-bin.zip`; feature scope remains frozen. [VERIFIED: .github/actions/setup-android-jvm/action.yml:1-13; packages/crosswake-shell-core-android/gradle/wrapper/gradle-wrapper.properties:1-7] |
| Artifact classification/cleanliness | Repository policy | Git | A dedicated policy owns intent; Git porcelain owns state observation, not cleanup scope. [VERIFIED: 166-CONTEXT.md:81-105] |
| CI parity | Phase 165 manifest guard | Repository stage manifest | Extend existing bidirectional authority rather than build a second CI engine. [VERIFIED: script/check_ci_leaf_manifest.py:128-242] |

## Project Constraints (from AGENTS.md)

- Preserve Phoenix-first route-policy/runtime-contract scope and explicit per-route runtime ownership; this phase adds no product capability. [VERIFIED: AGENTS.md:28-44]
- Preserve typed, versioned, low-frequency bridge contracts and honest offline claims; do not imply generic sync. [VERIFIED: AGENTS.md:31-36]
- Preserve fail-closed denials and prefer one-command host proof over new label taxonomy. [VERIFIED: AGENTS.md:36-39]
- Android is frozen: no feature, template, generator, Maven, JVM, vector, device, parity, or release-scope expansion. [VERIFIED: AGENTS.md:39-44; .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:112-120]
- Use the durable codename `First B2C Adopter` / `first_b2c_adopter`; public guides say `first adopter`; never infer or record identifying adopter facts. [VERIFIED: AGENTS.md:46-53]
- Never expose raw answers, media, transcripts, credentials, account identifiers, tokens, stable device identifiers, or other sensitive payloads in telemetry, diagnostics, proof, or this phase's output. [VERIFIED: AGENTS.md:54-59]
- Default to automated verification; human action is reserved for credentials, external approvals, or irreversible trust actions. Phase 166 requires none. [VERIFIED: AGENTS.md:61-80]
- Do not mutate branch protection, release authority, parked adopter state, or fast-changing external execution state. [VERIFIED: AGENTS.md:61-84]

## Standard Stack

### Core

| Tool | Required identity | Purpose | Why standard here |
|------|-------------------|---------|-------------------|
| Bash facade | repository script | Stable public entry point and root resolution | Existing gates use `#!/usr/bin/env bash`, `set -euo pipefail`, root normalization, and traps. [VERIFIED: script/check_phase165_efficient_ci.sh:1-24] |
| Node.js runner | `nodejs 22.14.0` proposed in current `.tool-versions` working tree | Fixed manifest parsing, argv-safe child execution, status graph, bounded rendering | Node is already required by browser proof and used by repository proof scripts. The quoted pin is present but currently uncommitted and must be made intentional before it becomes authoritative. [VERIFIED: .tool-versions:1-3; current `git diff -- .tool-versions`] |
| Git | porcelain v1 with `-z` | Exact baseline and final staged/unstaged/untracked snapshots | Git documents porcelain v1 as backwards-stable and `-z` as NUL-delimited with unquoted pathnames. [CITED: https://git-scm.com/docs/git-status] |
| Elixir / Erlang | quoted `elixir 1.19.5-otp-27`, `erlang 27.3` | Root, companions, format, warnings, example host | These are the checked-in toolchain identities. [VERIFIED: .tool-versions:1-2] |
| SwiftPM | quoted `// swift-tools-version: 5.9` | iOS package unit proof | The package itself declares this tools floor and existing CI runs `swift test`. [VERIFIED: packages/crosswake-shell-core-ios/Package.swift:1-29; .github/workflows/crosswake-ci.yml:898-929] |
| JDK / Gradle wrapper | quoted `default: "17"`; `gradle-8.7-bin.zip` | Frozen Android JVM proof | Existing setup derives the exact Gradle version from the wrapper and validates wrapper use. [VERIFIED: .github/actions/setup-android-jvm/action.yml:4-13,24-65; packages/crosswake-shell-core-android/gradle/wrapper/gradle-wrapper.properties:1-7] |
| Playwright Test | locked `1.60.0` | Browser proof | `package-lock.json` resolves the installed test runner; use `npm ci`, never floating install. [VERIFIED: examples/phoenix_host/package-lock.json:15-20] |

### Supporting

| Tool | Purpose | Rule |
|------|---------|------|
| ExUnit | Structural, negative, cleanup, and ownership-cone contracts | Reuse existing proof-test conventions; add Phase 166 behavioral tests, not source-string-only tests. [VERIFIED: test/crosswake/contract/contract_drift_test.exs:57-125] |
| `actionlint` | Workflow syntax after CI-owner edits | Run on `crosswake-ci.yml` and any touched workflow; existing Phase 165 aggregate already requires it. [VERIFIED: script/check_phase165_efficient_ci.sh:26-32,75-76] |
| Existing manifest/producer detectors | Leaf identity, static-needs, unique producer, remediation parity | Extend their schemas atomically for local-stage ownership. [VERIFIED: script/check_ci_leaf_manifest.py:128-242] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shell facade + Node runner | One large Bash script | Fewer files, but dependency graph, structured manifest validation, argv safety, and deterministic summary tests become harder to isolate. |
| Fixed JSON stage inventory | Copy commands into facade and workflow | Initially simpler, but directly violates executable parity and recreates command drift. |
| Exact-commit isolated checkout | Compare arbitrary dirty baseline | Faster during development, but D-15 forbids treating dirty state as clean evidence. |

**Installation:** no new external package should be installed. Use checked-in lockfiles and platform-native tools. [VERIFIED: 166-CONTEXT.md:27-32]

## Package Legitimacy Audit

Not applicable. Phase 166 should introduce no package name and therefore triggers no package-legitimacy gate. It composes existing Mix, npm-lock, SwiftPM, Gradle-wrapper, Git, shell, and repository scripts. Any plan that adds a dependency must stop, justify the scope expansion, and run the full legitimacy protocol before install.

## Architecture Patterns

### System Architecture Diagram

```text
maintainer / CI leaf
        |
        v
script/verify_repository.sh  ---- focused --stage ----+
        |                                            |
        v                                            |
fixed stage manifest <---- parity validator ---------+
        |
        +--> repository preflight --invalid--> FAIL; dependents BLOCKED
        |
        +--> bootstrap/tool checks --missing--> FAIL; dependent family BLOCKED
        |
        +--> root ------+
        +--> host ------+--> independent families keep running
        +--> browser ---+
        +--> iOS -------+
        +--> Android ---+
        +--> format ----+
        +--> warnings --+
        |
        v
always: exact owned-path cleanup -> NUL-safe final Git snapshot
        |
        v
bounded PASS / FAIL / BLOCKED summary + one remediation per defect
```

### Recommended Project Structure

```text
script/
├── verify_repository.sh                  # only public complete/focused facade
├── verify_repository.mjs                 # dependency graph, execution, cleanup, summary
├── repository_verification_stages.json   # fixed stage/owner/remediation inventory
├── repository_artifact_policy.json       # ignored/tracked-generated/forbidden families
└── check_phase166_clean_checkout_engineering_quality.sh # recurring phase contract
test/
├── js/repository_verification.test.mjs   # result graph, hostile paths, cleanup, output
├── fixtures/repository_quality/           # closed negative cases
└── crosswake/proof/phase166_repository_quality_test.exs # source/artifact/CI parity
.planning/.../166-ownership-ledger.md       # v22 base and evidence-bounded dispositions
```

### Pattern 1: One Stage Record, Multiple Entrypoints

The stage record should contain a stable purpose ID, dependencies, required tool facts, an argv array or fixed script path, CI owners, remediation, and exact owned-output roots. Both `--all` and `--stage` select from this inventory; the workflow parity guard verifies that every supported stage has an owner invoking the same leaf command. Do not allow free-form command input. [VERIFIED: 166-CONTEXT.md:15-40]

### Pattern 2: Closed Dependency-Aware Results

Validate repository invariants first. If a prerequisite fails, emit `FAIL` for that stage and `BLOCKED` for every dependent stage; continue stages whose prerequisites remain satisfied. Cleanup and final state inspection are unconditional, and any `FAIL` or `BLOCKED` makes the facade nonzero. [VERIFIED: 166-CONTEXT.md:107-115]

### Pattern 3: Invocation-Owned Isolation

Create one run root using a fixed `crosswake-repository-verify.` prefix under a validated temp parent. Route Swift scratch/cache, Gradle home, Playwright browser/output roots, and captured logs there where supported. For in-tree lock-governed outputs that must live beside manifests (`node_modules`, Mix `deps`/`_build`), record whether the invocation created them and remove only those exact paths during the finalizer. Never delete a pre-existing cache or use a wildcard cleanup. This extends the existing exact `mktemp` plus `trap` pattern. [VERIFIED: script/check_example_host_isolation.sh:4-19,63-97]

### Pattern 4: Generated Contract Check Without Index Mutation

The canonical generator quotes eight tracked outputs: `examples/ios_shell_host/Fixtures/route_activation.json`, `examples/android_shell_host/app/src/main/assets/route_activation.json`, `examples/ios_shell_host/Fixtures/route_activation-dev.json`, `examples/android_shell_host/app/src/dev/assets/route_activation.json`, `test/fixtures/bridge_contract_vectors.json`, `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`, `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json`, and `docs/_contract_snippet.md`. Regenerate default and `--dev` surfaces in an isolated checkout or snapshot exact bytes before regeneration, compare explicit paths byte-for-byte, and restore only the snapshot-owned copies if the focused check is permitted in a dirty tree. Do not stage anything. [VERIFIED: lib/mix/tasks/crosswake.contract.gen.ex:4-55,57-96; test/crosswake/contract/contract_drift_test.exs:20-51]

### Anti-Patterns to Avoid

- **Second CI engine:** local stages are behavioral commands, not a dynamic workflow scheduler. Preserve literal jobs and the `Crosswake CI` umbrella. [VERIFIED: 166-CONTEXT.md:33-40]
- **`CI=1` as the only browser determinism switch:** it also activates the current two retries. Set or test explicit no-retry and no-reuse semantics. [VERIFIED: examples/phoenix_host/playwright.config.ts:5-15,47-50]
- **Global cleanup:** do not remove `$HOME` caches, enumerate shared `/tmp`, or use `git clean`. [VERIFIED: 166-CONTEXT.md:98-105]
- **Cosmetic removal of phase IDs:** current leaf identities and historical paths are contracts/provenance. [VERIFIED: 166-CONTEXT.md:116-121]
- **Success-only cleanup:** residue inspection must run after child failure, interruption, and blocked execution. [VERIFIED: 166-CONTEXT.md:87-101,107-115]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Repository state parser | newline/space parser | `git status --porcelain=v1 -z --untracked-files=all` | Handles unusual filenames without quoting ambiguity. [CITED: https://git-scm.com/docs/git-status] |
| Test behavior | duplicate test logic in runner | existing `mix`, Playwright, `swift test`, and Gradle commands | The facade composes behavior; it does not reimplement it. [VERIFIED: 166-CONTEXT.md:15-25] |
| CI identity | new job taxonomy | `ci_leaf_manifest.json`, workflow jobs, producer audit | Existing literal identity is branch-protection authority. [VERIFIED: script/check_ci_leaf_manifest.py:18-74,128-242] |
| Generated drift | staged-index comparison | explicit tracked-path regeneration and byte comparison | Staging unrelated files is unsafe and explicitly forbidden. [VERIFIED: 166-CONTEXT.md:87-105] |
| Recursive cleanup | broad glob or `git clean` | run ledger of validated, exact created paths | Prevents deleting pre-existing/user state. [VERIFIED: 166-CONTEXT.md:98-105] |
| Secret detection by content dump | print/scour file bodies | path/category policy plus narrow safe-fixture exceptions | Diagnostics must never disclose suspicious contents. [VERIFIED: 166-CONTEXT.md:92-97] |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Example-host SQLite state is created by the test/web-server lifecycle; root isolation tests separately own exact `crosswake-example-host-*.sqlite3`, `-wal`, and `-shm` companions. | Treat test databases as invocation outputs; delete only exact paths created by the run. No data migration. [VERIFIED: examples/phoenix_host/mix.exs:29-37; test/support/example_host.ex:148-160] |
| Live service config | `Crosswake CI` and required-check policy are live GitHub authority, but Phase 166 local proof must not claim to reproduce or mutate them. | Structural parity only; no API write or migration. [VERIFIED: 166-CONTEXT.md:33-40] |
| OS-registered state | None authorized. The facade may not install system/global tools, register services, or require signing. | Preflight failure with exact correction; no registration. [VERIFIED: 166-CONTEXT.md:27-37] |
| Secrets/env vars | No variable rename is authorized. Existing proof must remain credential-free, and diagnostics may not emit environment values. | No migration; validate presence only for non-secret tool settings and never print values. [VERIFIED: AGENTS.md:46-59; 166-CONTEXT.md:92-97] |
| Build artifacts / installed packages | Materialized ignored families include Mix `_build`/`deps`, npm `node_modules`, Playwright reports/results/artifacts, Swift `.build`, Gradle `.gradle`/`build`, example SQLite, docs, and tmp. | Isolate or ledger invocation-created roots; cleanup on every exit; leave pre-existing caches untouched. [VERIFIED: .gitignore:1-68; current `git status --ignored --short`] |

## Common Pitfalls

### Pitfall 1: “Clean Git” Hides Ignored Residue

**What goes wrong:** `git status` is empty while the run leaves large or stateful ignored outputs. **Why:** ENG-03 permits ignored families, but the phase goal also says verification is without residue and D-18 limits cleanup ownership. **Avoid:** define artifact intent separately from the invocation-created path ledger, and test both final non-ignored status and exact owned-output cleanup. **Warning sign:** a test asserts only `git diff --exit-code`.

### Pitfall 2: NUL Output Stored in a Shell Variable

**What goes wrong:** command substitution drops NUL bytes, corrupting status records. **Avoid:** write porcelain bytes to invocation-owned files and compare/parse them with a NUL-aware implementation. **Warning sign:** `status="$(git status --porcelain=v1 -z)"`. [CITED: https://git-scm.com/docs/git-status]

### Pitfall 3: Browser Proof Is Green Only After Retry

**What goes wrong:** the repository claims determinism while CI accepts a flaky first failure. The current config quotes `retries: process.env.CI ? 2 : 0` and traces only on first retry. **Avoid:** repository verification and its CI owner must use zero retries and fail on flaky classification; force a fresh owned server rather than reusing port 4700. [VERIFIED: examples/phoenix_host/playwright.config.ts:5-15,47-50]

### Pitfall 4: Prerequisite Drift Becomes an Expensive Mid-Run Failure

**What goes wrong:** browser, Gradle, or Swift fails after root work because the host toolchain differs. The current machine does not have the checked-in Elixir/Erlang versions installed and has no Java runtime, while Swift/Xcode are present. **Avoid:** first make the tool-version contract complete, then test exact negative preflight fixtures before running any dependency fetch. [VERIFIED: .tool-versions:1-3; environment probe on 2026-09-09]

### Pitfall 5: Artifact Policy Misclassifies a Safe Fixture

**What goes wrong:** a blanket `.env` prohibition rejects the intentionally tracked `examples/phoenix_host/.env`. Its complete quoted contents are `COMPOSE_PROJECT_NAME=crosswake` and `PORT=4700`, and a contract test requires the path. **Avoid:** name it as a narrow safe fixture without generalizing the exception to other `.env` files. [VERIFIED: examples/phoenix_host/.env:1-2; test/crosswake/guides/port_registry_test.exs:4-12]

### Pitfall 6: Cleanup Candidate Review Deletes Authority Sentinels

**What goes wrong:** phase-labelled leaves, duplicate-looking cross-platform fixtures, or dynamic Mix entrypoints look dead by grep. **Avoid:** require entrypoint/workflow searches, dependency tracing, dynamic-dispatch review, focused regression, and the full clean gate; retain uncertainty. [VERIFIED: 166-CONTEXT.md:45-79]

## Code Examples

### Byte-Preserving Repository Snapshot

```bash
# Source: https://git-scm.com/docs/git-status
git status --porcelain=v1 -z --untracked-files=all >"${run_root}/git-before.z"
```

Compare the file after cleanup; never interpolate its contents into shell or print suspicious paths without category filtering.

### Exact Invocation-Owned Cleanup

```bash
# Pattern source: script/check_example_host_isolation.sh:10-14
run_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-repository-verify.XXXXXX")"
cleanup() {
  case "$run_root" in
    "${TMPDIR:-/tmp}"/crosswake-repository-verify.*) rm -rf -- "$run_root" ;;
    *) printf '%s\n' '[crosswake] FAIL cleanup invalid-owned-prefix' >&2 ;;
  esac
}
trap cleanup EXIT
```

The final implementation must additionally preserve the original child exit status and run the final Git snapshot before removing the log root.

## State of the Art

| Old/current approach | Phase 166 approach | Impact |
|----------------------|--------------------|--------|
| Phase-specific fail-fast aggregate | purpose-named dependency-aware repository facade | Independent defects appear in one run while invalid dependency chains remain blocked. [VERIFIED: script/check_phase165_efficient_ci.sh:8-24; 166-CONTEXT.md:107-115] |
| Workflow-copied commands | single stage inventory with executable owner parity | Local/CI drift becomes a test failure. [VERIFIED: 166-CONTEXT.md:20-40] |
| `git add -A` generated drift | explicit path regeneration and byte comparison | No index mutation or unrelated-file staging. [VERIFIED: .github/workflows/crosswake-ci.yml:318-333; 166-CONTEXT.md:87-105] |
| CI-conditioned Playwright retries/server reuse | explicit no-retry, fresh-server repository semantics | Clean-checkout proof measures first-run behavior. [VERIFIED: examples/phoenix_host/playwright.config.ts:5-15,47-50] |
| `.gitignore` as implicit intent | three-class artifact policy plus narrow safe fixtures | Tracked generated and forbidden families become auditable. [VERIFIED: .gitignore:1-68; 166-CONTEXT.md:81-97] |

## Bounded v22 Ownership Inventory

The mechanically reproducible pre-planning anchor is quoted as `8383aaea2a2b2e10bbe61dd843b51f4129a5d447`, the parent of the first v22 requirements commit. A NUL-safe diff from that anchor through current `HEAD` finds 94 non-planning paths: 39 under `.github`, 27 under `test`, 20 under `script`, four under `lib`, and one each under `scripts`, `examples`, root `mix.lock`, and `AGENTS.md`. These are candidate counts, not permanent truth; regenerate them after the final Phase 166 tree. [VERIFIED: `git rev-parse 11c9488dd1502dd5a3cc15a94fda6b295dfe7dd5^`; `git diff --name-only -z 8383aaea2a2b2e10bbe61dd843b51f4129a5d447 HEAD`]

The ownership ledger should record each path's existing owner and disposition, then expand only with a direct edge. Initial direct expansion candidates are `examples/phoenix_host/playwright.config.ts` (invoked by touched `crosswake-ci.yml` and owns retry/server semantics), `lib/mix/tasks/crosswake.contract.gen.ex` plus its eight outputs (invoked by the touched workflow and owns generated drift), and artifact output roots declared by package/build configuration. Do not interpret the 94 paths as 94 mandatory edits.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Node 22.14.0 should become the runner/tool pin; the line is currently an uncommitted working-tree change, not committed `HEAD` authority. | Standard Stack | Runner choice or pin may conflict with concurrent maintainer work; planner must inspect the final tree before tasking. |
| A2 | A shell facade plus Node runner is the best internal split. | Architecture | Bash-only may be preferred, but must still meet manifest, argv, dependency, and output tests. |

## Open Questions

1. **Will the current `.tool-versions` Node pin land before Phase 166 execution?**
   - What we know: the working tree quotes `nodejs 22.14.0`; committed `HEAD` contains only Erlang and Elixir.
   - Recommendation: make toolchain identity the first implementation task and preserve concurrent work rather than overwriting it.
2. **Which existing CI leaf should own the recurring Phase 166 contract?**
   - What we know: Phase 165 requires every stage owner to remain literal and manifest-governed; Phase 166 must not redesign umbrella authority.
   - Recommendation: extend the smallest existing repository-policy leaf if its behavior matches; add a new literal leaf only if the manifest/needs/producer migration is atomic and all parity controls prove it.
3. **How much dependency output should the complete run remove?**
   - What we know: D-04 allows lock-governed dependencies in ignored locations, while D-18 forbids removing pre-existing state.
   - Recommendation: delete only locations the invocation created; preserve a pre-existing ignored cache and prove it was not mutated unless the package manager requires mutation, in which case route the operation to the run root.

## Environment Availability

| Dependency | Required By | Available | Observed version | Fallback |
|------------|-------------|-----------|------------------|----------|
| Git | cleanliness/base ledger | ✓ | 2.41.0 | — |
| GNU Bash | facade | ✓ | 5.2.37 | keep implementation compatible with declared host policy |
| Node/npm | runner/browser | ✓ | 22.14.0 / 11.1.0 | — |
| Checked-in Elixir/Erlang | root/host | ✗ exact versions | host has other installs; asdf reports `1.19.5-otp-27` and `27.3` not installed | explicit preflight failure; maintainer installs declared tools |
| Java | Android | ✗ | no runtime located | explicit `BLOCKED` Android and nonzero complete run |
| Swift | iOS | ✓ | 6.3.3 | — |
| Xcode | iOS | ✓ | 26.6 (17F113) | — |
| actionlint | workflow edits | ✓ | 1.7.12 | — |

The present checkout cannot produce canonical complete-run evidence: it is dirty, lacks exact BEAM tools, and lacks Java. That is an environment observation, not an ENG-01 product failure; the planner should include deterministic preflight negative proof and defer the final full evidence until an isolated exact-commit checkout has all declared tools. [VERIFIED: environment probes and `git status --porcelain=v1 -z` on 2026-09-09]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus Node built-in test runner and existing Python self-tests |
| Config file | `test/test_helper.exs`; package-native configs remain owned by their packages |
| Quick run command | `node --test test/js/repository_verification.test.mjs && mix test test/crosswake/proof/phase166_repository_quality_test.exs` |
| Full suite command | `script/verify_repository.sh` from an isolated clean exact-commit checkout |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ENG-01 | Fixed stage inventory, exact preflight, dependency blocking, same focused/full commands | unit + integration + clean-room | `script/verify_repository.sh --self-test` then full facade | ❌ Wave 0 |
| ENG-02 | v22 base ledger, direct-edge cone, adversarial dead/duplicate/fallback dispositions | structural + focused regression | `mix test test/crosswake/proof/phase166_repository_quality_test.exs` | ❌ Wave 0 |
| ENG-03 | Three artifact classes, safe fixture exception, no index mutation, exact cleanup, clean final status | unit + integration | `node --test test/js/repository_verification.test.mjs` plus isolated facade | ❌ Wave 0 |
| ENG-04 | Stable closed results, bounded output, current purpose names, safe copy/paste remediation | golden/negative output tests | `script/verify_repository.sh --self-test` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** focused new test plus the existing detector/test directly touched.
- **Per wave merge:** `script/check_phase165_efficient_ci.sh`, Phase 166 quick tests, `actionlint` for workflow changes, and every stage changed in the wave.
- **Phase gate:** exact-commit isolated `script/verify_repository.sh`; captured NUL snapshots equal before/after; Git index unchanged; full summary contains no `FAIL` or `BLOCKED`.

### Wave 0 Gaps

- [ ] `test/js/repository_verification.test.mjs` — dependency graph, hostile filenames, cleanup-on-failure, bounded summary, and remediation safety.
- [ ] `test/crosswake/proof/phase166_repository_quality_test.exs` — stage/CI parity, artifact-policy closure, generated-output registry, and ownership-ledger structure.
- [ ] `test/fixtures/repository_quality/` — missing tools, failed/blocked chains, malicious filenames, forbidden artifacts, safe `.env` fixture, generated drift, cleanup failure.
- [ ] `script/check_phase166_clean_checkout_engineering_quality.sh` — recurring credential-free contract, created only after focused controls exist.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No authentication surface; do not add credentials. |
| V3 Session Management | no | No session surface. |
| V4 Access Control | yes, repository/CI authority | Preserve literal CI ownership and never mutate GitHub trust control-plane state. [VERIFIED: 166-CONTEXT.md:33-40] |
| V5 Input Validation | yes | Fixed manifest schema, argv execution, validated repository-relative paths, NUL-safe Git records, exact cleanup prefixes. [VERIFIED: 166-CONTEXT.md:87-105] |
| V6 Cryptography | no | No cryptographic implementation; signing material is forbidden. [VERIFIED: 166-CONTEXT.md:27-32] |

### Known Threat Patterns for Repository Tooling

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Filename/command injection | Tampering / elevation | Never eval or interpolate paths; fixed argv and NUL-safe records. |
| Symlink or prefix escape during cleanup | Tampering / denial of service | Resolve/validate parent and exact invocation prefix; refuse cleanup on mismatch. |
| Secret-bearing artifact disclosure | Information disclosure | Print category + repository-relative path + remediation only; never contents/environment. [VERIFIED: 166-CONTEXT.md:92-97] |
| Staging unrelated changes | Tampering | No `git add`; compare explicit generated paths outside the index. [VERIFIED: 166-CONTEXT.md:98-105] |
| Dirty baseline presented as clean | Spoofing / repudiation | Require empty baseline or isolated exact-commit checkout and preserve before/after snapshots. [VERIFIED: 166-CONTEXT.md:87-91] |
| Missing stage or divergent CI owner | Spoofing | Bidirectional stage/manifest/workflow parity and negative controls. [VERIFIED: 166-CONTEXT.md:33-40] |

## Sources

### Primary (HIGH confidence)

- Phase 166 `CONTEXT.md` — all locked behavior and scope.
- `AGENTS.md`, active requirements/roadmap/state, Phase 164 and 165 contexts — project, privacy, Android, and inherited authority.
- `mix.exs`, example `mix.exs`, `.tool-versions`, `.gitignore`, package manifests/configs — current command and artifact truth.
- `script/ci_leaf_manifest.json`, `script/check_ci_leaf_manifest.py`, `.github/workflows/crosswake-ci.yml` — literal CI identity, remediation, and current staging defect.
- `lib/mix/tasks/crosswake.contract.gen.ex`, contract drift tests — canonical generated-output ownership.
- Current Git/tool/environment probes — v22 candidate ledger and executor availability.

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- [Git status official documentation](https://git-scm.com/docs/git-status) — authoritative page fetched directly, but the configured confidence seam classifies `webfetch` as LOW.
- [Playwright configuration documentation](https://playwright.dev/docs/test-configuration) — used only to corroborate configurable retries/output; repository config remains the implementation authority.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — checked-in tool/version and package sources were opened; the uncommitted Node pin is explicitly gated.
- Architecture: HIGH — dictated by locked decisions and existing manifest/runner seams.
- Pitfalls: HIGH — each major pitfall is visible in current source or explicitly prohibited by context.
- Final environment viability: MEDIUM — current probes are exact but may change before execution.

**Research date:** 2026-09-09
**Valid until:** 2026-10-09 for repository structure; re-probe environment immediately before execution.
