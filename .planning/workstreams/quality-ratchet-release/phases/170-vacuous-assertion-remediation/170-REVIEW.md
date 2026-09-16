---
phase: 170-vacuous-assertion-remediation
reviewed: 2026-09-16T20:08:19Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - script/collection_assertion_ledger.json
  - script/collection_assertion_remediation.json
  - script/inventory_collection_assertions.exs
  - test/crosswake/bridge/push_test.exs
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/doctor/doctor_threadline_test.exs
  - test/crosswake/guides/evidence_manifest_test.exs
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/manifest/manifest_test.exs
  - test/crosswake/manifest/validator_test.exs
  - test/crosswake/planning/first_adopter_context_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase165_ci_policy_test.exs
  - test/crosswake/proof/phase166_repository_quality_test.exs
  - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  - test/crosswake/proof/phase170_guard_expression_match_test.exs
  - test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - test/crosswake/proof/phase64_runtime_line_policy_test.exs
  - test/crosswake/proof/phase65_diagnostic_export_seam_test.exs
  - test/crosswake/proof_lane/navigation_shell_advisory_test.exs
  - test/crosswake/release_candidate/mirror_test.exs
  - test/crosswake/shell/activation_test.exs
  - test/crosswake/shell/diagnostic_export_test.exs
  - test/crosswake/support_matrix/support_matrix_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
  - test/mix/tasks/crosswake_release_status_test.exs
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 170: Code Review Report

**Reviewed:** 2026-09-16T20:08:19Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Phase 170 adds a regenerable classifier/ledger (`script/inventory_collection_assertions.exs`,
`collection_assertion_ledger.json`, `collection_assertion_remediation.json`), three proof-test
files, and a `refute Enum.empty?(...)` guard at 52 previously-vacuous call sites across 24 test
files. The empty-input regression tests (D-12.2) are genuine and non-vacuous: each one drives the
real production code to an actual empty collection and asserts, via `assert_raise
ExUnit.AssertionError`, that the newly-inserted guard now fails where the old assertion would have
passed silently — spot-checked in `doctor_test.exs`, `evidence_manifest_test.exs`,
`release_boundaries_test.exs`, `support_matrix_test.exs`, and `mirror_test.exs`, all correct. The
pinned-count tests in `phase170_vacuous_assertion_ledger_test.exs` and
`phase170_guard_expression_match_test.exs` reproduce against the live ledger/manifest exactly
(220 audited sites, 42/131/47/0 shape split, 131/4/25/60 bucket split, 52 remediated rows — all
independently recomputed from the committed JSON during this review and matched).

The one substantive problem is architectural, not a one-off typo: the ledger's own "regenerate and
diff exactly" completeness guarantee (D-04/D-06) is weaker than it is documented and presented as
being. Both `--check`'s "matches the live tree exactly" message and the ledger test's "both
directions" assertion compare only the **set of row keys**, never row content — so the
`@manual_overrides` table (keyed by `{file, line}`, not by the same content hash the rest of the
ledger uses specifically to survive line drift) can go stale with zero test failure. Three
secondary classifier-soundness gaps and two nits round out the findings; none of the secondary
gaps currently misclassifies a real site (verified by inspection of all 25
`safe-cardinality-pinned` and all 4 `safe-compile-time-literal` rows), so they are recorded as
Warning/Info rather than Critical.

## Critical Issues

### CR-01: Ledger "completeness" only diffs key sets, never row content — `@manual_overrides` can go stale with no test noticing

**File:** `script/inventory_collection_assertions.exs:433-461` (manual overrides), `:698-753`
(`check/3`); `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs:71-92` ("both
directions" test)

**Issue:** D-04/D-05 explicitly key every ledger row by a content hash of `{enclosing test,
normalized expression, ordinal}` — never by line number — "so a moved-but-unchanged assertion
produces zero diff noise, while a genuinely new or altered one always produces a diff." That
guarantee is implemented correctly for the automatic classifier. It is **not** implemented for
`@manual_overrides`, which is keyed by `{file, line}` (line 433: `{"test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs", 92} => ...`) and looked up via `apply_manual_override/1` using
the row's *current, freshly-scanned* line number (`display_line(row["display"])`, line 525).

Nine sites (`validator_test.exs` ×4, `physical_iphone_test.exs`, `phase165_ci_integrity_test.exs`,
`mirror_test.exs`, `doctor_test.exs`, `first_adopter_context_test.exs`) rely on this table to stay
classified `safe-cardinality-pinned` instead of `needs-fix`, specifically *because* they are the
sites the general content-based heuristic cannot reach (line 410-432's own comment). If any future
edit adds or removes a line above one of these nine call sites, the override lookup silently stops
matching:

1. The row's **content-hash key is unaffected** by the line shift (by design), so it still exists
   in both the live and committed key sets.
2. `check/3` (script `--check`) and the ledger test's "both directions" assertion
   (`phase170_vacuous_assertion_ledger_test.exs:71-92`) both compute only
   `MapSet.difference` over `Map.keys/1` of the row maps — they never compare the row *values*
   (`bucket`, `rationale`, `display`) for a key present in both sets. A bucket that silently
   flips from `safe-cardinality-pinned` to `needs-fix` (or vice versa) between live and committed
   is invisible to this check.
3. The one test that pins bucket composition
   (`phase170_vacuous_assertion_ledger_test.exs`, "per-bucket composition matches @bucket_counts
   exactly") reads the **committed, static file**, not a fresh regeneration — so it cannot detect
   that the live tree would now produce different buckets for the same keys.

Net effect: `[crosswake] OK: 220 classified collection-assertion site(s), ledger matches the live
tree exactly` can print, and every `mix test` in this phase's own proof suite can pass green,
while one of these nine rows has quietly reverted to an unguarded, genuinely vacuous assertion in
the checked-in ledger's stale record of it. This is the same "absence scored as success" failure
mode the whole phase exists to eliminate, reproduced one layer up in the tool that is supposed to
prevent it. Verified this is not *currently* manifesting — all nine overrides match their present
line numbers correctly (confirmed by reading each file) — so this is a latent design gap, not an
active misclassification, which is why the finding is architectural rather than "row X is wrong
today."

**Fix:** Either (a) key `@manual_overrides` by the same content hash already computed for every
other row (the hash is available before `apply_manual_override/1` runs — thread `row["key"]`
through instead of `{file, line}`), which is a mechanical, low-risk change; or (b), if line-number
keying is kept for human-editability, make the completeness check compare full row equality
(`bucket`, `rationale`, `display`) per shared key, not just key-set membership, so a stale
override fails loudly instead of silently.

## Warnings

### WR-01: `compile_time_literal?/1` misclassifies a bare `[]` literal as "cannot be empty"

**File:** `script/inventory_collection_assertions.exs:546-552`

**Issue:** The predicate accepts any expression that "starts with `[`, ends with `]`, and contains
neither `Enum.` nor `|>`" as a compile-time literal collection that "cannot be empty by
construction" (rationale text at line 560). The literal `[]` itself satisfies all three
conditions, so `assert Enum.all?([], f)` or `refute Enum.any?([], f)` would be classified
`safe-compile-time-literal` with the rationale "is a literal list written directly in source; it
cannot be empty by construction" — which is false for the one input that matters most: `[]` is
already empty. No row in the current 220-site ledger has expression `"[]"` (confirmed by scanning
the committed ledger), so this is not an active misclassification today, but it is a real logic
gap in the classifier that would silently hide the single most literal instance of the exact
defect class this phase exists to remediate, and it would never surface as a review flag because
it is auto-classified with no human-written rationale to catch it (D-07's "residual gets human
rationale" only applies past this branch).

**Fix:** Add a guard for the degenerate case, e.g.:
```elixir
defp compile_time_literal?(expr) do
  trimmed = String.trim(expr)

  Regex.match?(~r/^@[a-zA-Z_]\w*$/, trimmed) or
    (trimmed != "[]" and String.starts_with?(trimmed, "[") and String.ends_with?(trimmed, "]") and
       not String.contains?(trimmed, "Enum.") and not String.contains?(trimmed, "|>"))
end
```

### WR-02: `pin_line?/2` / `guard_line?/2` accept a root that merely appears anywhere on the candidate line, not one that is actually the operand being compared

**File:** `script/inventory_collection_assertions.exs:656-683`

**Issue:** `root_word_boundary?/2` (line 656) only checks that the root identifier occurs
somewhere on the candidate line, word-bounded. `pin_line?/2` and `guard_line?/2` then combine that
with a separate, unanchored regex for "some `assert ... == [`" or "some `!= []`" pattern anywhere
on the same line. Nothing ties the two together — a line such as
`assert unrelated_helper(root) == [1, 2, 3]`, where `root` is merely an argument to an unrelated
call and the actual pinned expression is `unrelated_helper(root)`, would satisfy both regexes and
be accepted as a valid cardinality pin for `root`'s own emptiness, even though the line pins the
cardinality of `unrelated_helper(root)`, not of `root` itself. Spot-checked every one of the 25
`safe-cardinality-pinned` rows in the committed ledger and found no case that currently exploits
this (all real pins are genuine `assert Enum.map(root, ...) == [...]` / `assert map_size(root) ==
N` shapes), so this is a latent soundness gap rather than an active false classification.

**Fix:** Require the root to be adjacent to the comparison operator (e.g. root immediately
precedes `==`/`!=`, possibly through a known wrapper like `Enum.map(root, ...)` /
`length(root)`/`map_size(root)`), rather than merely present anywhere in the line.

### WR-03: `@manual_overrides` rationale for `validator_test.exs:86` does not match the code it describes

**File:** `script/inventory_collection_assertions.exs:437-439`

**Issue:** The stated rationale is: "a naive `refute Enum.empty?` inserted one line above a
DIFFERENT, later `Validator.validate(manifest)` call (same expression, same test, second
occurrence) is redundant with the first and was reverted after breaking nothing structurally."
The actual test body (`test/crosswake/manifest/validator_test.exs:81-90`, "an empty
unknown-blocking topology remains a valid non-promoting manifest section") contains exactly **one**
`Validator.validate(manifest)` call — there is no "later, second occurrence" anywhere in that test.
Whatever the real reason this row was left unguarded (plausibly: `Validator.validate/1` on this
fixture genuinely returns a non-empty error list unrelated to `NT-MANIFEST-ROOT_REQUIRED`, which
would make it a legitimate `safe-cardinality-pinned` classification by the same "confirmed via
real execution" standard the other eight override entries use), the *recorded* reason is factually
wrong. This also stands out from the other eight entries in the same table, every one of which
cites a specific `mix test ... :LINE` invocation and a concrete result (`findings == []` /
`errors == []`) as its evidence; this entry cites no such run. D-07 requires "a one-line rationale
string — never a bare boolean," specifically because an unverifiable or wrong rationale is the
"documented decay mode of every baseline mechanism in the industry" the phase's own design notes
call out — an inaccurate rationale defeats that purpose as surely as a missing one.

**Fix:** Re-verify this specific row against the real code path (e.g. `mix test
test/crosswake/manifest/validator_test.exs:81`, inspect `Validator.validate(manifest)`'s actual
return value) and rewrite the rationale to state what was actually observed, in the same
verifiable-citation style as the other eight entries.

## Info

### IN-01: Duplicate `refute Enum.empty?` guards inserted back-to-back for the same expression

**File:** `test/crosswake/doctor/doctor_threadline_test.exs:99,262,267,327,332`;
`test/crosswake/shell/diagnostic_export_test.exs:237,239`;
`test/mix/tasks/crosswake_gen_proof_lane_test.exs:129,133,157`

**Issue:** Where two `needs-fix` rows in the same test both consume the identical expression
(e.g. `report.findings`, `m`, `diff`), the mechanical per-row insertion (D-09's "applied uniformly
... regardless of the collection's origin") added a `refute Enum.empty?(...)` guard immediately
above *each* sibling assertion, producing two textually-identical guard lines a few lines apart in
the same test body — the second is redundant since the first already covers the same root within
the same test's unbounded backward scan (`find_backward/4` is unbounded within the test body, not
windowed). Functionally harmless, purely diff/readability noise.

**Fix:** None required for correctness; a future pass over the remediation manifest could
deduplicate guards sharing `{enclosing, root}` within one test body before emitting the fix.

### IN-02: `extract_root/1`'s pipe-splitting is naive text splitting, not parsing

**File:** `script/inventory_collection_assertions.exs:570-601`

**Issue:** `extract_root/1` finds a top-level `|>` via `String.contains?(trimmed, "|>")` +
`String.split(trimmed, "|>") |> List.first()`. A collection expression containing a *nested* `|>`
inside a lambda body passed as an earlier pipeline stage (e.g.
`x |> Enum.filter(fn y -> y |> foo() end)`) would be split at the wrong `|>` and produce an
incorrect root. The module's own header comment already discloses that this scanner is
"source-text balancing, not a real parser" and that none of the 220 audited sites currently
exercise the string/paren-comma edge case it names — this is the same class of limitation, just a
different concrete shape (nested pipe rather than embedded comma/paren), and equally unexercised
today. Recorded so a future contributor adding a call site in this shape doesn't unknowingly
reintroduce a false-safe classification.

**Fix:** None required now; worth a comment near `extract_root/1` noting the nested-pipe caveat
alongside the existing string-literal caveat, so both known gaps are documented in one place.

---

## Findings Closed (gap closure, plan 170-06)

**CR-01 (Critical) — closed.** `@manual_overrides` in
`script/inventory_collection_assertions.exs` is now keyed by `row["key"]` (the same sha256
content hash every other ledger row uses) instead of `{file, line}`, so an override tracks its
call site through line movement instead of silently stopping to match. `apply_manual_override/1`
was updated to look up by that key. Independently, `--check`'s completeness diff (and the "both
directions" ledger proof test) now compares full row CONTENT for every key present in both the
live and committed snapshots — not just key-set membership — so a bucket that silently drifts
between a committed snapshot and the live tree is reported as a `mismatched:` FAIL instead of
passing silently. A new D-14 non-vacuity control (`phase170_vacuous_assertion_ledger_test.exs`,
"mutating one row's bucket ... makes --check exit non-zero") proves the content-diff can go RED:
a bucket-only mutation with an unchanged key now fails `--check` and names the row. Ledger
regenerates byte-identical for this change alone (verified before layering WR-03's rationale
edit on top). Commit: `6a3c3973`.

**WR-03 (Warning) — closed.** Re-verified the `validator_test.exs:86` override against the real
code path: added a temporary `IO.inspect` and ran
`mix test test/crosswake/manifest/validator_test.exs:81`, which shows
`Validator.validate(manifest) == []` for that fixture. The previously recorded rationale's claim
of a "different, later `Validator.validate(manifest)` call (same expression, same test, second
occurrence)" was confirmed false — no such second call exists in that test. The site IS safe
(same positive-path "fixture validates cleanly" shape as the sibling override at line 303), just
not for the reason previously recorded; the rationale was rewritten to state the real, observed
reason with an accurate `mix test` citation. No reclassification: bucket composition is unchanged
at 131 safe-by-construction / 4 safe-compile-time-literal / 25 safe-cardinality-pinned / 60
safe-guarded (220 sites total). Commit: `b170a58c`.

Verification re-run after both fixes: `elixir script/inventory_collection_assertions.exs --check`
exits 0 (220 sites); `--emit-snapshot` regenerates byte-identical against the committed ledger;
all three phase170 proof test files pass (51 tests, 0 failures across
`phase170_vacuous_assertion_ledger_test.exs`, `phase170_guard_expression_match_test.exs`,
`phase170_vacuity_taxonomy_convention_test.exs`, plus `validator_test.exs`); `mix format
--check-formatted` is clean on every file touched.

WR-01, WR-02, IN-01, and IN-02 remain open by design — deliberately deferred, per this plan's
scope.

---

_Reviewed: 2026-09-16T20:08:19Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_Gap closure: 2026-09-16, plan 170-06_
