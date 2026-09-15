# Milestones

## v22.0 Quality Ratchet & Release Readiness (Shipped: 2026-09-15)

**Phases completed:** 5 phases, 48 plans, 100 tasks

**Closeout type:** `override_closeout`

**Known verification overrides:** 11 newly acknowledged, 0 carried forward

- Phases 167 and 168 both carried `stale` verification at close — their covered files changed
  after verification ran. 167 passed on 2026-09-12; 168 was re-verified at 5/6 must-haves with
  status `human_needed`. Neither was re-run; the milestone closed over both.
- 9 seeds were **deliberately left unacknowledged** so they keep surfacing. `SEED-017` is marked
  BLOCKING before any release past 0.2.1, and suppressing it at a milestone close is the exact
  failure it exists to prevent.
- 17 stale artifacts from archived milestones (v3.2 → v19.0) were acknowledged. Six of those, in
  Phase 121, could not be acknowledged through the CLI at all — the audit scanner reads GFM table
  rows as items but `audit-open acknowledge` refuses to write to a table-row span
  (`audit.cjs:1455`), so the scanner surfaced items its own writer could not clear. All six were
  re-run and pass; the record had gone stale. Worth reporting upstream against
  `@opengsd/gsd-core` 1.14.0.

### Known Gaps

- **The post-publication proof lane has never executed at any release.** Carried to v23.0 as
  `SEED-017` with `TODO-009` (release graph welded to 0.2.1 — any other version tags and then
  publishes nothing), `TODO-011` (companion clean-room lane green at zero of three releases
  inspected), and `TODO-012` (exact-public proof structurally unsatisfiable under D-15/D-16).
  An interim CI tripwire is on `main`.
- Phase 168's single behavior-unverified must-have — the exact-public clean-room proof against the
  live 0.2.1 family — is **deferred, not passed**. It must not be read as evidence that 0.2.1 is
  unsound, nor as evidence that it is proven; the repository simply cannot yet demonstrate
  soundness after publication.
- **PR #164 (`chore: release main`, proposing 0.2.2) must not be merged until SEED-017 lands.**

**Key accomplishments:**

- Patched Phoenix/LiveView/Plug/Bandit/hpax locks now pass independent Hex audits through one fail-closed command and one literal merge-blocking result.
- Strict workflow and executable-test ownership now compose every Phase 164 contract into one credential-free, fail-closed aggregate.
- Exact example-host resource ownership now supports a residue-checked parallel matrix across three tagged and complete-suite seeds.
- Exact aggregator leaf parity and an 11-class credential-free result matrix now prevent omitted, unknown, cancelled, or otherwise non-success work from becoming green.
- Owned WAL/SHM teardown and explicit broad-lane authority close the Phase 164 isolation gap without changing workflow topology.
- Sanitized current-main evidence and a strict authority snapshot now precede a NUL-safe documentation classifier, literal documentation proof, and checkout-free Crosswake CI umbrella.
- A closed documentation classifier and exact four-way proof inventory now guard a 46-job maximum checkout-free Crosswake CI shape before migration begins.
- Strict-lower cancellation now runs through a pure closed selector and a least-privilege default-branch controller that never executes pull-request code.
- Portable Android JVM proof, exact compiled-cache identities, and repository-wide timeout and runner audits now remove macOS waste without widening Android or weakening release trust.
- Core, security, example-host, hermetic-engine, and commerce PR proof now runs once as twelve literal Crosswake CI leaves while ten frozen legacy contexts and scheduled advisories retain their distinct authority.
- Eight named gating, companion, provider, operator, auth, closeout, and subscription proofs now run once under central PR classification while advisory trust stays isolated.
- Four named domain proof leaves now run once through the central classifier, with privacy-safe documentation scheduling and exact frozen-context compatibility preserved.
- Native, browser, offline, package, mirror, and focused documentation proof now runs once through a 40-leaf closed PR graph with explicit runner and advisory boundaries.
- One pull-request-only Crosswake CI graph now owns forty-four required proof leaves while preserving a visibly red, non-authoritative brand visual sibling and all twenty-seven frozen compatibility contexts.
- Exact-SHA live probes proved the complete Crosswake CI topology and monotonic cancellation, then added one strict umbrella context beside all twenty-seven legacy authorities while leaving retirement unapplied.
- The maintainer explicitly approved one freshly verified, digest-bound retirement proposal while strict dual branch protection remained unchanged.
- Strict main protection now requires only `Crosswake CI`; all migration-only compatibility conclusions are gone while the forty-four literal proof leaves remain intact.
- Exact landed CI source provenance and privacy-safe observations now close Phase 165 without claiming an unsupported efficiency improvement.
- A closed nine-stage Node runner now gives maintainers one strict repository proof facade with literal CI ownership, exact preflight rules, and dependency-aware failures.
- A dependency-aware repository runner now continues independent proof, blocks invalid chains, restores invocation-owned state, and reports deterministic non-disclosing results.
- A closed artifact policy now classifies repository intent and regenerates eight tracked contracts byte-for-byte without staging, leaking suspicious contents, or disturbing pre-existing state.
- A mechanically exact ownership ledger now closes the v22 audit cone, while an explicit Playwright repository mode proves first-attempt behavior against fresh server and invocation-owned output state.
- Crosswake CI now consumes the same fixed repository-stage facade as local verification, with mutation-tested ownership closure and one bounded recurring contract gate.
- A fail-closed remediation queue now binds the sole proven browser correction to its exact source owner and regression while making zero findings explicit and deterministic.
- Exact tracked commits can now be verified from dirty source repositories using a checksum-pinned, invocation-local Darwin/arm64 toolchain without leaking worktree bytes, private logs, or global state.
- Exact-commit proof now records nine passing repository stages, byte-identical clean Git state, unchanged index state, and privacy-safe bounded evidence for supported code SHA `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2`.
- A validated three-layer claim owner now keeps reusable contracts, dated reference-host evidence, and blocked first adopter activation distinct across generated guides and parked state.
- A fixed-purpose Mix command now writes or observationally checks both canonical documentation projections, while the existing artifact registry validates and restores both generator families independently.
- The existing documentation leaf now checks generated parity without writes, proves semantic current truth, and keeps generated-guide reviews inexpensive under the sole Crosswake CI umbrella.
- Answer-first authored guidance now routes six reader jobs to current executable owners, generated support truth, bounded recovery, and an explicit Phase 168 publication stop.
- All seven setup-java uses now share the official immutable v6 commit, and PR #121 merged only after exact-head Crosswake CI and fresh-default reachability proof.
- Exact package-floor truth and Phase41-partitioned root verification landed through an ancestry-preserving, 47-of-47-green PR transaction.
- The narrow PackStore waiter-closure cleanup landed as one exact-tested Swift commit, with 47-of-47 same-head CI and receipt-first protected-default integration.
- Seven ordinary PR dispositions, separate recovery provenance, and a tree-identical exact-head closeout merge with a bounded Phase 168 handoff
- Exact seven-field tuple membership now admits only reusable Crosswake authority, retained reference-host evidence, and blocked first adopter activation while rejecting every mixed or incomplete authority claim.
- An exact five-blob protected-default landing, tracked historical runtime authority, and cursor-complete live deferral-marker proof establish trustworthy inputs for the 0.2.1 candidate.
- A closed Elixir authority now binds exact candidate observations, derives five fail-closed states, and emits one canonical JSON receipt with deterministic human projections through the fixed 0.2.1 Mix command.
- Six exact-ref Hex packages now produce officially unpacked, content-addressed observations, while a closed validator proves the 0.2.1 core/native tuple and independent companion compatibility floors.
- Six built package payloads now pass a real `phx_new 1.8.13` five-profile companion matrix twice from isolated state, while exact-public proof remains fail-closed and publication-gated.
- Four fail-closed mirror modes now prove the public baseline and candidate write authority while keeping atomic ordinary publication structurally separate from exact-ref recovery.
- Existing trusted workflows now rehearse an exact candidate without mutation, then require one approved merge with an identical tree before an honest, independently observable Hex/iOS/Android 0.2.1 release graph can run.
- The existing Crosswake CI now provides fast candidate feedback on ordinary PRs and exact-head full local proof at release boundaries, paired with read-only linked-coordinate status and one seven-step approval runbook.
- All reversible 0.2.1 readiness work landed before a fresh Release Please candidate was bound to complete trusted proof, producing one exact receipt and one explicitly approved—but still unexecuted—irreversible release decision.

---
