# Phase 167: Documentation and Pull-Request Reconciliation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-10
**Phase:** 167-documentation-and-pull-request-reconciliation
**Areas discussed:** Documentation truth-source map, adopter claim boundary, open pull-request dispositions, documentation drift prevention

---

## Documentation Truth-Source Map

| Option | Description | Selected |
|--------|-------------|----------|
| Prose-first authority | Keep Markdown easy to edit and protect it mainly through phrase/link tests; semantic contradictions can remain green. | |
| One central documentation manifest | Put every fact and page relationship in a new documentation schema; risks duplicating runtime and release authority. | |
| Generate nearly all documentation | Maximize byte consistency; produces template-shaped explanations and noisy editorial reviews. | |
| Layered authority | Executable structured truth feeds generated projections; authored narratives teach user jobs; historical artifacts preserve dated truth. | ✓ |

**User's choice:** Lock the complete research-backed recommendation package.
**Notes:** README remains a map, ExDoc extras remain the guide system, generated support/capability
tables gain one explicit synchronization command, and the current brand spec supersedes the old
prompt-era brandbook. No new docs site or competing truth manifest.

---

## Adopter Claim Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Flat support labels | Simple, but conflates implementation, proof environment, evidence subject, and current activation. | |
| Component maturity ladder | Familiar experimental/stable model, but answers API lifecycle rather than whose host was proven. | |
| Support by test-coverage matrix | Separates support and coverage, but still allows reference evidence to be mistaken for adopter evidence. | |
| Existing-label three-layer claim ledger | Preserve current labels while separating evidence subject, source binding, and activation state. | ✓ |

**User's choice:** Lock the complete research-backed recommendation package.
**Notes:** Present reusable verified contracts, retained dated reference-host/device evidence, and
blocked real first-adopter activation as three separate claims. Public copy says “first adopter”;
durable planning retains “First B2C Adopter,” TODO-002, and the exact private handoff/device gate.
The current support-matrix versus capability/state contradiction must be repaired atomically.

---

## Open Pull-Request Dispositions

| Option | Description | Selected |
|--------|-------------|----------|
| Merge as-is | Clears the queue quickly but accepts stale bases, incomplete truth surfaces, or release-trigger risk. | |
| Rebase/complete then merge | Revalidates ordinary changes against current authority and reconciles all affected owners. | ✓ for #121, #110, #105 |
| Supersede | Use only when a bot or existing branch cannot carry the coherent correction cleanly. | conditional |
| Close or explicitly defer | Appropriate for obsolete work or release PRs whose immutable action belongs to a later approval gate. | ✓ defer #115, #57 |

**User's choice:** Lock the complete research-backed recommendation package.
**Notes:** #121 is rebased and completed across every setup-java owner; #110 is rebased and expands
to all compatibility/package truth surfaces; #105 is rebased/squashed and verified. #115 and #57
remain managed Release Please threads explicitly deferred to Phase 168. Phase 167 records and
applies dispositions during execution; discussion performs no remote mutation.

---

## Documentation Drift Prevention

| Option | Description | Selected |
|--------|-------------|----------|
| Contract-tiered existing gate | Byte parity for generated outputs, semantic invariants for authored claims, ExDoc/package proof, privacy scan, and local links. | ✓ |
| Preserve broad substring tests | Low change, but freezes phase-era prose and can miss contradictory meaning. | |
| Snapshot every document | Detects all edits but cannot establish correctness and encourages blind snapshot updates. | |
| Network/prose lint gates | Finds some rot but creates flaky authority and can conflict with privacy and brand voice. | |

**User's choice:** Lock the complete research-backed recommendation package.
**Notes:** Extend existing `documentation-contracts` and package/ExDoc owners rather than adding a
workflow. Keep live PR enumeration, external links, duplicate counts, and representative rendered
review as one-time or advisory evidence. Generated checks are no-write and never stage files.

---

## the agent's Discretion

- Exact internal placement of the documentation synchronization task and focused semantic tests.
- Exact closed atom names and compact rendering layout for evidence subject, source binding, and
  activation state, without changing their accepted semantics.
- Exact privacy-safe Phase 167 evidence filename/serialization and routine rebase mechanics.

## Deferred Ideas

- Exact 0.2.1 candidate proof and all immutable package/tag publication remain Phase 168.
- External-link availability may be one-time or scheduled advisory maintenance, not merge
  authority.
- New docs UI, dashboards, taxonomy, Android breadth, adopter activation, and product/mobile
  capabilities remain outside Phase 167.
