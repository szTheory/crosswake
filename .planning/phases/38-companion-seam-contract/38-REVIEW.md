---
phase: 38-companion-seam-contract
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/crosswake/companion.ex
  - lib/crosswake/companion/state.ex
  - mix.exs
  - lib/crosswake/doctor/doctor.ex
  - test/support/stub_companion.ex
  - test/crosswake/proof/phase38_companion_contract_test.exs
findings:
  critical: 1
  warning: 2
  info: 2
  total: 5
status: issues_found
---

# Phase 38: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 38 delivers a clean behaviour/struct/telemetry seam. The contract surface (`Crosswake.Companion`, `Crosswake.Companion.State`, and the telemetry dep declaration) is well-formed: enforce_keys are correct, typespecs are closed, the `{:deny, Finding.t()} | :pass` return is properly typed, and the alias block is exhaustive. The doctor wiring is architecturally sound and the fail-closed `:error` path for enabled+missing companions is correctly implemented and wired into `Report.status`.

One bug reaches blocker severity: the proof test declares `async: true` while two of its tests write to the same global Application env key (`{:crosswake, :companions}`). These tests can interleave under parallel execution, causing either test to observe the wrong companion list, making SC#2 and SC#4 flaky. Two warnings address a misleading doc string and a silent-but-unspecified case in the doctor. Two info items are minor quality notes.

`lib/crosswake/commerce.ex` is untouched (D-12 satisfied).

## Critical Issues

### CR-01: `async: true` with shared `Application.put_env` — race condition in SC#2 and SC#4

**File:** `test/crosswake/proof/phase38_companion_contract_test.exs:23,145,202`

**Issue:** The test module uses `use ExUnit.Case, async: true`, which allows its tests to run concurrently with each other. SC#2 (line 145) and SC#4 (line 202) both call `Application.put_env(:crosswake, :companions, [...])` on the same global application-env key, then call `Doctor.run/1`, which reads that key via `Application.get_env(:crosswake, :companions, [])`. `Application` env is a global OTP process state (`persistent_term`-backed in OTP 27+ or `:application` controller state in earlier versions) — it is NOT isolated per test process.

If SC#2 and SC#4 run concurrently:
- SC#2 sets `:companions` to `[BrokenCompanion]` and calls `Doctor.run/1`. If SC#4's `put_env` to `[StubCompanion]` wins between the `put_env` and `Doctor.run` in SC#2, the doctor will find `:ok` from StubCompanion and emit **no** `companion.dependency_missing` finding, causing SC#2 to fail its `assert finding != nil`.
- SC#4's telemetry assertion could similarly observe the wrong companion or miss the event entirely.

This is a real flakiness risk: the suite currently passes because of favorable scheduling, but will fail intermittently under load or BEAM scheduler variability. The pattern is unique to this test file — no other proof test in the codebase uses `Application.put_env` at all.

**Fix:** Drop `async: true` (or change to `async: false`) on this module. The test writes and reads global mutable OTP state; it cannot safely run concurrently with itself:

```elixir
# line 23 — change:
use ExUnit.Case, async: true
# to:
use ExUnit.Case, async: false
```

Alternatively, if async execution is important for suite speed, inject the companion list through a `Doctor.run/1` option (e.g. `companions:`) instead of `Application.put_env`, so each test operates on local data. That would require a one-line change to `phase_38_companion_seam_findings/0` to accept an optional override, but preserves the `async: true` design.

## Warnings

### WR-01: `@moduledoc` says "at compile time" for a key that is read at runtime

**File:** `lib/crosswake/companion.ex:18`

**Issue:** The `@moduledoc` instructs host app authors to "Register companions at compile time in your host application config" and shows `config :crosswake, :companions, [...]`. However, `phase_38_companion_seam_findings/0` deliberately reads this value via `Application.get_env/3` (runtime) rather than `Application.compile_env/3` — specifically so the proof test can observe `put_env` registrations without recompiling. The phrase "at compile time" is therefore technically inaccurate and will confuse hosts who write `Application.compile_env!(:crosswake, :companions)` in their code expecting it to work the same way. It also implies the list is frozen at compile time, which contradicts the runtime-read design.

**Fix:** Replace "compile time" with "runtime" (or drop the qualifier):

```elixir
# current (line 18):
Register companions at compile time in your host application config:

# corrected:
Register companions in your host application config (read at runtime by the doctor):
```

### WR-02: Unspecified case `{false, {:error, mods}}` silently dropped in doctor

**File:** `lib/crosswake/doctor/doctor.ex:564`

**Issue:** The `case {enabled, result}` block in `phase_38_companion_seam_findings/0` has three arms:
1. `{true, {:error, mods}}` — emits `:error` (correct, fail-closed)
2. `{false, :ok}` — emits `:advisory`
3. `_ ->` — returns `[]` (silent)

The wildcard arm `_ ->` catches two real states:
- `{true, :ok}` — enabled companion, dependency present: intentionally silent (the happy path).
- `{false, {:error, mods}}` — **disabled companion with a missing dependency**: also silently returns `[]`.

The plan (38-02-PLAN.md, task 2 behavior bullets) specifies behaviour for `{true, error}` and `{false, :ok}` but does not explicitly specify `{false, error}`. Silently dropping this case means a host who ships with a disabled companion that has a broken/missing dependency will get no warning at all — not even an advisory. This is arguably fine (disabled means inactive), but it makes doctor misleading when the host later enables the companion and suddenly gets a new error with no prior signal.

**Fix:** Add an explicit advisory for the `{false, {:error, mods}}` case rather than falling through to `_ ->`:

```elixir
{false, {:error, mods}} ->
  mod_names = Enum.map_join(mods, ", ", &inspect/1)
  [
    check(
      :advisory,
      "companion.disabled_dependency_missing",
      "companion.#{companion_id}",
      "Companion #{inspect(companion_id)} is disabled and its optional " <>
        "dependency is not loaded: #{mod_names}",
      "Add the missing library to your application's deps before enabling this companion.",
      %{missing_modules: mods}
    )
  ]

{true, :ok} ->
  []

_ ->
  []
```

This ensures every possible state is explicitly mapped rather than relying on the wildcard for two semantically different situations.

## Info

### IN-01: `validate_dependency/0` callback `@doc` refers to `enabled?: true` (style error in doc)

**File:** `lib/crosswake/companion.ex:108`

**Issue:** The `@doc` string for `validate_dependency/0` reads: "emits a `:companion.dependency_missing` finding when this returns an error AND the companion reports `enabled?: true`". The callback is `enabled?/1` (a function name with arity), not `enabled?: true` (a keyword-list key). The colon suffix makes this read as a struct/keyword field name rather than a function reference.

**Fix:**

```elixir
# current:
AND the companion reports `enabled?: true`.
# corrected:
AND `enabled?/1` returns `true`.
```

### IN-02: Advisory finding for disabled+present companion emits empty `details: %{}`

**File:** `lib/crosswake/doctor/doctor.ex:560`

**Issue:** The `:advisory` finding for `{false, :ok}` passes `%{}` as details. All other findings in the phase 38 block (and in `phase_19`) include structured details for programmatic consumers. An advisory with empty details omits `companion_id` from the details map, forcing consumers to parse the `check` field string (`"companion.<id>"`) to recover the companion identity. This is inconsistent with the `:error` finding which explicitly includes `%{missing_modules: mods}` for machine consumption.

**Fix:** Include the companion identity in the advisory details for consistency:

```elixir
%{companion_id: companion_id}
```

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
