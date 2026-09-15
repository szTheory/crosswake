# Phase 164: Dependency Security and Gate Authority - Research

**Researched:** 2026-08-28
**Domain:** Hex advisory remediation, GitHub required-check authority, ExUnit execution ownership, and fail-closed aggregation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Linux/macOS runner placement, trigger deduplication, cache identity, concurrency cancellation,
  docs-only scheduling, timing baselines, and reusable workflow consolidation: Phase 165.
- Broad clean-checkout quality and residue cleanup: Phase 166.
- Open-PR reconciliation and public documentation refresh: Phase 167.
- Version bump, release-candidate proof, immutable tag/package publication: Phase 168; final publish
  remains explicit maintainer approval.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEC-01 | Maintainers can run the root and example-host dependency audits with zero known security advisories. | Independent unauthenticated `mix hex.audit` invocations, a shared fail-closed wrapper, and exact safe versions are specified below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:11-12] |
| SEC-02 | Phoenix, Phoenix LiveView, Plug, and their lockfiles resolve to patched versions that remain inside Crosswake's declared public compatibility ranges. | The exact current-minor targets and an isolated resolver warning are documented below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:13-14] |
| SEC-03 | Pull requests receive one stable, actionable dependency-security result that fails closed when a known advisory is introduced. | One direct producer, positive audits, and a vulnerable-lock negative control are prescribed below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:15-16] |
| CIG-01 | Every merge-blocking check context has exactly one authoritative producer. | The inventory must become fail-closed and the live registration comparison bidirectional. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:20-21] |
| CIG-02 | Every intended ExUnit test file, including example-host-tagged tests, is exercised by a merge-blocking CI path. | A static execution-class ownership detector with negative fixtures is prescribed below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:22-23] |
| CIG-03 | Tests that mutate application configuration, code paths, files, or databases restore their state and pass both alone and in the full suite. | The central leaking seam and exact restoration pattern are identified below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:24-25] |
| CIG-04 | Required aggregators fail closed for failed, cancelled, or missing required work while allowing explicitly irrelevant work to report a visible neutral result. | The action vocabulary, negative-control extensions, and exact `needs` parity check are specified below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:26-27] |
</phase_requirements>

## Summary

Both supported lockfiles currently fail `mix hex.audit`. The root resolves `phoenix 1.8.7`, `phoenix_live_view 1.1.30`, and `plug 1.19.1`; the example resolves those first two versions plus `plug 1.19.2`, `bandit 1.12.0`, and `hpax 1.0.3`. The verbatim lock entries are `"phoenix" ... "1.8.7"`, `"phoenix_live_view" ... "1.1.30"`, `"plug" ... "1.19.1"` in root and `"bandit" ... "1.12.0"`, `"hpax" ... "1.0.3"`, `"plug" ... "1.19.2"` in the example. [VERIFIED: mix.lock:15-21] [VERIFIED: examples/phoenix_host/mix.lock:2-24]

The exact remediation target is `phoenix 1.8.13`, `phoenix_live_view 1.1.33`, `plug 1.19.5`, `bandit 1.12.5`, and `hpax 1.0.4`. Each is the newest stable release on its currently locked minor line and closes every advisory observed in the corresponding lock. [CITED: https://hex.pm/api/packages/phoenix] [CITED: https://hex.pm/api/packages/phoenix_live_view] [CITED: https://hex.pm/api/packages/plug] [CITED: https://hex.pm/api/packages/bandit] [CITED: https://hex.pm/api/packages/hpax] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-56811] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-64941] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-54892] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-75484]

Gate hardening should extend the repository's established seams. The workflow detector currently skips malformed YAML, silently substitutes job IDs for missing display names, skips dynamic names, and de-duplicates default output; the registration checker then proves only that each discovered candidate is registered. Its verbatim behaviors are `except Exception: continue`, `name = job.get("name") or jid`, `if "${{" in name: continue`, and `for c in sorted(set(contexts))`. [VERIFIED: script/list_merge_blocking_checks.py:56-90] The example-host helper likewise prepends code paths, overwrites Application configuration, starts detached global processes, and leaves the temporary SQLite path unmanaged. [VERIFIED: test/support/example_host.ex:8-15] [VERIFIED: test/support/example_host.ex:27-54] [VERIFIED: test/support/example_host.ex:70-118]

**Primary recommendation:** deliver this phase as four narrow contracts: exact constrained lock remediation, one stable dependency-security producer, one fail-closed context/test-ownership inventory, and exact-state/aggregator negative controls; make no Android, adopter, or Phase-165 topology changes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency resolution and audit | Repository / CI | Hex advisory service | The lockfiles are repository authority; Hex supplies advisory data. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html] |
| Required-context producer inventory | Repository / CI | GitHub branch protection | Workflow YAML defines producers while the protected branch defines the registered policy. [VERIFIED: script/list_merge_blocking_checks.py:2-23] [VERIFIED: script/check_required_checks_registered.sh:23-25] |
| ExUnit execution ownership | Test harness | CI workflow jobs | Tag policy classifies tests; workflow commands establish the merge-blocking execution classes. [VERIFIED: test/test_helper.exs:3-49] [VERIFIED: .github/workflows/requires-example-host-gate.yml:43-94] |
| Test-state restoration | Test harness | Example-host processes/storage | The helper owns injected paths, env, temporary SQLite, Repo, PubSub, and Endpoint lifecycle. [VERIFIED: test/support/example_host.ex:8-118] |
| Aggregator result authority | CI aggregator job | Leaf jobs | Aggregators consume `toJSON(needs)` under `if: always()` and must enforce an exact leaf manifest. [VERIFIED: test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:202-250] |

## Project Constraints (from AGENTS.md)

- Preserve Phoenix-first route-policy/runtime-contract scope; this is infrastructure, not a universal UI framework. Keep runtime ownership explicit and bridge contracts semantic, typed, versioned, and low-frequency. [VERIFIED: AGENTS.md:35-40]
- Preserve honest offline claims and fail-closed explicit denials. Diagnostics/proof are product surface, with one-command host proof preferred over new taxonomy. [VERIFIED: AGENTS.md:41-44]
- Android is frozen; do not add Android features, templates, device proof, parity work, or release requirements. Do not broaden into native UI, new companions, commerce, dashboard, generic sync, background sync, or generic native storage. [VERIFIED: AGENTS.md:45-50]
- Never identify or reidentify the First B2C Adopter. Do not expose raw answers, media, transcripts, credentials, account identifiers, tokens, stable device identifiers, or offline mutation payloads in logs, summaries, or proof artifacts. [VERIFIED: AGENTS.md:52-64]
- Use the explicit `quality-ratchet-release` workstream; keep the adopter lane parked. Default to automated verification and reserve a human handoff only for unavoidable credentials, approvals, or irreversible trust actions. [VERIFIED: AGENTS.md:66-84]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | Project declaration: `elixir 1.19.5-otp-27`; local research runtime: Elixir 1.19.5 | Resolve locks, run audits and ExUnit | Existing project toolchain; do not introduce another dependency manager. The verbatim project declarations are `erlang 27.3` and `elixir 1.19.5-otp-27`. [VERIFIED: .tool-versions:1-2] |
| Hex | 2.5.1 observed locally | Advisory authority and package resolution | `mix hex.audit` reports retired/advisory-bearing locked packages and returns a failing exit status when findings exist. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html] |
| Python + PyYAML | Python 3.14.4 observed; existing `yaml.safe_load` | Parse all workflow YAML into producer records | Extend the existing single detector rather than add another parser. The current parser calls `yaml.safe_load(f)`. [VERIFIED: script/list_merge_blocking_checks.py:28-64] |
| Bash + `gh` + `jq` | bash 3.2-compatible scripts; gh 2.95.0 and jq 1.7.1 observed | Read and update branch protection | Existing scripts already separate read-only audit from green-first admin mutation. [VERIFIED: script/check_required_checks_registered.sh:13-18] [VERIFIED: script/register_required_checks.sh:12-28] |
| `re-actors/alls-green` | Existing `release/v1` reference | Aggregate GitHub `needs` results | Preserve the established rollup convention and strengthen its executable contract. [VERIFIED: .github/workflows/aggregator-negative-control.yml:46-65] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| GitHub Actions contexts | Hosted service | Supplies `needs.<job>.result` as `success`, `failure`, `cancelled`, or `skipped` | Use at workflow aggregation boundaries; translate all non-success results through the closed policy. [CITED: https://docs.github.com/en/actions/learn-github-actions/contexts#needs-context] |
| OSV | Live advisory records | Establish affected ranges and fixed versions | Use to validate the Hex audit's exact minimum safe release, not as a runtime dependency. [CITED: https://api.osv.dev/v1/vulns/EEF-CVE-2026-56811] |
| ExUnit `on_exit` | Elixir standard test framework | Restore global state and delete resources | Register restoration at the same boundary that mutates state. [CITED: https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#on_exit/2] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending the existing workflow detector | A second inventory script | Rejected by D-05; two authorities can drift. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:35-38] |
| Exact constrained resolution | Naïve `mix deps.update phoenix phoenix_live_view plug` | An isolated resolver probe selected LiveView 1.2 and Plug 1.20 because `~> 1.1` and `~> 1.16` permit later minors; that violates D-01 despite satisfying the manifests. Keep the public declarations unchanged and constrain the mutation procedure instead. [VERIFIED: mix.exs:47-58] [VERIFIED: examples/phoenix_host/mix.exs:70-100] |
| Narrow restoration helpers | `--max-cases 1`, retries, or broader exclusions | Serialization remains a stopgap and does not repair leaked global state. [VERIFIED: .github/workflows/requires-example-host-gate.yml:77-94] |
| `allowed-failures` | Explicit `allowed-skips` only for declared irrelevant leaves | `allowed-failures` would authorize failed/cancelled work and violates the closed policy. [CITED: https://github.com/re-actors/alls-green/blob/release/v1/action.yml] |

**Installation:** no new package is required. Use the existing Elixir, Hex, Python/PyYAML, Bash, `gh`, `jq`, and action stack. [VERIFIED: script/list_merge_blocking_checks.py:28-53]

## Package Legitimacy Audit

Not applicable: Phase 164 introduces no new package names. It updates already-declared Hex dependencies and reuses existing repository tools; the GSD legitimacy seam supports npm, PyPI, and crates rather than Hex. [VERIFIED: mix.exs:39-59] [VERIFIED: examples/phoenix_host/mix.exs:70-101]

## Exact Dependency Remediation

| Package | Current lock(s) | Advisories observed | Fixed on current line | Prescribed lock target | Published |
|---------|-----------------|--------------------|-----------------------|------------------------|-----------|
| Phoenix | root/example `1.8.7` | EEF-CVE-2026-56811, EEF-CVE-2026-56812 | `1.8.9` | `1.8.13` | 2026-08-25 [CITED: https://hex.pm/api/packages/phoenix] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-56811] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-56812] |
| Phoenix LiveView | root/example `1.1.30` | EEF-CVE-2026-64941 | `1.1.33` | `1.1.33` | 2026-08-10 [CITED: https://hex.pm/api/packages/phoenix_live_view] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-64941] |
| Plug | root `1.19.1`; example `1.19.2` | EEF-CVE-2026-8468, -56813, -56814, -54892 | all closed at `1.19.5` | `1.19.5` | 2026-07-09 [CITED: https://hex.pm/api/packages/plug] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-8468] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-56813] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-56814] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-54892] |
| Bandit | example `1.12.0` | EEF-CVE-2026-65623, -74836, -75484 | all closed at `1.12.5` | `1.12.5` | 2026-08-20 [CITED: https://hex.pm/api/packages/bandit] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-65623] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-74836] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-75484] |
| hpax | example `1.0.3` | EEF-CVE-2026-58226 | `1.0.4` | `1.0.4` | 2026-07-05 [CITED: https://hex.pm/api/packages/hpax] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-58226] |

The public compatibility declarations can remain verbatim: root `{:phoenix, "~> 1.8"}` and `{:phoenix_live_view, "~> 1.1"}`; example `{:phoenix, "~> 1.8"}`, `{:phoenix_live_view, "~> 1.1"}`, `{:plug, "~> 1.16"}`, and `{:bandit, "~> 1.0"}`. Every prescribed target satisfies those declarations. [VERIFIED: mix.exs:47-58] [VERIFIED: examples/phoenix_host/mix.exs:81-100]

Do not use an unconstrained update command as the plan action. Resolve from a disposable copy with temporary exact constraints or another explicit Mix constraint mechanism, inspect the complete lock diff, copy only the intended coherent resolution, restore unchanged manifests, and run `mix deps.get --check-locked`, compile/tests, and both audits. Any collateral transitive change must be explained as resolver-required; reject unrelated refresh. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Update.html] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:20-33]

## Architecture Patterns

### System Architecture Diagram

```text
pull request / push
  -> dependency-security job (one stable display name)
       -> root mix.hex.audit ---------+
       -> example mix.hex.audit ------+-> sanitized package + corrective-command summary -> one result
       -> vulnerable-lock fixture ----+   (any finding/tool error/missing result => failure)

.github/workflows/*.{yml,yaml}
  -> single strict detector -> {context -> exact producer path/job}
       <-> live protected-branch contexts (read-only audit)
       -> duplicate / unnamed / dynamic / malformed / missing producer => failure
       -> green-on-main context -> existing admin registrar -> branch protection

root test files + test_helper exclusions + CI execution-class manifest
  -> ownership detector -> every intended file has default/hermetic or requires-example-host owner
  -> isolated helper lifecycle -> restore env/path/process/file/database

leaf jobs -> exact expected needs set -> if: always() -> alls-green closed policy -> required aggregator
```

### Recommended Project Structure

```text
script/
├── list_merge_blocking_checks.py       # sole strict producer inventory
├── check_required_checks_registered.sh # bidirectional live policy comparison
├── register_required_checks.sh         # existing green-first admin write
├── check_dependency_security.sh        # both audits and concise failure summary
└── check_exunit_ownership.exs           # static file/tag-to-execution-class proof
.github/workflows/
├── dependency-security.yml             # exactly one stable security producer
└── aggregator-negative-control.yml      # expanded closed-vocabulary proof
test/
├── fixtures/security/                   # inactive vulnerable-lock snapshot
├── support/example_host.ex              # owned resource lifecycle
└── crosswake/proof/                      # detector, ownership, parity negative controls
```

Paths above are recommendations under D-04/D-05 and the agent's naming discretion, not existing discrete values. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:31-38] [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:70-76]

### Pattern 1: One direct security producer

**What:** Add one job whose literal display name contains `merge-blocking` and whose steps run the root and example audit independently, then run the inactive vulnerable fixture and assert rejection. Do not hide an audit failure with workflow-level `continue-on-error`; capture command status only inside the wrapper so both projects are reported before the wrapper returns nonzero. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:28-43]

**When to use:** On every PR/push under the existing trigger model; trigger consolidation is Phase 165. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:66-68]

### Pattern 2: Strict producer inventory plus bidirectional policy comparison

**What:** Make the Python detector return records for every literal job display name and fail parsing errors. Treat missing names or expressions as errors whenever the job is required-style or matches a registered context. Keep the `merge-blocking` candidate set for green-first registration, but compare live registered contexts against the full producer map as well as candidates against registration. [VERIFIED: script/list_merge_blocking_checks.py:56-90] [VERIFIED: script/check_required_checks_registered.sh:64-85]

**Why:** The live branch currently includes a required context named `brand-structural`, while the local candidate detector deliberately discovers only names containing `merge-blocking`; therefore an exact candidate-set comparison would be wrong. The authoritative conditions are: each registered context has exactly one producer, and each local merge-blocking candidate is registered. [VERIFIED: script/list_merge_blocking_checks.py:4-7] [VERIFIED: script/check_required_checks_registered.sh:71-85]

### Pattern 3: Static ExUnit execution ownership

**What:** Parse `test/**/*_test.exs` as Elixir syntax, ignoring comments/string fixtures, and classify executable module/test tags against an explicit execution-class manifest. The current default exclusions are verbatim `:advisory_only`, `:collateral_binaries`, `:engine_present`, and `:requires_example_host`; the dedicated class executes `mix test --only requires_example_host --max-cases 1`. [VERIFIED: test/test_helper.exs:13-47] [VERIFIED: .github/workflows/requires-example-host-gate.yml:77-94]

**When to use:** Run it in an existing merge-blocking hermetic proof class. A new file that has no runnable tests in a declared merge-blocking class must fail with its path, effective exclusions, and either “remove/move the exclusion” or “add the file's class to a merge-blocking lane.” [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:45-56]

### Pattern 4: Exact resource ownership

**What:** Introduce a support helper that snapshots `Application.fetch_env/2` (distinguishing absent from present), registers `on_exit` immediately, and restores with `put_env` or `delete_env` exactly. Make `ExampleHost.load!` return added code paths and remove those paths on exit; make Repo/PubSub/Endpoint starts return owned PIDs, stop only owned processes, restore prior config, and delete only the unique temp database/files created by the test. [CITED: https://hexdocs.pm/elixir/Application.html#fetch_env/2] [CITED: https://hexdocs.pm/elixir/Code.html#delete_path/1] [CITED: https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#on_exit/2]

**When to use:** Every test that changes Application env, code path, temp files, or databases. The present helper's verbatim mutating calls include `Code.prepend_path/1`, `Application.put_env(:crosswake_example, repo, ...)`, and `Process.unlink(pid)`. [VERIFIED: test/support/example_host.ex:8-15] [VERIFIED: test/support/example_host.ex:34-45] [VERIFIED: test/support/example_host.ex:103-117]

### Pattern 5: Closed aggregation plus exact leaf parity

**What:** Keep `if: always()` and pass `${{ toJSON(needs) }}` to alls-green. Add synthetic `cancelled`, explicitly allowed `skipped`, disallowed `skipped`, unknown, and empty/missing arms. Separately change structural proof from “expected leaves are a subset” to exact set equality, and add a fixture where one expected leaf is absent. [VERIFIED: .github/workflows/aggregator-negative-control.yml:46-84] [VERIFIED: test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:202-250]

GitHub's `needs` context exposes only `success`, `failure`, `cancelled`, and `skipped`; check-run conclusions such as `timed_out`, `action_required`, and `stale` must still be treated as non-success at any API/reporting boundary. The action's declared allowed-skip input is the narrow mechanism for a visible neutral leaf; do not use allowed failures. [CITED: https://docs.github.com/en/actions/learn-github-actions/contexts#needs-context] [CITED: https://github.com/re-actors/alls-green/blob/release/v1/action.yml]

### Anti-Patterns to Avoid

- **Naïve dependency refresh:** broad declared ranges can resolve a later minor; constrain the resolver and review the full lock diff. [VERIFIED: mix.exs:47-58] [VERIFIED: examples/phoenix_host/mix.exs:86-93]
- **Audit allowlists:** the acceptance criterion is zero advisories in each supported lock, so do not configure ignored advisories. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:9-16]
- **Silent parser recovery:** malformed YAML, non-map `jobs`, unnamed required producers, and dynamic required names must be errors, not `continue`. [VERIFIED: script/list_merge_blocking_checks.py:61-80]
- **One-directional registration:** `declared ⊆ registered` does not prove every required context has a producer. [VERIFIED: script/check_required_checks_registered.sh:71-85]
- **Substring tag discovery:** comments and fixture strings can contain `requires_example_host`; parse executable syntax and derive file ownership, not counts. [VERIFIED: test/test_helper.exs:31-46]
- **Default-value restoration:** `get_env(..., [])` followed by `put_env` cannot distinguish an absent key from a present empty value; snapshot presence with `fetch_env`. [CITED: https://hexdocs.pm/elixir/Application.html#fetch_env/2]
- **Stopping unowned processes:** `already_started` means the fixture does not own that PID; never stop it during cleanup. [VERIFIED: test/support/example_host.ex:42-45] [VERIFIED: test/support/example_host.ex:111-117]
- **Subset-only `needs` validation:** the current `missing_needs` rejects absent expected leaves but accepts unexpected additions; enforce exact equality. [VERIFIED: test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:239-250]
- **Scope bleed:** no runner migration, trigger/cache/concurrency optimization, workflow consolidation, Android work, or adopter activation belongs here. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:66-68] [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:90-98]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Advisory database | Local CVE allow/deny table | `mix hex.audit` backed by Hex/OSV | The advisory corpus changes and Hex already supplies package-aware exit semantics. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html] |
| YAML parsing | Regex/indent parser | Existing PyYAML `safe_load` detector | Workflow YAML contains mappings, expressions, and alternate extensions; the existing parser is already the authority. [VERIFIED: script/list_merge_blocking_checks.py:25-64] |
| Required-check administration | New API client or workflow | Existing checker/registrar with `gh`/`jq` | It already preserves strict/existing checks and requires green-on-main before mutation. [VERIFIED: script/register_required_checks.sh:22-28] [VERIFIED: script/register_required_checks.sh:75-114] |
| Test process/storage cleanup | Global reset or suite retry | ExUnit `on_exit`, owned PIDs, unique temp paths | Cleanup must be scoped to resources the test actually created. [CITED: https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#on_exit/2] |
| Rollup action | Custom workflow-expression truth table | Existing alls-green plus exact structural proof | Preserve one established convention and prove its closed policy. [VERIFIED: .github/workflows/aggregator-negative-control.yml:6-27] |

**Key insight:** this phase is an authority repair. The trusted result must be derived from live lockfiles, workflow producers, executable test tags, exact resource ownership, and exact aggregator leaves; copied counts, prose, and one-directional checks are not authorities.

## Common Pitfalls

### Pitfall 1: The safe target resolves, but the lock update is broader than intended

**What goes wrong:** Mix selects the newest version admitted by a broad `~>` declaration, including a later minor, and refreshes unrelated transitives. **Why:** public compatibility ranges are intentionally broader than this security patch policy. **Avoid:** exact temporary constraints, full lock-diff review, unchanged committed manifests, `--check-locked`, both audits, and tests. **Warning signs:** LiveView `1.2.x`, Plug `1.20.x`, or unexplained lock churn. [VERIFIED: mix.exs:47-58] [VERIFIED: examples/phoenix_host/mix.exs:86-93]

### Pitfall 2: “All discovered checks are registered” is mistaken for full authority

**What goes wrong:** a registered context with no producer is never inspected. **Why:** the current loop iterates only `DECLARED` and tests membership in `registered`. **Avoid:** compare both directions using the full literal producer inventory. **Warning signs:** the success summary reports only declared candidate count. [VERIFIED: script/check_required_checks_registered.sh:71-85]

### Pitfall 3: Tag inventory counts comments instead of executable ownership

**What goes wrong:** a file containing a tag name in prose appears covered even when no test runs. **Why:** raw `rg` is lexical. **Avoid:** parse Elixir syntax and classify module-level and per-test tags. **Warning signs:** hard-coded file counts or a detector that never identifies an individual test directive. [VERIFIED: .github/workflows/requires-example-host-gate.yml:7-18] [VERIFIED: .github/workflows/requires-example-host-gate.yml:91-101]

### Pitfall 4: Cleanup changes pre-existing state

**What goes wrong:** a fixture deletes a key/process/path it did not create or restores absence as an empty value. **Why:** current setup treats `already_started` as success and detaches processes for indefinite reuse. **Avoid:** return ownership tokens from setup and cleanup only owned resources. **Warning signs:** `Process.unlink`, `already_started -> :ok`, `put_env` without a prior presence snapshot, or temp filenames never removed. [VERIFIED: test/support/example_host.ex:34-54] [VERIFIED: test/support/example_host.ex:103-117]

### Pitfall 5: Aggregator behavior is tested, but its input set is not

**What goes wrong:** alls-green correctly rejects bad values yet never receives a missing leaf because it was removed from `needs`. **Why:** `toJSON(needs)` can only serialize declared dependencies, and current parity proof checks missing expected leaves but not an exact manifest abstraction. **Avoid:** exact set equality and a direct missing-leaf fixture. **Warning signs:** only failure/skipped synthetic cases and no mutation of the expected leaf set. [VERIFIED: .github/workflows/aggregator-negative-control.yml:18-24] [VERIFIED: test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:239-250]

### Pitfall 6: A required check is registered before GitHub has produced it on main

**What goes wrong:** every PR waits for an impossible context. **Avoid:** land advisory first, observe the one security job green on `main`, then use the existing allowlisted registrar. **Warning signs:** registration in the same change that first introduces the producer. [VERIFIED: script/register_required_checks.sh:22-25] [VERIFIED: script/register_required_checks.sh:75-93]

## Code Examples

Verified patterns from official sources:

### Exact Application environment restoration

```elixir
# Source: https://hexdocs.pm/elixir/Application.html#fetch_env/2
# Source: https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#on_exit/2
before = Application.fetch_env(app, key)

on_exit(fn ->
  case before do
    {:ok, value} -> Application.put_env(app, key, value)
    :error -> Application.delete_env(app, key)
  end
end)

Application.put_env(app, key, temporary_value)
```

`{:ok, value}` and `:error` are quoted verbatim from the official `Application.fetch_env/2` return contract. [CITED: https://hexdocs.pm/elixir/Application.html#fetch_env/2]

### Fail-closed dual audit wrapper shape

```bash
# Source: https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html
status=0
(cd "$root_dir" && mix hex.audit) || status=1
(cd "$example_dir" && mix hex.audit) || status=1
exit "$status"
```

The implementation must resolve `root_dir` and `example_dir` from the script location, emit only package/path/corrective-command summaries, and run the negative control separately so an expected fixture failure cannot mask a real-lock failure. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:28-33]

### Explicit neutral aggregation

```yaml
# Source: https://github.com/re-actors/alls-green/blob/release/v1/action.yml
- uses: re-actors/alls-green@release/v1
  with:
    jobs: ${{ toJSON(needs) }}
    allowed-skips: explicitly-irrelevant-leaf
```

The leaf name above is illustrative, not an in-repo discrete value. The planner must substitute only a real leaf explicitly classified as irrelevant; otherwise omit `allowed-skips`. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:58-65]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Advisory awareness from lock age | Executable `mix hex.audit` with nonzero exit and OSV-linked records | Current Hex 2.5.1 docs | Security becomes a gate, not a report. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html] |
| Required-context name presence | Exact producer cardinality plus bidirectional registered-policy comparison | Phase 164 target | Prevents both duplicate masking and missing producers. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:35-43] |
| Serialized stateful tagged suite | Owned-resource restoration, repeated parallel evidence, then serialization removal | Phase 164 target | Converts ordering luck into isolation proof. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:45-56] |
| Failed/skipped action samples | Closed result vocabulary plus exact leaf-set proof | Phase 164 target | Missing work cannot disappear before aggregation. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:58-65] |

**Deprecated/outdated:**

- The current comments claiming fixed example-host file/test counts are stale-prone; derive counts live and report paths. [VERIFIED: .github/workflows/requires-example-host-gate.yml:7-18] [VERIFIED: .github/workflows/requires-example-host-gate.yml:91-101]
- The detector's silent YAML skip and job-ID fallback are incompatible with D-05. [VERIFIED: script/list_merge_blocking_checks.py:61-80]
- `--max-cases 1` remains only until bounded repeated parallel proof passes; it must not become the final isolation mechanism. [VERIFIED: .github/workflows/requires-example-host-gate.yml:80-94]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Recommendations are derived from locked context, opened repository sources, and official Hex/OSV/GitHub/Elixir sources. | — | — |

## Open Questions (RESOLVED)

1. **Exact constrained lock tuple set.** A disposable copy of the current tree temporarily pinned
   the five D-01 targets and every candidate collateral package, then ran Mix resolution without
   editing either canonical manifest or lock. The broad resolver result was rejected. Re-running
   with the old compatible collateral versions pinned proved that only `plug_crypto 2.2.0` is
   required outside the five named targets; Phoenix 1.8.13 requires its `~> 2.2` line. The complete
   allowed changed-entry set is therefore:

   | Lock | Target tuples | Resolver-required collateral | Proved unchanged candidate collateral |
   |------|---------------|------------------------------|---------------------------------------|
   | `mix.lock` | `phoenix 1.8.7 -> 1.8.13`; `phoenix_live_view 1.1.30 -> 1.1.33`; `plug 1.19.1 -> 1.19.5` | `plug_crypto 2.1.1 -> 2.2.0` | `phoenix_pubsub 2.2.0`; `websock_adapter 0.5.9` |
   | `examples/phoenix_host/mix.lock` | `bandit 1.12.0 -> 1.12.5`; `hpax 1.0.3 -> 1.0.4`; `phoenix 1.8.7 -> 1.8.13`; `phoenix_live_view 1.1.30 -> 1.1.33`; `plug 1.19.2 -> 1.19.5` | `plug_crypto 2.1.1 -> 2.2.0` | `decimal 3.1.0`; `elixir_make 0.9.0`; `phoenix_pubsub 2.2.0`; `websock_adapter 0.5.9` |

   The implementation may reproduce that disposable resolver procedure, but any changed lock key
   outside these two exact sets is unrelated refresh and must fail review. [VERIFIED: disposable
   exact-constraint probe executed 2026-08-28; canonical `mix.exs`,
   `examples/phoenix_host/mix.exs`, and both locks remained unchanged]

2. **Bounded isolation seed authority.** The fixed seed set is exactly `17`, `101`, and `1009`.
   Each seed must execute both the `requires_example_host` class and the complete root suite, for
   six required seed/class combinations total. The serialization stopgap may be removed only after
   the unfiltered six-run command and residue assertions pass. [VERIFIED:
   .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:50-56]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | dependency resolution, audits, tests | ✓ | Elixir 1.19.5; local OTP 28.4.1 | CI uses `.tool-versions` OTP 27.3 / Elixir 1.19.5-otp-27. [VERIFIED: .tool-versions:1-2] |
| Hex | advisory audit | ✓ | 2.5.1 | None; install/update Hex if missing. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html] |
| Python | workflow detector | ✓ | 3.14.4 | None within current detector. [VERIFIED: script/list_merge_blocking_checks.py:1-29] |
| PyYAML | workflow parsing | ✓ in this research environment | runtime import | Existing script attempts self-bootstrap, but Phase 165—not 164—owns setup consolidation. [VERIFIED: script/list_merge_blocking_checks.py:28-53] |
| `gh` | live registration audit/admin handoff | ✓ | 2.95.0 | Local producer proof remains available; live policy is UNVERIFIED, not pass, without credentials. [VERIFIED: script/check_required_checks_registered.sh:64-68] |
| `jq` | branch-protection JSON | ✓ | 1.7.1 | None in existing scripts. [VERIFIED: script/check_required_checks_registered.sh:71-75] |

**Missing dependencies with no fallback:** none observed.

**Missing dependencies with fallback:** live branch-protection write authority is intentionally not required for implementation; after the new result is green on `main`, the only human handoff is the existing explicit `DRY_RUN=0` registration command with admin-scoped `gh` auth. [VERIFIED: script/register_required_checks.sh:12-28]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under Elixir 1.19.5, plus executable repository scripts [VERIFIED: .tool-versions:1-2] |
| Config file | `test/test_helper.exs`; verbatim entry point `ExUnit.start()` [VERIFIED: test/test_helper.exs:1-1] |
| Quick run command | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs -x` (recommended Wave 0 file) |
| Full suite command | `mix test` plus `mix test --only requires_example_host` after example-host dev compilation [VERIFIED: test/test_helper.exs:31-46] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-01 | Both canonical locks have zero advisories independently | integration | `script/check_dependency_security.sh` | ❌ Wave 0 |
| SEC-02 | Exact safe current-minor versions resolve inside unchanged public ranges | structural + integration | `mix deps.get --check-locked && (cd examples/phoenix_host && mix deps.get --check-locked)` | Existing commands; exact assertions ❌ Wave 0 |
| SEC-03 | One producer; advisory-bearing fixture fails closed with actionable package/path | negative control | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs -x` | ❌ Wave 0 |
| CIG-01 | Unique literal producers; malformed/unnamed/dynamic/missing producer fail | unit + live audit | `mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs -x` and `script/check_required_checks_registered.sh` | Partial ✅; extend in Wave 0 [VERIFIED: test/crosswake/proof/phase153_1_gate_integrity_test.exs:30-145] |
| CIG-02 | Every intended root test file has a merge-blocking execution class | structural negative control | `script/check_exunit_ownership.exs` | ❌ Wave 0 |
| CIG-03 | Global state/resources restore; tagged class passes alone and full suite across fixed seeds | unit + integration | bounded loop over `mix test --only requires_example_host --seed N` and `mix test --seed N` | Helper tests ❌ Wave 0; suite exists [VERIFIED: .github/workflows/requires-example-host-gate.yml:77-94] |
| CIG-04 | Failed/cancelled/skipped/unknown/missing fail; explicit irrelevant skip passes | workflow negative control + structural | existing aggregator workflow and `mix test test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs -x` | Partial ✅; extend in Wave 0 [VERIFIED: .github/workflows/aggregator-negative-control.yml:46-84] [VERIFIED: test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:146-250] |

### Sampling Rate

- **Per task commit:** the focused phase-164 ExUnit file or changed detector command.
- **Per wave merge:** `mix test`, the example-host-tagged class, both audits, context inventory, and aggregator parity proof.
- **Phase gate:** both audits clean; all detector negative controls prove non-vacuity; bounded isolation matrix green; full root suite green before `$gsd-verify-work`.

### Wave 0 Gaps

- [ ] `script/check_dependency_security.sh` and an inactive vulnerable-lock fixture.
- [ ] `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` for lock targets, security negative control, and single producer.
- [ ] Strict fixture support for `script/list_merge_blocking_checks.py`: duplicate, malformed, unnamed, dynamic, and required-without-producer.
- [ ] `script/check_exunit_ownership.exs` plus owned/unowned and comment/string false-positive fixtures.
- [ ] Exact Application env/path/process/file/database restoration helper tests.
- [ ] Aggregator cancelled/allowed-skip/unknown/empty cases and direct missing-leaf structural fixture.

No new test framework installation is required. [VERIFIED: test/test_helper.exs:1-49]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No product authentication changes; Hex publishing credentials are explicitly absent. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:28-30] |
| V3 Session Management | no | No browser or backend session behavior is in scope. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:9-13] |
| V4 Access Control | yes, governance only | Branch-protection reads are automated; only the existing green-first registrar may perform the admin write. [VERIFIED: script/register_required_checks.sh:7-28] |
| V5 Input Validation | yes | `yaml.safe_load`, strict document/job/name types, literal context names, closed result vocabulary, exact leaf sets, and validated fixture paths. [VERIFIED: script/list_merge_blocking_checks.py:56-82] |
| V6 Cryptography | no | No cryptographic primitive or secret-handling implementation is introduced; never hand-roll crypto. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:9-13] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Duplicate required-check display names let a green producer mask a red producer | Spoofing / Tampering | Literal name inventory with exactly-one producer and negative fixtures. [VERIFIED: script/check_required_checks_registered.sh:40-61] |
| Missing leaf disappears from `needs` and is never evaluated | Tampering | Exact expected-vs-declared leaf-set equality plus direct missing-leaf test. [VERIFIED: test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs:202-250] |
| Malformed or dynamic workflow input is silently ignored | Tampering | Fail parsing/type/name errors; no `continue` or expression skip for authority-bearing jobs. [VERIFIED: script/list_merge_blocking_checks.py:61-80] |
| Vulnerable network parsing dependencies enable resource exhaustion | Denial of Service | Patch Phoenix/Plug/Bandit/hpax to the exact safe targets and gate both locks. [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-56811] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-54892] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-74836] [CITED: https://osv.dev/vulnerability/EEF-CVE-2026-58226] |
| Audit output leaks credentials or unrelated environment | Information Disclosure | No publishing credentials; emit only project/affected package/corrective command and sanitized summary. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md:28-30] |
| Test cleanup deletes another test's process/config/file | Tampering / Denial of Service | Ownership tokens, exact prior-state snapshots, unique resources, and cleanup only of owned state. [CITED: https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#on_exit/2] |

No adopter payload or identity belongs in any fixture, log, audit summary, or evidence artifact. [VERIFIED: AGENTS.md:52-64]

## Sources

### Primary (HIGH confidence)

- [Hex `mix hex.audit`](https://hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html) — task behavior and exit semantics.
- [Hex package API](https://hex.pm/api/packages/phoenix) — current releases and publish timestamps; equivalent official endpoints checked for LiveView, Plug, Bandit, and hpax.
- [OSV EEF-CVE-2026-56811](https://osv.dev/vulnerability/EEF-CVE-2026-56811) and linked EEF records — affected/fixed ranges for all live Hex findings.
- [GitHub `needs` context](https://docs.github.com/en/actions/learn-github-actions/contexts#needs-context) — job-result vocabulary.
- [`re-actors/alls-green` action contract](https://github.com/re-actors/alls-green/blob/release/v1/action.yml) — allowed failures/skips inputs.
- [Elixir Application](https://hexdocs.pm/elixir/Application.html#fetch_env/2), [Code](https://hexdocs.pm/elixir/Code.html#delete_path/1), and [ExUnit callbacks](https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#on_exit/2) — exact restoration primitives.
- Opened repository sources cited inline — current locks, manifests, workflows, detectors, tag policy, and helper lifecycle.

### Secondary (MEDIUM confidence)

- None used for prescriptive claims.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing tools and versions were opened or executed; official task contracts were checked.
- Dependency targets: HIGH — live Hex audit findings were cross-checked against official Hex release data and OSV fixed ranges.
- Architecture: HIGH — recommendations extend locked decisions and opened code seams.
- Pitfalls: HIGH — each is demonstrated by opened current code or an official contract.

**Research date:** 2026-08-28
**Valid until:** 2026-09-04 for advisory/package versions; architecture findings remain valid until the cited files change.
