# Phase 48: Strategic Signal and Milestone Memory - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Refresh Crosswake's durable strategic memory after v3.5 so downstream phases
can plan from current shipped truth instead of reconstructing it from execution
artifacts.

**Delivers:**
- `.planning/MILESTONE-ARC.md` as the canonical strategic source of truth for
  shipped milestones, active v3.6 work, and the next 4-6 milestone bets.
- A durable closeout contract that treats roadmap parity, requirements state,
  verification files, validation ledgers, thread/seed status, release
  continuity, and durable lessons as completion truth.
- A future queue that stays readable for contributors while preserving
  dependency and risk discipline for provider, auth, notification, shell, and
  audit surfaces.

**Satisfies:** STRAT-01 and STRAT-02.

**In scope:**
- Restructure or tighten `.planning/MILESTONE-ARC.md` so it remains canonical.
- Add or define a closeout checklist/ledger shape that downstream phases can
  enforce later.
- Promote v3.4/v3.5 retrospective and audit lessons into planning-time rules.
- Clarify the v3.7+ queue with why-now rationale, dependencies, risk tags,
  non-goals, and proof/support gates.

**Out of scope:**
- Implementing StoreKit, Play Billing, full Sigra machinery, Chimeway delivery,
  standalone shell packages, or Threadline audit behavior.
- Changing runtime contracts, route-policy semantics, companion behavior, or
  doctor/support-matrix code directly in this phase unless a tiny validation
  helper is needed for strategic artifact parity.
- Replacing GSD milestone workflows wholesale.

</domain>

<decisions>
## Implementation Decisions

### 1. Strategic Arc Shape - LOCKED
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

### 2. Closeout Contract - LOCKED
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

### 3. Future Queue And Dependency Discipline - LOCKED
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

### 4. Ecosystem Lessons To Preserve - LOCKED
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` section "Phase 48: Strategic Signal and Milestone Memory" - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "Strategic Memory" - STRAT-01 and STRAT-02.
- `.planning/PROJECT.md` - current v3.6 thesis, constraints, active requirements, and queue summary.
- `.planning/STATE.md` - current phase position and deferred items.
- `.planning/MILESTONE-ARC.md` - current strategic arc, shipped milestones, queue, support truth requirements, and closeout checklist.

### Prior milestone lessons and audit evidence
- `.planning/RETROSPECTIVE.md` - v3.4/v3.5 lessons and cross-milestone trends.
- `.planning/milestones/v3.5-MILESTONE-AUDIT.md` - artifact parity gaps and resolved closeout evidence from v3.5.
- `.planning/milestones/v3.5-REQUIREMENTS.md` - archived v3.5 requirement and deferred companion queue truth.
- `.planning/milestones/v3.4-MILESTONE-AUDIT.md` - validation-ledger and archetype-proof closeout precedent.
- `.planning/milestone-prefs.json` - project-local preferences around shipped-vs-documented truth and bookkeeping to threads/state.

### Recent phase context
- `.planning/milestones/v3.5-phases/47-companion-arc-guide-and-milestone-proof/47-CONTEXT.md` - docs-contract parity, companion guide, and milestone-proof decisions.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - auth contract-only scope and deferred full Sigra machinery.
- `.planning/milestones/v3.5-phases/45-rindle-in-tree-companion-mock-example-and-proof/45-CONTEXT.md` - media evidence/proof posture and hermetic/advisory pattern.

### Prompt corpus
- `prompts/crosswake-brand-book.md` - route-boundary and support-claim language.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, public contract honesty, proof lanes, and release truth.
- `prompts/crosswake-gsd-project-brief.md` - Phoenix-first route ownership and app/runtime boundaries.
- `prompts/crosswake-integrations-and-companions.md` - companion classification and sequencing.
- `prompts/crosswake-research-synthesis.md` - stable conclusions and current architecture thesis.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - runtime ladder and cross-ecosystem lessons.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - OSS library release, CI, packaging, and support posture.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - Hotwire Native lessons, path configuration, bridge/capability plane, and proof posture.
- `prompts/new elixir oss lib prompt.txt` - maintainer preference for deep research, DX, CI/CD, ecosystem lessons, and coherent recommendation-first planning.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/MILESTONE-ARC.md` already contains the right high-level sections:
  guardrails, durable lessons, shipped milestones, strategic queue, dependency
  graph, support truth requirements, closeout checklist, and open research
  flags. Phase 48 should tighten and parity-lock this artifact rather than
  replace it.
- `.planning/RETROSPECTIVE.md` contains the raw lesson material for v3.4/v3.5
  and should feed the durable lessons section.
- Existing milestone audits already use structured frontmatter for status,
  scores, gaps, tech debt, and Nyquist status. That is the closest precedent
  for a closeout ledger.
- `gsd-sdk query roadmap.analyze` already provided milestone audit evidence in
  v3.5; use existing GSD queries where possible before inventing new tooling.

### Established Patterns
- Crosswake prefers hermetic merge-blocking checks plus advisory lanes for
  environment-sensitive proof. Apply the same split to closeout: parity facts
  are merge-blocking; narrative judgment remains human-reviewed.
- Docs-contract parity should compare live truth to public claims rather than
  snapshot broad prose. Phase 48 should set up the same posture for strategic
  artifacts.
- Append-only audit/gap resolution history is preferred over rewriting prior
  failed checks.

### Integration Points
- `MILESTONE-ARC.md` should feed Phase 49-53 planning, not just the next
  milestone picker.
- Phase 53 should consume the closeout contract established here to enforce
  release continuity and closeout parity for v3.6.
- Future milestone creation should read the risk tags and dependencies before
  selecting v3.7+ work.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly asked for all three areas to be considered with subagent
  research and one coherent recommendation set, not a broad option menu.
- Advisor research converged on a single architectural posture: hybrid
  narrative plus structured contract plus parity checks.
- The planning posture should optimize for senior maintainer DX: concise
  current truth, explicit fields, local/CI feedback before closeout, and no
  hidden support claims.

</specifics>

<deferred>
## Deferred Ideas

- Implementing full `closeout.verify` tooling may belong in Phase 53 if Phase
  48 only defines the contract and refreshes the strategic artifact.
- Branch-protection configuration for closeout checks may require repository
  settings outside the codebase and should be documented if it cannot be
  enforced locally.

</deferred>

---

*Phase: 48-Strategic Signal and Milestone Memory*
*Context gathered: 2026-05-31*
