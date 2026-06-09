---
phase: 91-identity-telemetry-contract
reviewed: 2026-06-09T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/crosswake/bridge/contract.ex
  - lib/crosswake/bridge/denial.ex
  - lib/crosswake/shell/activation.ex
  - lib/crosswake/threadline/telemetry.ex
  - mix.exs
  - test/crosswake/bridge/contract_test.exs
  - test/crosswake/proof/phase91_threadline_contract_closeout_test.exs
  - test/crosswake/shell/activation_test.exs
  - test/crosswake/threadline/telemetry_test.exs
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# Phase 91: Code Review Report

**Reviewed:** 2026-06-09T00:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 91 adds the `thread_id` correlation field to the four bridge/activation
envelope structs, bumps the bridge contract version to 1.1.0, and introduces the
`Crosswake.Threadline.Telemetry` contract (event-name allowlist + PII-free
metadata allowlist/denylist guard). The envelope/`thread_id` plumbing is correct
and well-tested: round-trip, nil-omission, and from-request propagation are all
covered.

No security vulnerabilities or crash-on-input defects were found. The telemetry
PII denylist works as documented and is verified by tests.

However, the review surfaced a confirmed logic bug in commerce-corridor denial
enrichment (`failing_moment` overwritten with the role value), a defense-in-depth
gap in the telemetry emitter (`execute/3` bypasses the event-name allowlist it
documents), and a dead fallback branch in `Activation.resolve` whose
`:reasons`-key lookup can never succeed against the actual `RouteGate.Decision`
struct. None rise to BLOCKER because none corrupt the `thread_id` contract that is
this phase's deliverable, but the `failing_moment` bug ships incorrect diagnostic
data to operators and should be fixed.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: `enrich_commerce_corridor_denial` overwrites `failing_moment` with the role value

**File:** `lib/crosswake/shell/activation.ex:258`
**Issue:** The enrichment pipeline sets:

```elixir
|> maybe_put(:failing_moment, route_commerce && route_commerce.role)
```

`route_commerce.role` (e.g. `:purchase_intent`) is a commerce *role*, not a
*moment*. The constructor `Crosswake.Shell.Denial.new(reason: :commerce_corridor)`
deliberately seeds `details` with `%{failing_moment: :commerce_route_activation}`
(`lib/crosswake/shell/denial.ex:89`). Because `maybe_put` writes whenever the
value is non-nil, this enrichment step *clobbers* the meaningful
`:commerce_route_activation` moment with the role — and `:role` is already set to
the identical value on line 257. This is a copy/paste error: the line duplicates
`:role` under a second key and destroys the intended `failing_moment`. Operators
consuming the denial map get a corrupted/duplicated diagnostic. The
activation test (`activation_test.exs:378-382`) only asserts on `corridor_ref`,
`role`, `recovery.fallback`, and `recovery.actions`, so it does not catch this.

**Fix:** Either drop the line entirely (the constructor already supplies
`failing_moment`), or set a genuine moment value rather than the role:

```elixir
# preserve the constructor-seeded moment; do not overwrite with role
details =
  denial.details
  |> maybe_put(:corridor_ref, route_commerce && route_commerce.corridor_ref)
  |> maybe_put(:role, route_commerce && route_commerce.role)
  |> maybe_put(:failing_prerequisite, failing_prerequisite(denial))
  # removed: maybe_put(:failing_moment, route_commerce && route_commerce.role)
```

Add a regression assertion that `denial.details[:failing_moment] ==
:commerce_route_activation` after enrichment.

### WR-02: `Telemetry.execute/3` does not enforce the event-name allowlist it documents

**File:** `lib/crosswake/threadline/telemetry.ex:130-133`
**Issue:** The module moduledoc and `@event_names` declare a "low-cardinality
event-name allowlist," and `new_event/1` raises `ArgumentError` on an unknown
name. But the actual emission path, `execute/3`, calls `:telemetry.execute(name,
...)` with no `valid_event_name?/1` guard:

```elixir
def execute(name, measurements \\ %{}, metadata \\ %{}) do
  :telemetry.execute(name, measurements, metadata(metadata))
end
```

A caller can emit `[:crosswake, :threadline, :anything, :foo]` (or any list),
defeating the cardinality bound the module exists to guarantee. The metadata
allowlist is enforced; the event-name allowlist is not. This is an enforcement
asymmetry, not just style — the contract is only as strong as its weakest gate.

**Fix:** Validate before emitting (or document explicitly that `execute/3` is the
unchecked fast path and steer callers to a checked variant):

```elixir
def execute(name, measurements \\ %{}, metadata \\ %{}) do
  unless valid_event_name?(name) do
    raise ArgumentError, "unknown Threadline telemetry event name: #{inspect(name)}"
  end

  :telemetry.execute(name, measurements, metadata(metadata))
end
```

### WR-03: Dead fallback branch in `denial_from_gate` looks up a `:reasons` key that never exists

**File:** `lib/crosswake/shell/activation.ex:219-239` (specifically line 228)
**Issue:** `denial_from_gate/3` builds a fallback denial with
`details: %{reasons: Map.get(decision, :reasons, [])}`. The `decision` here is a
`Crosswake.Compatibility.RouteGate.Decision` struct whose fields are
`[:route_id, :status, :denial, denials: [], transition: :activate]`
(`route_gate.ex:14-26`) — there is no `:reasons` key, so `Map.get(decision,
:reasons, [])` is always `[]`. Worse, the entire `denial_from_gate` function is
effectively unreachable: `RouteGate.evaluate` always sets `denial: List.first(denials)`
to a non-nil `Denial` whenever `status == :deny` (`route_gate.ex:56-62`), and
`resolve/2` only calls `denial_from_gate` via `Map.get(decision, :denial) ||
denial_from_gate(...)` (line 112). Since `:denial` is never nil on a deny, the
fallback never runs. This is dead code carrying a latent wrong-key bug that would
silently produce `reasons: []` if the path ever did execute (e.g. after a future
RouteGate refactor).

**Fix:** Either remove `denial_from_gate/3` and the `||` fallback (trusting
RouteGate's invariant), or — if defensive fallback is intended — read the real
field: `details: %{reasons: Map.get(decision, :denials, [])}` and add a test that
exercises the nil-denial path so it stops being dead.

### WR-04: `Telemetry.Event` typespec omits four of the struct's five fields

**File:** `lib/crosswake/threadline/telemetry.ex:64-71`
**Issue:** The `Event` struct defines five fields
(`[:name, :thread_id, :correlation_id, :route_id, :source]`) but the typespec
declares only one:

```elixir
@type t :: %__MODULE__{name: [atom()]}
```

Under Elixir's struct-type semantics, `%__MODULE__{name: [atom()]}` constrains
only `:name` and leaves the rest as `term()`, so this is not a hard error, but it
misrepresents the contract to Dialyzer and to readers, and undercuts the
"typed contract" intent of the module. `metadata/1` and `new_event/1` both rely on
the metadata fields being present.

**Fix:** Complete the typespec:

```elixir
@type t :: %__MODULE__{
        name: [atom()],
        thread_id: String.t() | nil,
        correlation_id: String.t() | nil,
        route_id: String.t() | nil,
        source: atom() | nil
      }
```

## Info

### IN-01: `safe_value?/1` silently drops negative integers with no documentation

**File:** `lib/crosswake/threadline/telemetry.ex:149`
**Issue:** `safe_value?(value) when is_integer(value) and value >= 0` accepts only
non-negative integers; a negative integer for an allowlisted key is dropped with
no trace. The current allowlisted keys (`thread_id`, `correlation_id`, `route_id`,
`source`) are strings/atoms in practice, so this is latent, but the asymmetry is
surprising and undocumented.
**Fix:** Either accept all integers (`is_integer(value)`) if the `>= 0` constraint
is not intentional, or add an inline comment explaining why negatives are
considered unsafe.

### IN-02: `failing_prerequisite/1` and `default_corridor_actions/0` encode magic atoms inline

**File:** `lib/crosswake/shell/activation.ex:260-291`
**Issue:** Recovery atoms (`:return_to_phoenix_guidance`,
`:declare_corridor_or_disable_commerce_route`) are duplicated across
`enrich_commerce_corridor_denial`, `default_corridor_actions/0`, and
`failing_prerequisite/1`, and the same pair is independently re-declared in
`Crosswake.Shell.Denial.ensure_commerce_corridor_payload/3`
(`denial.ex:96-99`). Two modules now own the same recovery vocabulary, risking
drift.
**Fix:** Centralize the corridor recovery action atoms in one module (e.g.
`Crosswake.Shell.Denial`) and reference them from `Activation`.

### IN-03: `Atom.to_string(value)` not applied in telemetry `to_map/1` values

**File:** `lib/crosswake/threadline/telemetry.ex:121-128`
**Issue:** `to_map/1` stringifies keys but leaves values as-is, so `:source =>
:inbound` serializes to `%{"source" => :inbound}` (atom value under a string key).
Every other `to_map/1` in this phase (`contract.ex`, `denial.ex`,
`activation.ex`) consistently calls `Atom.to_string/1` on atom *values*
(e.g. `"status" => Atom.to_string(reply.status)`). The telemetry variant is
inconsistent and will not JSON-encode `:source` to a string without further
processing.
**Fix:** Normalize atom values during the map build, mirroring the sibling
modules: `{Atom.to_string(key), maybe_stringify(value)}`.

### IN-04: `@version "1.1.0"` (bridge contract) vs `@version "0.1.1"` (mix) — verify changelog coverage

**File:** `lib/crosswake/bridge/contract.ex:10` and `mix.exs:4`
**Issue:** The bridge protocol/contract version was bumped to `1.1.0` for this
phase, while the package `@version` is `0.1.1`. These are intentionally distinct
version axes (wire protocol vs. hex package), but the package version was not
bumped alongside a wire-contract change, and the closeout test only asserts the
contract version. Confirm `CHANGELOG.md` documents the `1.1.0` bridge contract
change and that consumers can distinguish the two version axes.
**Fix:** Documentation/changelog check only — no code change required if the
distinction is intended and recorded.

---

_Reviewed: 2026-06-09T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
