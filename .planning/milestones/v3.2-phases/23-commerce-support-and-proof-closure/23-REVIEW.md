---
phase: 23-commerce-support-and-proof-closure
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/phase23-proof.yml
  - guides/commerce.md
  - guides/compatibility.md
  - guides/support_matrix.md
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/doctor/formatter.ex
  - lib/crosswake/doctor/json_formatter.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/doctor/formatter_test.exs
  - test/crosswake/guides/commerce_test.exs
  - test/crosswake/proof/phase23_commerce_support_proof_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/crosswake/support_matrix/support_matrix_test.exs
findings:
  critical: 0
  warning: 9
  info: 7
  total: 16
status: partial_fixes_applied
---

# Phase 23: Code Review Report

**Reviewed:** 2026-05-27T00:00:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** partial_fixes_applied (all 9 WARNING findings addressed; 7 INFO findings remain for a follow-on pass)

## Summary

Phase 23 wires a new `commerce_summary` surface into the doctor pipeline, enriches the canonical `Crosswake.SupportMatrix` with corridor `proof_class` / `prerequisite_classes` / `rebuild_requirement` metadata, restructures `guides/commerce.md` into three explicit layers (support truth / playbooks / non-claims), and adds a hermetic merge-blocking proof workflow with an explicit advisory placeholder lane.

Core correctness is solid — type contracts are typed, support-matrix data is hermetic, tests exercise the proof-class taxonomy explicitly, and the workflow correctly distinguishes merge-blocking from advisory lanes. No security vulnerabilities, secrets, dangerous functions, or data-loss paths were observed. The findings below cluster around three themes:

1. **Silent fallthrough on unknown corridor roles** — when a route's `commerce.role` does not match any canonical corridor entry, the doctor's `commerce_summary` surface emits `nil` / `:unknown` values without any diagnostic. This contradicts the phase's stated "fail-closed, explicit non-claims" posture.
2. **Type inconsistency for `proof_class` in finding details** — some commerce findings store `proof_class: "merge_blocking"` (string), others store `:merge_blocking` (atom), and the proof-posture mixer in `build_proof_posture/4` matches only the string form. This works today because every commerce finding the doctor emits uses the string form, but the lenient `proof_class_label/1` shape and the support-matrix mapping (which uses atoms) create a parity hazard.
3. **CI and rendering robustness** — the workflow's advisory job is pinned to `macos-15` despite running only `echo` placeholders (cost/throughput concern), and the renderer for commerce corridor rows interpolates raw strings into markdown tables without escaping the `|` character.

Defect classification: 9 WARNING, 7 INFO, 0 BLOCKER. The phase is shippable but has rough edges that the maintainer should address before promoting any of these surfaces beyond v3.2.

## Warnings

### WR-01: `commerce_summary` silently accepts unknown corridor roles instead of failing closed

**File:** `lib/crosswake/doctor/doctor.ex:548-577`
**Issue:** `commerce_corridors_summary/2` looks up each route's `commerce.role` in `corridor_entries_by_role`. When the lookup returns `nil` (role not in canonical support-matrix taxonomy), it falls through silently:

- `proof_class` → `:unknown`
- `owner_posture` → `nil` (via `entry && entry.owner_posture`)
- `native_rebuild_required` → `nil`
- `advisory_provider_proof` → `false`

There is no doctor finding emitted for this case. The JSON output (see `json_formatter.ex:43-53`) then publishes `"proof_class": "unknown"`, `"owner_posture": null`, `"native_rebuild_required": null` to downstream consumers without any signal that the data is incomplete. This contradicts the Phase 23 contract in `23-CONTEXT.md` D-04/D-08/D-10 that taxonomy parity is mandatory and that unknown/stale support truth is "fail-closed and treated as merge-blocking support truth (never informational-only)."

In practice, the existing manifest compiler likely rejects unknown corridor roles before the route reaches doctor, so this path may be unreachable today. Even so, the silent `:unknown` / `nil` fallback is a latent contract drift waiting to bite a future scope change.

**Fix:** Emit a merge-blocking commerce finding when a commerce route's role cannot be resolved against `SupportMatrix.commerce_corridor_proof_classes/0`:

```elixir
defp commerce_corridors_summary(commerce_routes, corridor_entries_by_role) do
  commerce_routes
  |> Enum.map(fn route ->
    role = route.commerce.role |> Atom.to_string()

    case Map.fetch(corridor_entries_by_role, role) do
      {:ok, entry} ->
        %{
          route_id: route.id,
          corridor_ref: route.commerce.corridor_ref,
          role: role,
          owner_posture: entry.owner_posture,
          native_rebuild_required: entry.native_rebuild_required,
          proof_class: entry.proof_class,
          advisory_provider_proof: entry.advisory_provider_proof
        }

      :error ->
        # Surfaces an explicit unknown-role corridor row AND a merge-blocking
        # finding via stale_snapshot_findings/native_rebuild_findings sibling
        # (extend phase_23_commerce_summary to emit a commerce.corridor.role_unknown
        # finding for any route landing here).
        %{
          route_id: route.id,
          corridor_ref: route.commerce.corridor_ref,
          role: role,
          owner_posture: :unknown,
          native_rebuild_required: :unknown,
          proof_class: :unknown,
          advisory_provider_proof: false
        }
    end
  end)
  |> Enum.sort_by(& &1.route_id)
end
```

Pair with a new `commerce.corridor.role_unknown` finding routed through `extra_findings` with `proof_class: "merge_blocking"`.

---

### WR-02: `entitlement_snapshot_freshness: :not_applicable` silently overrides commerce-route presence

**File:** `lib/crosswake/doctor/doctor.ex:589-597`
**Issue:** `commerce_snapshot_freshness/2` accepts `:not_applicable` from caller opts even when commerce routes exist:

```elixir
defp commerce_snapshot_freshness(_routes, freshness)
     when freshness in [:fresh, :stale, :unknown, :not_applicable],
     do: freshness
```

Per the doctor docstring (line 154-158), `:not_applicable` is meant to be the *default* when no commerce routes are declared. Allowing a caller to pass `:not_applicable` explicitly with active commerce routes silently bypasses the fail-closed `commerce.entitlement.stale_snapshot` finding — `stale_snapshot_findings(_routes, :not_applicable)` matches the catch-all and returns `[]`. This is a contract bypass: a caller who incorrectly passes `:not_applicable` will see "no stale snapshot finding" even though commerce routes are present and freshness is undeclared.

**Fix:** Reject `:not_applicable` when commerce routes are present, OR coerce it to `:unknown`:

```elixir
defp commerce_snapshot_freshness([], _opt), do: :not_applicable
defp commerce_snapshot_freshness(_routes, nil), do: :unknown
defp commerce_snapshot_freshness(_routes, :not_applicable), do: :unknown
defp commerce_snapshot_freshness(_routes, freshness)
     when freshness in [:fresh, :stale, :unknown],
     do: freshness
defp commerce_snapshot_freshness(_routes, _other), do: :unknown
```

---

### WR-03: `proof_class` value type inconsistency between support-matrix source and finding details

**File:** `lib/crosswake/doctor/doctor.ex:617-660,662-692`
**Issue:** Across the doctor pipeline, `proof_class` is stored inconsistently:

- Commerce-summary findings (`stale_snapshot_findings`, `native_rebuild_findings`): `proof_class: "merge_blocking"` (string)
- Phase 19 corridor denial findings (`commerce_denial_check` → `commerce_role_proof_class`): also string (via `Atom.to_string/1`)
- `commerce_summary.corridors[].proof_class`: `:merge_blocking` (atom, from support matrix)
- `SupportMatrix.commerce_corridor_proof_classes()` mapping: `:merge_blocking` (atom)

`build_proof_posture/4` only matches the string form (`Map.get(finding.details, :proof_class) == "merge_blocking"`). If any caller ever stores an atom in `details[:proof_class]`, that finding will silently disappear from both the `merge_blocking` and `advisory` proof_posture lists. The advisory-boundary test at `doctor_test.exs:596-599` masks this by intersecting `MapSet.new(...)` directly, which would still pass with missing entries.

`format_check_proof_class` and `proof_class_label/1` in `formatter.ex:263-267` defensively handle both atom and string forms, which suggests the codebase already knows about this inconsistency.

**Fix:** Pick one canonical form for `details[:proof_class]` (recommend atom, matching support-matrix source) and normalize at every emission site. Update `build_proof_posture` to use a helper that accepts both forms during a transition window:

```elixir
defp proof_class_eq?(value, target_atom) when is_atom(target_atom) do
  value == target_atom or value == Atom.to_string(target_atom)
end

defp build_proof_posture(commerce_routes, _corridors, _proof_class_map, extra_findings) do
  merge_blocking_extra =
    Enum.filter(extra_findings, fn finding ->
      proof_class_eq?(Map.get(finding.details, :proof_class), :merge_blocking)
    end)
  # ...
end
```

Then file a follow-up to converge on atoms everywhere.

---

### WR-04: `Renderer.commerce_corridor_row/1` does not escape `|` in interpolated strings

**File:** `lib/crosswake/support_matrix/renderer.ex:185-193`
**Issue:** The commerce corridor row template interpolates `entry.fallback_behavior`, `entry.prerequisites`, `entry.denial_codes`, and `format_rebuild_requirement(entry.rebuild_requirement)` directly into a markdown table row. If any of these strings ever contains a literal `|` character, the rendered row will silently break the markdown table column layout, and the byte-identity test (`renderer_test.exs:137-151`) will lock the broken output in place.

The same hazard exists in `capability_row/1` (`entry.fallback`, `entry.denial`), `package_surface_row/1` (`entry.why`, `entry.release_burden`), `release_boundary_row/1` (`entry.versioning`, `entry.release_rule`), and `change_class_row/1`.

Current data is hardcoded and safe, but the absence of an escape pass means any future data addition (e.g., from a future companion-published support contribution) has a foot-gun.

**Fix:** Add a single `escape_table_cell/1` helper used by every row builder:

```elixir
defp escape_table_cell(nil), do: "-"
defp escape_table_cell(value) when is_binary(value) do
  value
  |> String.replace("\\", "\\\\")
  |> String.replace("|", "\\|")
  |> String.replace("\n", " ")
end
defp escape_table_cell(value), do: escape_table_cell(to_string(value))
```

Apply it to every interpolated cell that originates from a user-controlled or future-extensible source.

---

### WR-05: `format_offline/1` ignores `telemetry` for the legacy clause, dropping fields visible in JSON

**File:** `lib/crosswake/doctor/formatter.ex:176-184`
**Issue:** Doctor always builds the offline map with `:status, :states, :telemetry, :routes` keys (see `doctor.ex:408-416`). The human-formatter pattern-matches on three of those keys and renders a one-line summary, silently dropping `telemetry.metadata_keys` and `telemetry.terminal_outcomes`. The JSON formatter renders telemetry. Operators reading human output cannot see telemetry posture without inspecting JSON.

Not a correctness defect, but the operator-facing parity between human and JSON output is broken.

**Fix:** Extend `format_offline/1` to render telemetry summary lines (metadata keys, terminal outcomes) under the existing posture line; or add an explicit `# telemetry: keys=[...] terminals=[...]` line.

---

### WR-06: Advisory CI job runs on `macos-15` with no macOS-requiring steps

**File:** `.github/workflows/phase23-proof.yml:92-145`
**Issue:** The `advisory-commerce-proof` job declares `runs-on: macos-15` (~10× the minute cost of `ubuntu-latest`) but every current step is a placeholder `echo` plus dependency setup. Weekly scheduled runs charge premium minutes for no native work.

The placement is presumably motivated by the future StoreKit simulator step, but the comment at line 115-126 acknowledges that the StoreKit step is a placeholder pending a provider-adapter milestone. Until that milestone exists, the macOS pin is pure cost.

**Fix:** Either:
1. Demote to `ubuntu-latest` until the first real macOS-required step is added; or
2. Split the job: keep the Linux-runnable advisory placeholders (Play Billing test track, generic device/storefront smoke) on `ubuntu-latest`, and reserve a separate `macos-15` job for StoreKit-only work that is `if:`-gated on the existence of the StoreKit adapter.

---

### WR-07: `merge-blocking-commerce-proof` runs on `schedule` events too, burning CI minutes

**File:** `.github/workflows/phase23-proof.yml:46-83`
**Issue:** The merge-blocking job has no `if:` guard, so every scheduled run (weekly cron on Monday 06:00 UTC) executes the full hermetic test suite on `macos-15`. The job's purpose is to gate PR merges and main pushes, not to provide periodic re-verification.

Combined with WR-06, every scheduled run pays for two macOS-15 jobs, neither of which exercises macOS-specific behavior.

**Fix:** Add a guard so the merge-blocking job only runs on the events that can drive a merge:

```yaml
merge-blocking-commerce-proof:
  if: ${{ github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}
  # ...
```

Or run the hermetic Elixir tests on `ubuntu-latest` since they don't depend on macOS toolchains.

---

### WR-08: `detail/2` helper crashes when `details` is not a map

**File:** `lib/crosswake/doctor/formatter.ex:334-336` (also `json_formatter.ex:202-204`)
**Issue:** `defp detail(details, key) when is_map(details)` has no fallback clause. If any caller passes a `%Check{}` where `details` is `nil` (the struct allows it — `details: %{}` is only the default, not `@enforce_keys`), every call to `detail/2` from `format_commerce_corridor_fields/1`, `format_check_proof_class/1`, or `check_to_map/1` will raise `FunctionClauseError`.

The `check/6` constructor inside `doctor.ex` always passes a map default, so this is defensive only. But the public `%Check{}` struct can be constructed by any caller (the doctor tests at `formatter_test.exs:62-79` build Check structs by hand), and a single `details: nil` would crash the formatter.

**Fix:** Add a nil-safe clause:

```elixir
defp detail(nil, _key), do: nil
defp detail(details, key) when is_map(details) do
  Map.get(details, key) || Map.get(details, Atom.to_string(key))
end
```

---

### WR-09: `detail/2` short-circuits on legitimate falsy values

**File:** `lib/crosswake/doctor/formatter.ex:334-336` (also `json_formatter.ex:202-204`)
**Issue:** `Map.get(details, key) || Map.get(details, Atom.to_string(key))` uses `||` falsy fallthrough, so any legitimate `false` value at the atom-keyed slot will silently fall through to the string-keyed lookup. The fields currently passed through `detail/2` are strings/atoms (proof_class, role, corridor_ref, fallback_hint, denial_code) and won't hit this — but if `advisory_provider_proof: false` ever enters `details` (it's a natural extension for the corridor metadata surface), it would be silently overridden by the string-keyed lookup.

**Fix:** Use `Map.has_key?/2` based lookup:

```elixir
defp detail(details, key) when is_map(details) do
  cond do
    Map.has_key?(details, key) -> Map.get(details, key)
    is_atom(key) and Map.has_key?(details, Atom.to_string(key)) ->
      Map.get(details, Atom.to_string(key))
    true -> nil
  end
end
```

## Info

### IN-01: Duplicate companion-requirement sentence in `guides/compatibility.md`

**File:** `guides/compatibility.md:21-22`
**Issue:** Two adjacent lines repeat the same statement with only the leading capitalization differing:

```
Package versions alone do not answer support or rebuild questions.
package versions alone do not answer support or rebuild questions.
```

The lowercased second line is almost certainly a copy/paste artifact. Reads as a typo to any reviewer.

**Fix:** Delete the second line (`package versions alone do not answer support or rebuild questions.`).

---

### IN-02: Repeated `assert content =~ "authority"` in commerce_test

**File:** `test/crosswake/guides/commerce_test.exs:19-42`
**Issue:** Lines 25 and 27 both assert `assert content =~ "authority"` inside `test "makes authority vs evidence semantics explicit for entitlement_snapshot"`. Duplicate assertion adds no coverage.

**Fix:** Delete the duplicate assertion. Consider also replacing several of the bare keyword assertions with a single regex check anchored to the section heading, to guard against false positives from unrelated occurrences elsewhere in the doc.

---

### IN-03: Unused parameters in `build_proof_posture/4`

**File:** `lib/crosswake/doctor/doctor.ex:662`
**Issue:** `build_proof_posture(commerce_routes, _corridors, _proof_class_map, extra_findings)` accepts two underscore-prefixed parameters that are never used. Both `_corridors` and `_proof_class_map` are computed earlier in `phase_23_commerce_summary/2` and threaded through this call. Either the caller should stop computing them, or the function should consume them.

**Fix:** Either drop the parameters from the function signature (and stop passing them at the call site, doctor.ex:535) or use them — e.g., use `proof_class_map` instead of re-fetching `SupportMatrix.commerce_corridor_proof_classes()` inside `base_advisory` (line 681), which would also remove a redundant module-attribute round-trip per call.

---

### IN-04: Unused `_proof_class_map` already computed but re-fetched inside `build_proof_posture`

**File:** `lib/crosswake/doctor/doctor.ex:517,662,681`
**Issue:** `phase_23_commerce_summary/2` computes `proof_class_map = SupportMatrix.commerce_corridor_proof_classes()` at line 517 and passes it as `_proof_class_map` to `build_proof_posture/4` (line 535). Inside that function (line 681), `SupportMatrix.commerce_corridor_proof_classes()` is called again. Either compute once, or use the passed parameter.

**Fix:** Replace `SupportMatrix.commerce_corridor_proof_classes()` in `base_advisory` with the parameter, and rename `_proof_class_map` → `proof_class_map`.

---

### IN-05: `format_offline/1` legacy clause silently masks shape change

**File:** `lib/crosswake/doctor/formatter.ex:176-186`
**Issue:** The current `format_offline/1` clause expects exactly `:status, :states, :routes`. If the doctor ever stops emitting `:telemetry` (or the field is renamed), nothing here changes — the renderer keeps emitting the legacy one-line format. The `format_offline(_offline)` fallback at line 186 returns `nil`, hiding shape drift silently. Cross-references WR-05.

**Fix:** Add an explicit `format_offline(other) when is_map(other)` clause that logs a warning or asserts on the expected fields. Alternatively, accept the full `{status, states, telemetry, routes}` shape in the primary clause and render telemetry inline.

---

### IN-06: Pre-existing test failure for `mix crosswake.doctor` JSON contract not fixed in scope

**File:** `lib/crosswake/doctor/json_formatter.ex:180-189` (and see `.planning/phases/23-commerce-support-and-proof-closure/deferred-items.md` item 1)
**Issue:** The new `commerce.corridor.native_rebuild_required` finding emitted by `native_rebuild_findings/2` carries the same `corridor_ref`, `role`, `denial_code`, `fallback_hint` data as a corridor denial — but in `details`, not at the JSON top level. The pre-existing assertion in `test/mix/tasks/crosswake_doctor_test.exs` ("mix crosswake.doctor json output serializes commerce corridor fields") was deferred per `deferred-items.md`. Phase 23 introduced the finding without aligning the JSON schema, so any downstream tooling that consumed the legacy contract for "every JSON finding with code starting `commerce.corridor.*` has top-level `corridor_ref` / `role` / `denial_code` / `fallback_hint`" now breaks.

The `if String.starts_with?(check.code, "commerce.corridor.") and check.check == "commerce_corridor"` at line 180 explicitly excludes the new `commerce_summary` check, which is why the schema diverges.

**Fix:** Either widen the JSON formatter promotion to also lift top-level keys for `commerce_summary` findings whose codes start with `commerce.corridor.`, or update the pre-existing test contract — but do not leave the JSON shape inconsistent across two finding codes that share the same family prefix.

---

### IN-07: Inconsistent `String.starts_with?(code || "", ...)` defensive guard

**File:** `lib/crosswake/doctor/formatter.ex:302,324` and `lib/crosswake/doctor/json_formatter.ex:180,193`
**Issue:** `commerce_check?/2` (both formatters) uses `String.starts_with?(code || "", "commerce.")` defensively, but `format_commerce_corridor_fields/1` at `formatter.ex:324` and `check_to_map/1` at `json_formatter.ex:180` use `String.starts_with?(check.code, "commerce.corridor.")` without the same `|| ""` guard. The `Check` struct's `@enforce_keys` guarantees `code` is non-nil, so neither path can crash today — but the inconsistency reads as accidental and will trip whoever next loosens the Check contract.

**Fix:** Pick one form. Since `@enforce_keys` already guarantees `code != nil`, drop the `|| ""` guards in `commerce_check?/2` for symmetry; or add the guard at every site.

---

## Fixes Applied

Applied 2026-05-27 by gsd-code-fixer. All 9 WARNING findings addressed; INFO findings deferred to a follow-on pass. Each fix committed atomically. Verification ran `mix test test/crosswake/doctor/ test/crosswake/support_matrix/ test/crosswake/guides/ test/crosswake/proof/phase23_commerce_support_proof_test.exs test/mix/tasks/crosswake_doctor_test.exs` after every fix (96 baseline → 101 final tests, 0 failures throughout).

| Finding | Commit | Summary |
|---------|--------|---------|
| WR-01 | `6a60281` | Fail-closed `commerce.corridor.role_unknown` finding plus explicit `:unknown` corridor row when a commerce route role is not in canonical SupportMatrix taxonomy. Regression test asserts canonical fixtures never trigger the finding. |
| WR-02 | `0d6bc52` | Coerce `entitlement_snapshot_freshness: :not_applicable` → `:unknown` when commerce routes are present, so the merge-blocking `commerce.entitlement.stale_snapshot` finding still fires. Locked by regression test. |
| WR-03 | `cc86ac0` | Added `proof_class_eq?/2` helper in `build_proof_posture/4` that matches both atom and string `proof_class` forms, closing the silent-disappearance hazard if a caller stores `:merge_blocking` instead of `"merge_blocking"`. |
| WR-04 | `4bd8900` | Added `escape_cell/1` helper in `Crosswake.SupportMatrix.Renderer` and applied it to every interpolated cell across `row/0`, `capability_row/0`, `package_surface_row/0`, `commerce_corridor_row/0`, `release_boundary_row/0`, `change_class_row/0`, `format_list/1`, and `format_rebuild_requirement/1`. Byte-identity for `guides/support_matrix.md` preserved (no current canonical value contains `\|`, `\\`, or newlines). |
| WR-05 | `b2eef19` | Extended `format_offline/1` to render telemetry summary line (`  telemetry: metadata_keys=[...] terminal_outcomes=[...]`) so human output matches JSON output. Legacy three-key clause kept as fallback. |
| WR-06 | `c5f69b5` | Demoted `advisory-commerce-proof` job from `macos-15` to `ubuntu-latest` until a real macOS-required step lands. Comment documents the split-job pattern for future StoreKit adapter work. |
| WR-07 | `6ba0414` | Added `if:` guard restricting `merge-blocking-commerce-proof` to `pull_request`, `push`, and `workflow_dispatch` events. Scheduled weekly runs no longer re-execute the merge gate (zero signal, premium minute cost). |
| WR-08 | `44b1d79` | Added `defp detail(nil, _key), do: nil` clause in both `Crosswake.Doctor.Formatter` and `Crosswake.Doctor.JSONFormatter` so a `%Check{details: nil}` no longer raises `FunctionClauseError`. Locked by a nil-details fixture test. |
| WR-09 | `826e90d` | Replaced `Map.get(...) \|\| Map.get(...)` form of `detail/2` with `Map.has_key?/2`-based lookup in both formatters so legitimate falsy values (e.g. `advisory_provider_proof: false`) are preserved instead of falling through to the string-keyed slot. Locked by a `fallback_hint: false` regression test. |

### Deferred to a Follow-on Pass (7 INFO findings)

Per fix scope (WARNING only), the following INFO findings remain in this REVIEW.md unchanged and should be addressed by a subsequent `/gsd:code-review --fix --include-info` pass or by hand: IN-01, IN-02, IN-03, IN-04, IN-05, IN-06, IN-07.

IN-06 in particular cross-references a pre-existing test failure already logged in `deferred-items.md` (item 1) and may merit a dedicated commit if the JSON schema decision is made to widen rather than narrow.

---

_Reviewed: 2026-05-27T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
_Fixed: 2026-05-27 (WARNING findings only) by gsd-code-fixer_
