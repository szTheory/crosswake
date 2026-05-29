---
phase: 33-corridor-routes-and-ci-infrastructure
reviewed: 2026-05-29T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - examples/phoenix_host/lib/crosswake_example/router.ex
  - test/crosswake/proof/phase33_commerce_corridor_routes_test.exs
  - .github/workflows/phase34-proof.yml
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 33: Code Review Report

**Reviewed:** 2026-05-29
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

> **Remediation (2026-05-29):** **CR-01 RESOLVED** — the corridor proof test was
> rewritten to be hermetic (in-line `Crosswake.Router` fixture, mirroring
> `Phase23CommerceSupportProofTest`), dropping the `:requires_example_host` tag.
> It now runs untagged inside the merge-blocking `phase34-proof.yml` lane
> (verified: hermetic suite 271→274 tests, 31→29 excluded). WR-02 (commerce POST
> routes through `:browser`/CSRF) is deferred to Phase 35 when route handlers
> land — the routes are handler-less forward-references in Phase 33. Other
> warnings/info remain tracked here.

## Summary

Phase 33 adds a `scope "/commerce"` block declaring three corridor routes,
a manifest-landing proof test, and a `phase34-proof.yml` CI workflow adapted
from `phase23-proof.yml`. The forward-referenced modules (`PaywallEntryLive`,
`CorridorController`) and absent handlers are deliberate and locked, so they
are not flagged.

The router DSL usage is correct: I traced the atom corridor (`:subscription_default`)
through `Crosswake.Policy.Schema.validate_identifier/1` (which `Atom.to_string`s
it) so the test's string key `manifest.commerce_corridors["subscription_default"]`
and atom role assertions are consistent with the build pipeline. The `live/4` and
`post/4` macro forms resolve to the correct `Crosswake.Router` macros.

The headline problem is a CI wiring defect: the new proof test is tagged
`@moduletag :requires_example_host`, which routes it into a lane that does not
exist. It runs in no CI job — the merge-blocking lane excludes the tag, the lane
that actually exercises example-host proofs runs an explicit per-file list that
omits it, and `phase34-proof.yml` never compiles the example host the test needs.
The test is therefore dead in CI and provides zero protection against regressions
in the routes this phase ships.

## Critical Issues

### CR-01: Phase 33 proof test executes in no CI lane (silent zero-coverage)

**File:** `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs:7`
**Issue:**
The test is tagged `@moduletag :requires_example_host` and depends on the
compiled example host via `Crosswake.TestSupport.ExampleHost.load!()`
(`test/support/example_host.ex:4`), which prepends
`examples/phoenix_host/_build/dev/lib/*/ebin` to the code path. For the test to
run and pass, a CI lane must (a) include the `requires_example_host` tag and
(b) compile the example host first. No lane does both for this file:

- `.github/workflows/phase34-proof.yml:83` runs `mix test --exclude requires_example_host`,
  which **excludes** this test by tag. It also never compiles the example host
  (no `cd examples/phoenix_host && mix compile` / `gen_manifest.exs` step), so
  `ExampleHost.load!()` would find no ebin dir even if the tag were included.
- `hex-page-proof.yml:57`, `hex-publish.yml:67`, and `release-please.yml:97` all
  use `--exclude requires_example_host` as well.
- `script/verify_phase5_example_hosts.sh:10-16` is the only place that compiles
  the example host (`gen_manifest.exs`) and runs `requires_example_host` proof
  tests, but it does so via an **explicit per-file path list** that omits
  `phase33_commerce_corridor_routes_test.exs`. Tagged tests run there only if
  named.

Net effect: this test never executes in CI. The routes added in
`router.ex:221-246` ship with no enforced proof. This is the inverse of the
phase34-proof.yml header comment, which claims (line 8-10) that the hermetic lane
picks up the proof "automatically" because the file is "untagged" — the file IS
tagged, so the auto-discovery premise does not hold for this file.

(Note: `phase21_reconciliation_example_test.exs` shares the same omission from the
script list — a pre-existing gap outside this phase's scope. This finding concerns
only the test introduced by Phase 33.)

**Fix:** Pick one and make the wiring explicit:

Option A — run it where the example host is actually built. Add the file to the
explicit list in `script/verify_phase5_example_hosts.sh`:
```bash
mix test \
  test/mix/tasks/crosswake_install_test.exs \
  test/crosswake/proof/phase5_proof_lane_test.exs \
  test/crosswake/proof/adopter_profile_contract_test.exs \
  test/crosswake/proof/phase7_saas_lane_test.exs \
  test/crosswake/proof/phase8_selective_native_lane_test.exs \
  test/crosswake/proof/phase9_local_first_lane_test.exs \
  test/crosswake/proof/phase33_commerce_corridor_routes_test.exs
```

Option B — make the test genuinely hermetic (drop the tag) so the phase34 lane
picks it up. This requires `phase34-proof.yml` to compile the example host
before `mix test`, mirroring `verify_phase5_example_hosts.sh:8`:
```yaml
      - name: Build example host
        run: cd examples/phoenix_host && mix deps.get && mix run gen_manifest.exs
```
and replacing `ExampleHost.load!()`/the tag with `Code.require_file` (as the
header comment at phase34-proof.yml:80-82 already describes the Phase 36 file
doing). Until one of these lands, the test must not be considered a proof.

## Warnings

### WR-01: phase34-proof.yml header comment contradicts the shipped wiring

**File:** `.github/workflows/phase34-proof.yml:5-10, 77-82`
**Issue:**
The header states the merge-blocking lane "exercises library-level Elixir tests
across the full test suite (excluding requires_example_host-tagged tests), so the
Phase 36 hermetic paywall corridor proof file is picked up automatically." The
step comment (lines 80-82) further asserts the proof file is "untagged and uses
`Code.require_file`." This describes a Phase 36 file that does not exist yet and
mis-describes the Phase 33 file that does (which is tagged and uses
`ExampleHost.load!()`). A reviewer reading this workflow will reasonably conclude
corridor routes are proven on every PR; they are not (see CR-01). Misleading CI
documentation that overstates coverage is a maintainability/safety hazard.
**Fix:** Either scope the comment to the genuinely-untagged Phase 36 file once it
lands, or correct it now to state that the Phase 33 corridor-route proof runs in
the example-host lane (`verify_phase5_example_hosts.sh`), not in this hermetic
lane.

### WR-02: Commerce POST routes pipe through `:browser`, not `:api`

**File:** `examples/phoenix_host/lib/crosswake_example/router.ex:222, 232-244`
**Issue:**
`post "/purchase"` and `post "/restore"` are placed under `pipe_through [:browser]`.
The `:browser` pipeline (lines 35-38) declares `plug :fetch_session` but no CSRF
protection (`:protect_from_forgery`), and the sibling POST route in this same
router (`/study/sync`, line 50) deliberately uses the `:api` pipeline. State-
changing POST endpoints behind a session-cookie pipeline with no forgery
protection are a CSRF foot-gun for whoever wires up the real handlers in Phase 35.
Even though handlers are intentionally absent now, the pipeline choice is baked
into the route declaration that ships in this phase and sets the contract the
handler inherits.
**Fix:** Route the purchase/restore POSTs through `:api` (or a dedicated
`:commerce` pipeline) to match `/study/sync`, or add `plug :protect_from_forgery`
to a pipeline these routes use, before handlers land:
```elixir
scope "/commerce", CrosswakeExample do
  pipe_through [:browser]
  # live paywall here
end

scope "/commerce", CrosswakeExample do
  pipe_through [:api]
  # post /purchase, post /restore here
end
```

### WR-03: setup_all has no failure surface if the example host is not built

**File:** `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs:11-14`
**Issue:**
`ExampleHost.load!()` (`test/support/example_host.ex:4-11`) silently succeeds even
when `_build/dev/lib/*/ebin` matches nothing — `Path.wildcard/1` returns `[]` and
`Enum.each` is a no-op, returning `:ok`. If this test is ever run in a lane where
the example host was not compiled (the most likely failure mode given CR-01), the
modules `CrosswakeExample.Router` etc. are simply undefined and the first
`Manifest.compile(CrosswakeExample.Router)` raises `UndefinedFunctionError` /
`ArgumentError` with no hint that the root cause is "example host not built." This
produces a confusing red instead of an actionable one.
**Fix:** This is shared infra, so fix in `example_host.ex` (benefits all
example-host proofs): raise a clear error when the wildcard is empty:
```elixir
def load! do
  ebins =
    @app_root |> Path.join("_build/dev/lib/*/ebin") |> Path.wildcard()

  if ebins == [] do
    raise "example host not compiled; run `cd examples/phoenix_host && mix compile` first"
  end

  Enum.each(ebins, &Code.prepend_path/1)
  :ok
end
```

## Info

### IN-01: Stale workflow reference in test doc comment

**File:** `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs:5-6`
**Issue:**
The comment says "Run by phase5-proof.yml, which builds the example host first."
This is copied from sibling proof tests, but the file is not actually wired into
`phase5-proof.yml`'s runner script (see CR-01). The comment asserts a coverage
claim that is false for this file.
**Fix:** After resolving CR-01, update the comment to name the lane that actually
runs this file.

### IN-02: Redundant `runtime: :live_view` on the paywall route

**File:** `examples/phoenix_host/lib/crosswake_example/router.ex:224-228`
**Issue:**
`crosswake_defaults runtime: :live_view, ...` already sets `runtime: :live_view`,
and the paywall route re-declares `runtime: :live_view` inside its own
`crosswake:` opts (line 227). Harmless and consistent with the explicit override
pattern the purchase/restore routes use (`:native_screen`), but redundant for the
paywall case.
**Fix:** Optional — drop the redundant `runtime: :live_view` on the paywall route
and let the scope default apply, or keep it for symmetry with the sibling routes.
Low priority.

---

_Reviewed: 2026-05-29_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
