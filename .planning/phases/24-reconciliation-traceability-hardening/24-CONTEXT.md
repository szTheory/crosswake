# Phase 24: Reconciliation Traceability Hardening - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Normalize the v3.2 reconciliation traceability artifacts so the milestone audit reports RECN-01/02/03 as `satisfied` instead of `partial`. The implementation work was already verified in Phase 21 (`21-VERIFICATION.md` passes all three); the gap is purely artifact-shape inconsistency:

1. Phase 21's two SUMMARY.md files use `requirements:` frontmatter — every other phase (19, 20, 23) uses the canonical `requirements-completed:` key, which is what `.planning/v3.2-MILESTONE-AUDIT.md` cross-checks against.
2. `.planning/REQUIREMENTS.md` shows `- [ ] RECN-01/02/03` in the milestone section and `Pending` in the bottom traceability table, despite Phase 21 passing verification.
3. `.planning/v3.2-MILESTONE-AUDIT.md` permanently reports `gaps_found` with RECN-01/02/03 as `partial`; a re-audit must publish the fix without destroying the historical snapshot that justified Phases 23–24 existing.

This phase does NOT touch reconciliation behavior, contracts, vocabulary, or any commerce module under `lib/crosswake/commerce/`. It only edits planning artifacts and ships one deterministic parity test against `.planning/phases/*/*-SUMMARY.md`.

</domain>

<decisions>
## Implementation Decisions

### Unifying Posture
- **D-01:** Treat planning artifacts as first-class proof — append-only audit evidence, in-place requirement status flips, and a deterministic merge-blocking parity test. This is Phase 23 D-10 ("taxonomy parity is mandatory and enforced by deterministic parity tests") applied to the planning corpus.

### Phase 21 SUMMARY Frontmatter Normalization
- **D-02:** Rename the `requirements:` frontmatter key to `requirements-completed:` in `.planning/phases/21-reconciliation-example/21-01-SUMMARY.md` and `21-02-SUMMARY.md`. Preserve the list contents (`RECN-01`, `RECN-02`, `RECN-03`) exactly; this is a key rename, not a re-classification.
- **D-03:** Do NOT sweep other phase summaries in this phase. Scope is Phase 21 only — Phases 19, 20, and 23 already use the canonical key. The parity test (D-08) will catch any drift the audit tool missed.

### REQUIREMENTS.md Sync
- **D-04:** Flip `- [ ] **RECN-0X**` to `- [x] **RECN-0X**` in the milestone section. Keep the bullets in their current `Reconciliation Example (example/docs-only, companion-ready)` subsection — do not move them to a `### Validated` subsection. REQUIREMENTS.md's native shape is `milestone-section + traceability table at the bottom`; it has no `### Validated` subsection, and grafting one onto only RECN would create internal divergence with every other milestone subsection.
- **D-05:** Update the bottom traceability table cells for RECN-01/02/03: change phase column from `Phase 24` to `Phase 21 (validated); Phase 24 (traceability normalized)` and status column from `Pending` to `Complete`. Both the substring `Phase 21` and `Phase 24` MUST appear in the same cell so future audit-tool substring scans see both phases.
- **D-06:** Do not add narrative prose explaining the validated-in-21-normalized-in-24 distinction — the traceability table cell carries it. Prose drift is a documented footgun (see Footguns below).

### Milestone Audit Re-Audit Shape (Append-Only)
- **D-07:** Append a `## Re-Audit (Phase 24)` section to `.planning/v3.2-MILESTONE-AUDIT.md`. Do NOT overwrite the original `gaps_found` snapshot — it is the historical evidence that motivated Phases 23 and 24 existing. Append-only matches Phase 21 D-04 (append-only normalized evidence events) and Phase 23 D-11 (proof-lane evidence preservation). The re-audit must:
  - Add a `reaudits:` YAML key to the frontmatter (a list, so future re-audits append further entries). Each entry: `phase`, `date`, `current_status` (`satisfied` if all gaps closed, otherwise enumerate remaining gaps), `evidence` (citing the fix commits and the parity test).
  - Leave the top-level `status: gaps_found` field UNCHANGED. The verdict-at-time is historical fact. Derived current state lives in `reaudits[].current_status`.
  - Add a new `## Re-Audit (Phase 24)` body section that re-runs the three-source cross-check (REQUIREMENTS.md / VERIFICATION.md / SUMMARY frontmatter) for RECN-01/02/03 only, with explicit before/after diffs and links to the Phase 24 fix commits.
- **D-08:** Cite the new `## Re-Audit (Phase 24)` section from `24-VERIFICATION.md` as the canonical re-audit evidence. VERIFICATION.md does not duplicate the audit body.

### Regression Prevention (Merge-Blocking Parity Test)
- **D-09:** Ship a deterministic merge-blocking ExUnit test at `test/crosswake/planning/summary_frontmatter_test.exs`. New `planning/` subsystem directory under `test/crosswake/`, consistent with the existing `guides/`, `support_matrix/`, `proof/`, and `doctor/` layout (each a parity/contract test for one canonical-truth surface).
- **D-10:** Test assertions, narrowly scoped:
  - **(a)** Walk every `.planning/phases/*/*-SUMMARY.md`. Parse YAML frontmatter. If the summary lists requirements at all, it MUST use the `requirements-completed:` key. The bare `requirements:` key in a summary is forbidden (that key is reserved for PLAN-style artifacts).
  - **(b)** Every requirement ID listed under `requirements-completed:` MUST exist as a bullet in `.planning/REQUIREMENTS.md`.
  - Do NOT extend the test to assert verification status, commit SHAs, completion dates, plan numbers, or phase-number consistency in this phase. Each is a separate parity concern; coupling them would expand Phase 24's boundary and make the test brittle.
- **D-11:** Before committing the parity test, run it against ALL existing `.planning/phases/*/*-SUMMARY.md` files to catch retroactive failures. If any pre-Phase-19 summary uses a third key shape (e.g., older artifact format), the planner must either backfill those summaries in the same phase OR scope the test to a phase-number floor with an explicit allowlist and a comment citing the floor decision. This is a discovery step, not a guess — the survey result determines scope.

### Claude's Discretion
- Exact ExUnit module name, test description strings, and helper function decomposition for `summary_frontmatter_test.exs`, as long as the assertions in D-10 are present and the test is in the merge-blocking lane.
- Exact YAML key naming under `reaudits:` entries (e.g., `evidence_links` vs `commits` vs `references`) as long as the shape stays append-list and machine-readable.
- Exact wording of the `## Re-Audit (Phase 24)` body section, as long as it includes the three-source cross-check table and before/after diff cells for RECN-01/02/03.
- Whether the parity test reads `.planning/REQUIREMENTS.md` by parsing the bullet list with a regex or via a small reusable helper module — either is fine as long as the assertion (b) failure message names the missing requirement ID and the path it expected to find it in.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope, Requirements, And Audit Evidence
- `.planning/PROJECT.md` — Crosswake thesis, OSS DNA constraints ("install truth", "proof lanes are part of the product"), and v3.2 milestone framing.
- `.planning/REQUIREMENTS.md` — RECN-01/02/03 bullets (currently `[ ]`) and bottom traceability table (currently `Pending`). The artifact this phase mutates.
- `.planning/ROADMAP.md` — Phase 24 goal and success criteria (`requirements-completed` frontmatter, traceability sync, re-audit shows `satisfied`).
- `.planning/STATE.md` — current milestone posture; update after phase completion.
- `.planning/v3.2-MILESTONE-AUDIT.md` — the audit doc this phase appends to. Read the existing structure (frontmatter, "Requirements Cross-Check" table, RECN evidence rows reporting `partial`) before appending the re-audit section.

### Prior Locked Decisions (Carry Forward)
- `.planning/phases/19-commerce-route-corridors/19-CONTEXT.md` — corridor taxonomy posture.
- `.planning/phases/20-entitlement-lifecycle-semantics/20-CONTEXT.md` — lane semantics and authority/evidence boundary.
- `.planning/phases/21-reconciliation-example/21-CONTEXT.md` — D-01 through D-18: RECN contract semantics ARE LOCKED. Phase 24 must not touch reconciliation behavior. D-04 (append-only normalized evidence events) is the prior art for D-07 (append-only audit doc).
- `.planning/phases/23-commerce-support-and-proof-closure/23-CONTEXT.md` — D-10 (taxonomy parity enforced by deterministic parity tests) is the prior art for D-09/D-10. D-11/D-12 (merge-blocking vs advisory split) places the new parity test in the merge-blocking lane.

### Phase 21 Artifacts To Mutate
- `.planning/phases/21-reconciliation-example/21-01-SUMMARY.md` — frontmatter `requirements:` → `requirements-completed:`.
- `.planning/phases/21-reconciliation-example/21-02-SUMMARY.md` — same rename.
- `.planning/phases/21-reconciliation-example/21-VERIFICATION.md` — read-only reference; already passes RECN-01/02/03.

### Canonical Frontmatter Shape References
- `.planning/phases/19-commerce-route-corridors/19-01-SUMMARY.md` — canonical `requirements-completed:` example (single-line list shape).
- `.planning/phases/20-entitlement-lifecycle-semantics/20-01-SUMMARY.md` — canonical `requirements-completed:` example.
- `.planning/phases/23-commerce-support-and-proof-closure/23-03-SUMMARY.md` — canonical `requirements-completed:` example from a recent phase.

### Existing Parity-Test Idiom (Match This Style)
- `test/crosswake/support_matrix/renderer_test.exs` — canonical "rendered artifact stays in sync with canonical truth" parity test idiom. The new `summary_frontmatter_test.exs` should match its assertion shape and failure-message clarity.
- `test/crosswake/guides/commerce_test.exs` — docs-contract parity test that walks rendered artifacts and asserts canonical shape. Same idiom class.
- `test/crosswake/doctor/doctor_test.exs` — contract test layout reference.

### OSS DNA / Project Thesis
- `prompts/crosswake-elixir-oss-dna.md` — maintainer's OSS house style: install truth, narrow honest support claims, proof lanes as product surface. Phase 24 extends this posture to `.planning/` artifacts themselves.
- `prompts/crosswake-research-synthesis.md` — research synthesis constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`test/crosswake/support_matrix/renderer_test.exs` parity-test idiom** — establishes the byte-identity / canonical-source assertion style. The new parity test should mirror this shape rather than inventing a new test convention.
- **`test/crosswake/guides/commerce_test.exs` docs-contract walker** — pattern for walking a directory of markdown artifacts and asserting structural invariants. Reusable as a structural reference, not necessarily as imported code.
- **Existing YAML frontmatter parsing in summaries** — if Crosswake already has a frontmatter parser (check `lib/crosswake/`), reuse it; otherwise the test can use a regex-based parser since the surface is small (key:value lines until first blank line or `---`).

### Established Patterns
- **Parity tests live under `test/crosswake/<subsystem>/`** with one subsystem directory per canonical-truth surface (`guides/`, `support_matrix/`, `doctor/`, `proof/`). Phase 24 adds `planning/` as a new subsystem dir, consistent with this layout.
- **Merge-blocking lane** is the default for deterministic hermetic parity tests (Phase 23 D-12). The new test belongs here, not in any advisory lane.
- **YAML frontmatter contract** for phase summaries: opens `---`, key-value lines, closes `---`. Phase 19/20/23 examples are the schema reference.
- **REQUIREMENTS.md structure**: milestone section with `- [ ]` / `- [x]` bullets + bottom traceability table with `| ID | Phase | Status |` columns. Do not introduce a `### Validated` subsection — it does not match the doc's native shape.

### Integration Points
- Test runs as part of `mix test` in the merge-blocking lane. No CI workflow changes needed unless the existing CI does not already include `test/crosswake/**/*_test.exs` — verify during planning.
- The parity test reads `.planning/` paths from the project root via `File.cwd!()` or equivalent. Ensure the test works when ExUnit is invoked from the project root (the standard path).
- No `lib/crosswake/` modules change. No public API changes. No deps change.

</code_context>

<specifics>
## Specific Ideas

- **Substring `Phase 21` AND `Phase 24` both literally present** in the RECN-01/02/03 traceability table cells (D-05). The future audit tool substring-matches both — neither can be paraphrased.
- **`reaudits:` as a YAML list** (D-07), not a single object. Future re-audits append further entries; the shape must support N≥2 from day one.
- **Test path: `test/crosswake/planning/summary_frontmatter_test.exs`** (D-09). Matches existing subsystem-per-truth-surface layout.
- **Discovery step before committing parity test** (D-11): run it against every existing phase summary to catch retroactive failures. The survey result determines whether to backfill or allowlist.

</specifics>

<deferred>
## Deferred Ideas

- **Sweep all phase summaries to enforce canonical key retroactively.** Considered and rejected for this phase — scope is RECN-only, and the new parity test would catch any pre-existing drift at commit time (handled per D-11 with backfill or floor allowlist). If the survey reveals widespread drift, that becomes its own phase candidate, not Phase 24 scope creep.
- **Expand the parity test to assert verification status, commit SHAs, completion dates, plan-number consistency.** Each is a separate parity concern. Keeping the test narrow per D-10 avoids coupling Phase 24 to schema changes outside its boundary. A "planning-corpus parity test suite" could be a future hardening phase if drift in those dimensions becomes a recurring problem.
- **AGENTS.md / CONTRIBUTING note documenting the canonical frontmatter key.** Considered as a complement to the parity test but not required — the test is mechanical enforcement; the note would be redundant disclosure that rots. If the maintainer later wants a human-facing reference, it can be added in a docs phase.
- **Phase 20 VERIFICATION.md contradiction noted in `.planning/v3.2-MILESTONE-AUDIT.md` tech_debt.** Out of scope for Phase 24 (different phase, different requirements, doc-debt rather than traceability-shape). Belongs in a future Phase 20 doc-debt cleanup if pursued.
- **Cross-phase reconciliation drift checks between core and example reconciliation paths** (also flagged in audit `tech_debt`). Out of scope — that is a contract drift concern, not a traceability artifact-shape concern.

</deferred>

---

## Footguns (Mandatory For Planner To Address)

1. **Schema-lock without survey.** The parity test must be run against ALL existing `.planning/phases/*/*-SUMMARY.md` files BEFORE committing it (D-11). If any pre-Phase-19 summary uses a third key shape, the test will retroactively fail. Either backfill those summaries in the same phase OR scope the test to a phase-number floor with an explicit allowlist and an inline comment citing the floor decision.

2. **Audit doc top-level `status:` field is verdict-at-time and must not be flipped.** Append `reaudits:` to frontmatter; add `current_status` per re-audit entry. The original `status: gaps_found` stays as historical record. Mutating it destroys the audit chain.

3. **Both `Phase 21` and `Phase 24` substrings must appear literally in the same RECN traceability-table cell.** Do not abbreviate to `Phases 21+24` or "Phase 21/24" — the future audit tool substring-scans for both literal strings.

4. **No reconciliation behavior changes.** Phase 24 mutates planning artifacts and ships one parity test. Do not touch `lib/crosswake/commerce/reconciliation.ex`, `lib/crosswake/commerce/contracts.ex`, the `examples/phoenix_host/lib/crosswake_example/commerce/` modules, any commerce guides body content beyond what the canonical key requires, or any other RECN-adjacent code path. Any code-behavior change is scope creep — push it to a future phase.

---

*Phase: 24-reconciliation-traceability-hardening*
*Context gathered: 2026-05-27*
