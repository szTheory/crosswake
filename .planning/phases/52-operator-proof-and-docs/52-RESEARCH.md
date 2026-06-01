# Phase 52: Operator Proof and Docs-Contract Locks - Research

**Researched:** 2026-06-01
**Domain:** Crosswake v3.6 operator-proof lane + docs-contract durability
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### 1. Proof Lane Topology - LOCKED
- **D-01:** Add a dedicated Phase 52 proof workflow rather than scattering the
  new proof across earlier workflows or relying on Mix aliases alone.
- **D-02:** The workflow should be layered: one required hermetic
  merge-blocking operator-proof job plus separate advisory visibility for
  native/device/provider lanes when present.
- **D-03:** The merge-blocking job should cover deterministic local truth:
  inspection output, doctor publish-readiness findings, support matrix rows,
  docs-contract parity, denial vocabulary, rebuild/action classes, promotion
  rules, and public non-claims.
- **D-04:** Advisory jobs must be labeled as advisory and must not imply
  StoreKit, Play Billing, Chimeway delivery, full Sigra machinery, or standalone
  shell packages have shipped.
- **D-05:** Prefer boring Mix/ExUnit commands behind the workflow, such as a
  focused `mix test` path or small proof alias, so the same contract is easy to
  run locally.

### 2. Docs-Contract Lock Shape - LOCKED
- **D-06:** Use a hybrid docs-contract strategy. Do not make all prose
  byte-identical, and do not rely only on loose substring assertions.
- **D-07:** Keep byte-identical checks for generated canonical data projections,
  especially `guides/support_matrix.md` versus
  `Crosswake.SupportMatrix.Renderer.render/1`.
- **D-08:** Add live-code parity assertions for stable vocabularies and ids:
  support statuses, proof classes, denial reasons, rebuild/change/action
  classes, promotion rule ids, doctor readiness categories/codes, and guide
  anchors.
- **D-09:** Add normalized JSON/golden contract checks for
  `Crosswake.OperatorInspection` and doctor publish-readiness output. Normalize
  volatile fields such as timestamps and ordering before comparison.
- **D-10:** Use authored-guide assertions for public non-claims and rough edges:
  StoreKit/Play Billing not shipped, Sigra contract-only, notification-token
  provider-snapshot only, Chimeway delivery deferred, standalone shell packages
  deferred, and compatibility-window narrowing distinct from native rebuild.
- **D-11:** If guide sections mix generated data and authored prose, make the
  boundary explicit in tests or section markers so future maintainers know
  whether to edit the renderer or the prose.

### 3. Drift Failure Ergonomics - LOCKED
- **D-12:** Phase 52 proof failures should use domain-specific helper
  assertions with stable proof/check ids, not raw `assert actual == expected`
  failures alone.
- **D-13:** Failure messages should include: stable id, subject, expected live
  source, observed drift, guide or module path, remediation hint, and whether
  the drift affects merge-blocking or advisory support truth.
- **D-14:** Stable ids should follow a compact grouped convention such as
  `proof.operator.*`, `proof.docs.*`, `proof.denial.*`, `proof.rebuild.*`, and
  `proof.readiness.*`. Exact ids are planner discretion, but uniqueness and
  grouping must be tested.
- **D-15:** Generated drift reports, GitHub summaries, or annotations are useful
  presentation layers, but they must be derived from the same canonical proof
  checks. They must not become a second contract.
- **D-16:** Snapshot-style diffs are acceptable for normalized JSON and rendered
  docs, but accepting a snapshot update must never be the only remediation when
  support-truth semantics changed.

### 4. Coverage Boundary - LOCKED
- **D-17:** Use requirement-mapped selective rollup. Phase 52 is centered on
  v3.6 operator surfaces and pulls only the historical proof dependencies that
  PROOF-01/PROOF-02 actually rely on.
- **D-18:** Do not aggregate every historical proof into a single mega lane.
  Existing phase proofs remain their own canonical deep checks.
- **D-19:** Historical dependencies should be referenced only where they protect
  live v3.6 operator truth, for example commerce provider non-claims,
  companion/auth contract-only posture, `:step_up_required`, route/denial
  vocabulary, support-matrix rows, and docs anchors.
- **D-20:** A small cross-milestone smoke sentinel is acceptable only as an
  additive early-warning signal. It must not replace the requirement-mapped
  Phase 52 proof depth.
- **D-21:** Map proof modules or helper assertions back to PROOF-01 and
  PROOF-02 so Phase 53 release continuity can audit requirement coverage without
  reading every test by hand.

### 5. Ecosystem Lessons To Preserve - LOCKED
- **D-22:** Import the Phoenix/Plug/Ecto lesson: explicit structs, closed
  vocabularies, deterministic validation, and local Mix commands are better DX
  than hidden inference or shell-only policy.
- **D-23:** Import the Django checks lesson: stable ids, severity/posture,
  object references, hints, and docs links make diagnostics actionable.
- **D-24:** Import the Terraform lesson: versioned machine output and human
  output are separate contracts. Human prose is not the automation API.
- **D-25:** Import the Kubernetes lesson carefully: condition-like summaries are
  useful, but they must not replace raw support, proof, rebuild, provider,
  auth, notification, and denial axes.
- **D-26:** Import the npm audit lesson: thresholding helps CI, but noisy
  advisory failures erode trust. Advisory proof should stay visible without
  blocking by default.
- **D-27:** Import the Rails route-inspection lesson: the operator surface should
  be easy to run locally, deterministic, and tied to named routes/surfaces.

### the agent's Discretion
- Exact file layout is planner discretion. Strong default: a focused
  `test/crosswake/proof/phase52_operator_truth_test.exs` plus small helper
  modules under `test/support` if the assertions would otherwise duplicate.
- Exact Mix alias names are planner discretion. Bias toward obvious local DX,
  such as `mix test test/crosswake/proof/phase52_operator_truth_test.exs`.
- Exact GitHub Actions job names are planner discretion if they preserve
  required hermetic versus advisory semantics in the name.
- Exact normalized JSON fixture format is planner discretion. Avoid introducing
  a new dependency unless it clearly improves schema validation.
- Exact stable proof id names are planner discretion if they are grouped,
  unique, and point to actionable remediation.

### Deferred Ideas (OUT OF SCOPE)
- Full provider/device/storefront proof promotion remains deferred to future
  provider adapter milestones and must follow explicit promotion rules.
- Full Sigra session machinery, Chimeway delivery, and standalone shell package
  release choreography remain deferred to their planned milestones.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Hermetic tests lock inspection output, doctor findings, and support matrix rows for the v3.6 operator surface. | Dedicated merge-blocking phase workflow + `phase52_operator_truth_test` rollup around `mix crosswake.inspect`, `mix crosswake.doctor --check-publish`, support matrix canonical rows, denial vocabulary, and promotion/rebuild classes. [VERIFIED: codebase grep] |
| PROOF-02 | Docs-contract tests keep operator guidance synchronized with live doctor/support/denial/rebuild truth. | Hybrid docs-contract checks: byte-lock generated support matrix; parity-lock authored guide claims/non-claims to support matrix + doctor readiness + denial vocabulary. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 52 should be implemented as a new proof-contract layer, not by widening old lanes. Existing code already exposes stable operator surfaces (`Crosswake.OperatorInspection`, `Crosswake.Doctor.PublishReadiness`, `Crosswake.SupportMatrix`, `Crosswake.Shell.Denial`) and existing tests already demonstrate deterministic parity patterns to reuse. [VERIFIED: codebase grep]

The highest leverage plan is: add one focused Phase 52 proof module + one helper module for drift assertions + one dedicated CI workflow with explicit merge-blocking vs advisory jobs. This preserves the Phoenix-first thesis and keeps deferred provider/auth/notification claims non-shipped in both checks and failure messaging. [VERIFIED: codebase grep]

**Primary recommendation:** Implement a dedicated `phase52` hermetic proof lane that composes existing operator/support primitives and emits stable, actionable drift IDs, while keeping environment-sensitive checks visible but advisory. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as Phoenix-first route-policy/runtime-contract system, not a universal UI framework. [VERIFIED: codebase grep]
- Keep route runtime ownership explicit; avoid generic WebView wrapper collapse. [VERIFIED: codebase grep]
- Treat bridge contracts as semantic, typed, versioned, low-frequency; flows needing continuous client authority should move toward offline island/native screen. [VERIFIED: codebase grep]
- Keep offline claims honest (cached read-only vs local-first mutation/reconciliation). [VERIFIED: codebase grep]
- Treat diagnostics/support matrices/proof lanes/rough-edge docs as product surface. [VERIFIED: codebase grep]
- Respect v1 scope boundaries before broadening integrations/native breadth. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Operator inspection truth (`mix crosswake.inspect`) | API / Backend | Frontend Server (CLI task surface) | Inventory is built from route/manifest contracts in Elixir domain code and exposed via Mix task output. [VERIFIED: codebase grep] |
| Doctor publish-readiness truth (`mix crosswake.doctor --check-publish`) | API / Backend | Frontend Server (CLI/report formatting) | Readiness checks derive deterministic support/inspection state; JSON/human output are render layers. [VERIFIED: codebase grep] |
| Canonical support matrix + rendered guide parity | API / Backend | CDN / Static (guide artifact) | Source of truth is `SupportMatrix`; generated markdown is static projection. [VERIFIED: codebase grep] |
| Proof lane gating and advisory visibility | Frontend Server (CI orchestration) | API / Backend (test execution) | GitHub workflow controls required vs advisory posture; assertions execute in ExUnit. [VERIFIED: codebase grep] |
| Drift diagnostics with stable proof IDs | API / Backend | Frontend Server (CI annotation/summary) | Stable IDs and message semantics belong to assertion helpers; CI only presents them. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` project target; toolchain observed `1.19.5` | Core implementation and ExUnit proof tests | Existing project/tooling baseline for all proof and docs-contract tests. [VERIFIED: codebase grep] |
| Erlang/OTP | observed `28` (`mix --version` output) | BEAM runtime for deterministic Mix/ExUnit runs | Current CI/tooling line already used by existing proof workflows. [VERIFIED: codebase grep] |
| ExUnit | bundled with Elixir | Hermetic contract/proof testing | Existing proof strategy already phase-scoped in ExUnit. [VERIFIED: codebase grep] |
| GitHub Actions | workflow YAML jobs | Required vs advisory lane topology | Existing phase workflows already model this split. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jason` | `~> 1.4` | Stable JSON encoding for inspection/readiness fixtures | Normalized JSON/golden checks for operator + publish-readiness contracts. [VERIFIED: codebase grep] |
| `phoenix` | `~> 1.8` | Router/policy contract source for inspection/doctor inputs | Route fixtures inside proof tests. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit phase test + helper assertions | Snapshot-only harness across full guide corpus | Loses domain-specific remediation IDs and over-couples authored prose bytes. [VERIFIED: codebase grep] |
| Dedicated phase workflow | Fold into old phase workflows | Weakens ownership and makes PROOF-01/02 audit traceability harder. [VERIFIED: codebase grep] |

## Architecture Patterns

### System Architecture Diagram

`Route/Manifest + SupportMatrix + Denial + Doctor Readiness` -> `Phase52 Proof Assertions (stable IDs + normalization)` -> `Hermetic Merge-Blocking Job`  
`Env-sensitive provider/device checks` -> `Advisory Job(s)` -> `CI visibility only (no merge gate)`  
`Canonical sources` -> `Rendered guides / JSON output` -> `Docs-contract parity checks`

### Recommended Project Structure
```text
test/
├── crosswake/proof/
│   └── phase52_operator_truth_test.exs
├── support/
│   └── proof_assertions.ex
.github/workflows/
└── phase52-proof.yml
```

### Pattern 1: Requirement-Mapped Phase Rollup
**What:** Single phase proof file asserts only PROOF-01/02-relevant cross-surface truth. [VERIFIED: codebase grep]  
**When to use:** When prior phase proofs exist but a release-scope operator contract needs one auditable gate. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: test/crosswake/proof/phase47_companion_arc_test.exs
refute Regex.match?(~r/^\s*@moduletag\s+:advisory_only\b/m, source)
```

### Pattern 2: Byte-Lock Generated Docs, Parity-Lock Authored Prose
**What:** Keep `guides/support_matrix.md` exact-render checks while using semantic assertions for authored docs. [VERIFIED: codebase grep]  
**When to use:** Mixed generated/prose documentation with different drift risks. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: test/crosswake/support_matrix/renderer_test.exs
assert File.read!("guides/support_matrix.md") == Renderer.render(SupportMatrix.canonical())
```

### Pattern 3: Layered CI with Advisory Boundary
**What:** Required hermetic job on PR/push + scheduled/workflow_dispatch advisory jobs with `continue-on-error`. [VERIFIED: codebase grep]  
**When to use:** Environment-sensitive checks are useful signals but not release truth yet. [VERIFIED: codebase grep]  
**Example:**
```yaml
# Source: .github/workflows/phase45-proof.yml
continue-on-error: true
```

### Anti-Patterns to Avoid
- **Mega historical proof lane:** contradicts locked selective rollup and raises maintenance noise. [VERIFIED: codebase grep]
- **Snapshot-only remediation:** updates fixtures without proving semantic support-truth intent. [VERIFIED: codebase grep]
- **Advisory ambiguity:** jobs that look required or imply deferred features shipped. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Operator JSON normalization | Custom parser/serializer stack | Existing `Types.to_map/1` + sorted JSON formatter pattern | Existing deterministic ordering pattern already in project. [VERIFIED: codebase grep] |
| Guide generation contract | Manual markdown concatenation in tests | `SupportMatrix.Renderer.render/1` byte-parity checks | Single canonical source prevents dual truth. [VERIFIED: codebase grep] |
| CI advisory semantics | Custom scripts for gate logic | Existing Actions required/advisory job pattern | Clear, proven branch-gating posture in prior phases. [VERIFIED: codebase grep] |

**Key insight:** Phase 52 should compose existing canonical contracts, not invent a second truth layer. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Over-coupling prose to bytes
**What goes wrong:** Non-generated guide edits fail unrelated proof tests. [VERIFIED: codebase grep]  
**Why it happens:** Applying byte-identical checks to authored narrative sections. [VERIFIED: codebase grep]  
**How to avoid:** Byte-lock only generated sections, semantic-lock authored claims/non-claims. [VERIFIED: codebase grep]  
**Warning signs:** Frequent snapshot churn with unchanged support semantics. [ASSUMED]

### Pitfall 2: Merge-blocking job picks up advisory-only tests
**What goes wrong:** Flaky or env-dependent failures block merge. [VERIFIED: codebase grep]  
**Why it happens:** Missing exclusion tags or event guards. [VERIFIED: codebase grep]  
**How to avoid:** Follow phase43/45 pattern (`--exclude advisory_only`, schedule-only advisory jobs). [VERIFIED: codebase grep]  
**Warning signs:** Required job runs only on scheduled events or fails on missing optional deps. [ASSUMED]

### Pitfall 3: Drift failures not actionable
**What goes wrong:** Generic `assert ... == ...` messages slow triage. [VERIFIED: codebase grep]  
**Why it happens:** No stable check IDs or remediation hints. [VERIFIED: codebase grep]  
**How to avoid:** Add proof helper assertions with grouped IDs + subject/source/path/remediation fields. [VERIFIED: codebase grep]  
**Warning signs:** CI red with no direct pointer to guide/module to update. [ASSUMED]

## Code Examples

### Hermetic lane guard
```elixir
# Source: test/crosswake/proof/phase47_companion_arc_test.exs
refute String.contains?(source, "MIX_INCLUDE_" <> "RINDLE")
```

### Canonical support matrix byte lock
```elixir
# Source: test/crosswake/support_matrix/renderer_test.exs
rendered = Renderer.render(SupportMatrix.canonical())
on_disk = File.read!("guides/support_matrix.md")
assert rendered == on_disk
```

### Stable publish-readiness schema contract
```elixir
# Source: test/crosswake/doctor/publish_readiness_test.exs
assert report.schema_version == "1.0.0"
assert check.proof_class in [:merge_blocking, :advisory, :not_applicable]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Scattered proof assertions by feature phase | Requirement-mapped operator-truth rollup lane | v3.6 phase sequencing (48-52) | Easier release audit for PROOF-01/02 without mega-lane coupling. [VERIFIED: codebase grep] |
| Support/docs checks mostly local to one subsystem | Cross-surface docs-contract parity (inspection + doctor + support + denial) | v3.5->v3.6 transition | Better durability of operator-facing truth claims. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating advisory provider/device results as merge-gating truth before explicit promotion criteria. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Snapshot churn is likely warning sign of over-coupled prose checks. | Common Pitfalls | Medium: planner may over-prioritize helper tooling. |
| A2 | Required jobs failing on missing optional deps is a common symptom pattern. | Common Pitfalls | Low: operational guidance still valid. |
| A3 | CI triage delay mainly driven by generic assertion output. | Common Pitfalls | Low: stable-ID helper still improves clarity. |

## Open Questions

1. **Should Phase 52 use one proof module or split into `operator` + `docs` modules?**
   - What we know: Context preference is a focused single file with optional helpers. [VERIFIED: codebase grep]
   - What's unclear: Final granularity threshold for readability vs failure locality.
   - Recommendation: Start single module + helper; split only if module exceeds maintainability bounds.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix/ExUnit proof execution | ✓ | 1.19.5 | — |
| Mix | CLI proof/test orchestration | ✓ | 1.19.5 | — |
| Erlang/OTP | BEAM runtime | ✓ | 28 | — |
| GitHub Actions | CI topology for phase52 workflow | Assumed in repo CI | — | local `mix test` equivalent for dev loop |

**Missing dependencies with no fallback:**
- None detected for local hermetic proof implementation.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir/Mix) |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/crosswake/proof/phase52_operator_truth_test.exs -x` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Lock inspect output + doctor findings + support matrix rows | integration | `mix test test/crosswake/proof/phase52_operator_truth_test.exs -x` | ❌ Wave 0 |
| PROOF-02 | Lock docs-contract parity for support/denial/rebuild/non-claims | integration | `mix test test/crosswake/proof/phase52_operator_truth_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase52_operator_truth_test.exs -x`
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** `phase52-proof.yml` required hermetic job green

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase52_operator_truth_test.exs` — central PROOF-01/02 rollup
- [ ] `test/support/proof_assertions.ex` — stable proof ID assertion helpers
- [ ] `.github/workflows/phase52-proof.yml` — required/advisory lane topology

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve `:step_up_required` contract-only checks; no new auth machinery claims. [VERIFIED: codebase grep] |
| V3 Session Management | no | Phase 52 is proof/docs lock, not session implementation changes. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Fail-closed route/support truth and denial vocabulary parity checks. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Deterministic typed structs/check IDs; strict vocabulary checks in tests. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No crypto surface changes in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for Elixir proof/docs contracts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False support claim drift in docs | Tampering | Byte/parity locks against canonical `SupportMatrix` + readiness checks. [VERIFIED: codebase grep] |
| Advisory lane mistaken as shipped support | Spoofing | Explicit advisory labels + non-blocking job posture + non-claim assertions. [VERIFIED: codebase grep] |
| Undiagnosable proof failure | Repudiation | Stable proof IDs, explicit subject/source/path/remediation in helper assertions. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- Internal source: `.planning/phases/52-operator-proof-and-docs/52-CONTEXT.md` - locked phase decisions and scope.
- Internal source: `.planning/ROADMAP.md` - Phase 52 goal/success criteria.
- Internal source: `.planning/REQUIREMENTS.md` - PROOF-01/PROOF-02 contract text.
- Internal source: `.planning/STATE.md` - current milestone posture and deferred boundaries.
- Internal source: `mix.exs` - toolchain/dependencies baseline.
- Internal source: `lib/crosswake/operator_inspection/json_formatter.ex`, `lib/crosswake/doctor/publish_readiness.ex`, `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/shell/denial.ex` - canonical operator/support/denial contracts.
- Internal source: `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/doctor/publish_readiness_test.exs`, `test/crosswake/proof/phase47_companion_arc_test.exs`, `test/mix/tasks/crosswake_inspect_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs` - reusable proof patterns.
- Internal source: `.github/workflows/phase23-proof.yml`, `.github/workflows/phase41-proof.yml`, `.github/workflows/phase45-proof.yml` - required/advisory lane topology.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified in `mix.exs` and local toolchain.
- Architecture: HIGH - verified through existing module/test/workflow structure.
- Pitfalls: MEDIUM - mitigations are verified; warning-sign heuristics include assumptions.

**Research date:** 2026-06-01
**Valid until:** 2026-07-01
