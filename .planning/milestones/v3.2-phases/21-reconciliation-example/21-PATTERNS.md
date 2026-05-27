# Phase 21 Pattern Map: Reconciliation Example

Phase 21 should stay additive and example-first: show a runnable Phoenix-owned reconciliation inbox/projection reference without moving authority into device/storefront events, and without introducing provider-specific vocabulary into core seams.

## Target Files

| Target file | Planned action | Why this file |
| --- | --- | --- |
| `guides/commerce.md` | Modify | Add reconciliation example narrative, dual-key idempotency guidance, and projection precedence (`stale`/`pending`/`denied`/`granted`). |
| `test/crosswake/guides/commerce_test.exs` | Modify | Lock new guide language and prevent docs drift. |
| `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` | Create | Example-host append-only ingestion and attempt projection surface. |
| `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` | Create | Example-host `event_key` + `subject_key` derivation with provider-aware identity. |
| `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | Create | Example-host authoritative snapshot projection with monotonic ordering and derived top-level state. |
| `test/crosswake/proof/phase21_reconciliation_example_test.exs` | Create | Merge-blocking hermetic proof for RECN-01/02/03 using checked-in example host modules. |
| `examples/phoenix_host/lib/crosswake_example/application.ex` | Conditional modify | Only if the example uses a supervised in-memory process; follow existing child supervision pattern. |
| `examples/phoenix_host/README.md` | Optional modify | Discoverability pointer to reconciliation example modules and explicit example/docs-only scope statement. |

## Analog Map

| Target file | Closest analog(s) | Copy-forward pattern |
| --- | --- | --- |
| `guides/commerce.md` | `guides/commerce.md` (existing canonical flow + non-goals), `guides/capabilities.md` (docs-only posture language) | Extend existing sections with phase-21 additions; do not split vocabulary or introduce new guide style. |
| `test/crosswake/guides/commerce_test.exs` | `test/crosswake/guides/commerce_test.exs`, `test/crosswake/guides/capabilities_test.exs` | Keep literal string assertions for lockstep docs-contract checks; include negative provider-leak assertions in scoped sections. |
| `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` | `examples/phoenix_host/lib/crosswake_example/local_first/study.ex`, `examples/phoenix_host/lib/crosswake_example/selective_native/submissions.ex` | Keep thin host-context modules with explicit aliases and small functions; avoid framework mandates in core. |
| `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex` | `lib/crosswake/commerce/reconciliation.ex` (`IdempotencyKey` semantics) | Implement dual-key derivation as provider-aware backend identity; correlation IDs are trace metadata only. |
| `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | `lib/crosswake/commerce/contracts.ex` (lane structs + vocabulary), `lib/crosswake/commerce/reconciliation.ex` (non-authoritative outcomes) | Preserve lane model and fail-closed precedence; projection is the only grant/deny authority surface. |
| `test/crosswake/proof/phase21_reconciliation_example_test.exs` | `test/crosswake/proof/phase7_saas_lane_test.exs`, `test/crosswake/proof/phase8_selective_native_lane_test.exs`, `test/crosswake/proof/phase9_local_first_lane_test.exs` | Use `ExampleHost.load!/0`, assert example-host behavior plus scope boundary checks, and keep test naming/layout consistent with proof lane conventions. |
| Boundary posture (do not regress) | `lib/crosswake/policy/schema.ex`, `lib/crosswake/manifest/validator.ex` | Continue provider-neutral commerce vocabulary enforcement and fail-closed hints; phase 21 examples must align with these guards. |

## Pattern Notes

- **Example module structure (`CrosswakeExample.*`)**
  - Keep module names under `CrosswakeExample.Commerce.*`.
  - Keep functions small and explicit (input map/struct in, typed result out), mirroring host-context style.

```elixir
defmodule CrosswakeExample.SelectiveNative.Submissions do
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Submission

  def get_submission!(id), do: Repo.get!(Submission, id)
  def create_submission(attrs \\ %{}), do: %Submission{} |> Submission.changeset(attrs) |> Repo.insert()
end
```

- **Authority separation is hard guardrail**
  - Evidence ingestion can produce reconciliation status, replay metadata, and attempts.
  - Ingestion cannot mutate authority; projection does that after verification.

```elixir
def ingest_evidence(%Contracts.ReconciliationEvidence{} = evidence, opts \\ []) do
  with :ok <- reject_direct_authority_override(opts) do
    idempotency_key = to_idempotency_key(evidence)
    replay? = seen_idempotency_key?(idempotency_key, Keyword.get(opts, :seen_idempotency_keys, []))
    # ... returns EvidenceResult (non-authoritative)
  end
end
```

- **Provider-aware identity and replay semantics**
  - Copy `provider + provider_reference + event_kind` baseline identity shape.
  - Add separate `subject_key` for per-subject serialization; keep transient correlation IDs out of identity authority.

```elixir
defmodule IdempotencyKey do
  @enforce_keys [:provider, :provider_reference, :event_kind]
  defstruct [:provider, :provider_reference, :event_kind]
end
```

- **Docs-contract checks stay literal and explicit**
  - Extend existing guide tests with concrete phrase assertions (flow, keys, precedence).
  - Keep provider-leak `refute` checks in lifecycle/reconciliation sections.

```elixir
test "documents the canonical flow", %{content: content} do
  assert content =~ "Phoenix persists a reconciliation_attempt"
  assert content =~ "backend updates one authoritative entitlement_snapshot"
end
```

- **Proof-lane style is example-host first**
  - Phase proof tests should load checked-in example host code and assert behavior directly.
  - Reuse naming and setup style from existing phase proof files.

```elixir
setup_all do
  Crosswake.TestSupport.ExampleHost.load!()
  :ok
end
```

- **Boundary checks: provider-neutral vocabulary**
  - Keep example docs/code terms aligned with current manifest/policy provider-vocabulary rejection.
  - Do not introduce StoreKit/Play/RevenueCat labels in core or normalized example contract terms.

```elixir
if provider_specific_vocabulary?(commerce) do
  %{message: "route #{route.id} uses provider-specific commerce vocabulary ..."}
end
```

## Copy-Forward Checklist

- [ ] Keep all Phase 21 executable code under `examples/phoenix_host/...`, not `lib/crosswake/...`.
- [ ] Preserve backend-owned entitlement authority; evidence ingestion remains non-granting.
- [ ] Implement dual-key guidance explicitly: `event_key` (dedupe) + `subject_key` (serialized authority updates).
- [ ] Keep normalized evidence sources limited to `device`, `storefront`, `webhook`, `support`.
- [ ] Keep projection precedence deterministic and fail-closed (`stale` first, unresolved -> `pending`, then `granted`/`denied`).
- [ ] Guard monotonic projection ordering (`as_of` or equivalent) so stale events cannot overwrite fresher truth.
- [ ] Add proof-lane tests under `test/crosswake/proof/phase21_reconciliation_example_test.exs` with `ExampleHost.load!/0`.
- [ ] Extend `test/crosswake/guides/commerce_test.exs` with literal assertions for new example guidance.
- [ ] Keep provider-neutral vocabulary in docs and tests; add scoped `refute` checks where needed.
- [ ] Keep example/docs-only posture explicit in guide wording (no adapter shipped claims, no required persistence/job framework).

## Pitfalls

1. Treating device/storefront success as authority (violates ENTL-03 and Phase 20 contract posture).
2. Building idempotency around transient correlation IDs instead of provider-aware backend identity.
3. Allowing out-of-order events to overwrite newer snapshots (missing monotonic guard).
4. Leaking provider-specific enums/labels into normalized example docs or contract terms.
5. Turning example code into implicit framework mandate (Ecto/job queue required) instead of companion-ready reference.
6. Updating guide prose without corresponding docs-contract test updates.
