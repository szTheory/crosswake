---
phase: "179"
slug: "ios-host-setup-without-hand-patches"
status: secured
threats_open: 0
asvs_level: 1
created: "2026-10-13"
verified_at: "2026-10-14T00:43:06.134856+00:00"
audit_head: 96e5a63efab657f89f3ac84d5b1d84ff5da5d822
audit_tree: 0514b6244ec814c1d0701d580b04651f70f57019
---

# Phase 179 — Security

The independent audit verified all thirteen authored threat rows on candidate `96e5a63`, with zero open threats or unregistered flags. Fresh independent checks passed all thirteen migration/recovery boundary tests and the checker deadline test. No source changed during audit. Code re-review, broad proof and phase-goal verification remain separate gates.

## Trust Boundaries

Ordinary host build inputs cross normalization and rendering; native host files cross managed publication, recovery and bounded migration; Xcode subprocess output crosses a closed diagnostic boundary; implementation proof crosses public guide claims.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Verified mitigation | Status |
|---|---|---|---|---|---|---|
| T-179-01 | Tampering | host config / manifest | high | mitigate | Closed inputs and canonical HTTPS authority/port checks. | closed |
| T-179-02 | Elevation of privilege | static activation | high | mitigate | Static route projection grants no session, scope or replay authority. | closed |
| T-179-03 | Information disclosure | diagnostics | high | mitigate | Constant non-echoing errors and canary controls. | closed |
| T-179-04 | Tampering | managed filesystem | high | mitigate | Guarded ancestors/preflight, shared proof lifecycle lock and preview/staged-byte comparisons preserve conflicts. | closed |
| T-179-05 | Tampering | project migration | high | mitigate | Complete semantic graph and settings destination, shared byte spans, owned direct/conditional/variable-mask removal and post-validation. | closed |
| T-179-06 | Denial of service | recovery | high | mitigate | Pending boundaries and validated v1/v2/stage-only current/temporary byte recognition preserve external edits. | closed |
| T-179-07 | Information disclosure | check/diff | high | mitigate | Read-only classification and bounded safe causes/repair actions. | closed |
| T-179-08 | Tampering | effective settings | high | mitigate | Independent declaration oracle, semantic resource references and complete matrix enforcement. | closed |
| T-179-09 | Information disclosure | settings report | high | mitigate | In-memory capture, allowlisted timeout findings and one absolute checker/caller budget. | closed |
| T-179-10 | Spoofing | device settings | medium | mitigate | Declared device expectations and explicit settings-only claim. | closed |
| T-179-11 | Spoofing | guides | high | mitigate | Signing/install/physical-device and static-authority limits explicit. | closed |
| T-179-12 | Information disclosure | evidence | high | mitigate | Safe aggregate results; earlier missing-output unknowns and missing RED evidence remain disclosed. | closed |
| T-179-SC | Tampering | locked dependencies | low | accept | Existing authored acceptance; unchanged locked dependencies/toolchain. | closed |

## Independent Verification

- Injected all five managed bundle variables, with unconditional and simulator/device conditional forms, across shell and proof configurations. Every mask was removed and both migrations were idempotent.
- The preceding independent audit of `492eb79` observed five Debug simulator Xcode cells matching the original declaration. Its identity-removal implementation remains unchanged. The final `96e5a63` re-audit did not repeat that matrix; it ran thirteen recovery/migration tests and one deadline test, all passing.
- Prior migration ancestor, multiline, duplicate/remapped graph, direct mask and settings-reference reproductions are closed. Complete graph/byte-span implementation is in `ios_host_project_migration.ex` and `pbx_project.ex`; guarded migration I/O is in `managed_outputs.ex`.
- Packaged checker, resource traversal, closed input/output boundaries, recovery and guide limits remain present. The auditor made no source/report writes, removed private fixtures/raw output and did not repeat broad leaves.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| AR-179-SC | T-179-SC | Existing locked dependencies/toolchain only; no new package or upgrade. | Authored approved Phase179 plans | 2026-10-13 |

## Security Audit Trail

| Candidate | Closed | Open | Outcome |
|---|---|---|---|
| b659466 | 8 | 5 | Initial audit; preserved in `179-SECURITY-INITIAL.md`. |
| f92306a | 11 | 2 | Remaining migration path/graph gaps. |
| e25f17b | 12 | 1 | Remaining semantic graph/reference and rewrite gaps. |
| 09dcb71 | 12 | 1 | Actual Xcode reproduced managed-variable masking. |
| 492eb79 | 13 | 0 | Independent re-audit secured; actual Xcode identity control passed. |
| 96e5a63 | 13 | 0 | Post-review re-audit secured; 13 boundary tests and 1 deadline control pass. |

Repair details and bounded evidence are retained in `179-REVIEW-FIX.md` and `179-SECURITY-REPAIR-02.md` through `04.md`, plus `179-REVIEW-FIX-02.md`. No high risk was accepted. Earlier unretained observations remain unexplained, and no missing test-first evidence was invented.

## Sign-Off

- [x] Every threat has a disposition.
- [x] Authored low acceptance is persisted.
- [x] All blocking threats are repaired and independently re-audited.

**Approval:** Security mitigations verified on the stated candidate. This does not claim phase completion, release, physical-device or adopter readiness.
