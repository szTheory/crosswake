---
phase: 25
phase_name: "address-tech-debt-phase-20-verification-text-phase-24-parity"
project: "Crosswake"
generated: "2026-05-27"
counts:
  decisions: 11
  lessons: 5
  patterns: 8
  surprises: 4
missing_artifacts:
  - "UAT.md"
---

# Phase 25 Learnings: address-tech-debt-phase-20-verification-text-phase-24-parity

## Decisions

### D-02 — Minimal-scope delete for the Phase 20 doc-fix

Delete exactly the contradictory trailing sentence at `20-VERIFICATION.md:63`; do not rewrite, augment, or re-title the surviving line 61 or the `## Final Determination` heading.

**Rationale:** The audit's stated fix is literally "drop the trailing sentence." Any improvement to line 61, a heading retitle, or an explanatory closing paragraph is silent scope creep across the planner→file-state boundary (Footgun 5).
**Source:** 25-01-PLAN.md

---

### D-03 — Close WR-01 with a third presence test, not a relaxed helper

Add a third test asserting every `.planning/phases/*/*-SUMMARY.md` has YAML frontmatter AND declares a parseable `requirements-completed:` key.

**Rationale:** WR-01 is a missing-key silent-acceptance hole: the current `extract_completed_ids/1` returns `[]` for both "key absent" and "key empty," collapsing two distinct shapes into one. A separate presence test isolates the missing-key case from the empty-list case.
**Source:** 25-02-PLAN.md

---

### D-04 — Empty inline `requirements-completed: []` is the canonical tech-debt SUMMARY shape

Tech-debt SUMMARYs declare `requirements-completed: []` inline (the empty-list literal), NOT a bare key, NOT YAML null (`~`), NOT a multi-line block with zero bullets, NOT a `tech-debt: true` opt-out flag.

**Rationale:** Inline `[]` is parsed cleanly by the existing inline arm of `extract_completed_ids/1` (capture = `""`, `scan_ids("")` returns `[]`), so it does not require special-casing in the helper and remains internally consistent with the WR-02 raise behavior for malformed shapes.
**Source:** 25-02-PLAN.md, 25-01-SUMMARY.md, 25-02-SUMMARY.md

---

### D-05 — No `tech-debt: true` opt-out flag in SUMMARY frontmatter

Reject any escape-hatch flag (e.g., `tech-debt: true`) that would exempt a SUMMARY from the parity assertion.

**Rationale:** An opt-out flag re-introduces the silent-acceptance hole the phase exists to close. The canonical empty-list shape (D-04) is the contract; opt-outs erode it over time.
**Source:** 25-02-PLAN.md

---

### D-06 — Close WR-02 with a new third `cond` arm that raises

In `extract_completed_ids/1`, insert `Regex.match?(~r/^requirements-completed:/m, frontmatter) -> raise ...` BEFORE the existing `true -> []` fallback.

**Rationale:** Loud rejection on present-but-malformed shapes (bare-key, YAML null, indentation-broken bullets) replaces the silent `[]` fallback that would otherwise mask broken SUMMARYs in test output.
**Source:** 25-02-PLAN.md

---

### D-07 — The raise lives in the helper, not the test body

Place the new raise branch in `extract_completed_ids/1` (the helper), not inline in the test assertion.

**Rationale:** A helper-level raise protects all current AND future callers of the helper. A test-level raise only protects the current call site and would let new callers re-introduce silent acceptance.
**Source:** 25-02-PLAN.md, 25-02-SUMMARY.md

---

### D-08 — Add `@requirements_path` compile-time module attribute

Introduce `@requirements_path Path.join(File.cwd!(), ".planning/REQUIREMENTS.md")` symmetric with the existing `@summary_glob`. Refactor `parse_requirement_ids_from_requirements_md/0` to use it.

**Rationale:** Symmetric compile-time resolution eliminates compile-time/runtime cwd divergence under unusual invocation paths (custom Mix tasks, IEx `cd` re-runs).
**Source:** 25-02-PLAN.md

---

### D-09 — Widen REQUIREMENTS.md bullet regex to `[xX ]`

Change `~r/- \[[x ]\] \*\*([A-Z]+-\d+)\*\*/` to `~r/- \[[xX ]\] \*\*([A-Z]+-\d+)\*\*/`.

**Rationale:** Some markdown editors emit uppercase `[X]` for completed boxes. The narrower `[x ]` regex silently drops uppercase entries from `known_ids`, which would cause Test 2 to falsely report a referenced ID as "not in REQUIREMENTS.md."
**Source:** 25-02-PLAN.md

---

### D-10 — One atomic git commit for the four test edits + both Phase 25 SUMMARYs

Ship the strengthened test file, `25-01-SUMMARY.md`, and `25-02-SUMMARY.md` in a SINGLE commit; explicitly stage paths by name (no `git add -A` / `.`).

**Rationale:** The new presence assertion (D-03) iterates `Path.wildcard(@summary_glob)` and would fail against Phase 25's own un-shipped SUMMARYs if the test were committed alone. Committing the SUMMARYs alone leaves the contract un-enforced for one commit. The atomic commit closes both silent-acceptance windows.
**Source:** 25-02-PLAN.md

---

### D-11 — Plan 25-01 ships independently before Plan 25-02's atomic commit

Plan 25-01 (the single-line `20-VERIFICATION.md` delete) commits FIRST with its own Conventional Commits scope (`docs(phase-20)`). Plan 25-02 then ships the atomic three-file commit.

**Rationale:** Plan 25-01 has no dependency on the test hardening; making it independent preserves bisect granularity. The 25-01 SUMMARY is intentionally created by Plan 25-02 (not 25-01) so the parity-test presence assertion does not fail mid-phase.
**Source:** 25-01-PLAN.md, 25-02-PLAN.md

---

### D-12 — Pre-commit discovery survey is mandatory; silent weakening is forbidden

Before invoking `git commit` for the atomic three-file commit, run `mix test test/crosswake/planning/summary_frontmatter_test.exs` against the working tree (full corpus). On failure: (a) backfill the failing pre-existing SUMMARY in the same commit, OR (c) add a phase-number floor allowlist WITH an inline comment citing the floor decision and the failing path. (b) Silently weakening the assertion is explicitly forbidden.

**Rationale:** Hardening a parity guard that has been silently accepting malformed inputs may expose latent failures. The survey turns "shipped surprise" into "planned coverage decision."
**Source:** 25-02-PLAN.md

---

## Lessons

### Plan-supplied byte-exact pre-edit context prevents off-by-one rewrites

When a plan's `<interfaces>` block carries the verbatim pre-edit shape of the target file region (e.g., lines 59-63 of `20-VERIFICATION.md` reproduced exactly), the executor can confirm pre-state byte-by-byte before touching anything, catching drift between planning-time and execution-time file state.

**Context:** Plan 25-01 embedded the exact pre-edit lines 59-64 of `20-VERIFICATION.md` in its `<interfaces>` block, so the executor never had to re-derive line numbers from the live file. The single-line delete shipped with zero collateral edits.
**Source:** 25-01-PLAN.md

---

### Two-step staging on coupled changes always creates a silent-acceptance window

Splitting a contract-strengthening test edit from the artifacts it newly governs always produces ONE of two failure modes: (a) the test-first commit fails on the un-shipped artifacts, or (b) the artifacts-first commit leaves the contract un-enforced. Both are silent-acceptance windows.

**Context:** Phase 25's WR-01 presence assertion iterates `Path.wildcard(@summary_glob)`, which includes Phase 25's own SUMMARYs. Atomic commit (D-10) is the only correctness-preserving sequence.
**Source:** 25-02-PLAN.md

---

### Helper-level invariants outlive test-level invariants

A raise placed in the production helper protects every caller, current and future. A raise placed in the test only protects the current call site. When hardening a contract, push the loud failure DOWN into the helper.

**Context:** WR-02's `raise` lives in `extract_completed_ids/1` (the helper used by Test 1 and Test 2) rather than inline in the new third test. Any future caller — production, test, IEx — inherits the loud failure.
**Source:** 25-02-PLAN.md, 25-02-SUMMARY.md

---

### Compile-time vs runtime `File.cwd!()` resolution can drift

Mixing a compile-time module attribute that resolves cwd at compile time with a sibling function that resolves cwd at runtime via `File.cwd!()` can produce divergent paths under custom Mix tasks or IEx `cd` re-runs. Symmetric compile-time resolution eliminates the class.

**Context:** `@summary_glob` resolved cwd at compile time but `parse_requirement_ids_from_requirements_md/0` called `File.cwd!()` at runtime. IN-01 / D-08 introduced `@requirements_path` to align both.
**Source:** 25-02-PLAN.md

---

### A latent silent-acceptance hole may already be empirically vacuous

WR-01 was a real guard hole, but the survey showed all 16 existing SUMMARYs already declared a parseable `requirements-completed:` key — the hole had never been exercised in practice. The hardening was preventive, not corrective. Knowing this changes the urgency framing of similar tech-debt items.

**Context:** Pre-commit `mix test` against the working tree passed 3 tests, 0 failures across 18 SUMMARYs without any backfill or allowlist.
**Source:** 25-02-SUMMARY.md

---

## Patterns

### Pure-deletion invariant via `git diff` zero-additions assertion

For "delete one line" edits, assert `git diff` shows ONLY removed lines and zero added lines. Combined with `grep -c` checks on the kept text remaining at count `1`, this catches accidental rewrites disguised as deletions.

**When to use:** Any time a plan mandates a delete-only edit on a document or config file, especially when the surrounding text is similar enough that a partial rewrite might pass a casual diff review.
**Source:** 25-01-PLAN.md

---

### Pre-commit discovery survey against the full corpus

Before committing a contract-strengthening change, run the strengthened test against the full corpus (existing + new artifacts) in the working tree. Decide explicitly: backfill failures, loud-allowlist with inline comment, or revert.

**When to use:** When tightening a glob-walked or directory-scanned invariant. The survey converts "shipped surprise" into "planned coverage decision."
**Source:** 25-02-PLAN.md

---

### Atomic-commit narrative embedded in the commit body

When two or more files MUST ship together to preserve a correctness invariant, name the constraint in the commit body (e.g., "atomic commit," "D-10," "test + summary together"). The constraint is then visible at git-archaeology time, not just at planning time.

**When to use:** Any commit whose splitting would silently break a contract (test+fixture, schema+migration, contract-strengthening test + governed artifacts).
**Source:** 25-02-PLAN.md, 25-VERIFICATION.md

---

### Compile-time module attribute symmetry for resource paths

When a test module references multiple repo-relative resources, use compile-time `Path.join(File.cwd!(), ...)` module attributes (`@summary_glob`, `@requirements_path`) for ALL of them — never mix compile-time attributes with runtime `File.cwd!()` calls in the same module.

**When to use:** ExUnit modules that scan repo-relative directories or read fixture files. Symmetric resolution prevents cwd-drift bugs.
**Source:** 25-02-PLAN.md

---

### Cond-arm ordering that preserves the canonical-input fast path

When inserting a new "raise on malformed" arm into a `cond` that already handles the canonical happy-path shapes, place the raise arm AFTER the happy-path arms and BEFORE the silent fallback (`true -> []`). The canonical input never reaches the raise; only genuinely-malformed shapes do.

**When to use:** Tightening a guard that has shape-discriminating cond arms. Verify the invariant by mental-execution of the new ordering against every canonical input shape.
**Source:** 25-02-PLAN.md

---

### Loud-allowlist with inline-comment audit trail

If backward compatibility forces an allowlist (e.g., phase-number floor below which the new assertion does not apply), add an inline comment citing the decision rationale and the specific failing input. The allowlist becomes visible at code-review time rather than buried in test data.

**When to use:** When a contract-strengthening change cannot be applied uniformly across the corpus and a temporary carve-out is genuinely necessary. The comment is the audit trail.
**Source:** 25-02-PLAN.md

---

### Path-in-message assertion idiom

Embed the offending path directly in the assertion message (e.g., `"#{path} is missing required \`requirements-completed:\` key"`) so a failing assertion is self-locating without grepping.

**When to use:** Any test that iterates a directory or glob and asserts per-item invariants. Self-locating failures cut debug time when CI surfaces only the assertion line.
**Source:** 25-02-PLAN.md

---

### Verbatim pre-edit interface block in plan documents

Embed the exact pre-edit shape of the target file region (lines, whitespace, surrounding context) directly in the plan's `<interfaces>` block, then have the executor confirm the file matches before editing.

**When to use:** Single-line or small-region edits where adjacent-line drift is the primary failure mode. Especially valuable when the plan was written hours/days/weeks before execution.
**Source:** 25-01-PLAN.md

---

## Surprises

### Full SUMMARY corpus passed the new presence assertion on first survey

All 16 pre-existing SUMMARYs + 2 new Phase 25 SUMMARYs (18 total) passed the new WR-01 presence assertion immediately. Zero backfills required, zero allowlist entries needed. The hardening was entirely preventive.

**Impact:** The atomic commit shipped without surprise edits to historical SUMMARYs, keeping `5ca1306` to exactly three files. Future tech-debt items with similar "silent acceptance" framing may also turn out to be empirically vacuous — worth checking before pessimistically scoping backfill work.
**Source:** 25-02-SUMMARY.md, 25-VERIFICATION.md

---

### Plan 25-01's SUMMARY is created by Plan 25-02, not Plan 25-01

The natural ordering ("each plan creates its own SUMMARY") is broken here: 25-01 ships only the `20-VERIFICATION.md` delete in its commit (`4e0ed68`), and 25-02 creates BOTH 25-01-SUMMARY.md and 25-02-SUMMARY.md as part of its atomic three-file commit (`5ca1306`).

**Impact:** The D-10 atomic-commit constraint forces this non-intuitive ordering: if 25-01 created its own SUMMARY, that SUMMARY would not yet have its corresponding 25-02-SUMMARY counterpart, and the new presence assertion would fail mid-phase. Future phases with cross-plan contract changes should expect to encounter the same SUMMARY-ownership inversion.
**Source:** 25-01-PLAN.md, 25-02-PLAN.md

---

### Test count incremented by exactly +1 despite four distinct fixes

The atomic commit closed FOUR review items (WR-01, WR-02, IN-01, IN-02) but added only ONE new test (the WR-01 presence test). WR-02's raise, IN-01's `@requirements_path`, and IN-02's `[xX ]` regex all harden the existing two tests' behavior under the hood with no separate test added.

**Impact:** "Number of new tests" is a noisy proxy for "contract surface tightened." Three of the four fixes shifted behavior in the helper functions backing the existing tests rather than expanding the test count.
**Source:** 25-02-SUMMARY.md, 25-VERIFICATION.md

---

### Empty inline `requirements-completed: []` parses through the existing inline arm without special-casing

The new WR-02 raise branch never fires for the canonical tech-debt shape because the existing inline-`[..]` arm's `[^\]]*` capture matches `""` for `[]`, and `scan_ids("")` returns `[]`. No special-case for "empty list" was needed — the cond ordering alone preserves the Footgun 2 invariant.

**Impact:** D-04's canonical shape and D-06's loud-raise contract coexist without an explicit `[]` carve-out. The interaction is implicit in cond ordering and the inline regex's already-permissive capture group, which is fragile under future refactors — anyone reordering the cond arms or tightening the inline regex must mentally re-execute the empty-list case.
**Source:** 25-02-PLAN.md, 25-02-SUMMARY.md
