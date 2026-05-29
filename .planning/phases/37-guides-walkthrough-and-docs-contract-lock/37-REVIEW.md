---
phase: 37-guides-walkthrough-and-docs-contract-lock
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - guides/commerce.md
  - test/crosswake/guides/commerce_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 37: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the two Phase 37 changed files: the new `### Paywall Corridor Walkthrough` subsection in `guides/commerce.md` and the corresponding `describe "paywall corridor walkthrough"` block added to `test/crosswake/guides/commerce_test.exs`.

The guide prose is correct and well-formed. The `Code.require_file` paths resolve correctly from `test/crosswake/guides/`. Load order respects inter-module dependencies. `verify_and_broadcast/2` (which calls `Phoenix.PubSub`) is not invoked at module scope or in any test body — only `build_verified_snapshot/2` is covered by `function_exported?/3`, matching the walkthrough's actual anchors. `async: false` is consistent with the existing proof tests that load the same modules, and module-scope double-loading of already-compiled modules is handled gracefully by the BEAM (confirmed: no redefine warnings when run alongside phase34 proof tests). All six `function_exported?/3` arity checks match the actual exported signatures in the source modules.

Two warnings are present: a pair of existing (pre-phase-37) assertions that use heading-level-ambiguous split strings, which pass today via substring coincidence but do not enforce the intended heading level. These are pre-existing and were not introduced in this phase; they are reported here for completeness because they affect the robustness of the docs-contract surface.

No blockers. No security issues. No runtime side effects introduced.

---

## Warnings

### WR-01: Heading-level mismatch in section split — `"## Commerce Corridor Ownership"` vs actual H3

**File:** `test/crosswake/guides/commerce_test.exs:112` and `:219`
**Issue:** Two test locations reference `"## Commerce Corridor Ownership"` as an H2 heading, but the guide defines this section as an H3 (`### Commerce Corridor Ownership`, line 27 of `guides/commerce.md`). The assertions pass today only because `"## Commerce Corridor Ownership"` is a proper substring of `"### Commerce Corridor Ownership"` — the `##` prefix is contained within `###`. Consequences:

- The `assert content =~ "## Commerce Corridor Ownership"` at line 112 would still pass even if the heading were promoted to H4 or deeper (e.g., `#### Commerce Corridor Ownership`), so it does not lock heading level.
- The `String.split(content, "## Commerce Corridor Ownership")` at line 219 cuts at the H3 line but leaves a dangling `#` in the preceding part. This is currently harmless because the section content extracted is correct, but it is brittle: a future guide restructure that adds a true H2 `## Commerce Corridor Ownership` section above the existing H3 would cause the split to fire at the wrong boundary.

The same pattern is present at line 85: `assert content =~ "## Minimal Reconciliation Inbox Example"` while the guide has `### Minimal Reconciliation Inbox Example` (H3, line 103).

**Fix:** Use the exact heading strings that match the guide's actual heading depth. For H3 sections, use the `###` prefix in assertions and split keys:

```elixir
# line 112
assert content =~ "### Commerce Corridor Ownership",
       "commerce guide missing `### Commerce Corridor Ownership` section"

# line 219 (inside corridor roles test)
|> String.split("### Commerce Corridor Ownership")

# line 85
assert content =~ "## Minimal Reconciliation Inbox Example"
# should be:
assert content =~ "### Minimal Reconciliation Inbox Example",
       "commerce guide missing `### Minimal Reconciliation Inbox Example` section"
```

---

### WR-02: Reconciliation section boundary is latently fragile — includes Paywall Corridor Walkthrough subsection

**File:** `test/crosswake/guides/commerce_test.exs:153-166`
**Issue:** The `keeps reconciliation guidance provider-neutral` test (line 147) extracts the reconciliation section by splitting on `"### The Canonical Reconciliation Flow"` and terminating at `"## Reviewer And Storefront Playbooks"`. This boundary is wide: it captures all H3 subsections between those two landmarks, including the newly added `### Paywall Corridor Walkthrough` (guide lines 117-135) and `### Backend Idempotency`, `### Deterministic Projection Precedence`, and `### Fallback Behavior`.

Today the walkthrough text intentionally avoids naming StoreKit or Play Billing directly (it says "no native provider SDK dependency" and defers to the Non-Claims section), so the `refute reconciliation_section =~ "storekit"` passes correctly. However, the test is silently relying on future authors of _any_ subsection in that broad range avoiding provider names. A future author adding a provider-specific note inside `### Backend Idempotency` or `### Deterministic Projection Precedence` would break this refute without being warned by a more targeted test.

This is a robustness gap rather than a current failure — the test is correct for the current guide content — but the boundary is unexpectedly wide for what the test name implies.

**Fix:** Narrow the section boundary to the specific subsections the test intends to police, or add a comment making the wide scope explicit:

```elixir
# Option A: narrow to only the two canonical-flow subsections
reconciliation_section =
  content
  |> String.split("### The Canonical Reconciliation Flow")
  |> List.last()
  |> String.split("### Minimal Reconciliation Inbox Example")
  |> hd()
  |> String.downcase()

# Option B: keep the wide boundary but add an explicit comment
# NOTE: This section boundary intentionally covers all H3 subsections from
# "The Canonical Reconciliation Flow" through the Paywall Corridor Walkthrough,
# Backend Idempotency, Projection Precedence, and Fallback Behavior — all of
# which must remain provider-neutral per the Layer 1 contract.
```

---

## Info

### IN-01: Duplicate `assert content =~ "authority"` assertion in `makes authority vs evidence semantics explicit` test

**File:** `test/crosswake/guides/commerce_test.exs:48` and `:53`
**Issue:** The assertion `assert content =~ "authority"` appears twice in the same test body (lines 48 and 53). The second assertion is dead — it provides no additional coverage because the first already passes or fails on the same predicate.

```elixir
assert content =~ "authority"   # line 48 — first occurrence
assert content =~ "access"      # line 49
assert content =~ "reconciliation"  # line 50
assert content =~ "freshness"   # line 51
assert content =~ "effective"   # line 52
assert content =~ "authority"   # line 53 — duplicate, dead assertion
```

**Fix:** Remove the duplicate at line 53. No content change needed in the guide.

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
