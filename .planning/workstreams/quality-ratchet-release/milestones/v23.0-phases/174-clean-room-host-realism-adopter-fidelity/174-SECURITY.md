---
phase: "174"
slug: "clean-room-host-realism-adopter-fidelity"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-25"
---

# Phase 174 — Security

> Threat register reconciled from all seven executed plan threat models. Verification was performed
> inline against the phase summaries, current implementation, captured evidence, and prescribed
> guards; no security-sensitive external state was changed.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Candidate artifact manifest -> generated Phoenix host | Source-mode authority selects exact core and companion artifacts for isolated generated hosts. | Package metadata and source artifacts; no adopter data |
| Generated host -> installer/doctor | Installer patches generated host router/endpoint; doctor checks resulting runtime contract. | Synthetic routes, generated source and diagnostics |
| Captured run -> ROOM-02 disposition | Only complete runtime events and a passing evaluator result become durable evidence. | Sanitized pass markers and package/profile verdicts |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-174-01 | Tampering | Doctor manifest contract | high | mitigate | Pinned function and call-site guard passes; source remains unchanged. | closed |
| T-174-02 | Repudiation | Legacy evidence authenticity | high | mitigate | Real captured legacy run and named result marker. | closed |
| T-174-03 | Spoofing | Legacy marker roster | high | mitigate | Literal marker roster and cardinality/non-vacuity assertions. | closed |
| T-174-04 | Denial of Service | Legacy installer failure | medium | mitigate | Installer failures fail the harness; no swallowed failure path. | closed |
| T-174-05 | Information Disclosure | Legacy evidence | medium | mitigate | Synthetic host and codename-only evidence boundaries. | closed |
| T-174-06 | Tampering | Historical baseline fixture | high | mitigate | Baseline is pinned to historical source; guard and mutation tests verify drift failure. | closed |
| T-174-07 | Spoofing | Doctor source extraction | high | mitigate | Non-empty exact-count extraction precedes comparisons. | closed |
| T-174-08 | Tampering | Doctor guard call site | high | mitigate | Call site checked separately; deleted capture mutation fails. | closed |
| T-174-09 | Repudiation | Doctor guard exit status | high | mitigate | Exit status is checked directly, not through a pipeline tail. | closed |
| T-174-10 | Spoofing | Physical iPhone outcome | high | mitigate | Explicit result classifier maps non-pass to fail-closed status. | closed |
| T-174-11 | Tampering | Physical iPhone report validity | high | mitigate | Completeness, ownership, and ordering gates precede outcome classification. | closed |
| T-174-12 | Repudiation | Contract vocabulary change | high | mitigate | Breaking change decision is recorded and deferred with a reopen condition. | closed |
| T-174-13 | Information Disclosure | Adopter disposition | medium | mitigate | Only durable codename is used; adopter identifiers are excluded. | closed |
| T-174-14 | Denial of Service | Stale report schema | medium | mitigate | Exact envelope schema version is required; old versions are rejected. | closed |
| T-174-15 | Spoofing | Rehearsal workflow invocation | high | mitigate | Rehearsal uses the same invocation and action pins as the lane. | closed |
| T-174-16 | Tampering | Workflow inputs | medium | mitigate | Package choice is constrained and script validation remains fail-closed. | closed |
| T-174-17 | Repudiation | CI result record | high | mitigate | Run ID and job-level conclusion are captured from the real run. | closed |
| T-174-18 | Elevation of Privilege | Rehearsal workflow permissions | high | mitigate | Workflow has contents-read permission only. | closed |
| T-174-19 | Tampering | Doctor contract under CI failure | high | mitigate | Pinned doctor contract guard is rerun after repairs. | closed |
| T-174-20 | Repudiation | Companion failure findings | high | mitigate | Findings cite distinct live runs and captured logs. | closed |
| T-174-21 | Spoofing | Companion finding separation | high | mitigate | Independent findings are required for both roster members. | closed |
| T-174-22 | Tampering | Findings roster | high | mitigate | Roster comes from TODO-011 and missing-finding mutation fails. | closed |
| T-174-23 | Tampering | Doctor contract after red companion run | high | mitigate | Scope boundary and pinned guard prohibit contract weakening. | closed |
| T-174-24 | Information Disclosure | Companion evidence | medium | mitigate | No adopter-derived input is present in generated hosts or logs. | closed |
| T-174-25 | Repudiation | Non-vacuity record | high | mitigate | Each check and disposition has an explicit taxonomy row. | closed |
| T-174-26 | Spoofing | Requirement disposition | high | mitigate | Requirement dispositions name deciding artifacts and checks. | closed |
| T-174-27 | Tampering | Requirement wording | high | mitigate | Only evidence/status text changed; requirement statement remains intact. | closed |
| T-174-28 | Repudiation | Finding repair scope | medium | mitigate | Gap is recorded and addressed by the designated gap-closure plan. | closed |
| T-174-29 | Tampering | Matrix source-mode selection | high | mitigate | Installer is in the common post-selection loop; artifact authority and evaluator gates remain intact. | closed |
| T-174-30 | Repudiation | Installer/doctor order | high | mitigate | Ten exact pairs are captured; literal roster and source/log mutation controls pass. | closed |
| T-174-31 | Information Disclosure | Captured matrix log | high | mitigate | Synthetic hosts; evidence scan found no credentials, identifiers, answers, or transcripts. | closed |
| T-174-32 | Tampering | Doctor manifest contract | high | mitigate | `MANIFEST_CONTRACT_UNCHANGED_VERIFIED` passes against pinned function and call site. | closed |
| T-174-33 | Denial of Service | Matrix proof duration | medium | accept | The established ten-host proof remains bounded; installer failure stops the invocation instead of skipping a profile. | closed — accepted risk |
| T-174-SC | Tampering | npm/pip/cargo installation | high | mitigate / accept | Across all plans, no new npm, pip, or cargo install was added. Plan 174-07's existing Hex/Phoenix proof follows established commands. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-174-01 | T-174-33 | Ten isolated host runs add bounded wall-clock work to the proof lane; failure remains fail-closed. | Plan 174-07 disposition | 2026-09-25 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-25 | 34 | 34 | 0 | Codex inline verification |

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks documented
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-25
