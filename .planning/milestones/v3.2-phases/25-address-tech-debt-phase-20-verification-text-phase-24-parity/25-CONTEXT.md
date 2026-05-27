# Phase 25: Address tech debt: Phase 20 verification text + Phase 24 parity test WR-01/02 - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close two discrete pieces of milestone-audit tech debt flagged in `.planning/v3.2-MILESTONE-AUDIT.md` ("Tech Debt (Non-Blocking)") before archiving v3.2:

1. **Phase 20 VERIFICATION.md doc-debt** — `.planning/phases/20-entitlement-lifecycle-semantics/20-VERIFICATION.md:63` carries a contradictory trailing sentence ("Phase 20 goal is mostly implemented, but not fully achieved...") that conflicts with the preceding final-determination line at `:61` ("Phase 20 goal is achieved..."). Behavior is correct; only the artifact text is inconsistent.
2. **Phase 24 parity test hardening** — `test/crosswake/planning/summary_frontmatter_test.exs` has two advisory warnings from `24-REVIEW.md`:
   - **WR-01:** test does not assert presence of `requirements-completed:` — a SUMMARY that omits the key entirely passes silently.
   - **WR-02:** un-indented bullets under `requirements-completed:` are silently ignored by the third `cond` arm fallback (`true -> []`); combined with WR-01, two distinct malformed shapes both pass the guard.

This phase does **not** touch `lib/crosswake/`, `examples/`, commerce contracts, commerce vocabulary, CI workflows, or any phase artifact outside the two named files. Pure planning-artifact text fix + ExUnit test/helper hardening. The fixes themselves are essentially spec'd in `24-REVIEW.md` (WR-01, WR-02 patches) and the milestone audit (Phase 20 text).

</domain>

<decisions>
## Implementation Decisions

### Unifying Posture
- **D-01:** Apply the "loud, not silent" thesis from `24-REVIEW.md` WR-02 symmetrically across the parity guard. Both WR-01 (missing key) and WR-02 (malformed-but-present key) are silent-acceptance escape hatches; both close in this phase. Carries forward Phase 24 D-01 (planning artifacts as first-class proof) and the Crosswake OSS DNA stance that ill-formed input must reject loudly.

### Phase 20 VERIFICATION.md Fix
- **D-02:** Delete exactly one line — `20-VERIFICATION.md:63` ("Phase 20 goal is mostly implemented, but not fully achieved due to unresolved ENTL-03 runtime fail-closed enforcement gap for invalid evidence source values."). Keep line 61 unchanged ("Phase 20 goal is achieved. All required ENTL-01, ENTL-02, and ENTL-03 semantics are implemented..."). Do not rewrite line 61, do not add narrative explaining the deletion, do not retroactively edit `## Final Determination` heading or other Phase 20 sections. The audit's stated fix is "drop the trailing sentence"; honor that minimal scope.

### WR-01: Presence-Required Assertion (Every SUMMARY)
- **D-03:** Every `.planning/phases/*/*-SUMMARY.md` MUST declare `requirements-completed:` with a parseable value. The third assertion in `summary_frontmatter_test.exs` is "every summary has YAML frontmatter AND that frontmatter contains a parseable `requirements-completed:` key (inline `[..]` or multi-line `\n  - X` shape; empty inline `[]` is allowed)".
- **D-04:** Tech-debt phases that close zero requirements declare `requirements-completed: []` (empty inline list) explicitly. This is the canonical shape for tech-debt SUMMARYs. The `[^\]]*` capture in the existing inline regex accepts the empty case cleanly — `extract_completed_ids/1` returns `[]` without raising. The strict contract therefore costs one line per tech-debt SUMMARY, with no schema additions and no opt-out flag.
- **D-05:** Do NOT add a `tech-debt: true` (or similar) opt-out frontmatter flag. The empty `[]` shape from D-04 already encodes "this phase closes no requirements"; an opt-out flag would be redundant schema surface that rots.

### WR-02: Loud Fallback in the Helper
- **D-06:** Tighten `extract_completed_ids/1` in `test/crosswake/planning/summary_frontmatter_test.exs` so that when `requirements-completed:` is present in the frontmatter but neither the inline `[..]` nor the multi-line `\n  - X` regex arm matches, the helper raises with a clear message (24-REVIEW.md WR-02 fix snippet is the canonical shape). Empty inline `[]` still parses via the inline arm and does NOT raise; only a bare key with no value, a YAML null, or an indentation-broken bullet shape raises.
- **D-07:** The raise lives in the helper, not as a test-side assertion. Helper has exactly one caller today, but pushing strictness into the helper protects every future caller (planning tooling, doc generators, ad-hoc IEx use) from re-litigating the contract. Tests then assert behavior, not contract.

### Bundled Hygiene Items From 24-REVIEW (In-Scope For 25-02)
- **D-08:** Fix `IN-01` (cwd compile-time vs runtime mismatch) in the same edit. Resolve `.planning/REQUIREMENTS.md` via a compile-time module attribute (`@requirements_path Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")`) for symmetry with the existing `@summary_glob`. One-line change in a file 25-02 is already opening.
- **D-09:** Fix `IN-02` (uppercase `[X]` checkbox edge case) by widening the REQUIREMENTS.md bullet regex character class to `[xX ]`. Current corpus uses lowercase but uppercase is common in some editors and would silently drop a requirement ID from `known_ids` — same silent-drop failure mode the rest of the phase exists to close.

### Plan Packaging
- **D-10:** Split into two plans along the natural coupling seam:
  - **25-01-PLAN.md** — Phase 20 VERIFICATION.md text fix only. One file, one-line delete, one commit. Independent of every other deliverable in this phase.
  - **25-02-PLAN.md** — Parity test hardening as one atomic deliverable: WR-01 third test + WR-02 helper raise + IN-01 cwd consistency + IN-02 `[xX ]` regex + Phase 25's own 25-01 and 25-02 SUMMARYs declaring `requirements-completed: []`. The test changes and the new SUMMARYs MUST land in the same commit — committing the strengthened test first would fail the new presence assertion on Phase 25's own incomplete SUMMARYs; committing the SUMMARYs first leaves them un-guarded for one commit. Atomic coupling.
- **D-11:** Plan 25-01 is independent and may execute in parallel with 25-02, but the natural execution order is 25-01 first (smallest possible patch, lowest risk) then 25-02.

### Plan 25-02 Execution Discovery Step
- **D-12:** Before committing 25-02, run the strengthened parity test against ALL existing `.planning/phases/*/*-SUMMARY.md` files (the discovery pattern Phase 24 D-11 established). Verify that every existing SUMMARY in the corpus already satisfies the new presence assertion. If any pre-existing SUMMARY fails (e.g., an older artifact format the audit tool missed), the planner must either backfill it in the same plan OR scope the test to a phase-number floor with an explicit allowlist and an inline comment citing the floor decision. This is a survey, not a guess.

### Claude's Discretion
- Exact wording of the raise message in `extract_completed_ids/1` (D-06), as long as the message names the offending file path and indicates which shape was attempted.
- Exact wording of the third test description string in `summary_frontmatter_test.exs` (D-03).
- Exact wording of the commit messages (within Crosswake's existing conventional-commits convention).
- Whether the new third test uses an inline helper or extends the existing `parse_frontmatter/1` to detect emptiness — both meet the assertion in D-03 as long as the failure message names the missing path.
- Whether D-11's "natural order" (25-01 first) is achieved via wave ordering or simple sequencing in execute-phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope, Audit Evidence, And This Phase's Source Of Truth
- `.planning/PROJECT.md` — Crosswake thesis; OSS DNA stance that ill-formed input must reject loudly and that planning artifacts are part of the public product contract.
- `.planning/ROADMAP.md` §"Phase 25" — phase title and scope anchor: "Address tech debt: Phase 20 verification text + Phase 24 parity test WR-01/02".
- `.planning/REQUIREMENTS.md` — the artifact the parity test asserts existence against; this phase does NOT mutate requirement statuses (Phase 25 closes zero requirement IDs).
- `.planning/STATE.md` — current milestone posture; update after phase completion.
- `.planning/v3.2-MILESTONE-AUDIT.md` §"Tech Debt (Non-Blocking)" (lines 321–327) — the canonical statement of the Phase 20 text-fix scope and the WR-01/WR-02 hardening scope. The audit verdict (`status: gaps_found`, append-only `reaudits[]`) must NOT be flipped by this phase.

### Prior Locked Decisions (Carry Forward)
- `.planning/phases/24-reconciliation-traceability-hardening/24-CONTEXT.md` — D-01 (planning artifacts as first-class proof), D-09/D-10 (parity test idiom, merge-blocking lane), D-11 (discovery-before-commit pattern). Phase 25 extends 24-09's exact file, not a new test surface.
- `.planning/phases/24-reconciliation-traceability-hardening/24-REVIEW.md` — WR-01 fix snippet (lines 47–63) and WR-02 fix snippet (lines 75–91) are the canonical implementation references. D-06 and the WR-01 third test in D-03 should match these snippets in shape. IN-01 (lines 96–100) and IN-02 (lines 102–110) are the canonical references for D-08 and D-09.
- `.planning/phases/24-reconciliation-traceability-hardening/24-VERIFICATION.md` §"Advisory Warnings from Code Review (WR-01, WR-02)" (lines 107–113) — confirms the warnings were left advisory in Phase 24 with the explicit hand-off to a follow-up phase. Phase 25 is that follow-up.
- `.planning/phases/23-commerce-support-and-proof-closure/23-CONTEXT.md` — D-12 (merge-blocking lane for deterministic hermetic parity tests). The strengthened parity test stays in this lane.

### Files This Phase Mutates
- `.planning/phases/20-entitlement-lifecycle-semantics/20-VERIFICATION.md` (line 63 delete only — see D-02).
- `test/crosswake/planning/summary_frontmatter_test.exs` (third test added; `extract_completed_ids/1` tightened; `@requirements_path` added; `[xX ]` widening — see D-03, D-06, D-08, D-09).
- `.planning/phases/25-address-tech-debt-phase-20-verification-text-phase-24-parity/25-01-SUMMARY.md` (new; declares `requirements-completed: []` per D-04).
- `.planning/phases/25-address-tech-debt-phase-20-verification-text-phase-24-parity/25-02-SUMMARY.md` (new; declares `requirements-completed: []` per D-04).

### Canonical Frontmatter Shape References (Read-Only)
- `.planning/phases/24-reconciliation-traceability-hardening/24-01-SUMMARY.md` — multi-line `requirements-completed:` shape with indented bullets.
- `.planning/phases/19-commerce-route-corridors/19-01-SUMMARY.md` — inline `requirements-completed: [..]` shape.

### Existing Parity-Test Idiom (Already Established)
- `test/crosswake/planning/summary_frontmatter_test.exs` (current file being hardened) — Phase 24's deliverable; the new third test must match its module style, async posture (`async: true`), and failure-message clarity.
- `test/crosswake/support_matrix/renderer_test.exs` — canonical "rendered artifact stays in sync with canonical truth" idiom referenced by Phase 24.

### OSS DNA / Project Thesis
- `prompts/crosswake-elixir-oss-dna.md` — "install truth", "loud failure over silent acceptance", "proof lanes are part of the product". Phase 25 extends this stance from runtime artifacts to the planning corpus itself.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`extract_completed_ids/1` regex pair** in `summary_frontmatter_test.exs:57-76` — the inline `[^\]]*` capture already handles the empty `[]` case cleanly. No regex change needed to support D-04's empty-list shape; only the third `cond` arm changes from `true -> []` to a presence-detect-then-raise branch followed by the literal `true -> []` for "key truly absent" (which is the WR-01 missing-key path the new third test catches).
- **`parse_frontmatter/1`** at `:37-42` returns `""` when no `---` block is found; the new third test asserts `fm != ""` so a SUMMARY missing its YAML frontmatter entirely also fails loudly (24-REVIEW.md WR-01 explicitly cites this compounding silence).
- **Compile-time `@summary_glob`** at `:4` is the precedent for D-08's `@requirements_path` symmetry fix.

### Established Patterns
- **One subsystem directory under `test/crosswake/` per canonical-truth surface** (`guides/`, `support_matrix/`, `doctor/`, `proof/`, `planning/`). Phase 25 stays inside the existing `planning/` subsystem dir — no new test surface, no new file.
- **Merge-blocking lane** is the default for deterministic hermetic parity tests (Phase 23 D-12, Phase 24 D-09). The hardened test stays in this lane; no `.github/workflows/` changes.
- **YAML frontmatter contract** for phase summaries: opens `---`, key-value lines, closes `---`. Empty inline `[]` is now the canonical "this phase closes zero requirements" shape per D-04.
- **Discovery-before-commit** (Phase 24 D-11) — run the strengthened test against the existing corpus before merging the test change itself.

### Integration Points
- Test runs as part of `mix test` in the existing merge-blocking lane. No CI workflow changes needed.
- The parity test reads `.planning/` paths via `File.cwd!()` from project root — already wired and proven by Phase 24's CI run.
- Phase 25's own 25-01-SUMMARY.md and 25-02-SUMMARY.md, once created, become inputs to the hardened test on the next CI run. Both must declare `requirements-completed: []` (D-04).
- No `lib/crosswake/` modules change. No `examples/` change. No public API change. No deps change. No commerce code path.

</code_context>

<specifics>
## Specific Ideas

- **Exact line to delete in 20-VERIFICATION.md is line 63** (D-02) — "Phase 20 goal is mostly implemented, but not fully achieved due to unresolved ENTL-03 runtime fail-closed enforcement gap for invalid evidence source values." Verified in this discussion. Line 61 stays untouched.
- **Empty inline `[]` is the canonical tech-debt shape** (D-04). Phase 25's two SUMMARYs declare `requirements-completed: []` literally — not `requirements-completed:` with no value, not `requirements-completed: ~`, not the multi-line block form with zero bullets. The inline empty list is what the existing regex parses cleanly.
- **WR-02 raise must NOT fire on empty `[]`** (D-06). Verified: the inline arm `^requirements-completed:[ \t]*\[([^\]]*)\]/m` matches `requirements-completed: []` with capture group = `""`; `scan_ids("")` returns `[]`; the third arm never executes. Only true malformed-but-key-present cases hit the new raise.
- **Two atomic commits in 25-02** (D-10): the test-file changes (WR-01 third test, WR-02 helper raise, IN-01 cwd, IN-02 `[xX ]`) and the two new Phase 25 SUMMARYs ride in the same commit. Committing the test first would fail the new presence assertion against Phase 25's own incomplete SUMMARYs.
- **Discovery survey before committing 25-02** (D-12) — run the strengthened test locally against the current 16-summary corpus. All 16 currently use `requirements-completed:` per the discussion-time grep. Confirm at execution time.

</specifics>

<deferred>
## Deferred Ideas

- **IN-03 from 24-REVIEW (duplicate `assert summaries != []` guard)** — stylistic dedup via `setup_all` or a small helper. Not a correctness issue. Defer to a future cleanup phase if pursued; not worth the test-surface churn alongside the strictness changes in 25-02.
- **IN-04 from 24-REVIEW (`workflow_dispatch` runs both lanes simultaneously)** — documentation or input-gating change in `.github/workflows/phase23-proof.yml`. Different concern (CI ergonomics, not parity-guard strictness) and different file outside Phase 25's source-of-truth scope. Defer to backlog.
- **Sweep all SUMMARYs for additional frontmatter consistency** (e.g., uniform `phase:` / `plan:` / `tags:` shape) — Phase 24 D-10 deliberately scoped the parity test narrowly to one canonical-truth surface (`requirements-completed:`). Expanding the test to other frontmatter fields is its own concern; defer until drift on those fields is actually observed.
- **Add a `mix crosswake.planning.audit` task or similar planning-corpus CLI** — would surface the same checks the parity test enforces but outside ExUnit, useful for ad-hoc author use. Considered and deferred — the merge-blocking test is the mechanical enforcement; an additional CLI is optional ergonomics, not contract.
- **Rewrite line 61 of 20-VERIFICATION.md to match a canonical "Final Determination" idiom across phases** — out of scope per D-02. The audit's stated fix is minimal (drop the trailing sentence); any prose rewrite is doc-debt of a different class and belongs in a future docs polish phase if pursued.
- **Backfill Nyquist VALIDATION.md coverage for Phases 19/20/23/24** — also flagged in the audit's "Tech Debt (Non-Blocking)" section but explicitly NOT named in Phase 25's ROADMAP title. Discovery-only, never merge-blocking. Belongs in its own `/gsd-validate-phase` follow-up (the audit suggests this command explicitly at line 343). Out of scope for Phase 25.

</deferred>

---

## Footguns (Mandatory For Planner To Address)

1. **Commit ordering coupling in 25-02.** The strengthened parity test (WR-01 presence assertion) and Phase 25's own two SUMMARYs (which declare `requirements-completed: []`) MUST land in the SAME commit. Committing the test alone would make the test fail on Phase 25's own un-shipped or incomplete SUMMARYs (no presence). Committing the SUMMARYs alone is benign but leaves the contract un-enforced for one commit. Single atomic commit is required — D-10 makes this explicit.

2. **Empty inline `[]` must not trip WR-02 raise.** Verify in the planner-written 25-02 plan that the raise condition (D-06) is specifically `Regex.match?(~r/^requirements-completed:/m, frontmatter)` AFTER both shape arms have already failed to match. The inline arm's `[^\]]*` capture matches the empty-string case cleanly — `requirements-completed: []` reaches the inline arm, captures `""`, calls `scan_ids("")` → `[]`, and exits without touching the raise branch. The raise fires only on bare-key or indentation-broken shapes.

3. **Discovery survey before committing 25-02.** Run the strengthened test against the full 16-summary corpus before merging. If any pre-existing SUMMARY fails the new presence assertion, the planner must either backfill it in the same plan OR add an explicit phase-number floor allowlist with an inline comment citing the floor decision. Do NOT silently weaken the assertion to accommodate a discovered failure — that re-introduces the silent-acceptance hole the phase exists to close.

4. **No reconciliation, no commerce, no CI workflow changes.** Phase 25 mutates exactly two existing files (`20-VERIFICATION.md`, `summary_frontmatter_test.exs`) and creates exactly two new SUMMARYs (`25-01-SUMMARY.md`, `25-02-SUMMARY.md`). Any change to `lib/crosswake/`, `examples/`, `.github/workflows/`, commerce guides, or any other phase artifact is scope creep — push to a separate phase.

5. **Phase 20 VERIFICATION.md fix is one-line delete only.** Do not "improve" line 61, do not retitle `## Final Determination`, do not add a closing paragraph explaining the deletion, do not add a commit-message footnote disguised as artifact prose. The audit's stated fix is "drop the trailing sentence"; honor that minimal scope (D-02).

---

*Phase: 25-address-tech-debt-phase-20-verification-text-phase-24-parity*
*Context gathered: 2026-05-27*
