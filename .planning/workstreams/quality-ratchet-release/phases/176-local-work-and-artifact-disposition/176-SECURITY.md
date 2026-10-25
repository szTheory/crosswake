---
phase: "176"
slug: "local-work-and-artifact-disposition"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-11"
---

# Phase 176 — Security

The registered mitigations are present in the phase-local helper and exercised by 35 passing fixtures. The corrected live capture restored 170 units without limitations and validated the configured origin's pinned default-tip ancestry. The final post-writer audit remains a separate orchestration gate.

## Trust Boundaries

| Boundary | Control |
|---|---|
| Checkout to private archive | Owner-only persistent root; descriptor-based no-follow reads; explicit sensitive-path exclusion; read-only manifest and separate private integrity attestation. |
| Origin to scratch comparison | Exact advertised default commit; scratch-only fetch; commit/tree/parent/ancestry checks; private proof bound to the capture. |
| Private recovery to public evidence | Opaque unsafe paths; no payloads, private pointers or sensitive hashes; comparisons/recovery/policy checked against proof and repository policy. |
| Capture to GSD closeout | Full index freeze; narrow tracking spans; actual conditional-producer receipts; byte/type/mode rescan before and after sidecar publication. |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|---|---|---|---|---|---|---|
| T-176-01 | Tampering | Git records and restore | high | mitigate | Buffer/NUL parsing, rename sides, staged/worktree partitions, actual isolated Git index/status and byte/type/mode checks. | closed |
| T-176-02 | Information disclosure | Public evidence | high | mitigate | Credential-path exclusions, opaque IDs, private proof, sentinel fixtures and safe renderer. | closed |
| T-176-03 | Tampering | Archive transaction | high | mitigate | Exclusive capture, atomic publication, owner permissions, private read-only integrity attestation and interrupted/concurrent tests. | closed |
| T-176-04 | Tampering | Live capture and final audit | high | mitigate | Fresh capture, full restore, global index freeze, scoped writers and same-status byte-race rejection with invalid pass-sidecar removal. | closed |
| T-176-05 | Information disclosure | Archive and inventory | high | mitigate | Descriptor-pinned no-follow reads, real parent-swap fixture, precise credential exclusions and private/public separation. | closed |
| T-176-06 | Spoofing | Merged provenance | medium | mitigate | Configured origin's pinned advertised tip plus exact candidate trees, parents and ancestry in independent scratch. | closed |
| T-176-07 | Repudiation | Disposition handoff | medium | mitigate | Every captured row has a retain decision, recovery result, checked comparison, policy facts, concrete owner/action and linkage; final delta sidecar binds closeout. | closed |
| T-176-SC | Tampering | Dependency installs | high | mitigate | No install or new package dependency. Installed Node, Git and Python 3 standard libraries only. | closed |

## Accepted Risks Log

No accepted risks. Owner-controlled attestations detect unintended changes; they do not claim protection against the machine owner deliberately replacing both data and attestation.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-11 | 8 | 8 | 0 | GSD orchestrator; ASVS L1 registered-mitigation inspection and actual fixtures |

## Sign-Off

- [x] All eight unique planned threats have a verified mitigation.
- [x] No blocking threat remains at the configured high threshold.
- [x] Original attempts remain preserved; the bad metadata successor is excluded from completion evidence.
- [x] No source cleanup, Git mutation, runtime expansion or release action was performed.
