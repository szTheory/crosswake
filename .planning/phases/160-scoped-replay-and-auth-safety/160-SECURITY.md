---
phase: 160
slug: scoped-replay-and-auth-safety
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: 2026-08-02
updated: 2026-08-02
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
| T-160-01 | Spoofing / Elevation | Scope contract, IndexedDB partition, and cross-scope evidence | high | mitigate | Exact scope grammar/admission, compound scoped storage, and non-assigning legacy quarantine verified in `journal.ex`, `replay_admission.ex`, and `offline_study.js`; hostile-scope and quarantine cases passed. | closed |
| T-160-02 | Tampering / Denial of Service | Lifecycle, stale completion, and lifecycle evidence | high | mitigate | Fence-first epoch transitions and current-lease checks guard async storage/UI effects in `offline_study.js`; fence, stale-response, and inactive-online cases passed. | closed |
| T-160-03 | Elevation | Route, feature, Sigra, and domain authorization chain | high | mitigate | `replay_admission.ex` and `sigra.ex` resolve typed current authority in locked order and collapse failures closed; host/Sigra suites passed. | closed |
| T-160-04 | Information Disclosure | Telemetry, Logger, doctor, inspection, and evidence | high | mitigate | `SafeObservation` public projections revalidate the complete closed value set before egress; safe-observation and evidence tests passed. | closed |
| T-160-05 | Tampering / Repudiation | Scope-qualified idempotency and domain effect | high | mitigate | `study.ex` preserves closed nil-scope and same-scope outcomes with atomic effect/idempotency handling; Study suite passed. | closed |
| T-160-06 | Elevation / Denial of Service | Disabled or blocked replay drain | high | mitigate | `offline_study.js` retains unaccepted work, stops hot retry, and renders halted/malformed responses paused; browser cases passed. | closed |
| T-160-07 | Tampering / Elevation of Privilege | ReplayAdmission, Study, and ReviewEvent persistence | high | mitigate | Exact replay keys are admitted and persistence attributes/outcomes are reconstructed server-side in `replay_admission.ex` and `study.ex`. | closed |
| T-160-08 | Information Disclosure | Closed denial and validation evidence | medium | mitigate | Hostile inputs collapse to closed non-echoing denials; validation retains aggregate safe evidence only. | closed |
| T-160-09 | Tampering / Elevation of Privilege | Activation-to-worker lease handoff | high | mitigate | Activation delegates to the single scoped worker and preserves scope-plus-epoch authority; switch/fence cases passed. | closed |
| T-160-10 | Tampering | Replay acknowledgement parser | high | mitigate | `offline_study.js` requires full cardinality, empty rejected results, and ordered accepted-ID equality before deletion; truncated-success proof passed. | closed |
| T-160-11 | Spoofing / Elevation of Privilege | Scoped IndexedDB worker | high | mitigate | Compound scoped storage and exact active-lease checks ensure only the activated partition drains; partition tests passed. | closed |
| T-160-12 | Information Disclosure | Browser status, console, Playwright, and validation evidence | medium | mitigate | Browser output uses closed status paths and non-disclosure assertions; the browser corpus passed. | closed |
| T-160-13 | Denial of Service | Activation and blocked-response replay triggers | medium | mitigate | A one-flight guard and terminal paused handling prevent malformed-response retry loops; bounded request-count cases passed. | closed |
| T-160-14-01 | Spoofing / Elevation of Privilege | Anonymous public replay | critical | mitigate | Both replay routes use the request-bound replay-auth pipeline; anonymous denial proof passed. | closed |
| T-160-14-02 | Spoofing | Logged-out or revoked session | high | mitigate | Current host session resolution denies absent or revoked state before mutation; browser session-denial proof passed. | closed |
| T-160-14-03 | Elevation of Privilege | Account switch and scope mismatch | critical | mitigate | Current host-mapped scope is compared exactly before every event. | closed |
| T-160-14-04 | Tampering / Elevation of Privilege | Permissive fixture fallback | critical | mitigate | Missing authority configuration denies; fixture routes are compile-time test/E2E gated. | closed |
| T-160-14-05 | Tampering | Mid-batch stale feature/session/route authority | high | mitigate | Authorization resolves inside the per-event reducer and halts immediately on denial or changed authority. | closed |
| T-160-14-06 | Information Disclosure | Denial responses and captured output | high | mitigate | Replay auth, admission, and controller boundaries expose stable denial classes only. | closed |
| T-160-15-01 | Spoofing / Elevation of Privilege | Anonymous/test replay session | high | mitigate | Test authority issuance is confined to compile-time test/E2E routes. | closed |
| T-160-15-02 | Spoofing | Logged-out, switched, or revoked fixture session | high | mitigate | Mutable current test-session state exercises the production replay denial path. | closed |
| T-160-15-03 | Elevation of Privilege | Permissive fixture fallback | critical | mitigate | Production has no fixture fallback and missing authority configuration fails closed. | closed |
| T-160-15-04 | Tampering | Scope mismatch or stale lease after account switch | high | mitigate | Exact server scope comparison and browser epoch checks both remain mandatory. | closed |
| T-160-15-05 | Denial of Service | Immediate-online rejection and hot retry | high | mitigate | The guarded worker catches failure, retains queued work, renders paused, and does not hot-retry; regression passed. | closed |
| T-160-15-06 | Information Disclosure | Browser/test output | high | mitigate | Closed browser output paths and the full browser corpus exclude sensitive fixture/failure details. | closed |
| T-160-16-01 | Spoofing / Elevation of Privilege | Anonymous/logout/revoked replay aliases | critical | mitigate | Both public aliases enforce current request authentication. | closed |
| T-160-16-02 | Elevation of Privilege | Account switch, scope mismatch, and fixture fallback | critical | mitigate | Production fallback is absent; exact scope and test-only fixture gates were inspected and exercised. | closed |
| T-160-16-03 | Denial of Service | Immediate-online worker rejection | high | mitigate | Deterministic paused, retained, and zero-unhandled browser proof passed. | closed |
| T-160-16-04 | Information Disclosure | Validation and artifact inspection | high | mitigate | Closed observation/evidence schemas retain only approved stable fields and aggregate results. | closed |
| T-160-16-05 | Tampering / Repudiation | Stale or incomplete final evidence | high | mitigate | `160-VALIDATION.md` records a fresh post-160-17 complete same-tree gate; stale security status was not reused. | closed |
| T-160-16-06 | Tampering | Evidence race hook | medium | mitigate | The private digest barrier is compilation-guarded for test use only. | closed |
| T-160-17-01 | Spoofing / Elevation of Privilege | Legacy recovery account-switch path | critical | mitigate | Legacy bytes remain `recovery_required` and are never assigned scope from lifecycle state; two-account proof passed. | closed |
| T-160-17-02 | Tampering / Repudiation | Nil-scope ReviewEvent history | critical | mitigate | Nil-scope history maps to conflict before acknowledgement or persisted outcome mapping. | closed |
| T-160-17-03 | Tampering | Rating controls and pending IndexedDB write | medium | mitigate | Synchronous per-card submission ownership prevents competing writes; rapid-rating proof passed. | closed |
| T-160-17-04 | Information Disclosure | Browser, request, and validation output | high | mitigate | Closed projections, safe browser output, and aggregate-only evidence were verified. | closed |
| T-160-17-05 | Tampering / Repudiation | Stale or partial phase evidence | high | mitigate | Fresh post-160-17 complete-gate evidence supersedes earlier ledgers. | closed |
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

## Security Audit 2026-08-02 — Post-Repair Reconciliation

| Metric | Count |
|--------|-------|
| Threats found | 37 |
| Closed | 37 |
| Open | 0 |

### Verification Evidence

- The independent ASVS L1 auditor verified every deduplicated plan-authored threat against the current implementation and automated evidence.
- Focused current-tree evidence passed: 36 core tests, 15 Sigra tests, 17 Phoenix admission/Study tests, and 23 browser proof tests.
- Critical request-auth, account-switch, scope-mismatch, fixture-fallback, legacy-recovery, and nil-scope-history threats are closed and fail closed on missing authority.
- Operational and retained evidence uses closed projections; only stable IDs, paths, test names, commands, and aggregate outcomes were retained.
- No unregistered threat flag was reported. The accepted low-severity package-install risk remains unchanged.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-02 | 7 | 1 | 6 | Codex (`gsd-secure-phase`) |
| 2026-08-02 | 37 | 37 | 0 | GSD security auditor + Codex orchestrator (`gsd-secure-phase`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified — all 37 plan-authored threats are closed as of 2026-08-02.
