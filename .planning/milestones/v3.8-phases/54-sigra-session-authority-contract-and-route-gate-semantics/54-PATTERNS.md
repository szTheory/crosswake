# Phase 54: Sigra Session Authority Contract And Route-Gate Semantics - Pattern Map

**Mapped:** 2026-06-01
**Files analyzed:** 17
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/companions/sigra/contracts.ex` | model | request-response | `lib/crosswake/companions/sigra/contracts.ex` | exact |
| `lib/crosswake/companions/sigra/evaluator.ex` | service | request-response | `lib/crosswake/compatibility/route_gate.ex` | data-flow-match |
| `lib/crosswake/companions/sigra/denial_codes.ex` | utility | transform | `lib/crosswake/shell/denial.ex` | role-match |
| `lib/crosswake/compatibility/route_gate.ex` | middleware | request-response | `lib/crosswake/compatibility/route_gate.ex` | exact |
| `lib/crosswake/policy/schema.ex` | config | transform | `lib/crosswake/policy/schema.ex` | exact |
| `lib/crosswake/policy/route.ex` | model | transform | `lib/crosswake/policy/route.ex` | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | `lib/crosswake/manifest/types.ex` | exact |
| `lib/crosswake/shell/denial.ex` | model | transform | `lib/crosswake/shell/denial.ex` | exact |
| `lib/crosswake/doctor/doctor.ex` | service | batch | `lib/crosswake/doctor/doctor.ex` | exact |
| `lib/crosswake/doctor/publish_readiness.ex` | service | batch | `lib/crosswake/doctor/publish_readiness.ex` | exact |
| `lib/crosswake/operator_inspection.ex` | service | transform | `lib/crosswake/operator_inspection.ex` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | config | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `guides/companions.md` | config | transform | `guides/support_matrix.md` | role-match |
| `test/crosswake/companions/sigra/contracts_test.exs` | test | request-response | `test/crosswake/companions/sigra/contracts_test.exs` | exact |
| `test/crosswake/compatibility/route_gate_test.exs` | test | request-response | `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | role-match |
| `test/crosswake/proof/phase54_sigra_session_authority_test.exs` | test | request-response | `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | role-match |
| `test/crosswake/guides/companions_test.exs` | test | transform | `test/crosswake/guides/companions_test.exs` | exact |

## Pattern Assignments

### `lib/crosswake/companions/sigra/contracts.ex` (model, request-response)
**Analog:** `lib/crosswake/companions/sigra/contracts.ex`

**Imports + nested contract structs** ([contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/contracts.ex):1-42):
```elixir
defmodule Crosswake.Companions.Sigra.Contracts do
  defmodule AuthContext do
    @enforce_keys [:actor_id, :org_id, :mfa_level, :auth_age]
    defstruct [:actor_id, :org_id, :mfa_level, :auth_age, :session_authority_lane, :as_of]
  end

  defmodule SessionAuthorityLane do
    @enforce_keys [:authority_state, :mfa_level, :auth_age_seconds]
    defstruct [:authority_state, :mfa_level, :auth_age_seconds, :authenticated_at, :session_id]
  end
```

**Constructor + validator pattern** ([contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/contracts.ex):92-123):
```elixir
def new_auth_context(attrs), do: build_and_validate(attrs, AuthContext, &validate_auth_context/1, :auth_context)
def new_session_authority_lane(attrs), do: build_and_validate(attrs, SessionAuthorityLane, &validate_session_authority_lane/1, :session_authority_lane)
```

**Evidence-authority fence** ([contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/contracts.ex):64-65,136-145,204-212):
```elixir
@forbidden_evidence_authority_keys [:authority_state, :mfa_level, :auth_level, :session_authority, :access_granted]
```

### `lib/crosswake/companions/sigra/evaluator.ex` (service, request-response)
**Analog:** `lib/crosswake/compatibility/route_gate.ex`

**Return-shape pattern for evaluator decisions** ([route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex):17-29):
```elixir
defmodule Decision do
  defstruct [:route_id, :status, :denial, denials: [], transition: :activate]
end
```

**Fail-closed auth predicate entry check** ([route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex):180-189):
```elixir
auth_predicated? = not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth)
```

**Sanitized details pattern** ([route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex):261-280):
```elixir
|> maybe_put_optional_ref("challenge_ref", Keyword.get(opts, :challenge_ref))
|> maybe_put_optional_ref("step_up_token_ref", Keyword.get(opts, :step_up_token_ref))
```

### `lib/crosswake/compatibility/route_gate.ex` (middleware, request-response)
**Analog:** `lib/crosswake/compatibility/route_gate.ex`

**Layered denial ordering** ([route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex):41-56):
```elixir
gate_denials = prepend_gate_evaluation_findings([], route, target)
auth_denials = prepend_auth_evaluation_denials([], route, opts, gate_denials)
denials = gate_denials ++ auth_denials ++ compatibility_denials
```

**Auth contract validation boundary** ([route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex):222-229):
```elixir
case Contracts.validate_auth_context(auth_context) do
  :ok -> {:ok, auth_context}
  {:error, _reasons} -> {:error, %{}}
end
```

### `lib/crosswake/policy/schema.ex` + `lib/crosswake/policy/route.ex` + `lib/crosswake/manifest/types.ex`
**Analogs:** same files

**Schema option pattern** ([schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex):82-89):
```elixir
auth_min_level: [type: {:custom, __MODULE__, :validate_auth_min_level, []}],
requires_recent_auth: [type: {:custom, __MODULE__, :validate_requires_recent_auth, []}]
```

**Cross-field route validation pattern** ([route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex):57-63,89-111,120-139):
```elixir
with {:ok, validated} <- validate_offline_contracts(validated),
     {:ok, validated} <- validate_gating_posture(validated) do
  {:ok, struct!(__MODULE__, validated)}
end
```

**Manifest struct + serialization parity** ([types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex):206-210,674-677,954-961):
```elixir
auth_min_level: Keyword.get(attrs, :auth_min_level),
requires_recent_auth: Keyword.get(attrs, :requires_recent_auth)
```

### Diagnostics surfaces (`doctor`, `publish_readiness`, `operator_inspection`, `support_matrix`)
**Analogs:** same files

**Doctor finding pattern** ([doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex):727-755):
```elixir
check(:advisory, "auth.route_predicated", "auth.#{route.id}", ..., %{route_id: route.id, ...})
check(:advisory, "auth.step_up_required_contract", "auth.contract_posture", ..., %{fallback: :step_up_required})
```

**Publish-readiness advisory check pattern** ([publish_readiness.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/publish_readiness.ex):372-405):
```elixir
advisory_check(
  id: "auth.session_predicate_readiness",
  code: "diag.auth.sigra_contract_only",
  ...
)
```

**Operator inspection auth slice pattern** ([operator_inspection.ex](/Users/jon/projects/crosswake/lib/crosswake/operator_inspection.ex):241-255):
```elixir
%{
  auth_min_level: route.auth_min_level,
  requires_recent_auth: route.requires_recent_auth,
  fallback: if(predicated?, do: :step_up_required, else: nil)
}
```

**Support matrix canonical truth row** ([support_matrix.ex](/Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex):124-136):
```elixir
@auth_contract_truth [
  %{route_predicates: [:auth_min_level, :requires_recent_auth], denial_vocabulary: :step_up_required}
]
```

### Tests (`contracts_test`, `route_gate_test`, `phase54 proof`, `guides parity`)
**Analogs:** `test/crosswake/companions/sigra/contracts_test.exs`, `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`, `test/crosswake/guides/companions_test.exs`

**Contract test style** ([contracts_test.exs](/Users/jon/projects/crosswake/test/crosswake/companions/sigra/contracts_test.exs):6-23,54-71):
```elixir
assert {:ok, auth_context} = Contracts.new_auth_context(...)
assert {:error, errors} = Contracts.validate_evidence_lane(%{authority_state: :active})
```

**RouteGate proof style with hermetic router modules** ([phase46_sigra_auth_contract_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase46_sigra_auth_contract_test.exs):13-38,150-190,214-226):
```elixir
decision = RouteGate.evaluate(manifest, "secure", target, [])
assert decision.denial.reason == :step_up_required
```

**Docs-contract parity test pattern** ([phase46_sigra_auth_contract_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase46_sigra_auth_contract_test.exs):228-249):
```elixir
assert Enum.any?(report.findings, &(&1.code == "auth.step_up_required_contract"))
```

## Shared Patterns

### Authority Fence
**Source:** [lib/crosswake/companions/sigra/contracts.ex](/Users/jon/projects/crosswake/lib/crosswake/companions/sigra/contracts.ex):136-145  
**Apply to:** `contracts.ex`, `evaluator.ex`, all Sigra auth-return/handoff inputs
```elixir
def validate_evidence_lane(evidence) when is_map(evidence) do
  []
  |> reject_evidence_authority_lane(evidence)
  |> to_validation_result()
end
```

### Fail-Closed Gate Order
**Source:** [lib/crosswake/compatibility/route_gate.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex):54-56,177-189  
**Apply to:** `route_gate.ex`, new `evaluator.ex`
```elixir
denials = gate_denials ++ auth_denials ++ compatibility_denials
```

### Safe Denial Envelope
**Source:** [lib/crosswake/shell/denial.ex](/Users/jon/projects/crosswake/lib/crosswake/shell/denial.ex):51-67  
**Apply to:** `evaluator.ex`, `route_gate.ex`, diagnostics
```elixir
Denial.new(reason: :step_up_required, message: "...", route_id: route.id, details: sanitized_details)
```

### Canonical Support/Diagnostics Source
**Source:** [lib/crosswake/support_matrix/support_matrix.ex](/Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex):124-136  
**Apply to:** `doctor.ex`, `publish_readiness.ex`, `operator_inspection.ex`, guides/tests
```elixir
@auth_contract_truth [...]
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | - | - | Existing Sigra/RouteGate/doctor/support/proof surfaces provide direct analogs for all scoped files. |

## Metadata

**Analog search scope:** `lib/crosswake/**`, `test/crosswake/**`, `guides/**`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-06-01
