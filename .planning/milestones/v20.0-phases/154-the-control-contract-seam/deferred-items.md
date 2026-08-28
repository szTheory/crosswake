# Phase 154 — Deferred / Out-of-Scope Items

Discovered while executing 154-02 (`Capability.rebuild`/`Capability.interaction` +
`manifest_schema_version` 1.0.0 -> 1.1.0 bump). Logged per the executor's scope-boundary
rule — pre-existing, unrelated to this plan's changes, not fixed here.

## 1. `validator_test.exs` temp-file test hygiene (pre-existing, unrelated)

**File:** `test/crosswake/manifest/validator_test.exs`
**Test:** "json rendering is deterministic and preserves created, reused, and updated semantics"

The test writes to `Path.join(System.tmp_dir!(), "crosswake-manifest-#{System.unique_integer([:positive])}.json")`
and asserts the first `Serializer.write/2` call returns `{:ok, :created}`, but never
calls `on_exit(fn -> File.rm(path) end)` to clean up. `System.unique_integer([:positive])`
restarts its counter each fresh `mix test` BEAM instance, so a low integer from an early
test run in the suite can collide with a same-named leftover file from a much earlier
`mix test` invocation (confirmed: files as old as several weeks were found in `$TMPDIR`
during this session), causing the assertion to observe `{:ok, :updated}` instead of
`{:ok, :created}`.

**Confirmed unrelated to Phase 154:** stale `crosswake-manifest-*.json` files pre-dating
this phase's work were found in `$TMPDIR`; the collision is purely a function of how many
times `System.unique_integer/1` has been called earlier in a given `mix test` process, not
of anything this plan changed. Reproduces when running
`mix test test/crosswake/manifest/validator_test.exs` in isolation after several prior
`mix test` invocations in the same session; does not reproduce when run as part of the
full suite (a higher unique_integer value avoids the stale-file collision).

**Suggested fix (not applied — out of scope for this plan):** add `on_exit(fn -> File.rm(path) end)`
after the path is computed, so the test cleans up after itself regardless of pass/fail.
