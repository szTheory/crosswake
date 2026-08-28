---
phase: 158
slug: adoption-reset-and-route-map
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: 2026-07-31
---

# Phase 158 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host route policy → Crosswake validators | Host-owned route declarations determine runtime ownership and permitted first-adopter surfaces. | Route names, owners, bridge capabilities, and offline-island declarations |
| Repository text → adoption-context scanner | Tracked documentation and source text are inspected for protected identity, commercial, geography, payload, and path disclosures. | Repository-relative paths and privacy-safe diagnostics; never matching sensitive values |
| Offline scope → replay authority | Mutations remain partitioned by opaque scope and replay only after backend authorization. | Opaque scope references and authorization outcomes; never raw answers, media, credentials, or account identifiers in diagnostics |
| Generated public guide → checked-in guide | The host-facing guide is generated from one canonical source and checked for byte parity. | Public first-adopter guidance with no protected identity or proprietary context |
| Pull request → protected CI | Recurring privacy, route-policy, documentation, and test contracts run without human UAT. | Pass/fail status and sanitized error codes |
| Maintainer branch → fork contribution | Protected-term scanning fails closed when repository secrets are unavailable to an untrusted fork. | Maintainer promotion decision; protected terms remain secret |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and L1 evidence | Status |
|-----------|----------|-----------|----------|-------------|----------------------------|--------|
| T-158-G01..G07 | Spoofing / Tampering / Information Disclosure / Repudiation / Denial of Service | Governing documents, route inventory, schema, validators, diagnostics, and phase gates | low–high | mitigate | Plan-defined typed validation, fail-closed errors, privacy-safe diagnostics, focused tests, and the hermetic phase gate are implemented and passing. | closed |
| T-158-G08-01..04 | Tampering / Information Disclosure / Elevation of Privilege | Protected-context scanner and CI integration | low–high | mitigate | Scanner bypass canaries, generic scan-by-default behavior, protected-term handling, and merge-blocking workflow coverage pass. | closed |
| T-158-G08-05 | Denial of Service | Fork contribution flow | medium | accept | Fork PRs require maintainer promotion before merge; this operational cost is the selected fail-closed privacy posture. | closed — accepted |
| T-158-G09-01..02 | Tampering / Information Disclosure | Canonical and generated first-adopter guides | low–high | mitigate | Generation and byte-parity checks make content drift observable and block automated verification. | closed |
| T-158-G09-03 | Repudiation | Manual guide edits | low | accept | Byte parity makes manual drift observable in the focused test suite. | closed — accepted |
| T-158-G10..G12 | Spoofing / Tampering / Information Disclosure / Repudiation / Denial of Service | Host proof, scope partitioning, replay authorization, and logout/account-switch behavior | low–high | mitigate | Plan-defined executable gates verify opaque scopes, backend authority, fail-closed transitions, and sanitized proof output. | closed |
| T-158-G13-01..02 | Tampering / Information Disclosure | Generated public guide | low–high | mitigate | Canonical rendering and repository-wide privacy scanning verify the checked-in artifact. | closed |
| T-158-G13-03 | Information Disclosure | Generated guide residual | low | accept | No content changes were planned; focused byte parity and the repository scan detect divergence. | closed — accepted |
| T-158-G14..G20 | Spoofing / Tampering / Information Disclosure / Repudiation / Denial of Service | Final implementation, review, reconciliation, and closure evidence | low–high | mitigate | Focused regressions, full hermetic tests, production scanning, independent goal verification, and transition-safe planning assertions pass. | closed |

The independent security auditor evaluated all 103 plan-time threat entries. One hundred
mitigations were present and passing; the three remaining entries were already assigned explicit
`accept` dispositions in their source plans and are recorded below. No open threat meets the
configured `high` blocking threshold.

*Severity: critical > high > medium > low. Only open threats at or above `workflow.security_block_on: high` count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-158-01 | T-158-G08-05 | Fork pull requests cannot safely receive protected scan terms. Requiring maintainer promotion preserves the deliberately fail-closed privacy boundary at the cost of contribution latency. | Phase 158 Plan 08 disposition | 2026-07-31 |
| AR-158-02 | T-158-G09-03 | Direct edits to the generated guide are possible, but canonical byte parity makes every divergence observable and blocks the automated gate. | Phase 158 Plan 09 disposition | 2026-07-31 |
| AR-158-03 | T-158-G13-03 | A generated-guide residual is low risk because byte parity and repository-wide scanning independently detect divergence before closure. | Phase 158 Plan 13 disposition | 2026-07-31 |

---

## Security Audit 2026-07-31

| Metric | Count |
|--------|-------|
| Threats evaluated | 103 |
| Mitigated | 100 |
| Accepted | 3 |
| Open | 0 |

ASVS L1 evidence confirms every high-severity threat has an executable, passing mitigation.
The accepted medium/low operational risks preserve the intended fail-closed privacy posture and
are not unresolved implementation defects.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-31 | 103 | 103 (100 mitigated, 3 accepted) | 0 | `gsd-security-auditor` |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] Automated ASVS L1 evidence passes without human UAT
- [x] `threats_open: 0` confirmed at the configured `high` blocking threshold
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-31
