# Phase 45: Rindle In-Tree Companion, Mock Example, And Proof - Research

**Researched:** 2026-05-31
**Status:** Ready for planning

## Research Complete

Phase 45 is an implementation and proof phase, not a new contract-design
phase. The strongest plan is to preserve Phase 44's contract boundary:
`Crosswake.Companions.Rindle.Contracts` and `Reconciliation` own reusable
semantic invariants, while `examples/phoenix_host` owns the runnable mock
workflow. Core should gain only the concrete companion module and optional
dependency posture.

## Existing Patterns

### Companion implementation

- `lib/crosswake/companions/rulestead.ex` is the direct template for a concrete
  companion. The Rindle companion must implement all six
  `Crosswake.Companion` callbacks, use `companion_id: :rindle`, and avoid
  compile-time references to optional APIs outside `Code.ensure_loaded?/1`.
- `lib/crosswake/companion/state.ex` already supports non-gating state through
  `details: %{}`. Rindle can report `gate_status: :unconfigured` and
  `kill_switch_status: :unconfigured` or `:inactive`, with media-specific
  details kept in `details`.
- Doctor dependency checks are already generic over registered companions. A
  Phase 45 proof can register `Crosswake.Companions.Rindle` in
  `Application.put_env(:crosswake, :companions, [...])` and assert
  `companion.dependency_missing` without adding new doctor plumbing.

### Optional dependency proof

- `mix.exs` already gates `rulestead` behind `MIX_INCLUDE_RULESTEAD`.
  Rindle should use the same pattern with `MIX_INCLUDE_RINDLE`.
- `test/crosswake/proof/phase43_rulestead_advisory_test.exs` is the model for
  an advisory-only dependency-present assertion. Rindle needs a separate
  `@moduletag :advisory_only` file so hermetic and advisory assertions do not
  conflict.
- `.github/workflows/phase43-proof.yml` is the closest workflow template:
  merge-blocking hermetic job with no optional dep, advisory scheduled/manual
  job with step-level env, and a documented promotion path.

### Media mock flow

- The commerce example modules under
  `examples/phoenix_host/lib/crosswake_example/commerce/` show the desired
  split:
  - mock evidence emitter
  - stable key derivation
  - evidence inbox/replay marking
  - backend projection
  - LiveView display state
- The media example should copy that shape without adding controller uploads,
  native shell behavior, storage-provider SDKs, or progress channels.
- `Crosswake.Companions.Rindle.Reconciliation.ingest_capture_evidence/2`
  already returns evidence-only `EvidenceResult` values and marks replay using
  stable idempotency key structs. Example-host modules can wrap those contracts
  rather than duplicating authority logic.

## Recommended Plan Shape

Use three plans:

1. Core companion and optional dependency wiring.
2. Example-host pure-Elixir media mock modules plus `/media/proof` LiveView and
   route policy entry.
3. Phase 45 proof lane: hermetic proof, advisory proof, and CI workflow.

This sequencing avoids blocking example-host work on CI details, while keeping
the proof plan last so it can assert the final mock route, invariants, and
optional dependency behavior.

## Implementation Notes

- `Crosswake.Companions.Rindle.validate_dependency/0` should check only the
  root `Rindle` module and return `:ok` or `{:error, [Rindle]}`.
- `route_gated?/2` should return `:pass`; Rindle is not a route gate in this
  phase.
- `kill_switch_active?/1` should return `false`; no Rindle kill-switch DSL is in
  scope.
- `report_state/0` should read `Application.get_env(:crosswake, :rindle, %{})`
  and set `enabled` from `:enabled`, mirroring Rulestead's style.
- The example mock should keep separate functions for grant creation, capture
  evidence emission, inbox ingestion, backend verification/projection, and
  display derivation. Avoid a single `upload_and_verify/1` helper.
- Stable media event identity should use `storage_target`, `grant_id`,
  `idempotency_key`, and event kind. `correlation_id` must remain trace-only.
- The LiveView proof route can be tested through direct LiveView callbacks like
  `phase35_paywall_live_test.exs`; it should be tagged
  `:requires_example_host` only when it depends on the checked-in example host
  being loaded.

## Validation Architecture

The validation strategy should be hermetic-first:

- Unit/proof tests for `Crosswake.Companions.Rindle` should run in the ordinary
  hermetic suite with no `rindle` dependency present.
- Pure media mock tests should `Code.require_file/2` only the example-host media
  modules they need, mirroring `phase34_mock_storefront_test.exs`.
- LiveView display assertions should be isolated in a `:requires_example_host`
  test if they need the example Phoenix host loaded.
- Advisory dependency-present assertions must live in a separate
  `@moduletag :advisory_only` file and run only under `MIX_INCLUDE_RINDLE=1`.
- CI should run `mix test --exclude requires_example_host --exclude advisory_only`
  for the merge-blocking job and only the advisory Rindle file in the advisory
  job.

## Risks And Mitigations

- Risk: Core grows into a generic upload framework.
  Mitigation: keep workflow orchestration in `examples/phoenix_host` and keep
  core changes limited to the companion module plus existing contracts.
- Risk: Queued or uploaded media is rendered as committed.
  Mitigation: plan source assertions and tests for copy/state labels that
  distinguish `:queued`, `:uploaded`, `:scanning`, and `:available`.
- Risk: Replay detection accidentally includes `correlation_id`.
  Mitigation: assert identical event/idempotency keys for changed correlation
  IDs and `replay?: true`.
- Risk: Advisory dependency inclusion bleeds into hermetic CI.
  Mitigation: use step-level `MIX_INCLUDE_RINDLE` only in advisory jobs and
  exclude `:advisory_only` from hermetic tests.
