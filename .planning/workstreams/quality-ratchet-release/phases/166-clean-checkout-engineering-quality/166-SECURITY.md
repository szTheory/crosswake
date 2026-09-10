---
phase: "166"
slug: "clean-checkout-engineering-quality"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: "2026-09-10"
---

# Phase 166 — Security

> Verified threat register for clean-checkout repository proof, exact-commit capture, and CI ownership contracts.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CLI to repository runner | Purpose IDs select only fixed manifest-owned argv | Low-cardinality purpose IDs and bounded results |
| Repository to child tools | Commands run from a normalized root with fixed argv and timeouts | Source, generated contracts, and private logs |
| CI manifest to workflow | Literal stage owners map bidirectionally to read-only jobs | Job IDs, commands, permissions, and result states |
| Network to evidence environment | Pinned archives enter an invocation-owned tool root | HTTPS bytes verified by SHA-256 |
| Archive to extraction root | Entries and link chains must remain contained | Paths, symlink targets, and hardlink targets |
| Dirty source to canonical proof | Only a reachable tracked commit is cloned and verified | Git object identity; no working-tree bytes |
| Private execution to retained evidence | Full logs are temporary; retained evidence is closed and redacted | Versions, stage outcomes, hashes, and cleanup state only |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-166-01 | Tampering / Elevation of privilege | Verification CLI | high | mitigate | Fixed CLI forms and closed argv spawning | closed |
| T-166-02 | Spoofing | CI owner mapping | high | mitigate | Literal owner/command validation and read-only workflow permissions | closed |
| T-166-03 | Information disclosure | Tool preflight | high | mitigate | Probe output stays private; only bounded tool facts and corrections render | closed |
| T-166-04 | Denial of service | Stage graph | medium | mitigate | Dependency/cycle validation and bounded timeouts | closed |
| T-166-05 | Tampering / Elevation of privilege | Child execution | high | mitigate | Direct argv, normalized cwd, and NUL-safe Git parsing | closed |
| T-166-06 | Tampering / Denial of service | Cleanup | high | mitigate | Absent-at-start ownership ledger, containment checks, and symlink refusal | closed |
| T-166-07 | Spoofing / Repudiation | Clean baseline | high | mitigate | Complete mode requires empty baseline and byte-identical final snapshot | closed |
| T-166-08 | Information disclosure | Execution logs | high | mitigate | Private modes and bounded terminal projection | closed |
| T-166-09 | Information disclosure | Artifact diagnostics | high | mitigate | Stable categories, escaped relative paths, and fixed remediations only | closed |
| T-166-10 | Tampering | Generated contracts | high | mitigate | Explicit registry, byte snapshots, restoration, and no index staging | closed |
| T-166-11 | Tampering / Elevation of privilege | Artifact policy | high | mitigate | Closed matcher kinds and repository-relative path validation | closed |
| T-166-12 | Spoofing | Artifact classification | medium | mitigate | Closed three-class schema with duplicate/overlap rejection | closed |
| T-166-13 | Spoofing / Tampering | Ownership ledger | high | mitigate | NUL-safe candidate regeneration, exact coverage, closed edges, cycle rejection | closed |
| T-166-14 | Tampering | Removal evidence | high | mitigate | Six required evidence classes; current ledger authorizes no removal | closed |
| T-166-15 | Denial of service / Spoofing | Browser repository mode | medium | mitigate | Zero retries, fresh server, one worker, invocation-owned outputs | closed |
| T-166-16 | Information disclosure | Ownership records | medium | mitigate | Paths and low-cardinality dispositions only; no contents or adopter facts | closed |
| T-166-17 | Spoofing | Stage/CI parity | high | mitigate | Bidirectional missing/extra/duplicate/cwd/env/argv validation | closed |
| T-166-18 | Tampering | CI generated proof | high | mitigate | Shared facade, explicit outputs, byte restoration, and no index writes | closed |
| T-166-19 | Elevation of privilege | PR workflow authority | high | mitigate | Global contents-read permission and checkout-free static umbrella | closed |
| T-166-20 | Repudiation | CI manifest | high | mitigate | Exact job/leaf membership, static needs, identity, producer, and parity checks | closed |
| T-166-25 | Tampering | Remediation queue | high | mitigate | Sorted tracked repository-relative owner/regression paths outside planning | closed |
| T-166-26 | Denial of service / Spoofing | Ownership remediation | high | mitigate | D-09 evidence gate, deterministic queue, and recurring repository gate | closed |
| T-166-27 | Spoofing / Tampering | Exact-commit capture | high | mitigate | Reachable 40-byte SHA, isolated clone, detached checkout, and HEAD verification | closed |
| T-166-28 | Tampering / Elevation of privilege | Tool provisioning | high | mitigate | HTTPS/SHA-256 pins and contained archive entry/link-chain validation | closed |
| T-166-29 | Information disclosure | Evidence capture | high | mitigate | Closed schema, forbidden sensitive keys, private logs, and owned-root trap cleanup | closed |
| T-166-30 | Spoofing / Repudiation | Evidence identity | high | mitigate | Supported SHA fixed before proof and exact four-path evidence-only delta | closed |
| T-166-31 | Tampering | Evidence binding | high | mitigate | SHA, nine PASS stages, clean state, unchanged index, and cleanup validation | closed |
| T-166-32 | Information disclosure | Canonical artifacts | high | mitigate | Recursive sensitive-key rejection and deterministic bounded rendering | closed |

All 28 registered threats are closed. Summary threat-flag sections reported no unregistered threats; post-review archive-link containment maps to T-166-28.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-10 | 28 | 28 | 0 | gsd-security-auditor |

## Verification Observed

- Repository runner: 25/25 tests passed.
- Evidence environment: 20/20 controls passed, including safe contained links and hostile link rejection.
- Capture isolation: 8/8 controls passed.
- Ownership validator: 16 controls plus production evidence binding passed.
- CI authority and stage-parity validation passed.
- Playwright repository mode: 3/3 tests passed.
- Canonical evidence verifier passed for `f9bf7eb2d7395599c6234ff618fc3589c95bd541`.
- The evidence-only delta contains exactly the four declared planning/evidence paths.

## Sign-Off

- [x] All threats have a disposition.
- [x] No accepted risks require documentation.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-09-10
