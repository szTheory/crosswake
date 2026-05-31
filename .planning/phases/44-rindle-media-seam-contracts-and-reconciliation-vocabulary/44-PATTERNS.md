# Phase 44 Patterns: Rindle Media Contracts

## Closest Analogs

| New file | Closest analog | Pattern to copy |
|----------|----------------|-----------------|
| `lib/crosswake/companions/rindle/contracts.ex` | `lib/crosswake/commerce/contracts.ex` | Struct modules, closed vocabularies, canonical source normalization, `validate_*/1 :: :ok | {:error, keyword()}` |
| `lib/crosswake/companions/rindle/reconciliation.ex` | `lib/crosswake/commerce/reconciliation.ex` | Outcome vocabulary, `Attempt`, `IdempotencyKey`, `EvidenceResult`, evidence ingestion fence |
| `test/crosswake/companions/rindle/contracts_test.exs` | `test/crosswake/commerce/contracts_test.exs` | Exact vocabulary assertions, invalid lane/source/state validation, struct-shape assertions |
| `test/crosswake/companions/rindle/reconciliation_test.exs` | `test/crosswake/commerce/reconciliation_test.exs` | Evidence ingestion assertions, replay detection, direct authority override rejection |

## Module Layout

Use the in-tree companion convention established by rulestead:

- `lib/crosswake/companions/rindle/contracts.ex`
- `lib/crosswake/companions/rindle/reconciliation.ex`
- `test/crosswake/companions/rindle/contracts_test.exs`
- `test/crosswake/companions/rindle/reconciliation_test.exs`

Do not create `lib/crosswake/companions/rindle.ex` in Phase 44. The companion implementation belongs to Phase 45.

## Contract Patterns To Preserve

From `Crosswake.Commerce.Contracts`:

- Vocabularies are module attributes and exposed through functions.
- Structs use `@enforce_keys` for required identity and authority fields.
- Constructors accept maps or keyword lists and return `{:ok, struct} | {:error, keyword()}`.
- Validators return `:ok | {:error, keyword()}`.
- Invalid source/state values return structured details rather than booleans.

Apply this to Rindle:

- `media_state_vocabulary/0` returns exactly `[:queued, :uploaded, :scanning, :available, :rejected]`.
- `validate_media_object/1` rejects any state outside that list.
- `validate_capture_evidence/1` rejects evidence that attempts to carry direct availability or authority fields.
- `new_*` constructors use `struct!` inside a rescue boundary, matching commerce's `new_entitlement_snapshot/1` pattern.

## Reconciliation Patterns To Preserve

From `Crosswake.Commerce.Reconciliation`:

- `outcome_vocabulary/0` returns the canonical closed list.
- `unresolved_outcome?/1` and `workflow_reporting_outcome?/1` separate workflow state from final reporting state.
- Outcome predicates always return false for authority/access grant semantics.
- `ingest_evidence/2` rejects direct authority mutation before building an `EvidenceResult`.
- Replay detection accepts a list or `MapSet`.

Apply this to Rindle:

- `outcome_implies_availability?/1` returns false for every media reconciliation outcome.
- `availability_mutation_allowed_from_evidence?/1` returns false for `%CaptureEvidence{}`.
- `ingest_capture_evidence/2` rejects `availability_state: :available` and `authority_state: :available` opts.
- `ingest_capture_evidence/2` marks replays using `seen_idempotency_keys`.
- `IdempotencyKey` excludes `correlation_id`.

## Verification Pattern

Use hermetic ExUnit tests in the same style as commerce:

- `use ExUnit.Case, async: true` is acceptable because the tests should not mutate global application env.
- Fixture helpers should use `struct!(Module, Map.merge(base, overrides))`.
- Tests should assert exact atoms and exact error tuples/keywords.
- No `Code.require_file` or `examples/phoenix_host` dependencies are needed.

## Naming Notes

Use `Crosswake.Companions.Rindle.Contracts` and `Crosswake.Companions.Rindle.Reconciliation`, not `Crosswake.Rindle.*`. This keeps the namespace aligned with the v3.5 in-tree companion convention while avoiding a runnable companion implementation before Phase 45.

