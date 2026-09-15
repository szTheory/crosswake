# Phase 164: Dependency Security and Gate Authority - Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Patch the known Hex dependency advisories in both supported Elixir lockfiles and make the existing
merge-gate surface trustworthy: one stable security result, one producer per required context,
complete ownership of intended ExUnit files, isolated state-mutating tests, and rollups that cannot
turn missing, cancelled, or failed work green. This phase establishes gate correctness; workflow
consolidation, runner migration, cache optimization, and docs-only scheduling belong to Phase 165.

</domain>

<decisions>
## Implementation Decisions

### Dependency remediation
- **D-01:** Update the root and `examples/phoenix_host` lockfiles together. Select the newest fixed
  patch on the currently locked minor line when that closes the advisory; cross a minor line only
  when no fixed release exists on the current line or executable compatibility proof demonstrates
  that the broader already-declared public range is safe.
- **D-02:** Keep the public Phoenix, Phoenix LiveView, and Plug compatibility declarations unchanged
  unless the security fix is impossible inside them. The milestone is not authorization for a
  compatibility-floor expansion or unrelated dependency refresh.
- **D-03:** `mix hex.audit` must pass independently in the root project and example host without Hex
  publishing credentials. The retained result names the affected package and corrective command,
  but does not expose credentials or dump unrelated environment state.
- **D-04:** Add a deterministic negative-control fixture or script test proving the security gate
  rejects an advisory-bearing lock snapshot; never commit an active vulnerable lockfile merely to
  exercise CI.

### Required-context authority
- **D-05:** A single local detector owns the inventory of merge-blocking job contexts across all
  workflow YAML. Duplicate producers, unnamed producers, and required contexts with no producer are
  errors; stable check names are contracts and are not cosmetically renamed.
- **D-06:** Reuse the existing branch-protection audit and registration machinery rather than adding
  a second governance path. Repository-local proof is automated; any unavailable administration
  credential or explicit trust-policy write is surfaced as the one specific maintainer handoff.
- **D-07:** The dependency-security result has exactly one stable producer and is eligible for
  required-check registration only after it is green on `main`.

### Test-file ownership and isolation
- **D-08:** Every intended root `*_test.exs` file must map to at least one merge-blocking execution
  class. The coverage detector understands default/hermetic exclusions and the
  `:requires_example_host` lane; a newly added unowned test file fails with its path and expected
  remediation.
- **D-09:** Preserve the dedicated `:requires_example_host` lane, but treat `--max-cases 1` as the
  documented stopgap it is. Snapshot and restore each mutated Application environment key, BEAM code
  path, temporary file, and database resource, then prove the tagged set both alone and as part of
  the complete suite. Remove serialization only after repeatable parallel evidence is green.
- **D-10:** Prefer narrow `on_exit` restoration helpers and per-test unique resources over global
  suite serialization. Do not hide an isolation defect by excluding a file, weakening async
  coverage, or adding retries.

### Aggregator semantics
- **D-11:** Required aggregation recognizes an explicit closed result vocabulary. `success` passes;
  an explicitly declared irrelevant leaf may report visible neutral; `failure`, `cancelled`,
  `timed_out`, `action_required`, `stale`, `skipped` without an irrelevance declaration, unknown,
  and missing all fail closed.
- **D-12:** Extend the existing aggregator negative control and structural parity proof instead of
  inventing a second rollup convention. A missing required leaf must be tested directly, not inferred
  from only failed/skipped examples.
- **D-13:** Phase 164 may add the minimum security/coverage jobs and correctness helpers needed for
  these requirements. Deduplicating setup, moving runners, path filtering, cache keys, and workflow
  count reduction remain Phase 165 so the optimized topology starts from trusted semantics.

### the agent's Discretion
- Exact helper/module/script names, test-file organization, and whether lockfile mutation fixtures
  are expressed in ExUnit or a small repository script.
- The number of repeated seeds used to demonstrate isolation, provided the retained evidence is
  deterministic and bounded.
- Concise step-summary wording and machine-readable output shape, provided failures remain
  actionable and privacy-safe.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone authority
- `AGENTS.md` — current priority, frozen Android boundary, sensitive-data rules, and automated
  verification policy.
- `.planning/PROJECT.md` — Phoenix-first project thesis, shared decisions, and active-workstream
  boundary.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — SEC-01..03 and CIG-01..04
  acceptance scope.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 164 boundary and its separation
  from Phase 165 optimization.
- `.planning/seeds/SEED-007-ci-cd-performance.md` — source observations behind the CI integrity and
  state-isolation work.

### Dependency and test authority
- `mix.exs` — core public dependency ranges and supported aliases.
- `mix.lock` — root resolved dependency authority.
- `examples/phoenix_host/mix.exs` — example-host dependency ranges and test setup.
- `examples/phoenix_host/mix.lock` — example-host resolved dependency authority.
- `test/test_helper.exs` — canonical root test-tag exclusions and example-host opt-in behavior.
- `test/support/example_host.ex` — example-host code-path and application-state setup boundary.
- `.github/workflows/requires-example-host-gate.yml` — sole current tagged-suite lane and documented
  serialization stopgap.

### Gate and aggregator authority
- `.github/workflows/required-checks-audit.yml` — existing branch-protection detection and human
  authority boundary.
- `script/list_merge_blocking_checks.py` — local discovery of merge-blocking contexts.
- `script/check_required_checks_registered.sh` — fail-closed registration audit semantics.
- `script/register_required_checks.sh` — green-first administration handoff.
- `.github/workflows/aggregator-negative-control.yml` — executable rollup semantics proof.
- `.github/workflows/contract-drift-gate.yml` — canonical sibling-leaf aggregation pattern.
- `.github/workflows/native-behavioral-proof-gate.yml` — native aggregator and frozen Android proof
  boundary.
- `.github/workflows/offline-sync-e2e-gate.yml` — browser/example-host aggregator pattern.
- `.planning/milestones/v20.0-phases/153.1-ci-gate-integrity-and-runner-cost/153.1-CONTEXT.md`
  — prior decisions on producer uniqueness, tagged-suite coverage, and runner-cost evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `script/list_merge_blocking_checks.py` already parses workflow jobs and detects duplicate
  merge-blocking names; extend its contract rather than adding a parallel inventory.
- `script/check_required_checks_registered.sh` and `script/register_required_checks.sh` already
  separate read-only detection from administration writes and preserve green-first registration.
- `re-actors/alls-green` plus the three existing sibling aggregators provide one established rollup
  convention and a negative-control harness.
- `test/support/example_host.ex` centralizes example-host loading, code-path injection, database
  configuration, and endpoint setup, making it the first isolation seam to harden.

### Established Patterns
- Root broad lanes deliberately exclude `:requires_example_host`; one dedicated Ubuntu lane compiles
  the example host and runs that tag.
- Required check names contain `merge-blocking` and are treated as branch-protection contracts.
- Security and proof gates are browser-free where possible and print stable step summaries.
- Global Application configuration mutations are generally repaired with captured prior values and
  `on_exit`; the remaining tagged-lane serialization comment identifies the known debt.

### Integration Points
- Add dependency audit execution at one stable workflow/job boundary, covering both lockfiles.
- Add test-file ownership and context-producer checks to the existing repository-local CI audit
  surface.
- Extend the aggregator negative control and structural tests so missing/cancelled semantics are
  executable, not prose-only.
- Repair state leakage in `test/support/example_host.ex` and the specific tests identified by
  isolation probes; keep product runtime code unchanged unless a test has exposed a real defect.

</code_context>

<specifics>
## Specific Ideas

- Current evidence shows both lockfiles at Phoenix `1.8.7` and Phoenix LiveView `1.1.30`; the root
  lock carries Plug `1.19.1` while the example host carries `1.19.2`. Treat the live audit as the
  authority for exact fixed versions rather than copying these observations into a permanent
  allowlist.
- The repository currently has 170 root `*_test.exs` files and 24 files containing the
  `requires_example_host` marker. The ownership check should derive live paths and tags, not retain
  these counts as truth.
- A clean gate should tell a maintainer which lockfile, check context, or test path needs attention
  in one screenful.

</specifics>

<deferred>
## Deferred Ideas

- Linux/macOS runner placement, trigger deduplication, cache identity, concurrency cancellation,
  docs-only scheduling, timing baselines, and reusable workflow consolidation: Phase 165.
- Broad clean-checkout quality and residue cleanup: Phase 166.
- Open-PR reconciliation and public documentation refresh: Phase 167.
- Version bump, release-candidate proof, immutable tag/package publication: Phase 168; final publish
  remains explicit maintainer approval.

</deferred>

---

*Phase: 164-dependency-security-and-gate-authority*
*Context gathered: 2026-08-28*
