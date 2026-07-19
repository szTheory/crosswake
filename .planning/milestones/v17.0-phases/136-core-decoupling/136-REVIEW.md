---
phase: 136-core-decoupling
reviewed: 2026-07-01T18:30:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/crosswake/companions/sigra.ex
  - lib/crosswake/companions/chimeway.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - mix.exs
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: needs-attention
---

# Phase 136: Code Review Report

**Reviewed:** 2026-07-01T18:30:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** needs-attention

## Summary

Reviewed the four Phase 136-06 gap-closure source files: the new `Crosswake.Companions.Sigra`
companion facade, the extended `Crosswake.Companions.Chimeway` facade, the updated
`SupportMatrix.auth_contract_truth/0`, and the `mix.exs` application env registration. The
core decoupling mechanism is sound — no `compile_env` violations, no static core→companion
references outside `lib/crosswake/companions/**`, Denial passthrough is unchanged, and the
BEAM module-loading guard in `auth_contract_truth/0` is correctly applied.

Three warnings require attention before Phase 137:

1. **auth_contract_truth/0 does not filter disabled companions** when scanning for the auth
   authority, creating a semantic divergence from RouteGate that could cause a disabled Sigra
   to be treated as the auth authority in the support matrix while RouteGate would see
   `:dependency_missing`.

2. **build_reserved_events/0 (telemetry.ex) uses a bare-pattern match** `%{tier: tier}` that
   will raise a `MatchError` at runtime if any companion's `telemetry_events/0` returns maps
   lacking a `:tier` key — the Phase 136 facades are correct, but the guard is fragile for
   future companions.

3. **Map.from_struct/1 on Evaluator.Result exposes the internal `:denial` field** to callers
   of `evaluate_auth/3` on the allow branch. The behaviour contract says `{:allow, map()}` is
   opaque but `Result.denial` is always `nil` on allow, so it is dead weight in the public
   map; more importantly, the field name clashes with shell-facing denial vocabulary, which is
   a future confusion hazard.

---

## Warnings

### WR-01: auth_contract_truth/0 skips enabled? check — diverges from RouteGate's auth-authority selection

**File:** `lib/crosswake/support_matrix/support_matrix.ex:731-734`

**Issue:** `auth_contract_truth/0` selects the auth-authority companion with:

```elixir
Enum.find(companions, fn mod ->
  _load = mod.companion_id()
  function_exported?(mod, :auth_authority?, 0) and mod.auth_authority?()
end)
```

RouteGate's `prepend_auth_evaluation_denials/4` uses:

```elixir
Enum.filter(fn companion ->
  config = Application.get_env(:crosswake, companion.companion_id(), %{})
  companion.enabled?(config) and
    function_exported?(companion, :auth_authority?, 0) and
    companion.auth_authority?()
end)
```

`auth_contract_truth/0` omits `companion.enabled?(config)`. This means that when Sigra is
disabled (`:enabled false` in the `:sigra` application env), `auth_contract_truth/0` will
still find Sigra as the auth authority and return fully-populated `denial_codes`,
`telemetry.event_names`, etc., while RouteGate will find zero auth authorities and fail
closed with `:dependency_missing`. The support matrix then claims Sigra auth data is live
while the gate is actually inoperative — a misleading operator/doctor signal in exactly the
failure scenario where accurate diagnosis matters most.

**Fix:** Mirror RouteGate's enabled? guard in `auth_contract_truth/0`:

```elixir
auth_authority =
  Enum.find(companions, fn mod ->
    _load = mod.companion_id()
    config = Application.get_env(:crosswake, mod.companion_id(), %{})
    mod.enabled?(config) and
      function_exported?(mod, :auth_authority?, 0) and
      mod.auth_authority?()
  end)
```

Apply the same guard to the `denial_codes` flat_map scan for consistency.

---

### WR-02: build_reserved_events/0 bare-pattern match on %{tier: tier} will crash on tierless maps

**File:** `lib/crosswake/telemetry.ex:182`

**Issue:** The filter inside `build_reserved_events/0` is:

```elixir
|> Enum.filter(fn %{tier: tier} -> tier == :reserved end)
```

This is a bare map-pattern destructure. If any future companion's `telemetry_events/0`
returns a map that lacks the `:tier` key, Elixir will raise a `FunctionClauseError` (no
matching function clause) rather than returning `false`. The Phase 136 facades always include
`tier: :reserved`, so this is not a current runtime failure — but the pattern is fragile and
will crash silently inside a `flat_map` for any companion that forgets the field.

This file (`lib/crosswake/telemetry.ex`) is not in the Phase 136-06 file scope, but the
Sigra and Chimeway facades in scope directly feed this path, and the plan explicitly
identifies `build_reserved_events/0` as a contract the facades must satisfy. The fragility
is most acutely exposed by Phase 136 code.

**Fix:** Use a defensive match with a default:

```elixir
|> Enum.filter(fn event -> Map.get(event, :tier) == :reserved end)
```

or, if a hard crash on malformed companion output is preferable:

```elixir
|> Enum.filter(fn
  %{tier: :reserved} -> true
  %{tier: _other}    -> false
  _missing_tier      ->
    Logger.warning("[crosswake] telemetry_events/0 returned a map with no :tier key: #{inspect(event)}")
    false
end)
```

---

### WR-03: Map.from_struct/1 on Evaluator.Result leaks the :denial field into the public {:allow, map()} tuple

**File:** `lib/crosswake/companions/sigra.ex:84`

**Issue:** `evaluate_auth/3` converts an allow result with:

```elixir
{:allow, %Evaluator.Result{} = result} ->
  {:allow, Map.from_struct(result)}
```

`Evaluator.Result` is `defstruct [:status, :denial, facts: %{}]`. On the allow branch,
`result.denial` is always `nil` (the Evaluator only populates `denial` internally as an
intermediate before constructing `Denial.new/1`; the allow path returns
`%Result{status: :allow, facts: %{...}}`). `Map.from_struct/1` produces
`%{__struct__: ..., status: :allow, denial: nil, facts: %{...}}` — wait, actually
`Map.from_struct/1` strips `__struct__` but retains all other fields, so the returned map is
`%{status: :allow, denial: nil, facts: %{...}}`.

The concrete issues:
- The `:denial` key (value `nil`) is exposed to RouteGate and any host consumer of the allow
  result. The behaviour contract says `{:allow, map()}` is opaque, so no consumer should
  depend on this key — but advertising a field named `:denial` in an `:allow` response is
  semantically misleading and will create confusion during Phase 137 when this surface is
  audited.
- `__struct__` is NOT in the output of `Map.from_struct/1` (it only removes `__struct__`
  by design), so there is no struct-atom leak — that part is fine.

**Fix:** Explicitly project only the semantically meaningful fields:

```elixir
{:allow, %Evaluator.Result{status: status, facts: facts}} ->
  {:allow, %{status: status, facts: facts}}
```

This keeps the public map clean, avoids leaking `denial: nil`, and is resilient to future
`Result` struct additions.

---

## Info

### IN-01: Sigra facade's companion_id/0 used as a BEAM load side-effect — implicit coupling

**File:** `lib/crosswake/support_matrix/support_matrix.ex:732`

**Issue:** The BEAM module-loading guard in `auth_contract_truth/0` uses:

```elixir
_load = mod.companion_id()
```

This works correctly today — calling any function on the module triggers the BEAM loader —
but it silently couples the load trigger to the specific `companion_id/0` callback name. If
a future companion interface refactor renames or makes `companion_id/0` optional, this line
could revert to the false-negative `function_exported?` bug without a compilation error. The
SUMMARY correctly notes this mirrors the RouteGate pattern, but neither site documents
**why** `companion_id/0` specifically is used rather than, say, `Code.ensure_loaded!/1`.

**Fix:** Consider replacing the implicit pattern with an explicit load call for clarity:

```elixir
_ = Code.ensure_loaded!(mod)
function_exported?(mod, :auth_authority?, 0) and mod.auth_authority?()
```

`Code.ensure_loaded!/1` raises on failure (boot-time bug surfacing), signals intent, and
does not rely on a particular callback being present. Since `companion_id/0` is a required
callback this is a low-risk practical concern, but the explicit form is clearer.

---

_Reviewed: 2026-07-01T18:30:00Z_
_Reviewer: Claude (adversarial standard-depth review)_
_Depth: standard_
