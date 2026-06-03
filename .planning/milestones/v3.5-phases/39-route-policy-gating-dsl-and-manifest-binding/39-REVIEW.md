---
phase: 39-route-policy-gating-dsl-and-manifest-binding
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/crosswake/manifest/builder.ex
  - lib/crosswake/manifest/types.ex
  - lib/crosswake/policy/route.ex
  - lib/crosswake/policy/schema.ex
  - test/crosswake/proof/phase39_route_policy_gating_test.exs
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 39: Code Review Report

**Reviewed:** 2026-05-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 39 adds the `gated_by` / `on_unavailable` DSL keys to route policy and threads
the compiled binding through to the manifest `RouteEntry`. The core logic is sound: the
atom-identifier validator, the cross-key constraint (gated_by required when
on_unavailable is set; default-to-deny when gated_by set without on_unavailable), and
the nil-omission in `to_map/1` are all correctly implemented.

Four warnings were found — none are blockers, but two (WR-01, WR-02) affect correctness
under edge cases that are realistic at call-site.

---

## Warnings

### WR-01: `Enum.zip/2` silently truncates when `routes` and `managed_routes` lengths differ

**File:** `lib/crosswake/manifest/builder.ex:117`

**Issue:** `Enum.zip(routes, managed_routes)` stops at the shorter list without error.
If the two lists ever diverge in length (programming error at a call-site, or a future
refactor that passes a filtered `managed_routes` list), routes at the tail of the longer
list are silently dropped. This produces a manifest with fewer routes than declared,
with no warning, no crash, and no observable signal at build time.

**Fix:** Add a length assertion before the zip, or use `Enum.zip_with/3` with an
explicit crash on mismatch:

```elixir
defp route_entries(routes, managed_routes, origin) do
  if length(routes) != length(managed_routes) do
    raise ArgumentError,
      "routes/managed_routes length mismatch: #{length(routes)} vs #{length(managed_routes)}"
  end

  routes
  |> Enum.zip(managed_routes)
  |> Map.new(fn {%Route{} = route, managed_route} -> ... end)
end
```

---

### WR-02: `nil` branch of `validate_on_unavailable/1` is unreachable via the NimbleOptions schema, masking a schema type gap

**File:** `lib/crosswake/policy/schema.ex:156`

**Issue:** The NimbleOptions schema entry for `on_unavailable` (line 77–80) uses
`type: {:custom, __MODULE__, :validate_on_unavailable, []}` with no `default:` key.
NimbleOptions does not inject a default for custom types when the key is absent — it
passes the key through as absent rather than calling the validator with `nil`. The
`validate_on_unavailable(nil)` clause therefore only fires if the caller explicitly
passes `on_unavailable: nil`. The expected default of `nil` for a non-gated route
is supplied downstream by `validate_gating_posture/1` in `Route`, not by the schema.
This is not a bug today, but it creates a latent trap: any caller who uses
`Schema.validate/1` directly (bypassing `Route.new/1`) will receive a validated
keyword list that simply omits `:on_unavailable`, and a subsequent `struct!/2` call
will default the field to `nil` from the struct definition — which happens to be
correct, but only by accident. The spec signature `{:ok, :deny | {:fallback_phoenix, atom()} | nil}` advertises `nil` as a valid return, yet the schema does not enforce it
consistently.

**Fix:** Add `default: nil` to the `on_unavailable` schema entry so the contract is
explicit and the validator is exercised on the canonical absent-key path:

```elixir
on_unavailable: [
  type: {:custom, __MODULE__, :validate_on_unavailable, []},
  default: nil,
  type_spec: quote(do: :deny | {:fallback_phoenix, atom()} | nil)
]
```

---

### WR-03: `Mix.Project.config/0` called at runtime in library code

**File:** `lib/crosswake/manifest/builder.ex:62`, `lib/crosswake/manifest/types.ex:969`

**Issue:** Both files call `Mix.Project.config()` at runtime (inside function bodies,
not at compile time via `@` module attributes). `Mix` is not available in a compiled
release (`mix` is a build tool, not part of the runtime OTP app). This will raise
`** (UndefinedFunctionError) function Mix.Project.config/0 is undefined` in any
production release that calls `build/3` without explicitly providing
`:crosswake_version` / `:phoenix_version` / `:live_view_version` opts.
`builder.ex` has a `|| "dev"` guard that limits the blast radius for
`crosswake_version`, but `types.ex:969` (`dependency_requirement/1`) has no guard
and will hard-crash.

**Fix:** Read the values at compile time using module attributes, or require callers to
supply them explicitly (the `opts` keyword path already exists). For the common case,
capture the version at compile time:

```elixir
# In types.ex — read once at compile time, safe in releases
@phoenix_requirement (Mix.Project.config()
                      |> Keyword.fetch!(:deps)
                      |> Enum.find_value(fn
                           {:phoenix, r} when is_binary(r) -> r
                           _ -> nil
                         end))
```

Or gate the call behind an `if Code.ensure_loaded?(Mix)` guard with a safe fallback.

---

### WR-04: `validate_commerce_declaration/1` does not reject an empty-string corridor

**File:** `lib/crosswake/policy/schema.ex:193-199`

**Issue:** `validate_optional_identifier/1` delegates to `validate_identifier/1`, which
accepts any binary with `byte_size(value) > 0`. However `validate_commerce_declaration`
then passes the validated corridor through to the route, and
`route_commerce/1` in `builder.ex` (line 212) pattern-matches
`when is_binary(corridor)` with no additional emptiness check. A corridor value like
`" "` (a single space) would pass all validation and be serialized into the manifest as
a non-empty, nonsensical corridor reference. The `validate_identifier` function itself
does not strip or check for whitespace-only strings.

**Fix:** Add a whitespace-only guard to `validate_identifier/1` or to the corridor path
specifically:

```elixir
def validate_identifier(value) when is_binary(value) do
  if String.trim(value) == "" do
    {:error, "expected a non-empty string (whitespace-only strings are not valid)"}
  else
    {:ok, value}
  end
end
```

---

## Info

### IN-01: Unused variable `struct_keys` bound on line 269 of proof test

**File:** `test/crosswake/proof/phase39_route_policy_gating_test.exs:269`

**Issue:** `struct_keys = Map.from_struct(route) |> Map.keys()` is assigned and then
re-computed inline on lines 271, 274, 277 via `Map.from_struct(route)` rather than
using the bound variable. The bound `struct_keys` is only used on lines 281–282. The
Elixir compiler will emit an `unused variable` warning for `struct_keys` in some
versions, and the redundant `Map.from_struct/1` calls are wasted work. Not a
correctness issue, but it undermines test clarity.

**Fix:** Either use `struct_keys` consistently for all four checks, or remove the
intermediate binding and inline all checks with the same expression:

```elixir
struct_keys = Map.from_struct(route) |> Map.keys()
refute :gated_by_value in struct_keys, "..."
refute :gate_enabled in struct_keys, "..."
refute :flag_state in struct_keys, "..."
assert :gated_by in struct_keys
assert :on_unavailable in struct_keys
```

---

### IN-02: `acc ++ [normalized]` in `reduce_while` accumulators — linear append in a loop

**File:** `lib/crosswake/policy/schema.ex:211`, `lib/crosswake/policy/schema.ex:226`

**Issue:** Both `validate_pack_requirements/1` and `validate_transfer_declarations/1`
accumulate results with `acc ++ [normalized]`, which copies the entire accumulator list
on each iteration. For typical route declarations (small lists of packs/transfers) this
is harmless, but the pattern is an anti-idiomatic Elixir accumulation that also
diverges from the project's own convention elsewhere.

**Fix:** Accumulate with prepend and reverse at the end (standard Elixir idiom):

```elixir
{:cont, {:ok, [normalized | acc]}}
# then after reduce_while:
|> case do
  {:ok, list} -> {:ok, Enum.reverse(list)}
  error -> error
end
```

---

_Reviewed: 2026-05-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
