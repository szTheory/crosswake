---
phase: "165"
slug: "efficient-and-maintainable-ci"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-09"
---

# Phase 165 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Pull-request source → authoritative CI | Untrusted PR changes must not gain write authority, credentials, or release capability. | Repository source, workflow inputs, read-only tokens |
| Git diff → classifier and scheduler | Malformed or ambiguous change records must fail closed to the full proof graph. | NUL-delimited paths and closed status vocabulary |
| Workflow-run APIs → cancellation controller | Cancellation may target only a strict-lower run for the same repository, workflow, and PR. | Run identity, status, attempt, PR association |
| Cache inputs → shared archives | Restore keys must encode every compatibility dimension that can affect reusable output. | Toolchain, platform, environment, dependency digests |
| Live GitHub APIs → retained evidence | Mutable API data must be normalized to an allowlisted, privacy-safe evidence schema. | Counts, timings, outcomes, exact source digests |
| Retirement proposal → maintainer decision → branch protection | A stale or broadened proposal must never change merge authority. | Exact removal set, protection digest, explicit approval |
| Landed default branch → final evidence | Final claims must bind to the exact landed workflow and manifest blobs. | Remote tip SHA and SHA-256 blob digests |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-165-01 | Denial of service | CI concurrency | high | mitigate | Repository/PR-scoped concurrency plus exact cancellation identity validation. | closed |
| T-165-02 | Tampering / Denial of service | Obsolete-run cancellation | high | mitigate | Strict-lower same-PR selection, complete pagination, gated mutation, and live inversion proof. | closed |
| T-165-03 | Tampering / Elevation | Change classifier | high | mitigate | NUL-safe argv parsing, closed statuses, adversarial fixtures, and full-proof fail-closed fallback. | closed |
| T-165-04 | Tampering | Proof graph and umbrella | high | mitigate | Exact manifest/static-needs/producer parity; 44 leaves, one control, zero compatibility rows. | closed |
| T-165-05 | Elevation of privilege | Authoritative PR workflow | high | mitigate | Read-only permissions and no secret expressions or release/recovery credentials in Crosswake CI. | closed |
| T-165-06 | Tampering | Build caches | high | mitigate | Complete BEAM, Gradle, and Swift compatibility identities with one-dimension miss fixtures. | closed |
| T-165-07 | Information disclosure | CI evidence | high | mitigate | Closed evidence schemas, forbidden-field fixtures, and allowlisted final artifacts. | closed |
| T-165-08 | Elevation of privilege | Required-context retirement | critical | mitigate | Digest-bound exact-set approval, strict apply, immediate target-state readback, and unique producer audit. | closed |
| T-165-09 | Tampering | Android proof portability | medium | mitigate | Portable branch assertions forbid device or feature expansion and preserve the frozen Android posture. | closed |
| T-165-10 | Denial of service | Workflow jobs | medium | mitigate | Positive job timeouts and structural rejection of assertion retry loops. | closed |
| T-165-11 | Denial of service | Authoritative triggers | medium | mitigate | PR-only authoritative workflow and removal of duplicate push producers. | closed |
| T-165-12 | Elevation of privilege | Release and recovery separation | high | mitigate | Credential-free PR workflow; isolated offline Hex dry-run; separate release/manual authority. | closed |
| T-165-13 | Spoofing | Advisory checks | medium | mitigate | Advisory jobs remain outside the required manifest and umbrella authority. | closed |
| T-165-14 | Elevation of privilege | Release automation | high | mitigate | Separate triggers, permissions, secrets, and non-cancelling release/recovery workflows. | closed |
| T-165-15 | Spoofing / Tampering | Final source binding | high | mitigate | Exact remote tip `71732ad439ca3319c7d7dfbeb439d1f74545e9c8` with matching landed workflow/manifest digests and live target audit. | closed |

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-09 | 15 | 15 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-09
