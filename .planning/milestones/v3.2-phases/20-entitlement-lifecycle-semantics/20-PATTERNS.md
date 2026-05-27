## PATTERN MAPPING COMPLETE

# Phase 20 Pattern Map: Entitlement Lifecycle Semantics

This map turns Phase 20 scope into concrete "reuse this exact shape" anchors from the current codebase so planning stays provider-neutral, backend-authoritative, and fail-closed.

## Scope Snapshot

Likely modifications from `20-CONTEXT.md` and `20-RESEARCH.md` cluster in:

- Core commerce contract semantics (`contracts`, `reconciliation`, optional thin seam updates)
- Boundary enforcement (`policy/schema`, `policy/validator`, `manifest/validator`)
- Support/doctor/docs parity for lifecycle vocabulary (semantic only, not provider adapter work)
- Merge-blocking tests for ENTL-01/02/03, especially "evidence cannot grant authority"

Primary likely targets:

- `lib/crosswake/commerce/contracts.ex`
- `lib/crosswake/commerce/reconciliation.ex`
- `lib/crosswake/commerce.ex`
- `lib/crosswake/manifest/validator.ex`
- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/policy/validator.ex`
- `guides/commerce.md`
- `test/crosswake/commerce/contracts_test.exs`
- `test/crosswake/commerce/reconciliation_test.exs`
- `test/crosswake/guides/commerce_test.exs`

Secondary/conditional targets (only if Phase 20 semantics are surfaced there now):

- `lib/crosswake/manifest/builder.ex`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/support_matrix/renderer.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/doctor/formatter.ex`
- `lib/crosswake/doctor/json_formatter.ex`
- `test/crosswake/manifest/validator_test.exs`
- `test/crosswake/support_matrix/support_matrix_test.exs`
- `test/crosswake/doctor/doctor_test.exs`

## Non-Drift Rules (Phase 20)

1. Keep entitlement authority backend-owned; device/storefront/webhook/support are evidence inputs only.
2. Keep lifecycle axes orthogonal (`authority`, `access`, `reconciliation`, `freshness`, `effective`, `evidence`), not one collapsed enum.
3. Keep provider vocabulary out of core contracts and validators (`storekit`, `play_billing`, `revenuecat` remain boundary-only).
4. Keep fail-closed language explicit (`return_to_phoenix_guidance`, explicit denial/recovery), never silent fallback.
5. Keep docs/support/doctor/test vocabulary synchronized to one canonical term set.

## Reusable Code Anchors

### A1) Typed struct contract with required keys
Source: `lib/crosswake/commerce/contracts.ex`

```elixir
defmodule EntitlementSnapshot do
  @enforce_keys [:group_id, :authority_state, :access_state, :checked_at, :stale_after, :effective_until]
  defstruct [:group_id, :authority_state, :access_state, :checked_at, :stale_after, :effective_until]
end
```

Reuse for lane structs and lane-level required keys.

### A2) Canonical vocabulary function for explicit state set
Source: `lib/crosswake/commerce/reconciliation.ex`

```elixir
def outcome_vocabulary do
  [:pending_purchase, :pending_restore, :awaiting_verification, :projection_refreshed, :conflict, :verification_failed, :stale_authority]
end
```

Reuse for lane vocab helpers (especially reconciliation/freshness), not raw provider states.

### A3) Backend-owned idempotency identity shape
Source: `lib/crosswake/commerce/reconciliation.ex`

```elixir
defmodule IdempotencyKey do
  @enforce_keys [:provider, :provider_reference, :event_kind]
  defstruct [:provider, :provider_reference, :event_kind]
end
```

Reuse for ENTL-03 evidence ingestion identity; keep correlation IDs supplemental.

### A4) Provider-specific term rejection at policy boundary
Source: `lib/crosswake/policy/schema.ex`

```elixir
@provider_specific_commerce_terms [:storekit, :play_billing, :revenuecat]
defp validate_commerce_role(value) when value in @provider_specific_commerce_terms do
  {:error, "provider-specific commerce role #{inspect(value)} is not supported in route policy"}
end
```

Reuse for any new commerce/entitlement public vocabulary entrypoint.

### A5) Deep provider-vocabulary scan in manifest validation
Source: `lib/crosswake/manifest/validator.ex`

```elixir
defp provider_specific_vocabulary?(value) when is_map(value),
  do:
    value
    |> normalize_provider_vocab_map()
    |> Enum.any?(fn {key, nested_value} ->
      provider_specific_vocabulary?(key) or provider_specific_vocabulary?(nested_value)
    end)
```

Reuse for nested entitlement lane/evidence validation to prevent leakage.

### A6) Canonical support truth map row with fail-closed fallback
Source: `lib/crosswake/support_matrix/support_matrix.ex`

```elixir
%{
  corridor_role: "purchase_intent",
  owner_posture: "native_or_companion_required",
  denial_codes: ["commerce.corridor.runtime_incompatible", "commerce.corridor.unsupported"],
  fallback_behavior: "Fail closed with return-to-Phoenix guidance; never grant entitlement authority from device intent alone."
}
```

Reuse when adding entitlement/freshness support posture rows.

### A7) Doctor structured finding envelope
Source: `lib/crosswake/doctor/doctor.ex`

```elixir
%Check{
  severity: severity,
  code: code,
  check: check_name,
  message: message,
  hint: hint,
  details: details
}
```

Reuse for any new stale/pending/authority separation diagnostics.

### A8) Guide parity tests as literal vocabulary lock
Source: `test/crosswake/guides/commerce_test.exs`

```elixir
assert content =~ "entitlement_snapshot"
assert content =~ "reconciliation_evidence"
assert content =~ "pending_purchase"
assert content =~ "awaiting_verification"
```

Reuse to prevent docs drift from contract semantics.

## File-by-File Mapping (Target -> Analog -> Pattern -> Pitfalls)

| Target file | Closest analog file(s) | Pattern to reuse | Pitfalls to avoid |
|---|---|---|---|
| `lib/crosswake/commerce/contracts.ex` | `lib/crosswake/manifest/types.ex`, existing structs in `lib/crosswake/commerce/contracts.ex` | Use explicit `@enforce_keys` + typed nested structs and keep top-level snapshot readable for pattern matching. | Collapsing axes into a single lifecycle enum; embedding provider payload/status fields in core structs. |
| `lib/crosswake/commerce/reconciliation.ex` | existing `outcome_vocabulary/0`, `IdempotencyKey`, `EvidenceResult` | Keep canonical vocabulary helper functions and evidence-only structs separate from authority projection types. | Letting pending/verification states imply authority grant; using transient correlation IDs as idempotency truth. |
| `lib/crosswake/commerce.ex` | existing callback seam in same file | Keep seam thin and backend-owned via typed callbacks over contracts, not provider SDK semantics. | Adding provider-specific callbacks or convenience APIs that mutate authority directly from evidence ingest. |
| `lib/crosswake/policy/schema.ex` | existing `validate_commerce_role/1` provider-term rejection | Reuse explicit allowlist + explicit provider-term rejection in custom validators. | Accepting free-form status strings that bypass core vocabulary boundaries. |
| `lib/crosswake/policy/validator.ex` | `validate_commerce_role/2`, `validate_commerce_corridor/2` | Extend validator pipeline with entitlement-vocabulary checks and actionable hints, preserving route-level diagnostics shape. | Mixing route policy ownership checks with provider mapping logic (belongs outside core policy). |
| `lib/crosswake/manifest/validator.ex` | `validate_route_commerce_*`, `provider_specific_vocabulary?/1` | Reuse layered validation: required fields -> vocabulary checks -> provider leak checks, with deterministic hints. | Only validating shallow fields and missing nested lane/evidence provider vocabulary leakage. |
| `lib/crosswake/manifest/builder.ex` (conditional) | capability catalog entries for `purchase_intent`/`entitlement_snapshot` | Reuse capability metadata rows (`owner`, `proof_class`, `fallback`, `prerequisites`) to keep support truth consistent. | Hardcoding provider names or implying adapters are shipped in core metadata/fallback copy. |
| `lib/crosswake/support_matrix/support_matrix.ex` (conditional) | `@commerce_corridor_entries`, `capability_family_entries/1` | Add narrow, explicit entitlement lifecycle support rows with fail-closed fallback wording and provider-neutral prerequisites. | Expanding matrix scope into adapter claims or adding broad non-verifiable support claims. |
| `lib/crosswake/support_matrix/renderer.ex` + `guides/support_matrix.md` (conditional) | deterministic section/table renderer | Keep generated markdown deterministic and source-driven from support matrix structs/maps. | Hand-editing generated guide text and drifting from renderer truth. |
| `lib/crosswake/doctor/doctor.ex` (conditional) | `phase_19_commerce_corridor_posture/1`, `manifest_compile_check/1` | Add semantic checks as typed findings with stable code/check/message/hint/details envelopes. | Emitting ad hoc strings without canonical codes, or diagnosing provider states directly in core. |
| `lib/crosswake/doctor/formatter.ex` + `lib/crosswake/doctor/json_formatter.ex` (conditional) | commerce corridor formatting helpers | Reuse additive formatter pattern that mirrors details in both human and JSON output. | Adding fields in one formatter only (parity break) or creating non-canonical status words. |
| `guides/commerce.md` | existing sections: vocabulary, authority vs evidence, canonical flow, non-goals | Keep explicit "evidence != authority" and fail-closed posture language; add lane semantics without provider enums. | Ambiguous wording that implies device success can grant entitlement or that web fallback is acceptable for digital goods. |
| `test/crosswake/commerce/contracts_test.exs` | existing small-struct and state-distinction tests | Keep explicit struct-level assertions and add axis-placement + invalid-state rejection cases. | Positive-only tests that do not enforce invalid mixed-state rejections. |
| `test/crosswake/commerce/reconciliation_test.exs` | existing idempotency/evidence-only tests | Add ENTL-03 negative tests proving evidence replay/submission cannot directly produce authority grant. | Asserting only field presence; failing to assert "no authority mutation from evidence path." |
| `test/crosswake/manifest/validator_test.exs` | existing commerce undeclared/provider-vocab tests | Add nested entitlement/evidence provider-leak rejection fixtures and deterministic error/hint assertions. | Regression to raw string checking without asserting explicit canonical messages/hints. |
| `test/crosswake/guides/commerce_test.exs` | existing literal content checks | Lock new lane vocabulary, stale/pending semantics, and authority/evidence language with literal assertions. | Updating guide copy without updating locked vocabulary tests (or vice versa). |

## Recommended Sequence (Planner-Friendly)

1. Contract semantics first: `contracts.ex` + `reconciliation.ex` (types + invariants + vocab).
2. Boundary hardening next: `policy/schema.ex` + `policy/validator.ex` + `manifest/validator.ex`.
3. Proof of ENTL-03: strengthen `reconciliation_test.exs` and contract tests with negative authority shortcut checks.
4. Docs parity: update `guides/commerce.md` and lock with `guides/commerce_test.exs`.
5. Conditional support/doctor sync only if Phase 20 semantics are surfaced now (keep Phase 22 scope boundaries intact).

## Planner Checklist

- [ ] Snapshot model lanes are explicit and typed; no axis collapse into one enum.
- [ ] Pending/verification states live in reconciliation axis, not authority axis.
- [ ] Evidence sources remain bounded (`device`, `storefront`, `webhook`, `support`) and non-authoritative.
- [ ] Provider terms are rejected across policy + manifest + docs where core vocabulary is expected.
- [ ] At least one merge-blocking negative test proves evidence cannot directly grant authority.
- [ ] Fail-closed fallback language is explicit and consistent across code, doctor/support surfaces, and docs.
