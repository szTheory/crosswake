---
phase: 50
slug: doctor-publish-and-readiness-checks
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-01
---

# Phase 50 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo files -> publish readiness | Package metadata, docs links, changelog truth, and release wording cross from source files into a machine-readable release/support contract. | Hex metadata, docs extras, package file allowlist, changelog sections |
| operator inspection/support matrix -> readiness checks | Route/support/proof/rebuild/auth/notification truth is reused from canonical modules and must not become a second authority. | Route manifest, support status, proof class, rebuild posture, companion/auth/notification posture |
| deferred scope -> actionable messaging | Provider/auth/notification/native-shell caveats can become accidental overclaims if advisory or verification-required posture is collapsed into support. | StoreKit/Play Billing, Sigra, notification delivery, shell-package support claims |
| CLI argv -> doctor task | New flags and exit behavior can accidentally change established doctor semantics if not gated tightly. | `--check-publish`, `--format`, install manifest path, router module |
| publish-readiness contract -> doctor findings/renderers | The same readiness truth must appear in findings, human output, and JSON without drifting into multiple contracts. | Readiness report/check contract, doctor findings, human text, JSON payload |
| optional publish lane -> default doctor lane | Flagged release checks must be additive only; ordinary doctor must not silently start implying publish-readiness status. | Optional sidecar payload, default doctor report, process exit status |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-50-01 | Tampering | `lib/crosswake/doctor/publish_readiness.ex` | mitigate | `PublishReadiness.run/1` derives route truth via `Crosswake.OperatorInspection` and reuses `Crosswake.SupportMatrix`; tests lock the eight readiness categories and diagnostic code prefixes. | closed |
| T-50-02 | Repudiation | readiness result/status derivation | mitigate | Every readiness check carries explicit `result` and `blocking`; `status` is computed from blocking checks only and covered by `publish_readiness_test.exs`. | closed |
| T-50-03 | Information Disclosure | auth/provider/deferred-scope messaging | mitigate | Deferred Sigra, provider-adapter, notification-delivery, and shell-package claims are explicit in messages/details and asserted in tests. | closed |
| T-50-04 | Input Validation | `lib/mix/tasks/crosswake.doctor.ex` | mitigate | Existing strict `OptionParser` handling now includes only `--check-publish`; invalid options still raise and tests cover unchanged default paths. | closed |
| T-50-05 | Tampering | `lib/crosswake/doctor/doctor.ex` + renderers | mitigate | Doctor consumes `Crosswake.Doctor.PublishReadiness` directly, attaches it conditionally, and human/JSON renderers expose the same sidecar contract without re-deriving route inventory. | closed |
| T-50-06 | Denial of Service | doctor exit semantics | mitigate | Exit behavior remains scoped to `:error` findings; blocking publish checks affect status only when `--check-publish` is enabled, with CLI tests covering both paths. | closed |
| T-50-SC | Tampering | package-manager installs | accept | Phase 50 added no package-manager installs or external dependencies; supply-chain posture is documented as an accepted no-op risk for this phase. | closed |

Status: open or closed.
Disposition: mitigate (implementation required), accept (documented risk), or transfer (third-party).

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-50-01 | T-50-SC | No npm, pip, cargo, Hex dependency, or external package-manager install was introduced by Phase 50. The residual supply-chain risk is unchanged from baseline and documented rather than remediated in this phase. | Codex security audit | 2026-06-01 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-01 | 7 | 7 | 0 | Codex security audit |

## Evidence

- `lib/crosswake/doctor/publish_readiness.ex` defines the stable report/check contract, derives inspection truth through `Crosswake.OperatorInspection`, reuses `Crosswake.SupportMatrix`, and keeps blocking status driven by `check.blocking`.
- `lib/crosswake/doctor/doctor.ex` attaches `publish_readiness` only when `check_publish?: true` and merges `PublishReadiness.findings/1` without changing unflagged doctor behavior.
- `lib/mix/tasks/crosswake.doctor.ex` keeps strict option parsing and adds only the `check_publish: :boolean` switch.
- `lib/crosswake/doctor/formatter.ex` and `lib/crosswake/doctor/json_formatter.ex` render the optional sidecar contract conditionally.
- Tests cover category/code stability, deferred support non-claims, blocking status, conditional sidecar rendering, JSON gating, and CLI exit behavior.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-01
