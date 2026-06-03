# Phase 47: Companion Arc Guide And Milestone Proof - Research

**Researched:** 2026-05-31  
**Domain:** Companion docs-contract parity + milestone hermetic proof posture (Elixir/Phoenix)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep one canonical `guides/companions.md` for Phase 47. Do not split into per-companion guide files yet. A single guide is the least surprising shape for milestone closure, keeps ExDoc navigation simple, and gives docs-contract tests one authoritative product surface to lock.
- **D-02:** Restructure the one guide by reader intent, using a Diataxis-like shape inside the file: quick orientation, concepts, how-to/examples, reference/truth tables, proof posture, and non-goals. This keeps the file useful for both first-hour adopters and maintainers without creating a docs tree before the companion surface justifies it.
- **D-03:** The guide should lead with the companion contract before individual companions: `Crosswake.Companion`, six callbacks, in-tree location, host config registration, optional dependency validation, telemetry span, and fail-closed semantics.
- **D-04:** The Rulestead section should remain the route-gating exemplar: `gated_by`, `on_unavailable`, `:gate_denied`, `:kill_switch_active`, `MockFlagSource`, gate-state truth, and the advisory promotion path.
- **D-05:** Add a Rindle section as the non-gating media exemplar. It should document `UploadGrant`, `CaptureEvidence`, `MediaObject`, backend-owned verification, `:queued | :uploaded | :scanning | :available | :rejected`, mock upload/verify flow, and the rule that device evidence cannot promote availability.
- **D-06:** Add a Sigra section as the contract-only auth exemplar. It should document `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`, `auth_min_level`, `requires_recent_auth`, and `:step_up_required`, while saying plainly that v3.5 ships route predicates and fail-closed denial only.
- **D-07:** The guide should avoid marketing language and avoid implying a generic plugin bus. Companions are first-party, typed, semantic, route-local or contract-local seams that can only further restrict or clarify authority.
- **D-08:** Upgrade `test/crosswake/guides/companions_test.exs` beyond current string-anchor coverage. Keep explicit anchor assertions for readable failures, but add live-code set parity checks against canonical sources.
- **D-09:** Required guide anchors include:
  `Crosswake.Companion`, `companion_id`, `enabled?`, `route_gated?`,
  `kill_switch_active?`, `validate_dependency`, `report_state`,
  `lib/crosswake/companions/<name>/`, `[:crosswake, :companion, :validate_dependency]`,
  `gated_by`, `on_unavailable`, `:gate_denied`, `:kill_switch_active`,
  `UploadGrant`, `CaptureEvidence`, `MediaObject`, `AuthContext`,
  `SessionAuthorityLane`, `auth_min_level`, `requires_recent_auth`,
  `:step_up_required`, `companion.dependency_missing`,
  `auth.step_up_required_contract`, `Crosswake.SupportMatrix.gating_truth/0`,
  and `Crosswake.SupportMatrix.auth_contract_truth/0`.
- **D-10:** Live-code guards should assert exported functions/modules exist for
  the documented surface: `Crosswake.Companion`, `Crosswake.Companion.State`,
  `Crosswake.Companions.Rulestead`, `Crosswake.Companions.Rindle`,
  `Crosswake.Companions.Sigra.Contracts`,
  `Crosswake.Companions.Rulestead.MockFlagSource.set_flag/2`,
  `Crosswake.SupportMatrix.gating_truth/0`, and
  `Crosswake.SupportMatrix.auth_contract_truth/0`.
- **D-11:** Add set-style parity where practical rather than only checking
  keyword presence. Recommended checks:
  - documented companion IDs include `:rulestead` and `:rindle`;
  - guide includes route predicates from `SupportMatrix.auth_contract_truth/0`;
  - guide includes auth denial vocabulary from `auth_contract_truth/0`;
  - guide includes gate denial reasons from `Crosswake.Shell.Denial.reasons/0`
    or the closest exported denial vocabulary source;
  - guide includes doctor codes emitted by the companion dependency and auth
    posture findings.
- **D-12:** Avoid snapshot-only docs tests. Snapshot diffs are useful in some
  ecosystems, but they invite "accept the snapshot" drift and are weaker than
  targeted semantic parity for this product-contract surface.
- **D-13:** Tests should stay idiomatic ExUnit: no new test dependency, no
  brittle Markdown parser unless needed, clear assertion messages, `setup_all`
  with `File.read!`, and small helper functions inside the test module if they
  make parity assertions readable.
- **D-14:** Do not satisfy Phase 47 by relying only on existing Phase 43 and
  Phase 45 lanes. The roadmap explicitly asks for milestone-level hermetic
  proof; the aggregate claim must be asserted somewhere.
- **D-15:** Prefer one aggregate ExUnit proof module over a brand-new duplicated
  CI island. Recommended file: `test/crosswake/proof/phase47_companion_arc_test.exs`.
  It should be untagged so existing hermetic lanes running
  `mix test --exclude requires_example_host --exclude advisory_only` pick it up.
- **D-16:** The aggregate proof should register the shipped companion modules
  together where appropriate and assert enabled-but-missing optional dependency
  paths emit `companion.dependency_missing` `:error` findings for Rulestead and
  Rindle without crashing or silently passing.
- **D-17:** The Sigra proof in Phase 47 should be contract/auth-predicate
  oriented, not optional-dependency oriented. Sigra is contract-only in v3.5, so
  the aggregate proof should assert `auth_contract_truth/0`, route predicate
  anchors, and `:step_up_required` posture rather than inventing a missing
  optional dependency check for Sigra.
- **D-18:** If CI wiring is needed, minimally extend an existing hermetic proof
  workflow or shared hermetic test command. Avoid a new `phase47-proof.yml`
  unless branch-protection/release governance requires a single named milestone
  check.
- **D-19:** Keep advisory lanes advisory. Rulestead and Rindle dependency-present
  checks stay scheduled/manual with `continue-on-error: true` and step-scoped
  `MIX_INCLUDE_RULESTEAD=1` / `MIX_INCLUDE_RINDLE=1`. Do not promote them until
  real adapters, substantive optional-library behavior, sustained stability, and
  explicit roadmap/requirements changes exist.
- **D-20:** The aggregate hermetic proof must defend against the known optional
  dependency footguns from Phases 43 and 45: env var bleed into hermetic jobs,
  conflicting dependency-present vs dependency-absent assertions in the same
  test target, and accidentally including `@moduletag :advisory_only` tests in
  merge-blocking lanes.
- **D-21:** Import the Phoenix/Plug lesson: public contracts should be explicit
  behaviours, plugs/callbacks, and route-local declarations with boring names.
  Do not hide companion behavior behind magic macros.
- **D-22:** Import the Ecto/Phoenix docs lesson: docs should teach the mental
  model first, then show concrete examples, then document boundaries. Crosswake
  should document where host ownership begins and where library-owned contracts
  stop.
- **D-23:** Import Rails Active Storage/Shrine lessons for Rindle: upload
  evidence and backend availability are different states; direct upload success
  must not be documented as committed media.
- **D-24:** Import phx.gen.auth/OAuth/OWASP lessons for Sigra: server-side auth
  authority, recency, and step-up vocabulary matter; the docs must not imply
  Crosswake performs full re-auth machinery in v3.5.
- **D-25:** Import Rust doctest/Python doctest lessons at the principle level:
  executable documentation should test claims against code. Do this with
  targeted ExUnit parity checks, not heavy docs infrastructure.
- **D-26:** Import Jest snapshot footgun lessons: avoid tests whose normal
  workflow is approving broad text diffs without understanding the semantic
  contract change.

### the agent's Discretion
- Exact guide headings are planner discretion if the single-file,
  reader-intent structure remains.
- Exact helper names inside `companions_test.exs` are planner discretion.
- Exact aggregate proof file name and workflow hook are planner discretion.
  Bias toward the untagged proof-test approach unless CI visibility demands a
  separate workflow.
- Exact assertion source for denial vocabulary is planner discretion if the
  test still locks `:gate_denied`, `:kill_switch_active`, and
  `:step_up_required` to live code.

### Deferred Ideas (OUT OF SCOPE)
- Per-companion guide split — defer until companion surface area is large enough
  to justify multiple ExDoc pages.
- Real Rulestead snapshot adapter — future phase after optional-library behavior
  is stable enough to promote advisory proof.
- Real Rindle adapter/transport/storage provider integration — future phase.
- Full Sigra machinery — v3.6+ security-focused work.
- Chimeway seam and Threadline capstone — future companion sequence, not Phase
  47 implementation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-02 | `guides/companions.md` must cover companion seam + rulestead/rindle/sigra, include explicit deferred non-goals, and be parity-locked to support-matrix/doctor truth; milestone-level hermetic proof must assert fail-closed behavior with optional deps absent. | Guide structure + semantic docs-contract parity plan + aggregate hermetic proof pattern + CI lane guardrails are defined below. |
</phase_requirements>

## Summary
Phase 47 is primarily a parity-and-proof closure phase: expand `guides/companions.md` from Rulestead-only into full v3.5 companion guidance, then convert docs tests from mostly string anchors to semantic parity against live exported truth. [CITED: guides/companions.md] [CITED: test/crosswake/guides/companions_test.exs]  

The existing architecture already provides authoritative sources for parity: `Crosswake.Companion` callback contract, `SupportMatrix.gating_truth/0`, `SupportMatrix.auth_contract_truth/0`, `Shell.Denial.reasons/0`, and doctor finding codes for companion dependency/auth posture. [CITED: lib/crosswake/companion.ex] [CITED: lib/crosswake/support_matrix/support_matrix.ex] [CITED: lib/crosswake/shell/denial.ex] [CITED: lib/crosswake/doctor/doctor.ex]  

Milestone proof should be implemented as one untagged aggregate ExUnit module under `test/crosswake/proof/` so existing hermetic commands already used by Phase 43/45 workflows include it automatically, while still excluding `:advisory_only` tests and avoiding env-var bleed. [CITED: .github/workflows/phase43-proof.yml] [CITED: .github/workflows/phase45-proof.yml] [CITED: test/test_helper.exs]

**Primary recommendation:** Build Phase 47 around two deliverables only: (1) semantic docs-contract parity tests for the expanded companion guide, and (2) a single untagged aggregate hermetic proof test that composes Rulestead+Rindle missing-dep fail-closed checks with Sigra contract posture checks.

## Project Constraints (from AGENTS.md)
- Preserve Crosswake as Phoenix-first route-policy/runtime-contract system; do not reframe as universal UI framework. [CITED: AGENTS.md]
- Keep runtime ownership explicit per route; avoid generic WebView wrapper behavior. [CITED: AGENTS.md]
- Treat companion/bridge contracts as typed, semantic, versioned, low-frequency; move continuous client authority to offline island/native screen instead. [CITED: AGENTS.md]
- Keep offline claims explicit and honest (cached read-only vs local-first mutation). [CITED: AGENTS.md]
- Treat diagnostics, support matrices, proof lanes, rough-edge docs as core product surface. [CITED: AGENTS.md]
- Respect v1 scope boundaries in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md`. [CITED: AGENTS.md]

## Architectural Responsibility Map
| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Companion seam guide content | Documentation tier | Core library contracts | Guide must reflect contract surfaces, not invent new runtime behavior. |
| Docs-contract semantic parity | Test tier (ExUnit) | Docs + exported APIs | ExUnit is canonical existing enforcement mechanism for docs parity. |
| Milestone hermetic companion proof | Test tier (ExUnit proof) | CI workflow commands | Existing hermetic lanes run shared test command; aggregate proof slots in. |
| Optional-dep isolation enforcement | CI/build tier | `mix.exs` env-gated deps | Rulestead/Rindle optional deps are controlled by step-scoped env vars. |
| Support/doctor truth sourcing | Backend/library tier | Docs/test layer | Docs must read from live code outputs (`SupportMatrix`, `Doctor`, `Denial`). |

## Standard Stack
### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Elixir | 1.19.5 | Language/runtime for docs/proof tests | Current project runtime. [CITED: mix.exs] |
| ExUnit | built-in | Docs-contract + proof assertions | Existing test framework for all proof lanes. [CITED: test/crosswake/proof/phase45_rindle_companion_test.exs] |
| Mix | 1.19.5 | Test command + optional dep gating | Existing workflow foundation. [CITED: mix.exs] |
| GitHub Actions | existing workflows | Hermetic/advisory lane orchestration | Phase 43/45 pattern already established. [CITED: .github/workflows/phase43-proof.yml] [CITED: .github/workflows/phase45-proof.yml] |

### Supporting
| Library/Module | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `Crosswake.SupportMatrix` | in-tree | Canonical gating/auth truth | Build set-parity docs assertions. |
| `Crosswake.Shell.Denial` | in-tree | Canonical denial vocabulary | Verify guide denial reasons against exported list. |
| `Crosswake.Doctor` | in-tree | Canonical finding code surface | Verify guide references to doctor output codes. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| semantic parity assertions | markdown snapshot tests | Faster to write, but high drift risk and weaker contract guarantees. |
| untagged aggregate proof in existing lane | new `phase47-proof.yml` | Extra CI surface and duplication without stronger evidence by default. |

**Installation:** No new package install is required for Phase 47. [CITED: mix.exs]

## Package Legitimacy Audit
Not applicable: Phase 47 does not add external dependencies. [CITED: mix.exs]

## Architecture Patterns
### System Architecture Diagram
```text
guides/companions.md
        |
        v
companions_test.exs (setup_all File.read!)
        |
        +--> anchor assertions (human-readable failures)
        |
        +--> semantic parity helpers
                |--> SupportMatrix.gating_truth/0
                |--> SupportMatrix.auth_contract_truth/0
                |--> Shell.Denial.reasons/0
                |--> Doctor finding codes (stable literals in code)

phase47_companion_arc_test.exs (untagged)
        |
        +--> register companions: [Rulestead, Rindle] (+ Sigra contract checks)
        +--> run Doctor.run/...
        +--> assert dependency_missing :error for enabled missing deps
        +--> assert auth contract truth + :step_up_required posture
        |
        v
existing hermetic CI command:
mix test --exclude requires_example_host --exclude advisory_only
```

### Recommended Project Structure
```text
guides/
  companions.md                         # expand to full v3.5 guide
test/crosswake/guides/
  companions_test.exs                   # keep + upgrade to semantic parity
test/crosswake/proof/
  phase47_companion_arc_test.exs        # add aggregate untagged proof
.github/workflows/
  phase43-proof.yml / phase45-proof.yml # optionally reuse/ext minimally
```

### Pattern 1: Semantic Docs-Contract Parity (not brittle parsing)
**What:** Keep explicit `content =~` anchors, then add helper-driven set assertions sourced from exported code truth.  
**When to use:** Any public guide claiming contract/state vocabularies.  
**Example:**
```elixir
# Source: test/crosswake/guides/commerce_test.exs pattern
setup_all do
  %{content: File.read!(@guide_path)}
end

test "guide includes exported denial reasons", %{content: content} do
  reasons =
    Crosswake.Shell.Denial.reasons()
    |> Enum.filter(&(&1 in [:gate_denied, :kill_switch_active, :step_up_required]))
    |> Enum.map(&(":#{&1}"))

  for reason <- reasons do
    assert content =~ reason
  end
end
```

### Pattern 2: Aggregate Hermetic Proof Composition
**What:** One untagged proof module combines the companion-arc claim across Rulestead, Rindle, and Sigra contract posture.  
**When to use:** Milestone-level closure where per-companion proofs already exist.  
**Example:**
```elixir
# Source: phase42/45 proof setup style
Application.put_env(:crosswake, :companions, [
  Crosswake.Companions.Rulestead,
  Crosswake.Companions.Rindle
])

report = Crosswake.Doctor.run(route_source: Router, install_manifest_path: path, cwd: cwd)

assert Enum.any?(report.findings, &(&1.code == "companion.dependency_missing" and &1.check == "companion.rulestead"))
assert Enum.any?(report.findings, &(&1.code == "companion.dependency_missing" and &1.check == "companion.rindle"))
```

### Anti-Patterns to Avoid
- **Snapshot-only docs tests:** encourages blanket acceptance and contract drift.
- **Hermetic/advisory target mixing:** contradictory assertions (`:ok` vs missing dep) in one lane.
- **Workflow-level optional-dep env vars:** risks env bleed into merge-blocking jobs.

## Don't Hand-Roll
| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown semantics extraction | custom markdown AST parser | direct anchor + set parity assertions in ExUnit | Simpler, deterministic, aligns with existing test style. |
| New milestone CI island | duplicated `phase47-proof.yml` by default | existing hermetic command/lanes with untagged proof module | Less maintenance; same evidence quality. |
| Denial vocabulary constants in docs test | local copied list | `Crosswake.Shell.Denial.reasons/0` | Eliminates stale constant drift. |

**Key insight:** Phase 47 is contract parity work; reuse exported truth surfaces rather than introducing new abstraction layers.

## Common Pitfalls
### Pitfall 1: Optional-dep env bleed into hermetic lanes
**What goes wrong:** `MIX_INCLUDE_RULESTEAD`/`MIX_INCLUDE_RINDLE` leaks into merge-blocking jobs.  
**Why it happens:** Env set at job/workflow scope instead of step scope.  
**How to avoid:** Keep env only on advisory steps; hermetic jobs run without those vars.  
**Warning signs:** Hermetic assertions expecting missing deps start passing unexpectedly.

### Pitfall 2: Conflicting proof assertions in one test target
**What goes wrong:** Hermetic and advisory assertions run together and fail nondeterministically.  
**Why it happens:** Missing `:advisory_only` exclusion or over-broad test command.  
**How to avoid:** Keep advisory files tagged and excluded from hermetic command.  
**Warning signs:** Failures around `validate_dependency/0` expected shape.

### Pitfall 3: Keyword-only docs tests with no semantic locking
**What goes wrong:** Guide text includes keywords but drifts from live support/doctor truth.  
**Why it happens:** Tests never compare against exported sets/vocabularies.  
**How to avoid:** Add set-based parity for companion IDs, predicates, denial reasons, finding codes.  
**Warning signs:** Docs pass while support matrix or doctor output changed.

## Code Examples
### Companion callback surface reference
```elixir
# Source: lib/crosswake/companion.ex
@callback companion_id() :: atom()
@callback enabled?(config :: map()) :: boolean()
@callback route_gated?(route :: RouteEntry.t(), context :: Target.t()) :: {:deny, Finding.t()} | :pass
@callback kill_switch_active?(context :: Target.t()) :: boolean()
@callback validate_dependency() :: :ok | {:error, [module()]}
@callback report_state() :: State.t()
```

### Canonical denial vocabulary source
```elixir
# Source: lib/crosswake/shell/denial.ex
@reasons [:compatibility_mismatch, :undeclared_capability, ..., :gate_denied, :kill_switch_active, :step_up_required]
def reasons, do: @reasons
```

## State of the Art
| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Companion docs test as anchor-only checks | Anchor + semantic parity strategy | Phases 37/43 established baseline; Phase 47 extends | Better contract-drift detection with readable failures. |
| Per-companion proof claims only | Milestone aggregate proof claim | Required by Phase 47 | Closes v3.5 arc-level fail-closed guarantee. |

**Deprecated/outdated:**
- treating advisory-lane success as merge-blocking evidence.
- using guide prose as independent truth detached from support matrix/doctor exports.

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Existing hermetic lane command is sufficient for milestone aggregate proof pickup without new workflow file. [ASSUMED] | Architecture Patterns | May need explicit workflow wiring if branch protection requires named check. |

## Open Questions (RESOLVED)
1. **Should milestone proof be surfaced as a distinct required CI check name?**
   - What we know: Existing workflows run broad hermetic command that can pick up an untagged Phase 47 proof file.
   - Resolution: Use in-lane inclusion for Phase 47. The plan should add an untagged aggregate proof file that the existing hermetic command picks up, and should not create a distinct `phase47-proof.yml` unless a future branch-protection/governance phase explicitly requires one.
   - Recommendation: Plan default as in-lane inclusion; add explicit workflow check only in a future governance change if required.

## Environment Availability
| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | ExUnit/mix tests | ✓ | 1.19.5 | — |
| `mix` | test command + compile | ✓ | 1.19.5 | — |
| `git` | workflow and repo operations | ✓ | 2.41.0 | — |
| `node` | optional graph tooling already used in repo tooling | ✓ | v22.14.0 | — |

**Missing dependencies with no fallback:** none  
**Missing dependencies with fallback:** none

## Validation Architecture
### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 runtime) |
| Config file | [`test/test_helper.exs`](/Users/jon/projects/crosswake/test/test_helper.exs) |
| Quick run command | `mix test test/crosswake/guides/companions_test.exs -x` |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-02 | Companion guide includes contract+surfaces+non-goals and stays parity-locked to live truth | unit/docs-contract | `mix test test/crosswake/guides/companions_test.exs -x` | ✅ |
| PROOF-02 | Milestone arc hermetic fail-closed proof across shipped companion surfaces | proof/integration | `mix test test/crosswake/proof/phase47_companion_arc_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/guides/companions_test.exs -x`
- **Per wave merge:** `mix test --exclude requires_example_host --exclude advisory_only`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase47_companion_arc_test.exs` — aggregate milestone hermetic proof for PROOF-02
- [ ] expanded semantic parity helpers in `test/crosswake/guides/companions_test.exs` (set parity vs exported truth)

## Security Domain
### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Sigra contract truth + `:step_up_required` fail-closed posture in docs/proof parity |
| V3 Session Management | yes | `SessionAuthorityLane` contract-only semantics and recency predicates |
| V4 Access Control | yes | Route-level gate/auth denials (`:gate_denied`, `:kill_switch_active`, `:step_up_required`) |
| V5 Input Validation | yes | Typed contract validators in companion contracts; no free-form docs truth |
| V6 Cryptography | no | Not introduced/modified in this phase |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fail-open due to missing optional dependency | Elevation of Privilege | Doctor `companion.dependency_missing` error + hermetic proof enforcement |
| Stale/misleading operator docs | Tampering | Docs-contract semantic parity against exported support/doctor/denial truth |
| Advisory lane mistaken for guaranteed support | Repudiation | Keep advisory tags/exclusions + explicit proof-class language |

## Sources
### Primary (HIGH confidence)
- `guides/companions.md` — current companion guide baseline.
- `test/crosswake/guides/companions_test.exs` — current docs-contract test baseline.
- `test/crosswake/guides/commerce_test.exs` — mature parity-test style to mirror.
- `lib/crosswake/companion.ex` — canonical companion callback contract and telemetry mention.
- `lib/crosswake/support_matrix/support_matrix.ex` — `gating_truth/0`, `auth_contract_truth/0`, commerce proof posture patterns.
- `lib/crosswake/shell/denial.ex` — canonical denial reasons list.
- `lib/crosswake/doctor/doctor.ex` — stable finding codes (`companion.dependency_missing`, `auth.route_predicated`, `auth.step_up_required_contract`).
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` — hermetic fail-closed pattern.
- `test/crosswake/proof/phase45_rindle_companion_test.exs` — non-gating companion hermetic fail-closed pattern.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` — auth contract posture proof pattern.
- `.github/workflows/phase43-proof.yml` and `.github/workflows/phase45-proof.yml` — hermetic/advisory split and env scope conventions.
- `test/test_helper.exs` — advisory tag exclusion default.
- `mix.exs` — optional dependency env gates and docs extras surface.

### Secondary (MEDIUM confidence)
- `.planning/phases/43-*/43-RESEARCH.md` and `.planning/phases/45-*/45-RESEARCH.md` — prior phase implementation patterns and pitfalls.

### Tertiary (LOW confidence)
- none

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - entirely derived from in-repo runtime/workflow configuration.
- Architecture: HIGH - directly anchored to existing companion, doctor, support, and proof code.
- Pitfalls: HIGH - proven by existing Phase 43/45 lane structure and advisory tagging behavior.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30
