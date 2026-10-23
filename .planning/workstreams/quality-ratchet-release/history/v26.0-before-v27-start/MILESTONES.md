# Milestones

## v26.0 Harden Before Trust (Planning closeout: 2026-10-16)

**Status:** Planning closeout complete with tech debt; 2026-10-16. Product code is not delivered; it exists only in the `/private/tmp` candidate.
**Coverage:** 18/18 requirements; 5/5 phases (184–188); 37 plans; 96 tasks counted from the plan files (the installed CLI reported 21, an undercount).
**Closeout type:** `verified_closeout` — all five phases verified `passed`; the [audit](milestones/v26.0-MILESTONE-AUDIT.md) is `tech_debt` with no blocker.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git exceptions:** No commit, tag, staging, branch/worktree change or remote write in the recovery checkout.

### Key accomplishments

- The twin's clean-tree probe can no longer be fooled by git index flags or local/global config: one pinned git funnel serves every product probe call, and `mix crosswake.proof_lane.twin_preflight` tells a maintainer whether a run would be allowed without using up a run root (Phase 184).
- The absence checker, the v25 test loops and the twin runtime helpers now fail when they examine nothing; a guard script refuses an empty scan scope (Phase 185).
- The legacy host-command path denies instead of granting every `host.*` key, doctor stops passing on unreadable input and redacts paths, the physical preflight refuses a loopback origin, and the loopback harness reports its own failures (Phase 186).
- Doctor findings carry actionable details (unmanaged paths, router), an unbacked offline island is an error, proof evidence records real provenance instead of placeholders, and the A/D adopter-request deferrals are recorded with reopen triggers (Phase 187).
- All v26 changes were frozen at candidate `a53fbef`, a 30-label scripted go/no-go passed, and twin-05 ran exactly once and passed (10/10 groups, 7/7 identity joins); the result is byte-copied into planning (Phase 188).

### Retained debt

See the [debt disposition](milestones/v26.0-closeout/debt-disposition.md). Fix before the next twin run or twin-touching change: 188 WR-01 (empty-folder privacy scan passes), 188 WR-08 (gate labels without a failing self-test), the unpinned `g()` gate helper, 185 WR-02, 187 WR-02 and the stale guard pin (249 vs 253). 186 WR-01 (LOOP-07 residual) needs an owner decision. Two hand-offs to Phase 188 were not done there: the guard pin raise and the Swift G4 baseline failure.

### Source and archive limits

Candidate: `/private/tmp/crosswake-phase180-impl`, HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4` (tree `f7c4d7dc`), v26 commits over `50fcd57`. Delivery into the authoritative tree needs separate authorization. Residual external gates: a physical signed-iPhone run and the first adopter's sanitized route handoff. No whole-project LOC or milestone commit range is asserted.

Archive copies: [roadmap](milestones/v26.0-ROADMAP.md), [requirements](milestones/v26.0-REQUIREMENTS.md), [audit](milestones/v26.0-MILESTONE-AUDIT.md). Original phases, the root audit file and REQUIREMENTS.md remain in place.

**Closeout record:** [CLOSEOUT.md](milestones/v26.0-closeout/CLOSEOUT.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected.

---

## v25.0 iOS Host Setup & Digital Twin Proof (Planning closeout: 2026-10-15)

**Status:** Planning closeout complete with tech debt; 2026-10-15. Product code is not delivered; it exists only in the `/private/tmp` candidate.
**Coverage:** 20/20 requirements; 5/5 phases (179–183); 32 plans; 78 tasks counted from the plan files (the installed CLI reported 6, an undercount).
**Closeout type:** `verified_closeout` — all five phases verified `passed`; the [re-audit](milestones/v25.0-MILESTONE-AUDIT.md) is `tech_debt` with no blocker.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git exceptions:** No commit, tag, staging, branch/worktree change or remote write in the recovery checkout.

### Key accomplishments

- A compile-only Phoenix `:ios_host` declaration generates the iOS host resources and an Xcode-resolved simulator app identity with no hand patches; managed outputs regenerate safely and an interrupted update blocks the build until recovery (Phase 179).
- Routes declare `host.*` commands in a central versioned registry; the manifest (schema 1.2.0) is the sole authority, and activation delivers them to the native session and the bounded-shell offline island (Phase 181).
- A local/dev `:ios_host` mode allows an http loopback origin through `NSAllowsLocalNetworking` only; production stays HTTPS-only and the proof lane refuses local mode (Phase 182).
- One command, `mix crosswake.proof_lane.verify_twin ios`, runs the bounded reference twin across ten fixed groups and 49 observations and writes a privacy-safe receipt (Phase 180).
- The twin refuses an uncommitted or untracked candidate (`source_dirty`) before compile and after the run, and a missing source join can never pass; twin-04 passed against the committed fix `50fcd57` (Phase 183).

### Retained debt

See the [debt disposition](milestones/v25.0-closeout/debt-disposition.md). The two items that can degrade silently are 183 WR-01 (git index flags hide a modified file from the clean-tree probe) and WR-02 (`core.filemode` not pinned). Fix them in the next twin-touching change, before the next run root (twin-05).

### Source and archive limits

Candidate: `/private/tmp/crosswake-phase180-impl`, HEAD `50fcd5743243c0b20275a7e2bd9338bf25468687` (tree `d71bc587`), eight commits over `da53c54`. Delivery into the authoritative tree needs separate authorization. Residual external gates: a physical signed-iPhone run and the first adopter's sanitized route handoff. No whole-project LOC or milestone commit range is asserted.

Archive copies: [roadmap](milestones/v25.0-ROADMAP.md), [requirements](milestones/v25.0-REQUIREMENTS.md), [audit](milestones/v25.0-MILESTONE-AUDIT.md), [initial audit](milestones/v25.0-MILESTONE-AUDIT.initial.md). Original phases, the root audit files and REQUIREMENTS.md remain in place.

**Closeout record:** [CLOSEOUT.md](milestones/v25.0-closeout/CLOSEOUT.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected.

---

## v24.0 Repository Cleanup & Maintenance (Planning closeout: 2026-10-12)

**Status:** Planning closeout complete with six retained debt records; 2026-10-12.
**Coverage:** 8/8 requirements; 3/3 phases; 15 plans; 28 tasks counted by the installed CLI.
**Closeout type:** `verified_closeout` — all phases verified, with retained milestone debt and carried-forward artifact acknowledgements.
**Known verification overrides:** 0 newly acknowledged, 6 carried forward from v23.0 (see STATE.md Deferred Items). No phase verification override.
**Git exceptions:** No commit, tag, staging, branch/worktree change or remote write.

### Key accomplishments

- Captured all 119 changed paths and proved recovery of 170 eligible units before any cleanup.
- Validated supported maintenance commands while retaining all 78 uncertain historical modes and both unproven reader comparisons.
- Assigned concrete actions to 20 open issues and 4 PRs in the audit refresh.
- Updated maintenance guidance and derived assertion snapshots while preserving all 230 assertion keys and 52 frozen guard rows.
- Delivered the eight-file maintenance proposal as PR #238; it remains open and unmerged.
- Joined nine local verifier stages and 48 required hosted checks to governed merge commit f2d8875ee52d9679157c73b4a701b510ee612cb8.

### Retained debt

- Preserve all 15 original SUMMARY requirement arrays and use the independent audit cross-reference.
- Retain Plan93 source and artifacts until its original reader and receipt support comparison.
- Retain mirror source and artifacts until its original reader and receipt support comparison.
- Retain the historical guidance fixture under its original epoch; validate current scoped state separately.
- Retain the first earlier full-run failure as undiagnosed unless original assertion output appears or an equivalent failure reproduces.
- Retain the second earlier full-run failure under the same condition.

### Source and archive limits

Candidate range: d0dbdf7bf196cea167ced3c50cf620bf3cb2452b → 3e8a4b2601b542323edfd6053f25e56c67873b47. Final verified merge object: f2d8875ee52d9679157c73b4a701b510ee612cb8, tree 27f4073039b4dd976492127549603a76ce22499b. Eight candidate files, 166 additions and 31 deletions according to retained candidate evidence; this is not a whole-milestone Git range. Planning is uncommitted. Summary completion dates span 2026-10-11 through 2026-10-13 UTC; local closeout date is 2026-10-12. No whole-project LOC or fabricated milestone commit range is asserted. Full proof was warm-cache; missing failure output and missing delivery actor attribution remain unavailable.

Archive copies: [roadmap](milestones/v24.0-ROADMAP.md), [requirements](milestones/v24.0-REQUIREMENTS.md), [audit](milestones/v24.0-MILESTONE-AUDIT.md). Original phases, audit supplements and REQUIREMENTS.md remain in place. Protected history retains original bytes and paths.

**Closeout record:** [authorization](milestones/v24.0-closeout/authorization.md) and [debt disposition](milestones/v24.0-closeout/debt-disposition.md).

**Next:** `$gsd-new-milestone --ws quality-ratchet-release`; fresh scope is unselected. PR #238 merge remains a separate decision; the adopter lane stays parked.

---

## v23.0 Release Pipeline Repair & Proof-Lane Truth (Archived: 2026-10-11)

**Closeout type:** `override_closeout` — delivered with a preserved historical failure.
**Coverage:** 42/43 requirements; Phase 175 8/9; integration 8/8; flows 4/4.
**Phase scope:** 169–175. Phases 169–174 passed their dated reports; their current manager projection is stale. Phase 175 is archived with SC-1 breached, never marked passed.
**Known verification overrides:** 6 newly acknowledged, 0 carried forward (see STATE.md Deferred Items). Original bytes and statuses are retained in `milestones/v23.0-closeout/original-artifacts`.

### Key accomplishments

- Diagnostic commands distinguish failed checks from checks that could not run and report the specific cause.
- Release versions derive from the approved manifest; six packages retain independent source references and proof.
- Collection assertions have nonempty guards and a checked 230-site inventory.
- Crosswake 0.2.11 passed three publishers, both generated native consumer builds, exact-public proof and the six-child COMPLETE rollup.
- Chimeway 0.1.2 passed its own fresh gate, ordinary Hex publisher, public-host doctor and direct registry check.
- PR #237 proved ten real installer-before-doctor pairs and passed all 49 CI jobs without another publication.

### Known Gaps

- REL-10 remains unchecked: the incident-response runbook was absent from PR #147's first publish. Later releases cannot change that timing.
- Six accepted historical high limitations and twelve open lower findings remain; current blocking high findings: zero. Nyquist coverage is partial, as detailed in the archived audit.
- Eighteen historical plans lack matching numbered summaries. Fifteen are excluded by the CLI as superseded; Plans 46–48 retain blocked historical states and their forward deliverables are fulfilled by Plan 148. No missing summary was fabricated.
- Debug and v22 records are acknowledged for closure, not rewritten as fixed or passed. Stopped and PARTIAL release attempts remain unchanged.

### Stats and source boundaries

Seven phases; CLI active-plan inventory: 163 plans, 193 tasks. Raw historical files: 178 plans, 161 summaries. Approved-main range `ae08fba33d218bcc7c2a98efd47e543a65a1076a` → `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`: 371 files changed, 67471 lines added, 1474 removed (0 binary entries), 2026-09-17 → 2026-10-11. This range excludes uncommitted local planning history.

Actual published source: core merge `6da6df6f9ddc0f48614fd99c50decc6dc23387c4`; companion merge `2dbde2d9be8adfa36009e20bf894b00a5bb63e87`; final installer repair merge `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. The local milestone tag records planning closeout; it is not a package release tag or a claim that this recovery checkout is published source.

**Archive:** [roadmap](milestones/v23.0-ROADMAP.md), [requirements](milestones/v23.0-REQUIREMENTS.md), [audit](milestones/v23.0-MILESTONE-AUDIT.md), [phase history](milestones/v23.0-phases/).
**Next:** `$gsd-new-milestone --ws quality-ratchet-release`. Fresh scope remains to be chosen; adopter work remains parked.

---

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
