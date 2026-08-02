---
phase: 160
slug: scoped-replay-and-auth-safety
status: blocked
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 6
asvs_level: 1
created: 2026-08-02
---

# Phase 160 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host activation -> retained partition | A host-issued sensitive scope may activate exactly one otherwise inert partition. | Opaque scope reference and retained offline mutations (sensitive) |
| Async request completion -> current browser state | A completion must present the same active scope and epoch before any storage or UI mutation. | Replay result, lifecycle lease, and learner-visible status |
| Browser -> Phoenix endpoint | Untrusted scoped envelopes cannot establish session, scope, route, or feature authority. | Offline mutation envelope and current backend authority (sensitive) |
| Host/Sigra callbacks -> domain mutation | Every allow decision must be current, ordered, closed, and fail closed. | Route, feature, session, Sigra, and domain decisions (sensitive) |
| Transaction result -> retry | Lost responses and duplicates must not repeat the domain effect. | Scope-qualified idempotency key and mutation outcome |
| Sensitive replay/auth transport -> operational egress | Wire and domain values must be structurally unavailable to telemetry, logs, doctor, inspection, and aggregates. | Safe observation projection only |
| Automated assertion -> retained evidence | Only content-bound closed IDs may cross the Phase 159 evidence schema. | Closed assertion IDs and canonical evidence bytes |
| Generated proof -> support claim | Blocked, unavailable, or unknown external inputs cannot become passing evidence. | Closed proof outcome and non-sensitive rule identifier |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-160-01 | Spoofing / Elevation | Scope contract, IndexedDB partition, and cross-scope evidence | high | mitigate | Require exact-scope storage and content-bound evidence, including a non-assigning legacy-record migration, quarantine, or recovery path. Current v3 upgrade creates `scoped_mutations` but leaves legacy `mutations` records unreachable. | open |
| T-160-02 | Tampering | Lifecycle, stale completion, and lifecycle evidence | high | mitigate | Fence first, increment epoch, and recheck the captured lease before every post-await storage or UI side effect. Current browser code checks once before later awaited deletion/count operations. | open |
| T-160-03 | Elevation | Route, feature, Sigra, and domain authorization chain | high | mitigate | Resolve current authority in locked order for every event and fail closed when real Sigra route/session evidence cannot be constructed. The default branch currently evaluates `nil` route/session inputs and permits them. | open |
| T-160-04 | Information Disclosure | Telemetry, Logger, doctor, inspection, and evidence | high | mitigate | Revalidate or make opaque every `SafeObservation` at each public projection/egress boundary. Direct public struct construction currently bypasses `new/1` validation and reaches telemetry projection. | open |
| T-160-05 | Tampering / Repudiation | Scope-qualified idempotency and domain effect | high | mitigate | Preserve legacy idempotency during scope migration through authoritative backfill plus non-null scoped uniqueness, or a retained global guard/quarantine. Current migration drops global uniqueness while legacy scope values remain null. | open |
| T-160-06 | Elevation / Denial of Service | Disabled or blocked replay drain | high | mitigate | Halt without hot retry, retain unaccepted entries, and render the server `halted` result as visibly paused/blocked. Current browser response handling ignores partial-batch `halted` and can report normal sync progress. | open |
| T-160-SC | Tampering | Package installs | low | accept | No package-manager installation occurred; the phase reused existing runtime and test dependencies. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-160-01 | T-160-SC | Plans 160-01 through 160-03 declared no package-manager installation, and execution reused existing dependencies. The residual low-severity supply-chain surface did not change during this phase. | Phase 160 plan-time disposition | 2026-08-02 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit 2026-08-02

| Metric | Count |
|--------|-------|
| Threats found | 7 |
| Closed | 1 |
| Open | 6 |

### Verification Evidence

- The focused current-tree suites passed: 16 core tests, 8 Phoenix host tests, and 13 Sigra contract tests.
- A direct current-tree check confirmed the default Sigra evaluation allows nil authority inputs (`nil_authority_allowed=true`).
- A direct current-tree check confirmed a forged public `SafeObservation` struct reaches telemetry projection (`forged_struct_projected=true`).
- Artifact inspection confirmed no legacy IndexedDB migration/quarantine path, no post-await lease checks before all status writes, no `halted` browser response handling, and no safe legacy SQL idempotency transition.
- `160-REVIEW.md` and `160-VERIFICATION.md` independently identify the same implementation gaps. No external adopter input or human UAT is needed to reproduce them.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-02 | 7 | 1 | 6 | Codex (`gsd-secure-phase`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [ ] `threats_open: 0` confirmed
- [ ] `status: verified` set in frontmatter

**Approval:** blocked — six high-severity threats remain open as of 2026-08-02.
