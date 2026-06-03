---
quick_id: 260603-nzr
slug: tighten-validation-ledger-closeout-gate
description: Tighten the validation-ledger closeout gate (Step 1 of the recurring-debt fix)
date: 2026-06-03
mode: quick-full
must_haves:
  truths:
    - "A milestone cannot pass closeout while any PRIOR milestone's CLOSEOUT.md carries an unresolved `scope: validation-ledger-finalization` deferral (Option B backstop)."
    - "validation_ledger_check iterates over EXPECTED phases and flags a MISSING ledger (not just an existing-but-noncompliant one) as blocking."
    - "The verifier finds ledgers in BOTH the archived `.planning/milestones/<m>-phases/` location AND the live `.planning/phases/` location."
    - "A routed/open validation deferral whose revisit_phase has already shipped is treated as stale and blocking."
    - "`mix closeout.verify` goes RED against the real repo (v3.6 prior debt) BEFORE Step 2 backlog cleanup."
  artifacts:
    - "lib/crosswake/planning/closeout_verifier.ex — un-brittled globs + new prior_validation_debt_check + staleness"
    - "test/crosswake/planning/closeout_verifier_test.exs — extended coverage"
  key_links:
    - "lib/crosswake/planning/closeout_verifier.ex"
    - "test/crosswake/planning/closeout_verifier_test.exs"
    - "test/mix/tasks/closeout_verify_test.exs"
    - ".planning/milestones/v3.6-CLOSEOUT.md"
    - ".planning/milestones/v3.9-CLOSEOUT.md"
---

# Quick Task 260603-nzr: Tighten the validation-ledger closeout gate

## Context

`Crosswake.Planning.CloseoutVerifier.validation_ledger_check/2` is the loophole behind
recurring validation-ledger debt. Two structural defects:

1. **No teeth.** A milestone passes closeout if its CLOSEOUT.md records a well-shaped
   `deferred_with_reason` with `scope: validation-ledger-finalization`. Nothing ever forces the
   `revisit_phase` to resolve the debt, so a shaped deferral passes forever and rolls the debt
   to the next milestone (v3.6 → phase 48, never done; v3.9 → phase 64).
2. **Brittle + vacuous.** It hardcodes `@v39_phases ~w(59 60 61 62 63)` and globs
   `.planning/phases/{59,60,61,62,63}-*`, which is **empty** in the real repo — phases archive
   to `.planning/milestones/v3.9-phases/`. `Path.wildcard` returns `[]`, `problematic == []`,
   and the check passes against zero ledgers. The same dead glob also weakens
   `phase_verification_check/2` and `summary_frontmatter_check/2`.

This task ships **Option B (enforce routed deferrals) + tightened deferral (staleness)** and
un-brittles the archived-path globs, keeping the change LOCAL to this repo. Do NOT touch
`~/.claude/`. Step 2 (backlog cleanup) is a separate follow-up.

### CRITICAL invariants that keep existing tests green

- `test/mix/tasks/closeout_verify_test.exs` and `test/crosswake/planning/closeout_verifier_test.exs`
  fixtures write phases to the **live** `.planning/phases/<phase>-fixture/` path — the dual-location
  glob MUST still search `.planning/phases/`.
- The `complete_closeout` fixture has **no** `expected_phases:` array — `expected_phases/1` MUST
  fall back to the hardcoded `{59..63}` default when the array is absent.
- Those fixtures create **only** a `v3.9-CLOSEOUT.md` (no other milestone closeout) — the new
  `prior_validation_debt_check` MUST no-op (pass) when no OTHER milestone closeout exists, and
  MUST exclude the current closeout (the file at `closeout_path/2`) from the prior scan.
- Run `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs test/crosswake/planning/milestone_arc_closeout_parity_test.exs` — all must stay green.

---

## Task 1 — Un-brittle the archived-path globs + strict validation_ledger_check

**Files:** `lib/crosswake/planning/closeout_verifier.ex`

**Action:**

1. Add private helpers (place near `parse_frontmatter/1` / `closeout_path/2`):
   - `milestone(frontmatter)` — return the `milestone:` value (e.g. `"v3.9"`) via
     `Regex.run(~r/^milestone:\s*(\S+)/m, frontmatter, capture: :all_but_first)`; default `nil`.
   - `expected_phases(frontmatter)` — parse the
     `phase_verification_coverage.expected_phases: [ "59", "60", ... ]` array. Match the
     `expected_phases:` line inside frontmatter, extract bracketed values with
     `Regex.scan(~r/"?(\d+(?:\.\d+)?)"?/, list_str)`. **If absent or empty, fall back to
     `@v39_phases`.** (The mix-task fixture relies on this fallback.)
   - `phase_validation_paths(cwd, milestone, phase)` — return the list of VALIDATION.md paths for
     a phase by globbing **both** locations and concatenating:
     - archived: `Path.join(cwd, ".planning/milestones/#{milestone}-phases/#{phase}-*/*-VALIDATION.md")`
     - live: `Path.join(cwd, ".planning/phases/#{phase}-*/*-VALIDATION.md")`
     Use `milestone` only for the archived path; when `milestone` is nil, search live only.
   - Add sibling helpers `phase_verification_paths/3` and `phase_summary_paths/3` (same dual-glob,
     suffixes `*-VERIFICATION.md` and `*-SUMMARY.md`) OR a single generic
     `phase_paths(cwd, milestone, phase, suffix)` the three checks call. Generic is preferred.

2. Rewrite `validation_ledger_check/2` to be STRICT and iterate over expected phases:
   ```elixir
   defp validation_ledger_check(cwd, opts) do
     closeout = read_file(closeout_path(cwd, opts))
     fm = parse_frontmatter(closeout)
     ms = milestone(fm)
     phases = expected_phases(fm)

     problematic =
       Enum.reject(phases, fn phase ->
         paths = phase_paths(cwd, ms, phase, "*-VALIDATION.md")
         paths != [] and Enum.all?(paths, &(read_file(&1) =~ "nyquist_compliant: true"))
       end)

     deferred = closeout =~ "validation-ledger-finalization"

     passed =
       closeout =~
         ~r/validation_ledger_status:\s*\n\s*status:\s*(complete|deferred_with_reason|archived)/ and
         (problematic == [] or deferred)

     # ... check(...) with observed listing problematic phases ...
   end
   ```
   Note: a phase with NO ledger file (missing) now lands in `problematic` because `paths == []`.
   The current-milestone deferral escape (`deferred`) is preserved here — teeth for *prior*
   milestones live in Task 2. Keep the same check id `closeout.validation.ledger`, subject, hint.

3. Rewrite `phase_verification_check/2` and `summary_frontmatter_check/2` to use the same
   `expected_phases/1` + dual-location `phase_paths/4` helpers instead of the hardcoded
   `.planning/phases/{59,60,61,62,63}-*` globs. Preserve their existing check ids, pass/fail
   semantics, and the `"phase-verification-finalization"` deferral escape in
   `phase_verification_check`. For `summary_frontmatter_check`, keep the existing
   `requirements-completed:` frontmatter regex; only the path-discovery changes.

4. You MAY keep `@v39_phases` as the documented fallback constant used by `expected_phases/1`.

**Verify:**
- `mix compile --warnings-as-errors`
- `mix test test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_verifier_test.exs` — green (proves live-path + fallback still work).

**Done:** All three checks derive phases from the closeout and find ledgers in both archived and
live locations; a missing expected ledger is flagged; existing tests pass.

---

## Task 2 — Add prior_validation_debt_check (Option B) + deferral staleness

**Files:** `lib/crosswake/planning/closeout_verifier.ex`

**Action:**

1. Factor a shared `deferred_entries(frontmatter)` helper out of the entry-splitting logic
   already in `malformed_deferred_entries/1`. It returns a list of raw entry strings (reuse the
   `~r/^deferred_with_reason:\s*\n(...)/m` block match + `~r/^\s*-\s+(.*?)(?=^\s*-\s+|\z)/ms`
   scan). Add small field extractors `entry_field(entry, "scope")` etc. via
   `Regex.run(~r/(?:^|\n)\s*#{field}:\s*"?([^"\n]+)"?/, entry, capture: :all_but_first)`.
   Refactor `malformed_deferred_entries/1` to reuse `deferred_entries/1` (behavior unchanged).

2. Add `stale_deferral?(cwd, entry)`:
   - `revisit = entry_field(entry, "revisit_phase")`; if nil/empty → `false`.
   - stale when a `<revisit>-*` dir exists under any archived phases dir:
     `Path.wildcard(Path.join(cwd, ".planning/milestones/*-phases/#{revisit}-*")) != []`.
   (v3.6 routes to phase 48 → `v3.7-phases/48-*` exists → stale. v3.9 routes to 64 → no match → not stale.)

3. Add `prior_validation_debt_check(cwd, opts)` — new stable id `closeout.validation.prior_debt`:
   - `current = closeout_path(cwd, opts)`.
   - `prior_closeouts = Path.wildcard(Path.join(cwd, ".planning/milestones/v*-CLOSEOUT.md")) |> Enum.reject(&(&1 == current))`.
   - For each prior closeout, parse frontmatter; for each `deferred_entries/1` entry where
     `entry_field(entry, "scope") == "validation-ledger-finalization"` and
     `entry_field(entry, "status") not in ["resolved", "closed"]`:
     - Resolve the milestone (`milestone(fm)`) and its `expected_phases(fm)`.
     - The entry is **satisfied** only if EVERY expected phase has a VALIDATION.md (via
       `phase_paths/4`) that is `nyquist_compliant: true`. If `expected_phases` resolves to the
       fallback but the milestone has no archived phases dir at all (e.g. v3.6), there are no
       compliant ledgers → NOT satisfied → it must be resolved by flipping status (Step 2).
     - Collect unsatisfied entries as blocking findings; annotate stale ones (via
       `stale_deferral?/2`) in the observed text.
   - `passed = unsatisfied == []`. Build the `check(...)` with id `closeout.validation.prior_debt`,
     a subject like "prior milestone validation-ledger debt", source
     `.planning/milestones/*-CLOSEOUT.md`, observed listing `"<milestone>: <reason-or-phases> (stale)"`,
     hint "Resolve prior validation-ledger deferrals (make named ledgers nyquist_compliant: true
     or mark the deferral status: resolved with evidence) before closing a new milestone."

4. Wire the new check into the `run/1` checks list (add after `validation_ledger_check(cwd, opts)`).
   It is included only in the non-`security_only?` branch, same as the others.

**Verify:**
- `mix compile --warnings-as-errors`
- `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs` — green (prior check no-ops when no other closeout exists in fixtures).

**Done:** A new milestone cannot close while a prior milestone's validation-ledger deferral is
unsatisfied; stale routes are surfaced; fixtures unaffected.

---

## Task 3 — Extend tests + prove the gate goes RED on real repo

**Files:** `test/crosswake/planning/closeout_verifier_test.exs`

**Action:** Add tests (reuse `tmp_dir!/1`, `write_minimal_files!/1`, `find_check!/2`; create small
fixture helpers for prior closeouts + archived phase dirs as needed):

1. Add `"closeout.validation.prior_debt"` to the stable-ids assertion in the first test.
2. **Prior debt blocks:** write current `v3.9-CLOSEOUT.md` (complete) + a prior `v3.6-CLOSEOUT.md`
   with a `validation-ledger-finalization` deferral `status: routed` and NO compliant ledgers for
   its expected phases → `closeout.validation.prior_debt` is blocking, report status `:failed`.
3. **Prior debt satisfied by compliant ledgers:** same but write the prior milestone's expected
   phase VALIDATION.md files (archived `.planning/milestones/v3.6-phases/<phase>-x/<phase>-VALIDATION.md`)
   all `nyquist_compliant: true` → check passes.
4. **Prior debt satisfied by status: resolved:** same as #2 but entry `status: resolved` → passes
   (accept-and-close path).
5. **Stale deferral surfaced:** prior deferral `revisit_phase: 48` with an archived
   `.planning/milestones/v3.7-phases/48-x/` dir present and ledgers absent → blocking, observed
   mentions stale.
6. **validation_ledger_check archived + missing:** current milestone with expected phases where
   ledgers live under `.planning/milestones/<m>-phases/` and one expected ledger is MISSING and the
   closeout has NO validation-ledger deferral → `closeout.validation.ledger` blocking.

**Verify:**
- `mix test test/crosswake/planning/closeout_verifier_test.exs` — all green.
- Full related suite:
  `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs test/crosswake/planning/milestone_arc_closeout_parity_test.exs` — green.
- **Teeth proof (Step 1f):** run `mix closeout.verify` against the real repo. Expect it to
  **FAIL** with `closeout.validation.prior_debt` blocking on v3.6 (unresolved, stale route to
  shipped phase 48, no compliant ledgers). Capture the output in the SUMMARY — this is the
  intended RED state before Step 2 cleanup. Do NOT "fix" it by editing v3.6-CLOSEOUT.md here.

**Done:** New tests cover the backstop + staleness + archived/missing ledger; `mix closeout.verify`
demonstrably bites on real prior debt.

---

## Out of scope (Step 2, separate task)

Backlog cleanup — creating v3.9 62/63 ledgers, signing 59/61, v3.8 54-58, flipping v3.6/v3.9
deferrals to resolved, reconciling STATE.md. Do NOT do that here. This task must end with
`mix closeout.verify` RED on prior debt, proving the gate works.
