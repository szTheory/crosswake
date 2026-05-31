# Phase 48: Strategic Signal and Milestone Memory - Research

**Researched:** 2026-05-31  
**Domain:** Strategic planning artifacts, milestone closeout contract, and queue discipline for v3.6  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use a hybrid strategic-memory shape. `.planning/MILESTONE-ARC.md`
  remains the canonical narrative and strategic queue, but its durable sections
  should use a stable field contract rather than freeform prose only.
- **D-02:** Required fields for each queued milestone: `Objective`, `Why now`,
  `Depends on`, `Risk tags`, `Key outputs`, `Non-goals`, and `Proof required`.
  This is enough structure for downstream planners without duplicating
  `ROADMAP.md` phase detail.
- **D-03:** `PROJECT.md`, `ROADMAP.md`, and `STATE.md` may summarize the active
  arc, but they must reference `MILESTONE-ARC.md` for strategic queue truth
  rather than restating divergent copies.
- **D-04:** Strategic changes should be dated and explicit. Prefer small
  decision notes inside `MILESTONE-ARC.md` or linked ADR-lite notes over silent
  rewrites that erase why a milestone moved, split, or deferred.
- **D-05:** The planner should add a lightweight parity check for required arc
  sections/fields if feasible in Phase 48. If implementation cost is too high,
  record the exact check as a Phase 53 enforcement target rather than leaving
  it vague.
- **D-06:** Do not rely on prose-only closeout guidance. v3.5 showed that green
  behavior can still miss completion truth through missing verification files,
  stale roadmap status, open thread residue, and uneven validation ledgers.
- **D-07:** Use a hybrid closeout contract: human-readable checklist plus a
  machine-readable closeout ledger shape that can be audited by CI or GSD
  tooling.
- **D-08:** Required closeout ledger fields: milestone id/name/status,
  shipped date, requirements state, roadmap parity result, phase verification
  coverage, SUMMARY frontmatter coverage, validation ledger status, thread/seed
  disposition, release/changelog continuity, public support-claim changes,
  deferred items with reasons, and explicit exceptions.
- **D-09:** Exceptions must use a deliberate `deferred_with_reason` or
  equivalent shape with owner/scope/revisit phase. A missing artifact without a
  reason is not an exception.
- **D-10:** Closeout automation should be left-shifted where practical:
  local/CI checks should detect missing verification, stale roadmap status,
  malformed SUMMARY frontmatter, unclosed threads/seeds, and validation ledger
  drift before the final milestone-close run.
- **D-11:** A future `closeout.verify` check should be merge-blocking for
  parity-critical facts. Human judgment remains appropriate for narrative
  lessons and release positioning, but not for whether required artifacts exist.
- **D-12:** Represent the future queue as an authoritative dependency DAG plus
  a readable Now/Next/Later presentation. A fixed linear list is readable but
  hides dependency truth; a graph alone is accurate but too hard to scan.
- **D-13:** Apply risk tags to queued milestones: at minimum `provider`,
  `authority`, `notification`, `shell-runtime`, `archetype-proof`, and
  `auditability`. Tags are planning signals, not marketing labels.
- **D-14:** v3.7 Commerce Provider Adapters depends on v3.6 operator/doctor/
  support truth. Provider evidence must continue to feed backend-owned
  reconciliation rather than device authority.
- **D-15:** v3.8 Full Sigra Auth and Session Machinery depends on v3.5 Sigra
  contracts and should precede auth-sensitive notification-open claims.
- **D-16:** v3.9 Chimeway Notification Seam may use notification-token and
  route/auth readiness truth, but must not imply first-party delivery support
  until delivery/provider proof is explicitly scoped and proven.
- **D-17:** v4.0 Production Shell Runtime Line must establish compatibility
  windows, rebuild policy, permission/entitlement templates, diagnostics export,
  Android verification closure, and device UAT expectations before v4.1 makes
  production-shaped archetype claims.
- **D-18:** Threadline remains a later audit capstone until commerce, auth,
  notification, media, shell, and sensitive route-decision surfaces are stable
  enough to audit without defining them.
- **D-19:** Import the Phoenix/Plug lesson: contracts should be explicit,
  composable, boringly named, and fail closed when required state is absent.
  Strategic planning artifacts should follow the same principle: explicit
  fields beat implied convention.
- **D-20:** Import the Ecto migration lesson: append-only history plus current
  schema truth is stronger than mutable prose. Closeout ledgers should preserve
  gap/resolution history rather than overwriting failed audits.
- **D-21:** Import Hex/Phoenix OSS release lessons from the prompt corpus:
  install truth, release truth, docs-contract parity, support matrices, and
  proof lanes are product surface. The strategic arc must plan them as first
  class work, not cleanup.
- **D-22:** Import cross-ecosystem mobile lessons from Hotwire Native,
  Capacitor, React Native/Expo, and native app release systems: native/provider
  breadth without compatibility, rebuild, permission, and proof policy creates
  support debt. Queue milestones must include proof/support gates before
  widening claims.

### the agent's Discretion
- Exact filename for the closeout ledger is planner discretion. Strong default:
  `.planning/milestones/<milestone>-CLOSEOUT.md` or a stable section inside the
  milestone audit if that better matches existing archive shape.
- Exact implementation of parity checks is planner discretion. Prefer simple
  deterministic tests or `gsd-sdk` queries over a new heavyweight schema system.
- Exact wording and ordering inside `MILESTONE-ARC.md` is planner discretion if
  D-01 through D-18 remain visible and machine-checkable where practical.

### Deferred Ideas (OUT OF SCOPE)
- Implementing full `closeout.verify` tooling may belong in Phase 53 if Phase
  48 only defines the contract and refreshes the strategic artifact.
- Branch-protection configuration for closeout checks may require repository
  settings outside the codebase and should be documented if it cannot be
  enforced locally.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STRAT-01 | Maintainers can read one current strategic arc with accurate shipped milestones and next 4-6 bets with dependencies and why-now rationale. | Canonical source-of-truth structure, required milestone fields, dependency/risk presentation pattern, and parity checks for arc freshness. |
| STRAT-02 | Maintainers have a milestone closeout checklist preserving durable lessons, threads/seeds, roadmap parity, requirements, validation ledgers, and release continuity. | Hybrid checklist+ledger contract, required ledger schema, deterministic parity checks, and left-shift validation map. |

## Summary

Phase 48 should be planned as a planning-artifact hardening phase, not a product-runtime phase. The concrete implementation surface is `.planning/MILESTONE-ARC.md` plus one machine-readable closeout ledger artifact shape and minimal parity checks, with no changes to route-policy/runtime contracts. [VERIFIED: codebase grep]  

Current repo state already contains the sections needed in `MILESTONE-ARC.md` (guardrails, durable lessons, shipped milestones, strategic queue, dependency graph, support-truth requirements, closeout checklist), but the phase context locks a stricter field contract and exception shape for durability. [VERIFIED: .planning/MILESTONE-ARC.md] [VERIFIED: .planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md]  

The most important planning move is to convert historical closeout lessons from v3.4/v3.5 audits into deterministic pre-close checks: verification-file presence, roadmap parity, SUMMARY frontmatter coverage, validation-ledger status, thread/seed disposition, and release-continuity assertions. [VERIFIED: .planning/milestones/v3.5-MILESTONE-AUDIT.md] [VERIFIED: .planning/RETROSPECTIVE.md]

**Primary recommendation:** Plan Phase 48 as three slices: (1) arc contract refresh in `MILESTONE-ARC.md`, (2) closeout ledger schema + checklist contract, and (3) lightweight parity-check wiring (or explicit Phase 53 defer note with exact enforcement spec). [VERIFIED: .planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Strategic arc truth (`STRAT-01`) | Planning docs tier (`.planning/`) | GSD query/check tier | Source-of-truth is markdown structure; checks validate freshness/parity. |
| Milestone closeout memory (`STRAT-02`) | Planning docs tier (`.planning/`) | Test/tooling tier | Human-readable checklist plus machine-readable ledger requires both docs and deterministic checks. |
| Queue dependency discipline | Strategic docs tier | Milestone planner tier | Queue semantics drive downstream planning order, not runtime behavior. |
| Left-shift closeout detection | Tooling/check tier | Planning docs tier | Automated checks enforce artifact completeness before milestone close. |

## Project Constraints (from AGENTS.md)

- Keep Crosswake Phoenix-first and route-policy-first; do not reframe as universal UI framework. [VERIFIED: AGENTS.md]
- Keep runtime ownership explicit per route; avoid generic WebView-wrapper behavior. [VERIFIED: AGENTS.md]
- Keep bridge/companion contracts semantic, typed, versioned, low-frequency. [VERIFIED: AGENTS.md]
- Keep offline claims honest and scoped (cached read-only vs local-first mutation). [VERIFIED: AGENTS.md]
- Treat diagnostics/support matrices/proof lanes/docs as product surface. [VERIFIED: AGENTS.md]
- Respect v1 scope boundaries from `PROJECT.md` and `REQUIREMENTS.md`. [VERIFIED: AGENTS.md]

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|--------------|---------|---------|--------------|
| Markdown planning artifacts under `.planning/` | N/A | Canonical strategic memory + closeout contract | Existing project system of record for strategy and closeout truth. [VERIFIED: codebase grep] |
| `gsd-sdk` CLI | `v1.1.0` | Roadmap/state parity queries and planning checks | Already used in audits and planning flows. [VERIFIED: command output] |
| ExUnit planning artifact tests | In-repo | Deterministic frontmatter/parity checks | Existing pattern for merge-blocking planning consistency. [VERIFIED: test/crosswake/planning/summary_frontmatter_test.exs] |

### Supporting
| Library/Tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| Milestone audit ledgers | In-repo format | Append-only gap/resolution history | Use as closeout evidence source and ledger pattern. |
| `VALIDATION.md` frontmatter (`nyquist_compliant`) | In-repo format | Validation completeness signal | Use for closeout parity and exception handling. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Lightweight parity checks (`grep`/`gsd-sdk`/ExUnit) | Full schema system + custom parser | Higher implementation cost now; Phase 48 context prefers minimal deterministic checks. [VERIFIED: 48-CONTEXT.md] |
| Single canonical `MILESTONE-ARC.md` queue truth | Duplicate queue in multiple docs | Creates drift risk already observed in prior milestones. [VERIFIED: .planning/RETROSPECTIVE.md] |

**Installation:** No new external package installation is required for Phase 48. [VERIFIED: scope docs]

## Package Legitimacy Audit

Not applicable for this phase because no external package installation is required. [VERIFIED: scope docs]

## Architecture Patterns

### System Architecture Diagram

```text
Inputs
  ├─ PROJECT.md / REQUIREMENTS.md / ROADMAP.md / STATE.md
  ├─ MILESTONE-ARC.md (current strategic arc)
  ├─ milestone audits + retrospective evidence
  └─ phase context locked decisions (48-CONTEXT.md)
           |
           v
Phase 48 artifact refresh
  1) Arc contract hardening in MILESTONE-ARC.md
  2) Closeout checklist + machine-readable ledger schema
  3) Parity check definitions (now or explicit Phase 53 defer target)
           |
           v
Verification path
  ├─ deterministic local/CI checks
  ├─ roadmap/requirements/state parity checks
  └─ exception path via deferred_with_reason + owner/scope/revisit
           |
           v
Outputs consumed by Phases 49-53 planning + milestone close
```

### Recommended Project Structure

```text
.planning/
├── MILESTONE-ARC.md                     # canonical strategic narrative + queue contract
├── PROJECT.md                           # references arc as queue truth
├── ROADMAP.md                           # phase status parity against shipped state
├── REQUIREMENTS.md                      # active requirement truth
├── STATE.md                             # current milestone/phase truth
└── milestones/
    ├── v3.5-MILESTONE-AUDIT.md          # precedent: gap+resolution evidence
    └── <milestone>-CLOSEOUT.md          # recommended ledger filename (planner discretion)
```

### Pattern 1: Hybrid Narrative + Structured Strategic Queue
**What:** Keep readable arc prose, but enforce required fields for each queued milestone (`Objective`, `Why now`, `Depends on`, `Risk tags`, `Key outputs`, `Non-goals`, `Proof required`).  
**When to use:** Always for queued milestones in `MILESTONE-ARC.md`.  
**Example:**
```markdown
### Next: v3.7 Commerce Provider Adapters

**Objective**
...
**Why now**
...
**Depends on**
- v3.6 operator truth
**Risk tags**
- provider
- authority
```

### Pattern 2: Closeout Contract = Checklist + Ledger
**What:** Pair human-readable closeout checklist with machine-readable ledger fields and exception semantics.  
**When to use:** Every milestone close, and as plan-time target in this phase.  
**Example:**
```yaml
milestone: v3.6
status: in_progress
roadmap_parity: pass
requirements_state: pass
phase_verification_coverage: pass
summary_frontmatter_coverage: pass
validation_ledger_status: partial
thread_seed_disposition: pass
release_changelog_continuity: pass
exceptions:
  - type: deferred_with_reason
    owner: maintainer
    scope: nyquist-ledger-finalization
    revisit_phase: 53
```

### Pattern 3: Left-Shifted Parity Checks
**What:** Verify artifact parity before final milestone close to avoid audit-time surprises.  
**When to use:** During phase completion and before milestone close run.  
**Example checks:**
```bash
gsd-sdk query roadmap.analyze
mix test test/crosswake/planning/summary_frontmatter_test.exs -x
rg --files .planning/phases | rg "VERIFICATION.md$"
```

### Anti-Patterns to Avoid
- **Prose-only closeout guidance:** repeats v3.5 audit gap pattern. [VERIFIED: v3.5-MILESTONE-AUDIT.md]
- **Queue truth duplicated across docs:** creates strategic drift and stale status. [VERIFIED: RETROSPECTIVE.md]
- **Silent exceptions:** any missing artifact without `deferred_with_reason` + owner/scope/revisit is invalid per locked decision. [VERIFIED: 48-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Strategic queue duplication | Separate queue definitions in multiple files | `MILESTONE-ARC.md` as canonical + references elsewhere | Prevents drift and conflicting strategic signals. |
| Heavy schema framework for closeout | New parser framework | Minimal YAML/markdown field checks with existing test/query tools | Lower cost, aligned with locked Phase 48 direction. |
| One-off manual closeout reconciliation | Ad hoc review-only process | Deterministic parity checks + ledger exceptions | Reproducible and auditable for future milestones. |

**Key insight:** This phase should standardize strategic-memory contracts, not add new runtime behavior.

## Common Pitfalls

### Pitfall 1: Artifact parity drift despite green behavior
**What goes wrong:** milestone appears green, but closeout fails due to missing verification, stale roadmap status, or open thread residue.  
**Why it happens:** execution evidence exists but closeout artifacts are incomplete.  
**How to avoid:** left-shift parity checks and explicit closeout ledger fields.  
**Warning signs:** mismatch between `ROADMAP.md`, audit ledger, and phase artifacts. [VERIFIED: v3.5-MILESTONE-AUDIT.md] [VERIFIED: RETROSPECTIVE.md]

### Pitfall 2: Validation ledger ambiguity
**What goes wrong:** phases are functionally verified but `VALIDATION.md` state is partial/draft and untracked in closeout logic.  
**Why it happens:** validation bookkeeping is treated as optional cleanup.  
**How to avoid:** include `validation_ledger_status` and explicit exceptions in closeout ledger.  
**Warning signs:** `nyquist_compliant: false` persists in completed phase ledgers. [VERIFIED: codebase grep]

### Pitfall 3: Strategic edits without dated rationale
**What goes wrong:** future planners cannot reconstruct why milestones moved/split/deferred.  
**Why it happens:** silent rewrites in `MILESTONE-ARC.md`.  
**How to avoid:** dated decision notes/ADR-lite references in arc updates.  
**Warning signs:** queue changes with no timestamped note. [VERIFIED: 48-CONTEXT.md]

## Code Examples

### Planning parity test pattern (existing)
```elixir
# Source: test/crosswake/planning/summary_frontmatter_test.exs
assert Regex.match?(~r/^requirements-completed:[ \t]*(?:\[|\r?\n[ \t]+-)/m, fm),
       "#{path} is missing required `requirements-completed:` key"
```

### Roadmap parity analysis command (existing)
```bash
# Source: milestone audits and workflow docs
gsd-sdk query roadmap.analyze
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Closeout as mostly narrative/manual sweep | Hybrid deterministic parity + ledger contract | Locked in Phase 48 context (2026-05-31) | Better reproducibility and fewer milestone-close surprises. |
| Queue as readable list | Queue as readable list + dependency/risk discipline | Active in v3.6 planning (2026-05-31) | Better planning quality for Phases 49-53 and v3.7+ sequencing. |

**Deprecated/outdated:**
- Treating strategic arc updates as prose-only edits without machine-checkable fields. [VERIFIED: 48-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Closeout ledger filename should default to `.planning/milestones/<milestone>-CLOSEOUT.md`; exact file is planner discretion. [ASSUMED] | Architecture Patterns | Planner may choose alternate shape/location, requiring plan updates. |
| A2 | Existing `summary_frontmatter` parity-test style is sufficient baseline for additional closeout checks without new framework. [ASSUMED] | Standard Stack / Pattern 3 | Could under-cover edge cases if new checks need richer parsing. |

## Open Questions (RESOLVED)

1. **RESOLVED — Phase 48 implements lightweight executable parity checks now and records the exact Phase 53 promotion target.**
   - What we know: D-05 allows deferral only if exact enforcement check is documented, not vague. [VERIFIED: 48-CONTEXT.md]
   - Decision: Plan 48-03 adds dependency-free ExUnit parity guards for the strategic arc and closeout ledger now; Plan 48-02 records the concrete `closeout.verify` Phase 53 merge-blocking enforcement target.

2. **RESOLVED — the live closeout ledger lives at `.planning/milestones/v3.6-CLOSEOUT.md`.**
   - What we know: phase context permits either dedicated closeout file or stable section in milestone audit. [VERIFIED: 48-CONTEXT.md]
   - Decision: Plan 48-02 creates a dedicated live closeout artifact so the later milestone audit can remain append-only evidence rather than the active checklist.

## Environment Availability

Step 2.6: SKIPPED (no external runtime/service dependency is required; this phase is planning-artifact and parity-check scoped). [VERIFIED: phase scope]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (project standard) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/planning/summary_frontmatter_test.exs -x` |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STRAT-01 | Arc fields and shipped/queue status stay canonical and current | planning parity | `gsd-sdk query roadmap.analyze` + targeted grep/assert checks | ❌ Wave 0 |
| STRAT-02 | Closeout checklist/ledger tracks all required parity fields and exceptions | planning parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs -x` (+ new closeout parity checks) | ⚠️ Partial |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/planning/summary_frontmatter_test.exs -x`
- **Per wave merge:** `mix test --exclude requires_example_host --exclude advisory_only`
- **Phase gate:** parity checks + roadmap analyze + full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] Add explicit parity checks for strategic-arc required field contract (`D-02`) and/or document exact Phase 53 enforcement target.
- [ ] Add closeout-ledger schema/field validation checks (or deterministic checker command) for `D-08`/`D-09`.
- [ ] Add planner-facing checklist that verifies roadmap/requirements/state/verification/validation/thread-release continuity before milestone close.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (no auth-surface implementation in this phase) |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | Deterministic validation of closeout ledger fields and exceptions |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Strategic truth drift across docs | Tampering | Canonical source (`MILESTONE-ARC.md`) + parity checks |
| Missing closeout evidence silently accepted | Repudiation | Required ledger fields + explicit `deferred_with_reason` exceptions |
| False support claims from stale milestone state | Information Disclosure | Roadmap/requirements/verification/release continuity checks before close |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md` - locked decisions, required fields, exceptions, and scope.
- `.planning/MILESTONE-ARC.md` - current strategic arc structure and queue.
- `.planning/ROADMAP.md` - Phase 48 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `STRAT-01` and `STRAT-02`.
- `.planning/STATE.md` - active milestone/phase position.
- `.planning/PROJECT.md` - thesis and active v3.6 requirements context.
- `.planning/milestones/v3.5-MILESTONE-AUDIT.md` - closeout gap precedents.
- `.planning/milestones/v3.4-MILESTONE-AUDIT.md` - validation-ledger precedent and closeout signal shape.
- `.planning/RETROSPECTIVE.md` - recurring closeout/process lessons.
- `test/crosswake/planning/summary_frontmatter_test.exs` - existing deterministic planning parity test pattern.
- `.planning/config.json` - `workflow.nyquist_validation: true`.

### Secondary (MEDIUM confidence)
- `.planning/phases/47-companion-arc-guide-and-milestone-proof/47-RESEARCH.md` - recent planning artifact and validation-architecture format precedent.

### Tertiary (LOW confidence)
- none

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all based on existing repo tooling/patterns.
- Architecture: HIGH - directly constrained by locked Phase 48 context decisions.
- Pitfalls: HIGH - grounded in v3.4/v3.5 audit and retrospective evidence.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30
