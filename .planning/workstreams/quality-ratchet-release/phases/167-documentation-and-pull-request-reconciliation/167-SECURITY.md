---
phase: "167"
slug: "documentation-and-pull-request-reconciliation"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-09-12"
---

# Phase 167 — Security

> Per-phase security contract for documentation authority, parked-adopter truth, and guarded pull-request reconciliation.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Executable claim owner → generated guides | Only validated canonical support/adoption tuples may reach public projections. | Closed, low-cardinality support facts |
| Parked workstream → public documentation | Durable codename-only state remains non-transferable and externally blocked. | Sanitized status and recovery guidance |
| Repository → GitHub | PR observations and decisions use exact heads, checks, ancestry, and allowlisted fields. | OIDs, PR numbers, closed outcomes, fixed markers |
| Phase 167 → Phase 168 | Phase 167 hands off names and ownership only; immutable publication remains separately approval-gated. | Five repository-relative path names and one fixed owner |
| Evidence → diagnostics | Validators expose stable rule-oriented failures without raw logs, prose, URLs, credentials, or supplied private values. | Closed results and hashes |
| Repository tooling → local/CI runtime | Phase execution relies on already-pinned repository tooling without runtime dependency installation. | Tracked scripts, actions, and declared toolchain versions |

---

## Threat Register

Duplicate identifiers are qualified by their declaring plan.

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-167-01 | Spoofing / Tampering | adoption claims and renderers | high | mitigate | Exact canonical authority tuples in `Crosswake.CapabilityMap`; hostile mutation coverage in the capability-map tests. | closed |
| T-167-02 | Information disclosure | docs and parked state | high | mitigate | Destination-aware adoption-context scan, codename-only state, and non-echoing validation. | closed |
| T-167-03 | Repudiation | retained evidence attribution | medium | mitigate | Immutable source/date/runtime attribution with explicit non-transferability. | closed |
| T-167-04 | Tampering / Elevation of privilege | generator argv and outputs | high | mitigate | Closed arguments, array execution, safe relative outputs, and collision fixtures. | closed |
| T-167-05 | Tampering | documentation check mode | high | mitigate | In-memory rendering and byte/index/status preservation tests. | closed |
| T-167-06 | Information disclosure | failure output | medium | mitigate | Allowlisted owner/path/remediation facts; content and environment values are not echoed. | closed |
| T-167-07 | Spoofing | documentation leaf and umbrella | high | mitigate | Exact manifest/workflow owner parity and fail-closed required-result tests. | closed |
| T-167-08 | Tampering | docs-only classification | high | mitigate | Closed allowlist, release-input exclusion, and unknown-path full-proof routing. | closed |
| T-167-09 | Tampering | generated CI check | high | mitigate | Literal no-write `--check` invocation with no staging or default-write command. | closed |
| T-167-10 | Spoofing / Repudiation | authored current claims | medium | mitigate | Executable-owner links and semantic guide tests retain generated-source authority. | closed |
| T-167-11 | Information disclosure | public guides | high | mitigate | Public/durable terminology separation and adoption-context scanning. | closed |
| T-167-12 | Elevation of privilege | release runbook | high | mitigate | Explicit Phase 168 proof and maintainer-approval stop before immutable publication. | closed |
| T-167-13 | Tampering / Elevation of privilege | setup-java pin | high | mitigate | All seven uses share the official immutable v6 OID and are count-asserted. | closed |
| T-167-14 | Tampering / Spoofing | PR mutation | high | mitigate | Exact head/base/check guards and retained resolution receipts. | closed |
| T-167-15 | Information disclosure | GitHub input/output | high | mitigate | Structured bounded fields only; no PR prose, logs, tokens, or URLs retained. | closed |
| T-167-16 | Tampering / Information disclosure | failure ledger | high | mitigate | Closed schemas, stable rules, and reproduced-owner classification. | closed |
| T-167-17 | Spoofing / Tampering | candidate history and shallow CI | critical | mitigate | Pinned ancestry/tree proof plus independent shallow-fixture queue/schema proof. | closed |
| T-167-18 | Tampering | repair scope | high | mitigate | Closed repair universe, committed RED/GREEN sequence, and exactly authorized formatter additions. | closed |
| T-167-19 | Repudiation | exact-head merge and local reconciliation | high | mitigate | Frozen phase source, same-head CI, reachability/tree equality, and clean local-main reconciliation. | closed |
| T-167-20 [167-06] | Elevation / Repudiation | PR 148 and PR 110 | high | mitigate | Replacement authority precedes fixed-marker closed-unmerged receipts. | closed |
| T-167-21 [167-06] | Information disclosure | evidence/runtime | high | mitigate | Closed schemas, hash-only retained facts, and non-echoing diagnostics. | closed |
| T-167-22 [167-06] | Elevation | release/adopter/Android boundary | critical | mitigate | No publication, release merge, adopter resume, or Android breadth. | closed |
| T-167-29 | Tampering | shared cleanup | high | mitigate | Version-independent bytecode prevention, pre-existing-file preservation, and residue failure coverage. | closed |
| T-167-30 | Information disclosure / Repudiation | hosted browser proof | high | mitigate | Closed diagnostic classification, causal RED/GREEN evidence, and ordinary failure authority restoration. | closed |
| T-167-31 | Tampering / Elevation | recovery attempt budget | critical | mitigate | Fixed identities and consumed attempt counters prevent further retry, update, merge, or closure authority. | closed |
| T-167-32 | Denial of service / Tampering | nested subprocess scheduling | high | mitigate | Exact dedicated-three/broad-suite partition, ordering, parity, and mutation tests. | closed |
| T-167-SC [167-06] | Tampering | package install | high | accept | No npm, pip, or cargo install; execution relies only on repository-pinned tooling. | closed — accepted |
| T-167-20 [167-07] | Tampering | PR 105 mutation and integration | high | mitigate | Unprotected phase execution, exact-head CI, and receipt-backed protected-default integration. | closed |
| T-167-21 [167-07] | Denial of service | controlled waiter queues | medium | mitigate | Actor-isolated barriers and single-resume Swift package tests. | closed |
| T-167-22 [167-07] | Information disclosure | GitHub observations | medium | mitigate | Structured allowlisted observations with fixed-output failures. | closed |
| T-167-23 | Tampering / Information disclosure | disposition inventory | high | mitigate | Exact seven ordinary rows, separate four-row recovery schema, and stable non-echoing validation. | closed |
| T-167-24 | Tampering | closeout source | high | mitigate | Payload-only source scope and sole-manifest-delta candidate proof. | closed |
| T-167-25 | Elevation / Repudiation | release-only PRs | critical | mitigate | Exact four-open/deferred assertion; no merge, close, recreation, or publication. | closed |
| T-167-26 | Spoofing | hosted CI | high | mitigate | Exact 47/47 PR-head CI, candidate reachability, and merge-tree identity. | closed |
| T-167-27 | Repudiation | post-merge authority | high | mitigate | Exact five-path Phase 168 handoff and fixed `phase_168_first_reversible_landing` owner. | closed |
| T-167-28 | Tampering | local reconciliation | high | mitigate | Phase branch, local-main ref, ancestry, index, runtime hashes, and clean-state checks. | closed |
| T-167-SC [167-08] | Tampering | package install | high | accept | No npm, pip, or cargo install; execution relies only on repository-pinned tooling. | closed — accepted |
| T-167-09-01 | Tampering / Elevation of privilege | adoption authority validator | high | mitigate | Exact three-tuple membership with available-state cross-product and all-axis mutations. | closed |
| T-167-09-02 | Spoofing / Repudiation | adoption claim attribution | high | mitigate | Exact subject/binding/proof/date/runtime/promotion tuple before either renderer consumes a claim. | closed |
| T-167-09-03 | Information disclosure | validation and privacy proof | high | mitigate | Fixed rule identifiers plus destination-aware privacy scanning. | closed |
| T-167-09-SC | Tampering | package supply chain | low | accept | No dependency, action, service, or package installation was introduced by Plan 167-09. | closed — accepted |

*Severity: critical > high > medium > low. Only open threats at or above `workflow.security_block_on: high` count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-167-01 | T-167-SC [167-06] | The reconciliation recovery uses existing repository-pinned tools and performs no runtime package installation. Residual trust is limited to the reviewed pins already required by the repository proof lane. | Maintainer via execute-phase security checkpoint | 2026-09-12 |
| AR-167-02 | T-167-SC [167-08] | Closeout validation uses the same already-pinned repository toolchain and adds no package installation or dependency authority. | Maintainer via execute-phase security checkpoint | 2026-09-12 |
| AR-167-03 | T-167-09-SC | The gap closure changed tracked Elixir source/tests only and introduced no dependency, action, service, or package installation. | Maintainer via execute-phase security checkpoint | 2026-09-12 |

These acceptances do not authorize new dependencies, dynamic installation, external services,
publication, Android work, or first-adopter activation.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-12 | 41 | 41 | 0 | `gsd-security-auditor` plus maintainer accepted-risk checkpoint |

---

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented in the Accepted Risks Log.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-09-12
