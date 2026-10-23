---
phase: "172"
slug: "per-package-proof-scope"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-25"
---

# Phase 172 — Security

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Approved manifest to clean-room evaluator | Manifest values must not supply the independent standard used to judge those same values | Public package metadata and refs |
| Shell positional arguments to artifact parser | Malformed or mis-grouped arguments must fail closed | Public artifact coordinates and refs |
| Package bytes and digests to classifier | Digest comparison is the integrity decision point | Public package bytes and derived digests |
| Per-package outcomes to aggregate state | Individual failures or weaker claims must not be averaged away | Public package proof claims |
| Structural assertions to proof result | Source checks must be behaviorally reachable and falsifiable | Test and source structure |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|----------------------|--------|
| T-172-01 | Spoofing | Independent observed-ref derivation | high | mitigate | Ref resolved from checked-out HEAD with 40-hex guard; shell and cleanroom tests pass | closed |
| T-172-02 | Tampering | Seven-field positional contract | high | mitigate | Fixed-width parser and both shell callers updated together; distinct-ref tests pass | closed |
| T-172-03 | Tampering | Approved-artifact schema | high | mitigate | Required per-artifact key and malformed/absent-ref rejection tests pass | closed |
| T-172-04 | Repudiation | Candidate-local ref handling | medium | accept | Plan records that upstream checked-out-HEAD assertion establishes provenance; scope is explicit | closed — accepted risk |
| T-172-05 | Information disclosure | Public candidate refs | low | accept | Ref is public repository metadata and reveals no additional private information | closed — accepted risk |
| T-172-06 | Tampering | Byte-exact metadata and payload digest comparison | high | mitigate | Metadata and payload mutations both retain `digest_mismatch`; fresh cleanroom tests pass | closed |
| T-172-07 | Elevation of privilege | Attested aggregate state | high | mitigate | Attested state is distinct from COMPLETE and cannot pass the terminal gate; regression tests pass | closed |
| T-172-08 | Repudiation | Drift precedence over harder failures | high | mitigate | Failure ordering and drift-combination tests preserve the harder failure reason | closed |
| T-172-09 | Information disclosure | Public package claim strings | low | accept | Claims expose only public package names and proof states | closed — accepted risk |
| T-172-10 | Denial of service | Malformed observed ref | low | accept | Invalid refs raise and fail closed; malformed-ref regression passes | closed — accepted risk |
| T-172-11 | Repudiation | Non-vacuity evidence | high | mitigate | All 40 checks are mutation-backed or have a specific decidable reason in `172-NON-VACUITY.md` | closed |
| T-172-12 | Tampering | Structural assertions | high | mitigate | Positive assertions and evaluator reachability tests make missing code fail | closed |
| T-172-13 | Tampering | Byte-level proof | high | mitigate | Real byte mutation cannot reach fully proven or COMPLETE; regression passes | closed |
| T-172-14 | Denial of service | Future package count change | low | accept | Test roster derives from `Artifact.packages/0`, avoiding a fixed count | closed — accepted risk |
| T-172-SC | Tampering | Package-manager installation | high | mitigate | No package-manager install was added; existing load-bearing tools are unchanged | closed — not applicable |

Repeated T-172-SC entries in the three plans are consolidated because they describe the same
non-occurring install boundary.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-172-01 | T-172-04, T-172-05, T-172-09, T-172-10, T-172-14 | Explicitly accepted low/medium residual behavior is recorded in the plans; each fails closed or exposes only public data | Phase verification | 2026-09-25 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-25 | 15 | 15 | 0 | Codex, automated artifact and test review |

## Sign-Off

- All threats have an explicit disposition.
- Accepted risks are recorded above and in the plans.
- `threats_open: 0` confirmed; high-severity mitigations are covered by passing focused tests and mutation evidence.
- `status: verified`.

**Approval:** automated, 2026-09-25
