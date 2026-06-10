---
phase: 97-fix-guide-accuracy-conn-assigns-claim-record-in-multi-arity
reviewed: 2026-06-10T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - guides/threadline.md
  - test/crosswake/proof/phase96_threadline_docs_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 97: Code Review Report

**Reviewed:** 2026-06-10
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed `guides/threadline.md` (the primary deliverable correcting the WR-02 and WR-03 guide inaccuracies) and its companion contract test `test/crosswake/proof/phase96_threadline_docs_contract_test.exs`.

The two targeted fixes (WR-02: `record_in_multi/3` arity and WR-03: `Logger.metadata()[:crosswake_thread_id]` read-path) are present and correct in the guide. All 25 contract test assertions are satisfiable against the current guide content — the test suite would pass as written.

Two defects surfaced:

1. **WR-01 (WARNING)** — The hermetic lane guard in the test file uses a broken string concatenation that produces `"CrosswakeExample."` instead of `"Crosswake.Example."`, silently defeating the guard it is supposed to provide.

2. **WR-02 (WARNING)** — The guide uses `(posture: :inbound)` and `(posture: :minted)` notation in the Propagation Contract section when describing the header read/mint behaviour, but the actual emitted telemetry metadata key for these values is `source`, not `posture`. The correct key is documented in a separate sentence on line 49, but the inline label on line 22 will mislead operators who scan the guide to understand what keys their telemetry handlers will see.

---

## Warnings

### WR-01: Hermetic lane guard checks wrong string — guard is silently broken

**File:** `test/crosswake/proof/phase96_threadline_docs_contract_test.exs:44`

**Issue:** The test uses Elixir's binary concatenation operator to avoid the guard pattern matching itself:

```elixir
refute String.contains?(source, "Crosswake" <> "Example."),
```

Elixir evaluates `"Crosswake" <> "Example."` to `"CrosswakeExample."` (no dot inserted between the two string literals). The error message on line 45 says the test guards against `Crosswake.Example.*`, but the actual runtime check looks for `CrosswakeExample.` — a string that will never appear in a well-formed Elixir source file. If someone accidentally adds `alias Crosswake.Example.Repo` or any other `Crosswake.Example.*` reference to this test, the guard would silently pass instead of failing.

The correct split that prevents self-match while checking the right string is:

```elixir
refute String.contains?(source, "Crosswake." <> "Example."),
       "guides/threadline.md parity test must not reference the example-host ..."
```

Or equivalently using a regex:

```elixir
refute source =~ ~r/Crosswake\.Example\./,
       "guides/threadline.md parity test must not reference the example-host ..."
```

---

### WR-02: Guide uses `posture:` label where the actual telemetry key is `source`

**File:** `guides/threadline.md:22`

**Issue:** The Propagation Contract section says:

> The plug reads an inbound header **(posture: `:inbound`)** or mints a new id **(posture: `:minted`)**.

Elixir developers reading parenthetical key-value hints like `(posture: :inbound)` will parse this as a keyword-list entry. The real telemetry metadata key for these values is `source`, not `posture`. The actual emission (confirmed in `lib/crosswake/plug/threadline.ex:50`) is:

```elixir
meta = [thread_id: id, source: source]
```

where `source = :inbound | :minted`. An operator writing a telemetry handler who reads line 22 before line 49 will look for a `posture` key in event metadata and not find it, then look for a `source` key in alarm/confusion.

Line 49 correctly documents `source` as one of the four allowlisted keys, but the line 22 notation introduces a contradictory label immediately in the first section an operator reads.

**Fix:** Change line 22's parentheticals to use the real key name:

```markdown
The plug reads an inbound header (source: `:inbound`) or mints a new id
(source: `:minted`). It stores the id in `Logger.metadata` under the
`:crosswake_thread_id` key — read it in downstream plugs or controllers
via `Logger.metadata()[:crosswake_thread_id]`.
```

---

## Info

### IN-01: Guide file read repeated in every test — no shared binding or `setup_all`

**File:** `test/crosswake/proof/phase96_threadline_docs_contract_test.exs:53,65,78,91,113,131,144,151,158,165,172,179,190,197,204,211,222,229,236,252,261`

**Issue:** `File.read!("guides/threadline.md")` is called 21 times — once per test body. The test module has `async: false` and no `setup_all` block. While not incorrect, the repeated I/O is unnecessary; the file is static for the duration of the test run.

**Fix:** Hoist the read into a `setup_all/1` callback and share the result via context:

```elixir
setup_all _ctx do
  %{guide: File.read!("guides/threadline.md")}
end

test "guides/threadline.md documents ...", %{guide: guide} do
  assert guide =~ "..."
end
```

This also makes it immediately visible if the file is missing (one failure at setup, not 21 cascading failures).

---

### IN-02: Telemetry event name contract test checks segments, not full event-name strings

**File:** `test/crosswake/proof/phase96_threadline_docs_contract_test.exs:93-95`

**Issue:** The event-name test iterates over each segment of each event name (`[:crosswake, :threadline, :request, :start]` → checks `"crosswake"`, `"threadline"`, `"request"`, `"start"` individually). The individual segments `"start"`, `"stop"`, `"request"` are extremely common English words that appear naturally throughout the guide for unrelated reasons. The check would pass even if the guide's event-name table were deleted, as long as those words appeared anywhere in the document.

This is a pre-existing weakness in the test design. The guide does correctly document all three full event-name literals verbatim (lines 45–47), so the test result is correct — but for the wrong reason for the `:start`/`:stop`/`:request` segments.

**Fix:** Add an assertion that checks for the complete event-name string in addition to the per-segment loop:

```elixir
for event_name <- Crosswake.Threadline.Telemetry.event_names() do
  full_name = Enum.map_join(event_name, ", ", &":#{&1}")
  assert guide =~ "[#{full_name}]",
         "guides/threadline.md must document full event name '[#{full_name}]'"
end
```

---

_Reviewed: 2026-06-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
