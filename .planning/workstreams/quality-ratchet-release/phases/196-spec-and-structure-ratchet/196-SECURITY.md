---
phase: "196"
slug: "spec-and-structure-ratchet"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-29"
---

# Phase 196 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

ASVS L1, block_on high. No claim of ASVS certification. The register was authored at plan time in all 17 plans (`<threat_model>` blocks); 39 unique threat IDs (38 high, 1 medium), every one disposition `mitigate`. Verified by gsd-security-auditor against HEAD `368f08db` (origin/main `97ec5f7b` plus the UAT commit), with read-only guard re-runs: rescue boundaries (0 findings, 2 reviewed exceptions), runtime dependencies (6 projects, 12 executions, 0 findings), compile structure enforce (cap 4, 0 findings), absence guard enforce (delta 0), SPEC-04 preserved roster (32 paths byte-equal to anchor `90a809ce`) and the privacy scan over the 107 tracked phase files (clean).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Repository/tool input to proof verdict | Files, process exits and external tool output are untrusted until scope, identity and nonempty execution are verified. | Source blobs, exit codes, test counts (integrity) |
| Internal behavior to diagnostic/evidence output | Closed outcomes and synthetic-only checks must preserve authorization and privacy. | Hashes, counts, statuses only; never raw payloads or credentials (sensitive) |
| Committed planning truth to evidence verdict | Requirement disposition is derived from committed git objects; caller-authored or worktree-only claims carry no authority. | Git objects, roster digests (integrity) |
| Local branch to GitHub PR/CI | Remote state, check runs and synthetic merge results are external observations that must be re-read, never assumed. | PR heads, check-run conclusions (integrity) |
| Human decision to shared-history write | Only a fresh displayed one-use allow bound to the exact attempt authorizes the main merge. | Approval records on local-only refs (authorization) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-196-01 | Tampering | planning preservation/source identity | high | mitigate | Scoped preservation commits, exact main ancestry and protected hashes, finally restoration and wrong-ref controls. | closed |
| T-196-02 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-03 | Tampering | optional enabled artifact evidence | high | mitigate | Explicit enablement, real producer/consumer, missing/empty/malformed/wrong artifact red controls. | closed |
| T-196-04 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-05 | Tampering | Elixir/Swift request execution | high | mitigate | Independent loaded/completed pins, real resource mutation with rebuild and restoration. | closed |
| T-196-06 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-07 | Tampering | Swift reader completeness | high | mitigate | Exact reader roster and reader-kind-specific counts; missing-source rebuild controls. | closed |
| T-196-08 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-09 | Tampering | JVM reader completeness | high | mitigate | Real clean Gradle tests and per-reader pins; JDK identity and restored resource hashes. | closed |
| T-196-10 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-11 | Tampering | collection guard lexical proof | high | mitigate | Same-collection reachable branch facts, multiset identities, wrong-branch/duplicate/parse controls. | closed |
| T-196-12 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-13 | Information disclosure | scope and observation projections | high | mitigate | Constant errors, absolute anchors, every field/key plus forged projection tests and value-free evidence. | closed |
| T-196-14 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-15 | Elevation of privilege | policy oracle and provenance | high | mitigate | Independent 108-case table, staged compiler oracle, structured keys and paired sources with mutation controls. | closed |
| T-196-16 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-17 | Tampering | Mix graph evidence | high | mitigate | Fresh compile, independent source/manifest coverage and real built-in zero/cap threshold controls. | closed |
| T-196-18 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-19 | Elevation of privilege | arbitrary extension containment | high | mitigate | Exactly two semantic records and custom-exception fail-closed denial tests preserving existing catch. | closed |
| T-196-20 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-21 | Tampering | runtime dependency inventory | high | mitigate | Exact six-project roster, both branches in sequential isolated children and classification/purpose controls. | closed |
| T-196-22 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-23 | Information disclosure | derived credential workflow classification | high | mitigate | Conserved supported/denied/unknown inventory and executed stdout/ordering controls without values. | closed |
| T-196-24 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-25 | Tampering | mutation process/report adapter | high | mitigate | Frozen protocol, real nonempty output first, full schema/process controls and per-target known-kill/survive. | closed |
| T-196-26 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-27 | Tampering | pilot adoption/coverage verdict | high | mitigate | Full uncapped five-file useful coverage, all-survivor ledger, aggregate1800s/noise20% and pending incomplete results. | closed |
| T-196-28 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-29 | Tampering | required guard promotion | high | mitigate | Exact final guard blobs join actual-main measurements (absence flip recaptured before use); process-derived child counts with pinned executed/excluded expectations and high-finding blocker. | closed |
| T-196-30 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-31 | Spoofing | PR head/CI identity | high | mitigate | Remote/head/base reconciliation, immediate current-base open check and separate synthetic merge identity. | closed |
| T-196-32 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-33 | Elevation of privilege | main merge authorization/evidence | high | mitigate | Fresh one-use attempt-bound allow; auto-delete read and required off with no setting mutation; reconcile uncertain write; post-merge evidence only on a feature branch and PR; actual-main automated proof. | closed |
| T-196-34 | Information disclosure | retained diagnostics and proof | high | mitigate | Synthetic probes, closed label/count/status receipts, exact redaction assertions and fresh per-file privacy scans before commits/pushes; never store raw payloads, credentials or extension exceptions. | closed |
| T-196-35 | Repudiation | SPEC-04 disposition and preserved Muex evidence | high | mitigate | phase-evidence derives moved_to_v29 from committed ROADMAP/REQUIREMENTS objects, applies the structured checks and affirmative-claim prose scan with positive and negative controls, and compares each of the 32 preserved paths' anchor 90a809ce blobs to HEAD and worktree bytes. | closed |
| T-196-36 | Tampering | protected-source verifier amendment | high | mitigate | One second fixed reviewed replan identity whose base-to-replan diff over every phase Markdown path and both receipts must equal the pinned list; ancestry and committed sidecar required; any other change, stale bytes or caller override refuses; real git-fixture controls including an unlisted-Markdown edit. | closed |
| T-196-37 | Repudiation | PR body and delivery evidence SPEC-04 statement | medium | mitigate | Gate pr-open and ready re-derive moved_to_v29 from committed objects on the pushed head and run the SPEC-04 claim scan over pr-body.md and delivery.json. | closed (partial: ready stage re-derives the disposition but does not rerun the prose scan; pr-open and landed scan) |
| T-196-38 | Repudiation | landed/verification SPEC-04 record and preserved Muex evidence on main | high | mitigate | Landed mode re-derives moved_to_v29 from committed objects at the merge commit, requires the roster digest to equal candidate.json and applies the shared structured checks and prose scan; protected 196-VALIDATION.md stays unedited. | closed |
| T-196-SC | Tampering | package installation surface | high | mitigate | No npm/pip/cargo or production dependency install; Muex Hex tool only in plan13, pinned0.12.0 with source/checksum and isolated MIX/HEX homes. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Audit notes (non-blocking)

1. **Grammar receipt drift after landing.** `test/js/ci_secret_masking.test.mjs` is blob `10944c82` on main; the receipt `196-EVIDENCE/main-grammar.json` and landed merge `51a1885c` hold `e0891db6`. Commit `94d2d788` (PR 265) changed only the linear-time timing bound, not a masking assertion, and the suite passes 207/207 on main. `phase-evidence.mjs self-test` therefore refuses `stale_measured_blob` at HEAD by design; a later phase that re-verifies promotion at HEAD needs a recapture or an amendment.
2. **T-196-37 partial.** `gateReady` re-derives `moved_to_v29` but does not rerun `spec04Claims`; `pr-open` and `landed` do. Medium, below block_on. A strict follow-up is to add the prose scan to `gateReady`.
3. Untracked local `tdd-*-red.json` captures contain a home path; they are excluded through `.git/info/exclude` and never tracked.
4. Low review items already accepted in `196-REVIEW.md` (R-03, R-04, R-05, R-07, R-14, R-15, R-22, R-23) were not re-opened.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-29 | 39 | 39 | 0 | gsd-security-auditor (ASVS L1, via /gsd-verify-work 196) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-29
