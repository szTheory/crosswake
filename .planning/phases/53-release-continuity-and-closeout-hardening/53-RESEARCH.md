# Phase 53: Release Continuity and Closeout Hardening - Research

**Researched:** 2026-06-01
**Domain:** Elixir/Phoenix release-truth enforcement and milestone closeout verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### 1. Release And Changelog Truth - LOCKED
- **D-01:** Keep `CHANGELOG.md` as the canonical public release-history
  surface. Do not introduce a separate release-support ledger as a second
  primary truth source.
- **D-02:** Add a richer `[Unreleased]` structure that explicitly separates:
  public support claims not yet published to Hex, verification-required or
  advisory surfaces, deferred/non-shipped claims, and the last published Hex
  truth (`0.1.0`).
- **D-03:** Use a changelog-first public UX with doctor/check-derived
  validation. The changelog remains human-authored; deterministic checks catch
  missing `[Unreleased]`, missing current package version sections, false
  shipped language, and drift from support-matrix/readiness non-claims.
- **D-04:** Do not generate the whole changelog from code. Generated/checkable
  claim truth should enforce bounded vocabulary and known non-claims while
  preserving maintainable release prose.
- **D-05:** Public language must keep planning milestones (`v3.6`) distinct from
  installable Hex SemVer releases (`0.1.0`, future `0.2.0`, etc.).
- **D-06:** Phase 53 should extend existing publish-readiness/doc-contract
  checks rather than inventing a parallel release command.

### 2. Closeout Verification Shape - LOCKED
- **D-07:** Implement a shared Elixir closeout validator with a thin
  `mix closeout.verify` task or alias wrapper. The Mix task is the maintainer
  DX; the validator module is the single source of truth.
- **D-08:** Back the validator with ExUnit tests under `test/crosswake/planning`
  so CI and local `mix test` exercise the same checks as the operator command.
- **D-09:** The verifier must fail closed on the Phase 48 closeout contract:
  stale roadmap parity, unchecked/unarchived requirements state, stale
  `.planning/STATE.md`, missing phase verification, malformed or missing
  `requirements-completed:` frontmatter, validation-ledger drift without a
  structured exception, unresolved thread/seed status, public support-claim
  changes without release/changelog continuity, malformed
  `deferred_with_reason`, and stale strategic queue refresh.
- **D-10:** Use stable check ids and actionable failure messages. Each failure
  should include the subject, source artifact, observed drift, expected shape or
  command, remediation hint, and whether the issue is merge-blocking closeout
  truth or human-review guidance.
- **D-11:** Preserve human judgment for release prose, durable lessons wording,
  and strategic narrative. Artifact existence, frontmatter shape, traceability,
  exception shape, and public-claim parity are deterministic and must be checked
  mechanically.
- **D-12:** Do not rely on docs-only checklists or `gsd-sdk`-only scripts as the
  primary enforcement path. They may feed the validator, but the project-facing
  command should be idiomatic Mix/Elixir.

### 3. Next-Milestone Handoff - LOCKED
- **D-13:** Close v3.6 with an explicit archive/reset boundary rather than only
  updating `PROJECT.md`, `MILESTONE-ARC.md`, and `STATE.md`.
- **D-14:** Archive v3.6 requirements/roadmap/closeout evidence before resetting
  active planning state for v3.7. The reset must make `$gsd-discuss-phase 48`
  the clear next execution step.
- **D-15:** If a handoff artifact is added, it must be pointer-first and thin:
  link to `PROJECT.md`, `MILESTONE-ARC.md`, archived v3.6 requirements/roadmap,
  `v3.6-CLOSEOUT.md`, `CHANGELOG.md`, and `STATE.md` instead of duplicating
  release/support truth.
- **D-16:** `PROJECT.md` and `.planning/MILESTONE-ARC.md` remain the durable
  strategic queue surfaces. Any short handoff doc is transitional continuity,
  not a new queue.
- **D-17:** The next-milestone queue must preserve the current sequencing:
  v3.7 commerce provider adapters, v3.8 full Sigra machinery, v3.9 Chimeway
  notification seam, v4.0 production shell runtime line, v4.1 multi-SaaS
  archetype proof, then Threadline audit capstone unless closeout explicitly
  records a changed rationale.

### 4. Ecosystem Lessons To Preserve - LOCKED
- **D-18:** Import the Hex/ExDoc lesson: package metadata, package file
  allowlists, changelog sections, and docs generation are release truth, not
  incidental paperwork.
- **D-19:** Import the Phoenix/Mix lesson: project-specific operational checks
  should be boring local commands with clear output and standard `mix help`
  discoverability.
- **D-20:** Import the Django checks lesson: stable ids, severity/posture,
  object references, hints, and deploy-oriented checks make closeout failures
  actionable.
- **D-21:** Import the Terraform lesson: human output and machine-readable truth
  serve different users. Human prose may improve; validator data and check ids
  must remain stable.
- **D-22:** Import the Ecto migration lesson: milestone boundaries should be
  explicit, ordered, and auditable rather than implicit tool state.
- **D-23:** Import the Kubernetes/Rails/Django release lifecycle lesson:
  release notes, deprecation/support claims, and upgrade/next-step routing must
  be synchronized before widening support.
- **D-24:** Import the npm audit lesson: thresholding is useful, but noisy
  advisory failures erode trust. Phase 53 should block on false support truth
  and malformed closeout evidence, while keeping advisory/provider/device
  signals visible but not overpromoted.

### the agent's Discretion
- Exact module names are planner discretion. Strong default:
  `Crosswake.Planning.CloseoutVerifier` plus `Mix.Tasks.Closeout.Verify`.
- Exact command spelling is planner discretion if it preserves the roadmap
  target `closeout.verify`. Prefer `mix closeout.verify` over a shell script.
- Exact check id names are planner discretion if they are stable, grouped, and
  tested. Good prefixes: `closeout.roadmap.*`, `closeout.requirements.*`,
  `closeout.state.*`, `closeout.verification.*`, `closeout.validation.*`,
  `closeout.release.*`, and `closeout.handoff.*`.
- Exact `[Unreleased]` subsection headings are planner discretion if published
  Hex truth, unreleased support truth, advisory/verification-required posture,
  and deferred non-claims remain visibly separate.
- Exact handoff artifact shape is planner discretion. Bias toward no new
  artifact unless it materially improves continuity; if added, make it a
  pointer index and parity-check it.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Release/changelog guidance reflects all public support claims shipped after `0.1.0` and makes unreleased versus published Hex truth clear. | Changelog-first truth model, publish-readiness parity extension, deterministic closeout verifier, and milestone archive/reset handoff contract. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Phoenix-first thesis; avoid reframing Crosswake as universal UI framework. [VERIFIED: codebase files]
- Keep runtime ownership explicit per route; avoid generic WebView wrapper patterns. [VERIFIED: codebase files]
- Keep bridge contracts typed/versioned/low-frequency; move continuous client authority to offline island/native surfaces. [VERIFIED: codebase files]
- Distinguish cached read-only from true local-first mutation and reconciliation. [VERIFIED: codebase files]
- Treat diagnostics/support/proof/rough-edge docs as product surface. [VERIFIED: codebase files]
- Respect v1 scope in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md`. [VERIFIED: codebase files]

## Summary

Phase 53 is a hardening phase, not a feature phase: the winning implementation is to **promote existing release-readiness and planning parity checks into a unified, fail-closed closeout verifier**, then use that verifier to enforce release/changelog truth and milestone closeout parity before v3.7 planning begins. [VERIFIED: codebase files]

The repo already contains the building blocks: changelog truth checks in `Crosswake.Doctor.PublishReadiness`, deterministic planning parity tests for closeout/frontmatter shape, and an explicit v3.6 closeout contract that names `closeout.verify` as the enforcement target. Phase 53 should consolidate these into one project-facing Mix command backed by ExUnit and stable check IDs. [VERIFIED: codebase files]

**Primary recommendation:** Implement `Crosswake.Planning.CloseoutVerifier` + `mix closeout.verify`, wire it into CI as merge-blocking for closeout truth, and keep `CHANGELOG.md` as the single public release-truth surface with richer `[Unreleased]` semantics. [VERIFIED: codebase files]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public release truth language (`CHANGELOG.md`) | API / Backend | — | Project release contract is source-controlled documentation tied to package metadata and doctor checks. [VERIFIED: codebase files] |
| Deterministic closeout verification | API / Backend | Database / Storage | Implemented as Elixir module + Mix task over planning artifacts on disk. [VERIFIED: codebase files] |
| Human/operator command surface (`mix closeout.verify`) | Frontend Server (SSR) | API / Backend | Mix task is the maintainer-facing command wrapper over backend validation logic. [CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| CI gate for closeout/release parity | CDN / Static | API / Backend | GitHub workflow executes hermetic tests/commands; code remains in repo modules/tests. [VERIFIED: codebase files] |
| Milestone archive/reset handoff | Database / Storage | API / Backend | Planning artifacts and milestone docs are persisted file-state requiring deterministic mutation order. [VERIFIED: codebase files] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Implement validator and Mix task | Existing project runtime and tooling baseline. [VERIFIED: codebase files] |
| Mix Task API | bundled with Elixir 1.19.5 | Maintainer command UX (`mix closeout.verify`) | Matches existing task posture (`mix crosswake.doctor`, `mix crosswake.inspect`). [VERIFIED: codebase files] |
| ExUnit | bundled with Elixir 1.19.5 | Deterministic proof of validator behavior | Existing phase-proof pattern and CI contract. [VERIFIED: codebase files] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Crosswake.Doctor.PublishReadiness` | local module | Reuse release-truth checks and messaging style | For changelog/published-version parity and advisory-vs-blocking semantics. [VERIFIED: codebase files] |
| `Crosswake.TestSupport.ProofAssertions` | local module | Stable, actionable failure messages | For closeout check ID/assertion helper consistency. [VERIFIED: codebase files] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mix closeout.verify` | docs checklist only | Non-deterministic; contradicts locked D-07..D-12. [VERIFIED: codebase files] |
| shared validator module | shell/`gsd-sdk`-only script | Weaker project-local DX and testability. [VERIFIED: codebase files] |

**Installation:**
```bash
# No new external packages required for Phase 53 baseline.
```

**Version verification:**
```bash
mix --version
elixir --version
```

## Architecture Patterns

### System Architecture Diagram

```text
CHANGELOG.md + mix.exs + planning artifacts
          |
          v
Crosswake.Planning.CloseoutVerifier.run/1
  -> roadmap parity checks
  -> requirements/status checks
  -> STATE frontmatter checks
  -> verification/validation ledger checks
  -> release/changelog continuity checks
  -> handoff/queue continuity checks
          |
          v
structured check results (stable ids, severity, hint, posture)
      |                               |
      v                               v
mix closeout.verify (human output)    ExUnit tests (machine contract)
      |                               |
      +------------> CI merge gate ---+
```

### Recommended Project Structure
```text
lib/
├── crosswake/planning/closeout_verifier.ex   # single source of closeout truth
└── mix/tasks/closeout.verify.ex              # thin operator command wrapper
test/
└── crosswake/planning/closeout_verifier_test.exs  # stable-id, fail-closed contract tests
```

### Pattern 1: Thin Mix Task Over Shared Validator
**What:** Keep all logic in `Crosswake.Planning.CloseoutVerifier`; task only parses args/renders/exits non-zero on blocking drift.
**When to use:** Any maintainer operator check that must run identically in local and CI.
**Example:**
```elixir
# Source: https://hexdocs.pm/mix/Mix.Task.html
defmodule Mix.Tasks.Closeout.Verify do
  use Mix.Task
  @shortdoc "Verify closeout parity and release continuity"
  def run(_args) do
    report = Crosswake.Planning.CloseoutVerifier.run(cwd: File.cwd!())
    Mix.shell().info(Crosswake.Planning.CloseoutVerifier.render(report))
    if report.status == :error, do: Mix.raise("closeout verification failed")
  end
end
```

### Anti-Patterns to Avoid
- **Second release ledger:** Duplicating public support/release truth outside `CHANGELOG.md` creates drift and contradicts locked decisions.
- **Task-only business logic:** Parsing files directly in Mix task makes tests brittle and blocks reuse.
- **Advisory-only closeout:** Closeout drift must fail closed for merge-blocking truth surfaces.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Operator CLI framework | custom command runtime | Mix tasks | Native Elixir workflow, discoverable via `mix help`. [CITED: https://hexdocs.pm/mix/Mix.Task.html] |
| Manual closeout review | ad-hoc checklist interpretation | deterministic ExUnit + validator checks | Prevents context-loss regression and checklist drift. [VERIFIED: codebase files] |
| Changelog generation | full auto-generated changelog prose | human-authored changelog + machine parity assertions | Preserves nuanced release wording while enforcing truth boundaries. [VERIFIED: codebase files] |

**Key insight:** The repo already has the right primitives; Phase 53 should consolidate enforcement, not invent new systems. [VERIFIED: codebase files]

## Common Pitfalls

### Pitfall 1: Milestone Label Drift Into Release Claims
**What goes wrong:** Wording confuses v3.x planning milestones with Hex SemVer releases.
**Why it happens:** Same docs surface carries both planning and release context.
**How to avoid:** Enforce explicit unreleased vs published sections and keep last published release anchored (`0.1.0` now).
**Warning signs:** Terms like “shipped” without saying “published to Hex”.

### Pitfall 2: Closeout Evidence Exists But Isn’t Gate-Enforced
**What goes wrong:** Artifacts are present, but no blocking command enforces parity.
**Why it happens:** Tests/checklists are dispersed.
**How to avoid:** Single `mix closeout.verify` command with stable check IDs and fail-closed posture.
**Warning signs:** CI green while closeout ledger remains `pending`.

## Code Examples

### Existing Publish Truth Contract Hook
```elixir
# Source: /Users/jon/projects/crosswake/lib/crosswake/doctor/publish_readiness.ex
# publish_parity_check currently enforces:
# - [Unreleased] exists
# - current [version] section exists
# - package/source URL parity stays consistent
```

### Existing Planning Parity Test Surface
```elixir
# Source: /Users/jon/projects/crosswake/test/crosswake/planning/milestone_arc_closeout_parity_test.exs
# closeout keys and phase53 enforcement target terms are already asserted.
# Phase 53 should promote this parity into runtime verifier checks + task command.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| manual/implicit closeout follow-through | explicit v3.6 closeout contract with deterministic parity tests | 2026-05-31 (Phase 48) | Enables fail-closed promotion path for Phase 53. [VERIFIED: codebase files] |
| release truth mostly package/changelog hygiene | release truth coupled with operator support-claim parity and publish-readiness checks | 2026-06-01 (Phase 50–52) | Better anti-drift posture for public claims. [VERIFIED: codebase files] |

**Deprecated/outdated:**
- `STATE.md` “next step” still references `/gsd-discuss-phase 53`; Phase 53 closeout target requires next command routing to `$gsd-discuss-phase 48` after archive/reset. [VERIFIED: codebase files]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CI should add a dedicated `closeout.verify` merge-blocking invocation (new or existing workflow). [ASSUMED] | Architecture Patterns / Validation | Medium: could require different lane integration strategy. |

## Open Questions

1. **Where should `mix closeout.verify` run in CI?**
   - What we know: Existing proof workflow pattern supports merge-blocking + advisory split.
   - What's unclear: Reuse `phase52-proof.yml` versus add phase53/closeout workflow.
   - Recommendation: Keep one merge-blocking command (`mix closeout.verify`) in whichever workflow already gates v3.6 operator truth.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | `mix closeout.verify`, tests | ✓ | Mix 1.19.5 | — |
| `elixir` | validator runtime | ✓ | Elixir 1.19.5 | — |
| `gsd-sdk` | roadmap parity helper command | ✓ | available (version not printed) | `ROADMAP.md` parity checks in verifier if command unavailable |
| `node` | optional graph tooling | ✓ | v22.14.0 | skip graph context (already unavailable) |

**Missing dependencies with no fallback:**
- None found.

**Missing dependencies with fallback:**
- Knowledge graph (`.planning/graphs/graph.json`) absent; continue with direct artifact checks.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 runtime) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/planning/milestone_arc_closeout_parity_test.exs -x` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Unreleased vs published Hex truth and support-claim release continuity | unit/integration (validator + doc parity) | `mix test test/crosswake/doctor/publish_readiness_test.exs` | ✅ |
| REL-01 | Closeout parity and fail-closed enforcement target continuity | unit | `mix test test/crosswake/planning/milestone_arc_closeout_parity_test.exs` | ✅ |
| REL-01 | New unified closeout command behavior (`mix closeout.verify`) | unit | `mix test test/crosswake/planning/closeout_verifier_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/planning/milestone_arc_closeout_parity_test.exs -x`
- **Per wave merge:** `mix test test/crosswake/planning`
- **Phase gate:** `mix test` full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/planning/closeout_verifier_test.exs` — covers REL-01 fail-closed verifier contract.
- [ ] CI invocation of `mix closeout.verify` in merge-blocking lane.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A for this phase scope |
| V3 Session Management | no | N/A for this phase scope |
| V4 Access Control | no | N/A for this phase scope |
| V5 Input Validation | yes | Strict parsing/shape checks of frontmatter and artifact state; fail-closed on malformed exceptions. [VERIFIED: codebase files] |
| V6 Cryptography | no | N/A for this phase scope |

### Known Threat Patterns for Elixir planning verifier workflows

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent checklist drift (missing evidence treated as success) | Repudiation | Deterministic checks with explicit blocking posture and stable IDs. [VERIFIED: codebase files] |
| Release-claim overstatement | Tampering | Changelog/publish parity checks tied to package version + unreleased section + support posture. [VERIFIED: codebase files] |
| Exception abuse (`deferred_with_reason` missing required fields) | Tampering | Validate required keys (`owner/scope/reason/revisit_phase/evidence/status`) and fail closed. [VERIFIED: codebase files] |

## Sources

### Primary (HIGH confidence)
- Local codebase artifacts and tests (phase context, roadmap, requirements, closeout contract, Mix/ExUnit implementations). [VERIFIED: codebase files]

### Secondary (MEDIUM confidence)
- Mix task documentation: https://hexdocs.pm/mix/Mix.Task.html

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing runtime/tools already present and verified locally.
- Architecture: HIGH - locked decisions in `53-CONTEXT.md` are explicit and implementation-targeted.
- Pitfalls: HIGH - directly observed from existing closeout contract/tests and state markers.

**Research date:** 2026-06-01
**Valid until:** 2026-07-01
