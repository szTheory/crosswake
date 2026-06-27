---
phase: 129-stable-companion-contract-surface
reviewed: 2026-06-25T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - guides/companion_contract.md
  - guides/companions.md
  - lib/crosswake/companion.ex
  - lib/crosswake/companion/state.ex
  - lib/crosswake/compatibility/compatibility.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/shell/denial.ex
  - mix.exs
  - test/crosswake/guides/release_boundaries_test.exs
  - test/crosswake/hex_page_test.exs
  - test/crosswake/proof/phase129_companion_contract_freeze_test.exs
  - test/fixtures/proof/phase52_publish_readiness.json
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 129: Code Review Report

**Reviewed:** 2026-06-25
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 129 is a documentation/promotion phase: it promotes five modules
(`Crosswake.Companion`, `Crosswake.Companion.State`, `Crosswake.Compatibility.Finding`,
`Crosswake.Compatibility.Target`, `Crosswake.Manifest.Types.RouteEntry`) from
`@moduledoc false` to public-stable with `## Stability` moduledocs, `@moduledoc since: "0.1.0"`,
and `@typedoc` on `t/0`; adds a new `guides/companion_contract.md` ExDoc extra plus a
`"Companion Contract"` `groups_for_modules` entry and `"Extension Authors"` extras group in
`mix.exs`; and adds a merge-blocking freeze-proof test. The diff confirms **no struct fields,
types, or callback signatures changed** — only doc additions — so there is no semantic drift in
the promoted types themselves, and the existing doc-parity tests (`hex_page_test`,
`release_boundaries_test`) were correctly updated for the two new doc groups.

The promotion mechanics are sound. The defects found are in **contract-document accuracy** and
**freeze-test completeness** — exactly the high-risk surface for a "freeze the public API" phase,
where a wrong example or an under-specified freeze ships as a semver promise. No bugs, no security
issues, no data-loss risk.

## Warnings

### WR-01: `Finding` moduledoc example axis (`:feature_flag`) contradicts the actual shipped contract

**File:** `lib/crosswake/compatibility/compatibility.ex:65` (promoted `Finding` moduledoc)
**Issue:**
The newly-promoted public-stable `Finding` moduledoc states:

> Required fields: `:axis` (atom identifying the policy axis, e.g. `:feature_flag`) ...

But no shipped companion uses `:feature_flag`. The shipped feature-gating companion
(`lib/crosswake/companions/rulestead.ex:44,56`) returns `%Finding{axis: :gate_denied, ...}`.
More importantly, the `:axis` value carries real semantics through `finding_to_denial/2`
(`compatibility.ex:147-184`): there is no `:feature_flag` (nor `:gate_denied`) branch in that
`case`, so a companion that follows the example literally and emits `axis: :feature_flag` would,
if its finding ever flowed through `finding_to_denial/2`, fall to the catch-all and become a
`:compatibility_mismatch` denial — the wrong denial reason for a feature gate. (Gate findings
from RouteGate currently bypass `finding_to_denial/2` per the comment at
`compatibility/route_gate.ex:37,90`, which is *why* the doc example is untested and slipped
through, but the moduledoc is now a semver-stable public contract that companion authors copy.)
This is a misleading public contract example on a freshly-frozen surface.

**Fix:** Use a real, contract-faithful axis in the example, and either reference the actual denial
mapping or state that gate findings use `:gate_denied`:
```elixir
# in the Finding @moduledoc
Required fields: `:axis` (atom identifying the policy axis — feature-gating
companions use `:gate_denied`, matching `Crosswake.Shell.Denial.reasons/0`)
and `:message` (human-readable explanation).
```
If a non-`:gate_denied` axis is genuinely intended as the example, add a corresponding branch to
`finding_to_denial/2` so the documented axis produces a coherent denial reason rather than the
`:compatibility_mismatch` fallback.

### WR-02: Freeze-proof test claims to freeze "5 contract modules" but never asserts the count — silent removal passes

**File:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs:68-83` (Test 2) and `:40-43` (`contract_modules/0`)
**Issue:**
The test moduledoc and Test 2 advertise proving "5 contract modules have non-hidden moduledoc",
but `contract_modules/0` derives the list dynamically from `mix.exs`
`groups_for_modules[:"Companion Contract"]`, and Test 2 simply iterates whatever that list
contains. No test asserts the **size** of the contract group (no `length(...) == 5`, no
membership check for `Crosswake.Companion` / `Crosswake.Companion.State` /
`Crosswake.Compatibility.Target` / `Crosswake.Manifest.Types.RouteEntry`). Only `Finding`
(present) and `Shell.Denial` (absent) are pinned by name (Tests 4/5). Consequences:
- If a future PR drops a module from the `"Companion Contract"` mix.exs group, Test 2's loop
  shrinks and still passes — silently narrowing the frozen public surface with no failing test.
- An empty group (`Keyword.get(..., [])` default, as the comment at `:40` notes it returns `[]`
  "until plan 129-02 lands") would make Tests 2 and 4 vacuously pass.

For a merge-blocking *freeze* whose stated job is "both additions AND removals fail" (the comment
at `:20-21` describes exactly this intent for callbacks), the module-set side of the freeze does
not enforce that invariant.

**Fix:** Pin the contract module set the way the callback set is pinned — by equality against a
hardcoded expected set, not just by iterating the derived list:
```elixir
@expected_contract_modules MapSet.new([
  Crosswake.Companion,
  Crosswake.Companion.State,
  Crosswake.Compatibility.Finding,
  Crosswake.Compatibility.Target,
  Crosswake.Manifest.Types.RouteEntry
])

test "Companion Contract module group is frozen at the Phase 129 set" do
  assert MapSet.equal?(@expected_contract_modules, MapSet.new(contract_modules()))
end
```
This makes additions and removals to the mix.exs group both fail, matching the callback freeze.

## Info

### IN-01: `companions.md` retains stale "v3.5 / extraction deferred" framing after `companion.ex` dropped its extraction caveat

**File:** `guides/companions.md:5,11,190`
**Issue:**
This phase deleted the "Companions live in-tree ... and may be extracted to separate packages in a
future milestone" sentence from `companion.ex`'s moduledoc (confirmed in the diff) and added a new
`companion_contract.md` describing the semver-stable surface that exists specifically to enable
extraction. But `companions.md` — a file edited in this same phase — still self-describes as "the
single canonical **v3.5** companion guide" (`:5`), says companions "live in-tree ... in v3.5"
(`:11`), and lists "Separate-package extraction of companions. v3.5 keeps companions in-tree" under
**Deferred Non-Goals** (`:190`). Per the active milestone context (v16.0 is the companion-extraction
milestone), this deferred-extraction language now contradicts the contract guide it links to.
Not a code defect, but a public-doc consistency gap on the exact topic this phase promotes.

**Fix:** Reconcile the extraction framing in `companions.md` (and the "v3.5" self-labeling) with the
new contract guide, or add a forward-reference note that extraction is now in progress under the
current milestone with module names preserved.

### IN-02: Test 3 uses a hard pattern-match on `Code.fetch_docs/1`, raising `MatchError` instead of a clean assertion on a missing module

**File:** `test/crosswake/proof/phase129_companion_contract_freeze_test.exs:91`
**Issue:**
```elixir
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(mod)
```
If `Code.fetch_docs/1` returned `{:error, :module_not_found}` / `{:error, :chunk_not_found}` (e.g.
a contract module renamed/removed, or docs chunk stripped in some build), this raises a raw
`MatchError` rather than producing the structured `ProofAssertions.stable_id_message` failure the
rest of the test is careful to emit. All four `@struct_contract_modules` are real and compiled
today, so this does not fire now — but a freeze test is precisely where a renamed module should
yield a legible failure.

**Fix:** Match defensively and route through the stable-id assertion:
```elixir
case Code.fetch_docs(mod) do
  {:docs_v1, _, _, _, _, _, docs} -> # ... existing typedoc lookup + assert
  other -> flunk(ProofAssertions.stable_id_message("proof.seam_01.typedoc.#{mod}.t", ...))
end
```

### IN-03: `companion_contract.md` Telemetry section duplicates the `companion.ex` moduledoc as a second source of truth

**File:** `guides/companion_contract.md:48-58`
**Issue:**
The guide restates the three telemetry event-name contracts and the
`%{companion_id: atom(), route_id: binary() | nil}` metadata shape, prefaced by
"(source of truth: `Crosswake.Companion` moduledoc)". I verified the metadata claim is currently
accurate — `doctor.ex:575,578` emits `route_id: nil` for the `validate_dependency` span, so "all
events carry `route_id`" holds. However, hand-copying the event list and metadata into a second
location with no test asserting parity between the guide and the `companion.ex` moduledoc means the
two can silently diverge later (the existing `hex_page_test` only checks link/grouping hygiene, not
prose parity). Low risk because the values are stable, but it is duplicated contract prose without a
drift guard.

**Fix:** Either trim the guide to a pointer ("see the `Crosswake.Companion` moduledoc for the
authoritative telemetry event/metadata contract") rather than re-listing, or add a small parity
assertion if the enumeration must live in both places.

---

_Reviewed: 2026-06-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
