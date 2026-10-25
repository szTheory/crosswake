---
phase: "179"
slug: "ios-host-setup-without-hand-patches"
status: blocked
threats_open: 5
asvs_level: 1
created: "2026-10-13"
---

# Phase 179 — Security

The independent audit reproduced five blocking mitigation gaps on candidate HEAD `b6594664270ebc7a4434612c0840f6d3b887f805` (tree `5caddd85b30cdfc174a66ab9d403c66122ceb07c`). Local repairs and re-audit are required before advancement.

## Trust Boundaries

Host build inputs cross the normalization/rendering boundary; host-native files cross managed publication/recovery and bounded migration; Xcode subprocess settings cross a closed report boundary; implementation evidence crosses into public guide claims.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / gap | Status |
|---|---|---|---|---|---|---|
| T-179-01 | Tampering | host config / manifest | high | mitigate | Nonnumeric origin port accepted and serialized. | open |
| T-179-02 | Elevation of privilege | static activation | high | mitigate | Route-only projection grants no session, scope, media, or replay authority. | closed |
| T-179-03 | Information disclosure | config diagnostics | high | mitigate | Closed inputs and constant non-echoing errors; canary tests. | closed |
| T-179-04 | Tampering | managed filesystem | high | mitigate | Ancestor symlink accepted; proof writes settings before complete scaffold preflight. | open |
| T-179-05 | Tampering | project migration | high | mitigate | Unknown proof XCBuildConfiguration accepted. | open |
| T-179-06 | Denial of service | interrupted recovery | high | mitigate | Proof recovery overwrites external post-interruption edits. | open |
| T-179-07 | Information disclosure | check/diff | high | mitigate | Read-only classifier and safe repair output. | closed |
| T-179-08 | Tampering | effective settings / resources | high | mitigate | Shell Resources unchecked; proof filename-comment check permits object-ID resource reference. | open |
| T-179-09 | Information disclosure | settings report | high | mitigate | Raw subprocess data stays in memory; closed fields and causes. | closed |
| T-179-10 | Spoofing | device settings | medium | mitigate | Declaration-derived settings and explicit settings-only claim. | closed |
| T-179-11 | Spoofing | guides | high | mitigate | Signing/install/physical and runtime-authority limits explicit. | closed |
| T-179-12 | Information disclosure | phase evidence | high | mitigate | Aggregate evidence only; deleted-output failure cause retained as unknown. | closed |
| T-179-SC | Tampering | locked dependencies | low | accept | Authored acceptance: existing pinned toolchain and lockfiles; no new package or upgrade. | closed |

## Reproduced Gaps

- T-179-01: `ios_host_config.ex:63–83` accepts a nonnumeric authority port; render serializes it.
- T-179-04: `managed_outputs.ex:304–329` omits ancestors above root. Preflight/publication succeeded through an ancestor symlink. `proof_lane/generator.ex:38–49,152–163` changes managed settings before rejecting a later unsafe scaffold.
- T-179-05: `ios_host_project_migration.ex:75–87` scans only known proof configuration IDs and accepts an extra Preview configuration.
- T-179-06: `proof_lane/generator.ex:329–375` recovered over an external edit and removed pending state.
- T-179-08: `verify_ios_host_settings.mjs:29–42` skips shell resources and checks proof filename comments. Production-generated object-ID links passed a parser-only control with synthetic schema-correct rows. The actual-Xcode attempt returned safe `macos_service_denied`/`output_invalid` causes; no live acceptance is claimed.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| AR-179-SC | T-179-SC | Existing locked dependencies/toolchain only; no new package or upgrade. | Authored approved Phase179 plans | 2026-10-13 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-13 | 13 | 8 | 5 | Independent gsd-security-auditor |

## Sign-Off

- [x] Every threat has a disposition.
- [x] Authored low risk acceptance persisted.
- [ ] Blocking threats repaired and independently re-audited.

**Approval:** Pending; five blocking threats remain. No open high threat is accepted.
